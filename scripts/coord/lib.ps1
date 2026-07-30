<#
.SYNOPSIS
    Who else is working in this repo right now, and what files they are changing.

.DESCRIPTION
    Dot-source this; it defines functions and does nothing on its own.

        . "$PSScriptRoot\lib.ps1"
        $peers = Get-CoordPeers          # live sessions in this repo, excluding this one
        $rows  = Get-CoordOverlap -File  "assets/css/styles.css"

    WHY A REGISTRY READ AND NOT THE SESSION MCP. The `ccd_session_mgmt` MCP tools are only callable by
    the model, never by a hook -- hooks are shell commands. And `list_sessions` enumerates only the
    sessions the desktop app itself spawned: verified on this host 2026-07-30, it returned 4 sessions
    while `<config-root>/sessions/*.json` held 6, the two extras being a VS Code session and this one.
    A coordination gate that cannot see a whole surface is not a gate. So the deterministic half of
    coordination reads the registry, and the model uses the MCP for what only it can do -- reading a
    peer's transcript and messaging it. See CLAUDE.md "Parallel sessions".

    LIVENESS IS A FENCE, NOT A PID CHECK. Pids are reused and these records outlive their process, so a
    bare "is the pid alive" test reports long-dead sessions as live. We compare the process start time
    against the recorded session start: a process that started AFTER its session registered is a
    recycled pid, not that session.

    SELF IS RESOLVED BY CWD, NOT BY PID. A hook runs as a child (often grandchild) of the session
    process, so its own $PID never appears in the registry; walking the parent chain needs a CIM query
    of the whole process table, which is the most expensive thing a per-edit gate could do. The hook
    inherits the session's working directory instead, so the session whose worktree contains $PWD is
    us. The one case that breaks -- two sessions sharing one worktree -- is handled by claiming self
    only when the match is unambiguous, so a second session in our own worktree surfaces as the loud
    peer it is rather than being silently swallowed as "self".

    READ-ONLY. Nothing here writes to the registry, deletes a record, or contacts another session.
#>

$script:CoordCacheTtlSeconds = 15

# --- Registry -----------------------------------------------------------------------------------

# Every config root holding a session registry. Several logins can coexist on one machine (~\.claude
# plus any ~\.claude-account-N) and a session is only visible to the login that owns it.
function Get-CoordConfigRoots {
    [CmdletBinding()]
    param([string[]]$ConfigRoot)
    if ($ConfigRoot) { return @($ConfigRoot | Where-Object { Test-Path $_ }) }
    return @(
        Get-ChildItem -Path $env:USERPROFILE -Directory -Filter ".claude*" -Force -EA SilentlyContinue |
            Where-Object { Test-Path (Join-Path $_.FullName "sessions") } |
            ForEach-Object { $_.FullName }
    )
}

function Get-CoordSessionRecords {
    [CmdletBinding()]
    param([string[]]$ConfigRoot)
    $out = @()
    foreach ($root in (Get-CoordConfigRoots -ConfigRoot $ConfigRoot)) {
        foreach ($f in @(Get-ChildItem (Join-Path $root "sessions") -Filter *.json -EA SilentlyContinue)) {
            # One malformed record must never take down a caller -- this runs in a SessionStart hook,
            # where a throw would replace the chat's entire starting context with a stack trace.
            try { $rec = Get-Content $f.FullName -Raw -EA Stop | ConvertFrom-Json -EA Stop } catch { continue }
            if ($rec) { $out += $rec }
        }
    }
    return $out
}

# The fence. See the header for why this is not just "is the pid alive".
#   LIVE        pid resolves and its start time is consistent. Trustworthy.
#   UNVERIFIED  pid resolves; the fence could not be evaluated. Treat as possibly-live.
#   STALE       pid resolves but belongs to a different process. The session is gone.
#   DEAD        no such pid.
# Only the positive answer is safe to act on: registry writes are event-driven and there is no
# heartbeat, so nothing here can prove a session is gone -- only that it is present.
function Test-CoordLiveness {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowNull()][object]$Record,
        # How far a process may have started BEFORE its session registered and still be the same run.
        # Generous: registration follows process start, but a cold start on a loaded box can lag.
        [int]$StartSkewMinutes = 15
    )
    if (-not $Record) { return @{ State = "DEAD"; Detail = "no record" } }
    $procId = [int]$Record.pid
    if (-not $procId) { return @{ State = "DEAD"; Detail = "no pid in record" } }

    $proc = Get-Process -Id $procId -EA SilentlyContinue
    if (-not $proc) { return @{ State = "DEAD"; Detail = "pid $procId not running" } }

    $procStart = $null
    try { $procStart = $proc.StartTime } catch { }
    # Access can be denied for a process in another context. Report the uncertainty rather than
    # upgrading it to LIVE: an unverifiable fence is not a passed fence.
    if (-not $procStart) { return @{ State = "UNVERIFIED"; Detail = "pid $procId alive; start time unreadable" } }
    if ($null -eq $Record.startedAt) { return @{ State = "UNVERIFIED"; Detail = "pid $procId alive; record has no startedAt" } }

    $registered = [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$Record.startedAt).LocalDateTime
    $delta = ($procStart - $registered).TotalMinutes
    if ($delta -gt 1) { return @{ State = "STALE"; Detail = "pid $procId reused (process started $([int]$delta)m after the session)" } }
    if ($delta -lt (-1 * $StartSkewMinutes)) { return @{ State = "STALE"; Detail = "pid $procId start precedes the session by $([int](-$delta))m" } }
    return @{ State = "LIVE"; Detail = "" }
}

# --- Repo scoping -------------------------------------------------------------------------------

function ConvertTo-CoordNorm([string]$p) {
    if (-not $p) { return "" }
    return ($p -replace '\\', '/').TrimEnd('/').ToLowerInvariant()
}

# Every worktree sharing this .git. Keyed on the whole set rather than one path, because the point is
# seeing siblings. The first entry git reports is the primary (trunk) checkout -- worth naming,
# because a session sitting there is the one most likely to collide with everyone else.
function Get-CoordWorktrees {
    $porcelain = & git worktree list --porcelain 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $porcelain) { return @() }
    $out = @()
    $cur = $null
    foreach ($line in $porcelain) {
        if ($line -like "worktree *") {
            $cur = [pscustomobject]@{ Path = $line.Substring(9).Trim(); Branch = "(detached)" }
            $out += $cur
        }
        elseif ($line -like "branch *" -and $cur) {
            $cur.Branch = ($line.Substring(7).Trim() -replace '^refs/heads/', '')
        }
    }
    return $out
}

function Get-CoordSurface([string]$Entrypoint) {
    switch -Regex ($Entrypoint) {
        '^claude-desktop$' { return "desktop" }
        '^claude-vscode$'  { return "vscode" }
        '^$'               { return "?" }
        default            { return $Entrypoint -replace '^claude-', '' }
    }
}

# --- Roster -------------------------------------------------------------------------------------

<#
    Every session whose cwd sits inside a worktree of THIS repo, fenced for liveness and marked with
    whether it is us. Returns [] outside a git repo.
#>
function Get-CoordRoster {
    [CmdletBinding()]
    param([string[]]$ConfigRoot, [int]$StartSkewMinutes = 15)

    $worktrees = Get-CoordWorktrees
    if ($worktrees.Count -eq 0) { return @() }

    $index = @{}
    foreach ($w in $worktrees) { $index[(ConvertTo-CoordNorm $w.Path)] = $w }
    $primaryNorm = ConvertTo-CoordNorm $worktrees[0].Path
    $hereNorm = ConvertTo-CoordNorm $PWD.Path

    $rows = @()
    foreach ($rec in (Get-CoordSessionRecords -ConfigRoot $ConfigRoot)) {
        if (-not $rec.cwd) { continue }

        # Scope: cwd inside one of this repo's worktrees. Longest match wins, so a session cd'd into a
        # subdirectory is attributed to its own worktree rather than to the primary that contains it.
        $cwdNorm = ConvertTo-CoordNorm $rec.cwd
        $matchKey = $null
        foreach ($k in $index.Keys) {
            if ($cwdNorm -eq $k -or $cwdNorm.StartsWith("$k/")) {
                if (-not $matchKey -or $k.Length -gt $matchKey.Length) { $matchKey = $k }
            }
        }
        if (-not $matchKey) { continue }
        $match = $index[$matchKey]

        $live = Test-CoordLiveness -Record $rec -StartSkewMinutes $StartSkewMinutes
        $sid = [string]$rec.sessionId
        $rows += [pscustomobject]@{
            State      = $live.State
            Detail     = $live.Detail
            Live       = ($live.State -eq "LIVE" -or $live.State -eq "UNVERIFIED")
            Surface    = Get-CoordSurface $rec.entrypoint
            SessionId  = $sid
            Short      = if ($sid) { $sid.Substring(0, [Math]::Min(8, $sid.Length)) } else { "?" }
            Pid        = [int]$rec.pid
            Worktree   = $match.Path
            Label      = if ($matchKey -eq $primaryNorm) { "the SHARED PRIMARY" } else { Split-Path $match.Path -Leaf }
            IsPrimary  = ($matchKey -eq $primaryNorm)
            Branch     = $match.Branch
            InMyTree   = ($hereNorm -eq $matchKey -or $hereNorm.StartsWith("$matchKey/"))
            IsSelf     = $false
        }
    }

    # Self by cwd, claimed only when unambiguous. If two live sessions share our worktree, neither is
    # marked self -- they are colliding on the same bytes and both deserve to be seen.
    $mine = @($rows | Where-Object { $_.InMyTree -and $_.Live })
    if ($mine.Count -eq 1) { $mine[0].IsSelf = $true }

    $order = @{ "LIVE" = 0; "UNVERIFIED" = 1; "STALE" = 2; "DEAD" = 3 }
    return @($rows | Sort-Object @{ E = { $order[$_.State] } }, @{ E = { $_.Label } })
}

function Get-CoordPeers {
    [CmdletBinding()]
    param([string[]]$ConfigRoot)
    return @(Get-CoordRoster -ConfigRoot $ConfigRoot | Where-Object { $_.Live -and -not $_.IsSelf })
}

# --- What each peer is changing -----------------------------------------------------------------

# The base to diff a worktree's branch against. origin/main when we have it (a branch cut days ago
# still diffs sanely), local main otherwise. $null means "no usable base" -- callers fall back to
# uncommitted changes only, which is a smaller answer, never a wrong one.
function Get-CoordBase([string]$WorktreePath) {
    foreach ($ref in @("origin/main", "main")) {
        & git -C $WorktreePath rev-parse --verify --quiet "$ref^{commit}" *>$null
        if ($LASTEXITCODE -eq 0) { return $ref }
    }
    return $null
}

<#
    Repo-relative paths a worktree is changing: committed on its branch plus anything uncommitted.
    Uncommitted matters most -- it is the work in flight right now.

    THE COMMITTED HALF IS AN INTERSECTION OF TWO DIFFS, AND IT HAS TO BE. Neither alone is right:

      three-dot (base...HEAD)  what this branch AUTHORED. Survives a squash merge -- the squashed
                               commit is not an ancestor of the branch, so the merge-base never moves
                               and the branch is credited with its files forever. Caught in testing
                               2026-07-30: a session whose PR had just merged still blocked 31 files.
      two-dot   (base HEAD)    what still DIFFERS from main. Zero after a squash merge, correctly --
                               but a branch merely behind main also "differs" on every file main
                               advanced, which would blame it for other people's work.

    Authored AND still differing is the honest definition of in-flight, and it self-clears the moment
    the work lands however it lands -- squash, rebase or merge commit.
#>
function Get-CoordChangedFiles([string]$WorktreePath) {
    $files = @()
    $base = Get-CoordBase $WorktreePath
    if ($base) {
        $authored = @(& git -C $WorktreePath diff --name-only "$base...HEAD" 2>$null)
        if ($LASTEXITCODE -eq 0 -and $authored.Count -gt 0) {
            $differs = @(& git -C $WorktreePath diff --name-only $base HEAD 2>$null)
            if ($LASTEXITCODE -eq 0) {
                $stillDiffers = @{}
                foreach ($d in $differs) { $stillDiffers[(ConvertTo-CoordNorm $d)] = $true }
                $files += @($authored | Where-Object { $stillDiffers[(ConvertTo-CoordNorm $_)] })
            } else {
                $files += $authored
            }
        }
    }
    $dirty = & git -C $WorktreePath status --porcelain 2>$null
    if ($LASTEXITCODE -eq 0 -and $dirty) {
        foreach ($line in $dirty) {
            if ($line.Length -le 3) { continue }
            $p = $line.Substring(3).Trim('"')
            # Renames arrive as "old -> new"; the destination is the file being written.
            if ($p -match '\s->\s(.+)$') { $p = $Matches[1] }
            $files += $p
        }
    }
    # Separators normalised, case PRESERVED: these paths are shown to a human in the banner and the
    # deny message, and "assets/docs/_md/adoption-guide.md" is a worse pointer than the real filename.
    # Matching downcases at comparison time instead.
    return @($files | ForEach-Object { ($_ -replace '\\', '/').Trim('/') } | Where-Object { $_ } | Sort-Object -Unique)
}

<#
    The overlap map: every live peer paired with the files it is changing.

    Cached briefly. This runs on EVERY Edit/Write, and the uncached path is two git invocations per
    peer worktree -- fine once, a tax you would notice across a long editing run. A short TTL keeps it
    honest: the collisions worth catching are minutes old, not seconds.

    Pass -File to filter to peers touching one path; that is the gate's whole question.
#>
function Get-CoordOverlap {
    [CmdletBinding()]
    param([string]$File, [switch]$NoCache)

    $rows = $null
    $repoKey = ConvertTo-CoordNorm ((& git rev-parse --path-format=absolute --git-common-dir 2>$null) | Select-Object -First 1)
    $cachePath = Join-Path ([System.IO.Path]::GetTempPath()) ("mefor-web-coord-" + [Math]::Abs($repoKey.GetHashCode()) + ".json")

    if (-not $NoCache -and (Test-Path -LiteralPath $cachePath)) {
        try {
            $age = ((Get-Date) - (Get-Item -LiteralPath $cachePath).LastWriteTime).TotalSeconds
            if ($age -lt $script:CoordCacheTtlSeconds) {
                $rows = @(Get-Content -LiteralPath $cachePath -Raw | ConvertFrom-Json)
            }
        } catch { $rows = $null }
    }

    if ($null -eq $rows) {
        $rows = @()
        foreach ($p in (Get-CoordPeers)) {
            $rows += [pscustomobject]@{
                Short    = $p.Short
                Surface  = $p.Surface
                Worktree = $p.Worktree
                Label    = $p.Label
                Branch   = $p.Branch
                State    = $p.State
                # Carried so the gate can drop peers sharing our own worktree: their changed files are
                # OUR changed files, and blocking on those would wedge every edit we make.
                InMyTree = $p.InMyTree
                Files    = @(Get-CoordChangedFiles $p.Worktree)
            }
        }
        try { ($rows | ConvertTo-Json -Depth 5 -AsArray) | Set-Content -LiteralPath $cachePath -Encoding UTF8 } catch { }
    }

    if (-not $File) { return @($rows) }

    # Match on the repo-relative tail, so an absolute path from a hook payload compares against the
    # relative paths git reports. Anchored on a segment boundary: "css/styles.css" must not match
    # "vendor/css/styles.css".
    $needle = ConvertTo-CoordNorm $File
    return @($rows | Where-Object {
        $hit = $false
        foreach ($f in @($_.Files)) {
            $cand = ConvertTo-CoordNorm $f
            if ($needle -eq $cand -or $needle.EndsWith("/$cand")) { $hit = $true; break }
        }
        $hit
    })
}
