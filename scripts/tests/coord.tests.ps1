<#
.SYNOPSIS
    Regression tests for the session-coordination library and the collision gate.

.DESCRIPTION
    Every check here corresponds to a defect that actually shipped and was caught by running the real
    thing, not by reading it. That is why the tests drive the REAL scripts against a fixture registry
    instead of re-implementing their rules -- a test that asserts a copy of the rule proves nothing.

    What each group pins down:

      SELF        A session that fails to recognise itself becomes its own peer, and the gate then
                  blocks it from every file it has touched -- a total wedge whose deny message names
                  the victim as the culprit. Happened 2026-07-30.
      PRIMARY     Worktrees live UNDER the primary checkout here, so a naive "is my cwd inside the
                  peer's worktree" test is true for the primary from anywhere. That hid the single
                  most collision-prone session in the repo from both the gate and the banner.
      SCOPING     git reports repo-relative paths, so matching an absolute target by its tail
                  degenerates to a bare filename and denies edits to same-named files in OTHER repos.
      FENCE       Only a positively-fenced (LIVE) session may block. UNVERIFIED is reportable but not
                  actionable: an unreadable process start never clears, so blocking on it is forever.

.EXAMPLE
    pwsh -NoProfile -File scripts\tests\coord.tests.ps1
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (& git rev-parse --show-toplevel 2>$null),
    [string]$WorkDir = (Join-Path ([System.IO.Path]::GetTempPath()) "mefor-coord-tests")
)

$ErrorActionPreference = "Stop"
if (-not $RepoRoot) { Write-Host "Not inside a git repository." -ForegroundColor Red; exit 1 }

$lib = Join-Path $RepoRoot "scripts\coord\lib.ps1"
$gate = Join-Path $RepoRoot "scripts\hooks\collision_gate.ps1"
. $lib

$fixtureRoot = Join-Path $WorkDir "registry"
$outside = Join-Path $WorkDir "outside"
$sessDir = Join-Path $fixtureRoot "sessions"
New-Item -ItemType Directory -Force -Path $sessDir, $outside | Out-Null
Get-ChildItem $sessDir -Filter *.json -EA SilentlyContinue | Remove-Item -Force

$script:fail = 0
function Check([string]$Name, [bool]$Cond, [string]$Detail = "") {
    if ($Cond) { Write-Host "  PASS  $Name" -ForegroundColor Green }
    else { Write-Host "  FAIL  $Name  $Detail" -ForegroundColor Red; $script:fail++ }
}
function GateSays([string]$Path) {
    # As a SUBPROCESS, like the harness runs it. Deny() writes with [Console]::Out.Write, which goes
    # straight to the console handle and bypasses PowerShell's output stream -- call the gate
    # in-process and every deny reads as an allow.
    $out = pwsh -NoProfile -File $gate -PathOverride $Path -ConfigRoot $fixtureRoot 2>$null
    if (-not $out) { return "ALLOW" }
    try { if (($out | ConvertFrom-Json).hookSpecificOutput.permissionDecision -eq "deny") { return "DENY" } } catch { }
    return "ALLOW"
}

$worktrees = Get-CoordWorktrees
if ($worktrees.Count -lt 2) {
    Write-Host "Needs at least one linked worktree to exercise the primary-vs-worktree rules." -ForegroundColor Yellow
    exit 0
}
$primary = $worktrees[0].Path
$here = $null
$hereNorm = ConvertTo-CoordNorm $PWD.Path
foreach ($w in $worktrees) {
    $k = ConvertTo-CoordNorm $w.Path
    if ($hereNorm -eq $k -or $hereNorm.StartsWith("$k/")) {
        if (-not $here -or $k.Length -gt (ConvertTo-CoordNorm $here).Length) { $here = $w.Path }
    }
}
if ((ConvertTo-CoordNorm $here) -eq (ConvertTo-CoordNorm $primary)) {
    Write-Host "Run this from a linked worktree, not the primary." -ForegroundColor Yellow
    exit 0
}

# A fabricated session in the SHARED PRIMARY, and one that is us. Both reuse a real live pid so the
# liveness fence passes without mocking it.
$selfId = "aaaaaaaa-0000-0000-0000-00000000se1f"
$primaryId = "ffffffff-0000-0000-0000-00000000beef"
$started = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
@{ sessionId = $selfId; pid = $PID; cwd = $here; entrypoint = "claude-desktop"; startedAt = $started } |
    ConvertTo-Json | Set-Content (Join-Path $sessDir "self.json")
@{ sessionId = $primaryId; pid = $PID; cwd = $primary; entrypoint = "claude-vscode"; startedAt = $started } |
    ConvertTo-Json | Set-Content (Join-Path $sessDir "primary.json")

Write-Host "`nprimary : $primary"
Write-Host "here    : $here`n"

Write-Host "roster"
$roster = @(Get-CoordRoster -ConfigRoot $fixtureRoot -SelfSessionId $selfId)
$mine = $roster | Where-Object { $_.SessionId -eq $selfId }
$prim = $roster | Where-Object { $_.SessionId -eq $primaryId }
Check "sees both sessions"                    ($roster.Count -eq 2) "got $($roster.Count)"
Check "SELF: this session is IsSelf"          ($mine.IsSelf -eq $true)
Check "SELF: cwd fallback also finds self"    ((@(Get-CoordRoster -ConfigRoot $fixtureRoot) | Where-Object { $_.SessionId -eq $selfId }).IsSelf -eq $true)
Check "SELF: unknown id claims exactly one"   (@(@(Get-CoordRoster -ConfigRoot $fixtureRoot -SelfSessionId "nope") | Where-Object { $_.IsSelf }).Count -eq 1)
Check "PRIMARY: not mistaken for self"        ($prim.IsSelf -eq $false)
Check "PRIMARY: not marked InMyTree"          ($prim.InMyTree -eq $false)
Check "PRIMARY: flagged as the primary"       ($prim.IsPrimary -eq $true)
Check "FENCE: a live pid is Confirmed"        ($prim.Confirmed -eq $true)
Check "surface reported verbatim"             ($prim.Surface -eq "vscode")
Check "exactly one peer, and it is not us"    (@(Get-CoordPeers -ConfigRoot $fixtureRoot -SelfSessionId $selfId).Count -eq 1)

Write-Host "`nfence"
$myStart = (Get-Process -Id $PID).StartTime.Ticks
Check "FENCE: a dead pid is neither Live nor Confirmed" (
    (Test-CoordLiveness -Record ([pscustomobject]@{ pid = 999999; startedAt = $started })).State -eq "DEAD")
Check "FENCE: a recycled pid reads STALE" (
    (Test-CoordLiveness -Record ([pscustomobject]@{ pid = $PID; startedAt = 1 })).State -eq "STALE")
Check "FENCE: exact procStart reads LIVE" (
    (Test-CoordLiveness -Record ([pscustomobject]@{ pid = $PID; procStart = "$myStart"; startedAt = $started })).State -eq "LIVE")
# A REUSED pid, modelled honestly: the old session recorded its own process start AND registered at
# that same old moment, and the pid now belongs to a process that started later. Shifting procStart
# alone would instead model a mis-encoded field, which must degrade rather than read STALE (below).
$oldTicks = $myStart - 100000000000
$oldStarted = ([DateTimeOffset]::new([datetime]::new($oldTicks), [TimeZoneInfo]::Local.GetUtcOffset([datetime]::new($oldTicks)))).ToUnixTimeMilliseconds()
Check "FENCE: reused pid reads STALE" (
    (Test-CoordLiveness -Record ([pscustomobject]@{ pid = $PID; procStart = "$oldTicks"; startedAt = $oldStarted })).State -eq "STALE")
Check "FENCE: unparseable procStart falls back, not throws" (
    (Test-CoordLiveness -Record ([pscustomobject]@{ pid = $PID; procStart = "junk"; startedAt = $started })).State -eq "LIVE")
Check "FENCE: absent procStart falls back to startedAt" (
    (Test-CoordLiveness -Record ([pscustomobject]@{ pid = $PID; startedAt = $started })).State -eq "LIVE")
# A differently-ENCODED procStart parses fine, so the catch{} never fires. Without a plausibility
# guard it returns a confident STALE for every session, which clears Live AND Confirmed: gate off,
# banner blank, roster empty — all identical to genuinely working alone.
Check "FENCE: UTC-ticks procStart degrades, not STALE" (
    (Test-CoordLiveness -Record ([pscustomobject]@{ pid = $PID; procStart = "$((Get-Process -Id $PID).StartTime.ToUniversalTime().Ticks)"; startedAt = $started })).State -eq "LIVE")
Check "FENCE: unix-ms procStart degrades, not STALE" (
    (Test-CoordLiveness -Record ([pscustomobject]@{ pid = $PID; procStart = "$started"; startedAt = $started })).State -eq "LIVE")
# One out-of-spec record must not throw out of the enumeration and disable the whole mechanism.
Check "ROBUST: overflowing pid is DEAD, not a throw" (
    (Test-CoordLiveness -Record ([pscustomobject]@{ pid = "99999999999999"; startedAt = $started })).State -eq "DEAD")
Check "ROBUST: microsecond startedAt does not throw" (
    @("LIVE", "UNVERIFIED", "STALE") -contains (Test-CoordLiveness -Record ([pscustomobject]@{ pid = $PID; startedAt = 1785434153709000 })).State)
Check "ROBUST: non-numeric pid is DEAD, not a throw" (
    (Test-CoordLiveness -Record ([pscustomobject]@{ pid = "abc"; startedAt = $started })).State -eq "DEAD")
# The gate must not write to a peer's tree. --no-optional-locks is what stops `status` rewriting the
# index of every worktree it inspects, on every single edit.
Check "READ-ONLY: git calls pass --no-optional-locks" (
    (Select-String -Path $lib -Pattern 'no-optional-locks' -AllMatches).Matches.Count -ge 3)
Check "READ-ONLY: git calls disable quotepath" (
    (Select-String -Path $lib -Pattern 'core\.quotepath=false' -AllMatches).Matches.Count -ge 3)

Write-Host "`ngate"
$temporary = $null
$primFiles = @(Get-CoordChangedFiles $primary)
if ($primFiles.Count -eq 0) {
    $temporary = Join-Path $primary "coord-gate-test.tmp.html"
    Set-Content -LiteralPath $temporary -Value "<!-- fixture -->" -Force
    $primFiles = @(Get-CoordChangedFiles $primary)
}
try {
    $victim = $primFiles[0]
    Check "PRIMARY: a session there CAN deny"        ((GateSays (Join-Path $here $victim)) -eq "DENY") "victim: $victim"
    $twin = Join-Path $outside (Split-Path $victim -Leaf)
    Set-Content -LiteralPath $twin -Value "unrelated" -Force
    Check "SCOPING: same name, other repo, allowed"  ((GateSays $twin) -eq "ALLOW") "path: $twin"
    Check "SCOPING: path in no repo at all, allowed" ((GateSays (Join-Path $outside "nowhere\index.html")) -eq "ALLOW")
    Check "a file nobody is touching is allowed"     ((GateSays (Join-Path $here "licensing.html")) -eq "ALLOW")
    $mineFiles = @(Get-CoordChangedFiles $here)
    if ($mineFiles.Count -gt 0) {
        Check "SELF: own in-flight file is allowed"  ((GateSays (Join-Path $here $mineFiles[0])) -eq "ALLOW") "file: $($mineFiles[0])"
    }

    # CANONICALISATION: the same file spelled with '..', '.' or a doubled separator must still DENY.
    # A raw string prefix-strip lets all of these through -- a silent allow on a contested file.
    # Note the shape: "<dir>/../<dir>/<leaf>" resolves to "<dir-parent>/<dir>/<leaf>", a DIFFERENT
    # file, so it is not the regression. Route through a sibling directory instead, which resolves
    # back to the same path the peer is changing.
    $viaDotDot = Join-Path $here "scripts/../$victim"
    Check "SCOPING: '..' spelling still denies"      ((GateSays $viaDotDot) -eq "DENY") "path: $viaDotDot"
    Check "SCOPING: './' spelling still denies"      ((GateSays (Join-Path $here "./$victim")) -eq "DENY")
    Check "SCOPING: doubled separator still denies"  ((GateSays ((Join-Path $here $victim) -replace '\\', '\\\\')) -eq "DENY")
} finally {
    if ($temporary) { Remove-Item -LiteralPath $temporary -Force -EA SilentlyContinue }
}

Write-Host ""
if ($script:fail -gt 0) { Write-Host "$script:fail check(s) FAILED" -ForegroundColor Red; exit 1 }
Write-Host "all coordination checks passed" -ForegroundColor Green
exit 0
