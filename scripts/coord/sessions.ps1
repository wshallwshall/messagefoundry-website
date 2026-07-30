<#
.SYNOPSIS
    Who is working in this repo right now, and what they are changing.

.DESCRIPTION
    The human-facing view of scripts\coord\lib.ps1. Read-only: it never writes to the session
    registry, never touches another worktree, and never contacts another session.

    Two different questions, one answer:
      WHO is here   -- stops you editing the same FILE as someone else.
      WHAT they build -- stops you building the same THING in a different file, which no file-shaped
                         check can catch.

.EXAMPLE
    pwsh -NoProfile -File scripts\coord\sessions.ps1
    pwsh -NoProfile -File scripts\coord\sessions.ps1 -All          # include stale/dead records
    pwsh -NoProfile -File scripts\coord\sessions.ps1 -Json
    pwsh -NoProfile -File scripts\coord\sessions.ps1 -File assets/css/styles.css
#>
[CmdletBinding()]
param(
    # Show STALE and DEAD registry entries too. Default lists only sessions that could be live.
    [switch]$All,
    [switch]$Json,
    # Only report sessions changing this path -- the question the collision gate asks.
    [string]$File,
    # Config roots to scan. Tests point this at a fixture so real discovery logic is exercised.
    [string[]]$ConfigRoot
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib.ps1"

if ($File) {
    $rows = Get-CoordOverlap -File $File -NoCache
    if ($Json) { ($rows | ConvertTo-Json -Depth 5 -AsArray) | Write-Output; exit 0 }
    if ($rows.Count -eq 0) { Write-Host "No other live session is changing $File." -ForegroundColor DarkGray; exit 0 }
    Write-Host ""
    Write-Host "$File is also being changed by:" -ForegroundColor Yellow
    foreach ($r in $rows) { Write-Host "  $($r.Short)  $($r.Surface)  in $($r.Label)  [$($r.Branch)]" }
    Write-Host ""
    exit 0
}

$roster = Get-CoordRoster -ConfigRoot $ConfigRoot
if (-not $All) { $roster = @($roster | Where-Object { $_.Live }) }

if ($Json) { ($roster | ConvertTo-Json -Depth 5 -AsArray) | Write-Output; exit 0 }

if ($roster.Count -eq 0) {
    Write-Host "No live sessions found for this repo. (Add -All to include stale/dead records.)" -ForegroundColor DarkGray
    exit 0
}

Write-Host ""
Write-Host "Claude sessions in this repo ($($roster.Count)):"
foreach ($r in $roster) {
    Write-Host ("  {0,-8} {1,-8} {2,-34} {3}" -f $r.Short, $r.Surface, $r.Label, $r.Branch)
    $notes = @()
    if ($r.IsSelf) { $notes += "<-- THIS session" }
    if ($r.IsPrimary -and -not $r.IsSelf) { $notes += "in the SHARED PRIMARY" }
    if ($r.State -ne "LIVE") { $notes += "$($r.State): $($r.Detail)" }
    if ($notes.Count -gt 0) { Write-Host ("           " + ($notes -join "  ")) -ForegroundColor DarkGray }
}

# What they are building. The roster above prevents you editing the same file; this is the only thing
# that prevents you building the same thing twice in different files.
$busy = @(Get-CoordOverlap -NoCache | Where-Object { @($_.Files).Count -gt 0 })
if ($busy.Count -gt 0) {
    Write-Host ""
    Write-Host "What they are changing -- check before you start, so you don't build it twice:"
    foreach ($b in $busy) {
        Write-Host "  $($b.Short) [$($b.Branch)] -- $(@($b.Files).Count) file(s)"
        foreach ($f in @($b.Files | Select-Object -First 6)) { Write-Host "      $f" -ForegroundColor DarkGray }
        if (@($b.Files).Count -gt 6) { Write-Host "      ... and $(@($b.Files).Count - 6) more" -ForegroundColor DarkGray }
    }
}
Write-Host ""
