<#
.SYNOPSIS
    PreToolUse gate: refuse to edit a file another LIVE session is already changing.

.DESCRIPTION
    Worktrees stop two sessions overwriting each other's bytes. They do NOT stop two sessions editing
    the same file in parallel and finding out at merge -- by which point both have built on divergent
    assumptions and someone's work is thrown away. This turns a merge-time surprise into an edit-time
    refusal, which is the only point where it is still cheap.

    THIS REPO'S SHARED SURFACES MAKE IT WORSE THAN AVERAGE. The header and footer are duplicated inline
    into every page on purpose, and there is one stylesheet for the whole site -- so "change one, change
    all" edits are routine, and two sessions doing site-wide sweeps at once will collide by design.

    NOTHING TO OPT INTO. It reads git state and the session registry, both by-products of working
    normally. A coordination step you have to remember is one you will skip.

    ONLY LIVE SESSIONS BLOCK, AND NEVER OUR OWN WORKTREE. A dormant worktree with changes is not racing
    you. And a peer sharing our worktree has our changed files, so blocking on those would wedge every
    edit we make.

    FAILS OPEN, DELIBERATELY. Any error -- unparseable payload, no git, no registry -- exits 0 and
    allows the edit. This gate prevents rework; it must never be the reason a session cannot work. That
    is the opposite of the worktree gate's posture (which protects the shared tree and fails closed),
    and the difference is intentional.

    Wired at USER level on Edit|Write|MultiEdit|NotebookEdit by a shim that resolves this exact path,
    so the filename is load-bearing and must not be renamed.
#>
[CmdletBinding()]
param(
    # Skip stdin and decide on this path instead. Lets a test drive the REAL gate against a fixture
    # rather than re-implementing its rule -- a test asserting a copy of the rule proves nothing.
    [string]$PathOverride
)

# No "Stop": this gate fails OPEN, and a throw would be a deny-by-crash.
$ErrorActionPreference = "SilentlyContinue"

function Deny([string]$Reason) {
    # The hookSpecificOutput wrapper is MANDATORY -- a bare permissionDecision is silently ignored,
    # which would leave this looking installed while permitting everything.
    $payload = @{
        hookSpecificOutput = @{
            hookEventName            = "PreToolUse"
            permissionDecision       = "deny"
            permissionDecisionReason = $Reason
        }
    }
    [Console]::Out.Write(($payload | ConvertTo-Json -Compress -Depth 6))
    exit 0
}

$target = $PathOverride
if (-not $target) {
    if (-not [Console]::IsInputRedirected) { exit 0 }
    try { $hook = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
    if (-not $hook) { exit 0 }
    $target = [string]$hook.tool_input.file_path
    # NotebookEdit names it differently; absence just means there is nothing to check.
    if (-not $target) { $target = [string]$hook.tool_input.notebook_path }
}
if (-not $target) { exit 0 }

try { . "$PSScriptRoot\..\coord\lib.ps1" } catch { exit 0 }

$rows = @()
try { $rows = @(Get-CoordOverlap -File $target | Where-Object { -not $_.InMyTree }) } catch { exit 0 }
if ($rows.Count -eq 0) { exit 0 }

$leaf = Split-Path $target -Leaf
$lines = @("$leaf is already being changed by another LIVE session -- editing it now means one of you loses work at merge.", "")
foreach ($r in $rows) {
    $lines += "  $($r.Short) ($($r.Surface)) in $($r.Label) [$($r.Branch)]"
    foreach ($f in @($r.Files | Select-Object -First 4)) { $lines += "      also changing: $f" }
    if (@($r.Files).Count -gt 4) { $lines += "      ... and $(@($r.Files).Count - 4) more" }
}
$lines += ""
$lines += "That session may already be doing what you are about to do. Before overriding:"
$lines += "  - read what it concluded : ccd_session_mgmt list_sessions, then list_events on its id"
$lines += "  - hand off instead       : ccd_session_mgmt send_message to that session"
$lines += "  - see everything in flight: pwsh -NoProfile -File scripts\coord\sessions.ps1"
$lines += "Then coordinate, work on a different file, or ask the user to arbitrate."

Deny ($lines -join "`n")
