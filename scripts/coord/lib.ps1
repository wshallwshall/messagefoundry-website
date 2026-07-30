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

    SELF IS IDENTIFIED BY THE HOOK PAYLOAD'S session_id, AND THAT IS NOT A DETAIL. Getting it wrong
    is the single most damaging failure this code has: a session that does not recognise itself becomes
    its own peer, and the gate then blocks it from every file it has already touched -- a total wedge,
    with a deny message naming the victim as the culprit. That happened, measured 2026-07-30.

    The hook payload's `session_id` is the SAME uuid as the registry's `sessionId` (confirmed from a
    live PreToolUse payload: a8e31b0a-... in both). It is exact, needs no inference, and stays correct
    even when two sessions share a worktree. Callers holding a payload MUST pass it.

    Without one we fall back to matching this process's working directory against the worktree list,
    claimed only when unambiguous. That is a guess, which is why the cache below no longer exists.

    NO CACHING, DELIBERATELY. An earlier version cached the overlap map in TEMP. It was wrong twice
    over. The key used String.GetHashCode(), which .NET Core randomises PER PROCESS, so every hook run
    wrote a fresh orphan file (~170 in 25 minutes) and never once read one. And the cached rows carried
    self-ness computed in a DIFFERENT process, which is precisely what wedged the session above.
    Recomputing costs ~307ms against a ~175ms process spawn that is unavoidable anyway. Correctness is
    worth 300ms; a cache that can silently invert the gate's verdict is not.

    READ-ONLY. Nothing here writes to the registry, deletes a record, or contacts another session.
#>

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
    # Every cast in here is defensive. These records are written by another program and one of them
    # being out of spec -- a pid that overflows Int32, a startedAt in microseconds -- must not throw:
    # the exception would escape Get-CoordRoster, abort the whole enumeration, and be swallowed by the
    # callers' fail-open catches. One malformed record would then silently disable the gate AND blank
    # the banner for every session in the repo, which is indistinguishable from working alone.
    $procId = 0
    try { $procId = [int]$Record.pid } catch { return @{ State = "DEAD"; Detail = "unreadable pid in record" } }
    if (-not $procId) { return @{ State = "DEAD"; Detail = "no pid in record" } }

    $proc = Get-Process -Id $procId -EA SilentlyContinue
    if (-not $proc) { return @{ State = "DEAD"; Detail = "pid $procId not running" } }

    $procStart = $null
    try { $procStart = $proc.StartTime } catch { }
    # Access can be denied for a process in another context. Report the uncertainty rather than
    # upgrading it to LIVE: an unverifiable fence is not a passed fence.
    if (-not $procStart) { return @{ State = "UNVERIFIED"; Detail = "pid $procId alive; start time unreadable" } }

    # EXACT MATCH FIRST. The registry records `procStart` -- .NET ticks, local time -- for precisely
    # this check. Measured on Claude Code 2.1.219: recorded 639210057454830080 decodes to
    # 2026-07-30T10:55:45.4830080 against an actual StartTime of ...45.4830084, i.e. equal to within
    # a rounding tick. So identity is decidable outright, and a reused pid cannot slip through a
    # tolerance window. (A comment in a sibling project asserts this field serialises as absent; that
    # was true of some earlier build and is not true here. Verify before trusting either claim.)
    $registered = $null
    if ($null -ne $Record.startedAt) {
        try { $registered = [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$Record.startedAt).LocalDateTime } catch { }
    }

    if ($Record.procStart) {
        try {
            $recorded = [datetime]::new([int64]$Record.procStart)
            # PLAUSIBILITY GUARD, and it is the important half. Only an UNPARSEABLE procStart used to
            # fall through to the coarse check; a numerically-valid but differently-ENCODED one (UTC
            # ticks instead of local, unix ms, unix seconds) parsed fine, missed the window, and
            # returned a confident STALE. Uniformly wrong encoding -- or simply changing the machine's
            # timezone -- would then mark EVERY session stale, and stale clears both Live and
            # Confirmed: the gate blocks nobody, the banner prints nothing, and the roster says "no
            # live sessions". All three are byte-identical to genuinely working alone, which is the
            # one conclusion that stops a session coordinating. Two harness builds already coexist in
            # this registry, so the encoding is not a fixed constant to bet the mechanism on.
            #
            # The window has to be TIGHTER THAN A TIMEZONE OFFSET, which is the whole point. A first
            # attempt allowed 24 hours and was useless: every real offset is 1-14 hours, so UTC-vs-local
            # ticks sailed through as "plausible" and still returned STALE. Caught by the test below,
            # not by reading it.
            #
            # The real constraint is tight and directional: a process starts, THEN registers its
            # session, milliseconds later. So the decode is credible only if it lands just before
            # startedAt -- never meaningfully after it, and never long before.
            $gap = if ($null -ne $registered) { ($registered - $recorded).TotalMinutes } else { 0 }
            $plausible = ($null -eq $registered) -or ($gap -ge -1 -and $gap -le $StartSkewMinutes)
            if ($plausible) {
                if ([Math]::Abs(($procStart - $recorded).TotalSeconds) -lt 1) { return @{ State = "LIVE"; Detail = "" } }
                return @{ State = "STALE"; Detail = "pid $procId reused (process start differs from the recorded one)" }
            }
        } catch { }   # unparseable: fall through to the coarse check rather than guess
    }

    # Fallback: compare against session registration, which FOLLOWS process start, so only a generous
    # window is defensible.
    if ($null -eq $registered) { return @{ State = "UNVERIFIED"; Detail = "pid $procId alive; record has no usable startedAt" } }
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
    param([string[]]$ConfigRoot, [int]$StartSkewMinutes = 15, [string]$SelfSessionId)

    $worktrees = Get-CoordWorktrees
    if ($worktrees.Count -eq 0) { return @() }

    $index = @{}
    foreach ($w in $worktrees) { $index[(ConvertTo-CoordNorm $w.Path)] = $w }
    $primaryNorm = ConvertTo-CoordNorm $worktrees[0].Path

    # WHICH worktree are WE in -- by the SAME longest-match rule used for peers below. Asking instead
    # "is my cwd inside the peer's worktree" is a different question with the same shape, and it is
    # wrong here: this repo's worktrees live UNDER the primary (.claude/worktrees/<name>), so from any
    # worktree that test is true for the PRIMARY. Consequences, both confirmed: a session working in
    # the shared primary -- the most collision-prone place there is -- got dropped by the gate and
    # never appeared in the banner; and with two rows flagged, the unambiguity check below failed, so
    # self was never claimed and the session listed ITSELF as a peer.
    $hereKey = $null
    $hereNorm = ConvertTo-CoordNorm $PWD.Path
    foreach ($k in $index.Keys) {
        if ($hereNorm -eq $k -or $hereNorm.StartsWith("$k/")) {
            if (-not $hereKey -or $k.Length -gt $hereKey.Length) { $hereKey = $k }
        }
    }

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
            # A POSITIVE fence, for the one caller that takes an irreversible action on it. Reporting a
            # maybe-live session in a banner costs a line of text; BLOCKING on one costs the session its
            # edits, indefinitely -- an unreadable StartTime (a recycled pid now owned by a process in
            # another security context) is UNVERIFIED forever, and nothing would ever clear it. So the
            # gate requires LIVE and the banner does not, per this file's own rule that only the
            # positive answer is safe to act on.
            Confirmed  = ($live.State -eq "LIVE")
            Surface    = Get-CoordSurface $rec.entrypoint
            SessionId  = $sid
            Short      = if ($sid) { $sid.Substring(0, [Math]::Min(8, $sid.Length)) } else { "?" }
            Pid        = [int]$rec.pid
            Worktree   = $match.Path
            Label      = if ($matchKey -eq $primaryNorm) { "the SHARED PRIMARY" } else { Split-Path $match.Path -Leaf }
            IsPrimary  = ($matchKey -eq $primaryNorm)
            Branch     = $match.Branch
            InMyTree   = ($null -ne $hereKey -and $hereKey -eq $matchKey)
            IsSelf     = $false
        }
    }

    # Exact identification first: the payload id IS the registry id, so this is not a heuristic.
    $claimed = $false
    if ($SelfSessionId) {
        foreach ($r in $rows) {
            if ($r.SessionId -and $r.SessionId -ieq $SelfSessionId) { $r.IsSelf = $true; $claimed = $true }
        }
    }
    # Fallback only when no payload was available (a CLI run, a test). Claimed only when unambiguous:
    # if two live sessions share our worktree neither is self, and both deserve to be seen.
    if (-not $claimed) {
        $mine = @($rows | Where-Object { $_.InMyTree -and $_.Live })
        if ($mine.Count -eq 1) { $mine[0].IsSelf = $true }
    }

    $order = @{ "LIVE" = 0; "UNVERIFIED" = 1; "STALE" = 2; "DEAD" = 3 }
    return @($rows | Sort-Object @{ E = { $order[$_.State] } }, @{ E = { $_.Label } })
}

function Get-CoordPeers {
    [CmdletBinding()]
    param([string[]]$ConfigRoot, [string]$SelfSessionId)
    return @(Get-CoordRoster -ConfigRoot $ConfigRoot -SelfSessionId $SelfSessionId |
        Where-Object { $_.Live -and -not $_.IsSelf })
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
        # Same flags, same reasons: a diff also refreshes the peer's index, and quotes non-ASCII paths.
        $authored = @(& git -C $WorktreePath --no-optional-locks -c core.quotepath=false diff --name-only "$base...HEAD" 2>$null)
        if ($LASTEXITCODE -eq 0 -and $authored.Count -gt 0) {
            $differs = @(& git -C $WorktreePath --no-optional-locks -c core.quotepath=false diff --name-only $base HEAD 2>$null)
            if ($LASTEXITCODE -eq 0) {
                $stillDiffers = @{}
                foreach ($d in $differs) { $stillDiffers[(ConvertTo-CoordNorm $d)] = $true }
                $files += @($authored | Where-Object { $stillDiffers[(ConvertTo-CoordNorm $_)] })
            } else {
                $files += $authored
            }
        }
    }
    # Three flags, each load-bearing:
    #   --no-optional-locks   a plain `status` REFRESHES AND REWRITES the index of the worktree it
    #                         inspects. This function runs inside every peer's worktree on every
    #                         single Edit, so without this the gate is writing to trees it has no
    #                         business touching -- breaking this file's own read-only contract, and
    #                         opening a window where the peer's own git command fails on index.lock.
    #   core.quotepath=false  otherwise git escapes any non-ASCII path as C-style octal
    #                         ("ren\303\251med.html"), which no comparison against a real filename
    #                         can ever match -- a silent allow on exactly the file a peer just added.
    #   -uall                 otherwise a wholly-untracked directory collapses to one "?? dir/" entry
    #                         and every file inside a peer's brand-new directory is invisible, which
    #                         is precisely when they are building something from scratch.
    $dirty = & git -C $WorktreePath --no-optional-locks -c core.quotepath=false status --porcelain -uall 2>$null
    if ($LASTEXITCODE -eq 0 -and $dirty) {
        foreach ($line in $dirty) {
            if ($line.Length -le 3) { continue }
            $p = $line.Substring(3)
            # Renames arrive as "old -> new"; the destination is the file being written. Split BEFORE
            # unquoting: git quotes each side separately, so trimming first leaves a stray quote on a
            # quoted destination and the path then matches nothing.
            if ($p -match '\s->\s(.+)$') { $p = $Matches[1] }
            $p = $p.Trim().Trim('"')
            $files += $p
        }
    }
    # Separators normalised, case PRESERVED: these paths are shown to a human in the banner and the
    # deny message, and "assets/docs/_md/adoption-guide.md" is a worse pointer than the real filename.
    # Matching downcases at comparison time instead.
    return @($files | ForEach-Object { ($_ -replace '\\', '/').Trim('/') } | Where-Object { $_ } | Sort-Object -Unique)
}

<#
    The overlap map: every live peer paired with the files it is changing. Computed fresh on every
    call -- see the header for why there is no cache.

    Pass -File to filter to peers touching one path; that is the gate's whole question.
#>
function Get-CoordOverlap {
    [CmdletBinding()]
    param([string]$File, [string]$SelfSessionId, [string[]]$ConfigRoot)

    $rows = @()
    foreach ($p in (Get-CoordPeers -SelfSessionId $SelfSessionId -ConfigRoot $ConfigRoot)) {
        $rows += [pscustomobject]@{
            Short    = $p.Short
            Surface  = $p.Surface
            Worktree = $p.Worktree
            Label    = $p.Label
            Branch   = $p.Branch
            State    = $p.State
            # Only a positively-fenced session is safe to block on -- see Confirmed in Get-CoordRoster.
            Confirmed = $p.Confirmed
            # Carried so a caller can drop peers sharing our own worktree as a second net behind the
            # session_id match: their changed files are OUR changed files.
            InMyTree = $p.InMyTree
            Files    = @(Get-CoordChangedFiles $p.Worktree)
        }
    }

    if (-not $File) { return @($rows) }

    # RESOLVE THE TARGET TO A PATH RELATIVE TO THIS REPO, THEN COMPARE EXACTLY.
    #
    # The obvious shortcut -- does the absolute target END WITH a path git reported -- is wrong in a
    # way that reaches outside this repo entirely. git reports repo-relative paths, so for anything at
    # the repo root the comparison degenerates to a bare filename, and the gate then denies edits to
    # any same-named file anywhere on the machine: another project's README.md, a scratch index.html,
    # a file in no repo at all. A gate that blocks unrelated work gets uninstalled.
    # CANONICALISE FIRST. The prefix strip below is a string operation, so a target that is merely
    # SPELLED differently slips past it: "<worktree>/scripts/../assets/img/logo.svg" starts with the
    # worktree root, survives the strip as "scripts/../assets/img/logo.svg", and then cannot equal the
    # "assets/img/logo.svg" git reports. That is a silent ALLOW on a file a peer is actively changing
    # -- the precise failure this gate exists to prevent, reachable by any '..', '.', './' or doubled
    # separator in a path the model happened to construct.
    $full = $File
    try { $full = [System.IO.Path]::GetFullPath($File) } catch { }
    $needle = ConvertTo-CoordNorm $full
    $rel = $null
    foreach ($w in (Get-CoordWorktrees)) {
        $k = ConvertTo-CoordNorm $w.Path
        if ($needle.StartsWith("$k/")) {
            $cand = $needle.Substring($k.Length + 1)
            # Longest worktree root wins, i.e. the shortest relative path: worktrees nest under the
            # primary here, so the naive first match would resolve against the wrong root.
            if (-not $rel -or $cand.Length -lt $rel.Length) { $rel = $cand }
        }
    }
    if (-not $rel) {
        # Absolute and inside none of our worktrees: not our business, say nothing.
        if ([System.IO.Path]::IsPathRooted($File)) { return @() }
        # Relative, and canonicalising against the cwd landed outside every worktree: a CLI or test
        # invocation from elsewhere, where the caller already means a repo-relative path. Use the
        # ORIGINAL, not $needle -- $needle is now absolute.
        $rel = ConvertTo-CoordNorm $File
    }

    return @($rows | Where-Object {
        $hit = $false
        foreach ($f in @($_.Files)) {
            if ($rel -eq (ConvertTo-CoordNorm $f)) { $hit = $true; break }
        }
        $hit
    })
}
