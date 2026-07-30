<#
.SYNOPSIS
    SessionStart hook: tell a new chat who else is working in this repo, and what they are changing.

.DESCRIPTION
    Whatever this prints to stdout is injected into the chat's starting context, so a new window opens
    already knowing its neighbours. It is wired at USER level (~/.claude/settings.json, marker
    "mefor-coord") by a shim that resolves `scripts/worktree/session-context.ps1` from this repo --
    which is why the filename and path are load-bearing and must not be renamed.

    UNTIL THIS FILE EXISTED, THIS REPO HAD NO COORDINATION AT ALL. The shim was installed and looked
    installed, but resolved to nothing here and exited 0 silently -- measured 2026-07-30 with four
    worktrees and two live sessions in this repo. A hook that fails silently is worse than an absent
    one, because nothing reports the absence.

    QUIET WHEN THERE IS NOTHING TO SAY. With one worktree and no peers this prints nothing: a banner
    that appears when it does not matter is a banner that gets skimmed when it does.

    NEVER THROWS. A failure here would replace the chat's entire starting context with a stack trace.
#>
$ErrorActionPreference = "SilentlyContinue"

$lines = @()
try {
    . "$PSScriptRoot\..\coord\lib.ps1"

    $worktrees = Get-CoordWorktrees
    $roster = @(Get-CoordRoster)
    $peers = @($roster | Where-Object { $_.Live -and -not $_.IsSelf })

    # Nothing to coordinate with: one checkout and nobody else here.
    if ($worktrees.Count -le 1 -and $peers.Count -eq 0) { exit 0 }

    $root = (& git rev-parse --show-toplevel 2>$null)
    $branch = (& git branch --show-current 2>$null)
    $isPrimary = ((& git rev-parse --git-dir 2>$null) -notmatch 'worktrees')

    $lines += "[PARALLEL SESSIONS - messagefoundry-website]"
    $lines += "This chat: $root  (branch: $branch)"

    # Loudest, first. The primary is the one checkout everyone shares.
    if ($isPrimary) {
        $lines += ""
        $lines += "  >>> You are in the SHARED PRIMARY checkout, where parallel sessions collide."
        $lines += "  >>> Do substantive work on a branch in your own worktree, not here."
    }

    if ($peers.Count -gt 0) {
        $lines += ""
        $lines += "LIVE sessions in this repo besides you ($($peers.Count)):"
        foreach ($p in $peers) {
            $flag = if ($p.State -ne "LIVE") { "  [$($p.State)]" } else { "" }
            $lines += "  $($p.Short)  $($p.Surface)  in $($p.Label)  [$($p.Branch)]$flag"
        }
        if (@($peers | Where-Object { $_.IsPrimary }).Count -gt 0) {
            $lines += "  WARNING: a session is working in the SHARED PRIMARY. Stay in your own worktree."
        }
        # The surfaces differ in what can reach them, and that changes how you coordinate.
        if (@($peers | Where-Object { $_.Surface -ne "desktop" }).Count -gt 0) {
            $lines += "  NOTE: a non-desktop (e.g. VS Code) session is live. ccd_session_mgmt cannot see or"
            $lines += "        message it -- coordinate through the PR or the user, not a session message."
        }

        # What they are building, not just where they are. The roster stops you editing the same FILE;
        # this is the only thing that stops you building the same THING in a different file.
        $busy = @(Get-CoordOverlap | Where-Object { @($_.Files).Count -gt 0 })
        if ($busy.Count -gt 0) {
            $lines += ""
            $lines += "WHAT THEY ARE CHANGING -- check before you start, so you don't build it twice:"
            foreach ($b in $busy) {
                $lines += "  $($b.Short) [$($b.Branch)] -- $(@($b.Files).Count) file(s) changed"
                foreach ($f in @($b.Files | Select-Object -First 5)) { $lines += "      $f" }
                if (@($b.Files).Count -gt 5) { $lines += "      ... and $(@($b.Files).Count - 5) more" }
            }
        }

        $lines += ""
        $lines += "Coordination rules (see CLAUDE.md, 'Parallel sessions'):"
        $lines += "  - Keep changes on this worktree's branch; never edit files in a sibling worktree."
        $lines += "  - Before overlapping work, read the peer's transcript with ccd_session_mgmt"
        $lines += "    (list_sessions -> list_events). Its list_sessions MISSES non-desktop sessions;"
        $lines += "    this banner is the authoritative roster."
        $lines += "  - Watch the shared surfaces: assets/css/styles.css, sitemap.xml, CLAUDE.md, and the"
        $lines += "    header/footer duplicated into every page."
        $lines += "  - The AI memory directory is shared across sessions. Read freely; only write when"
        $lines += "    the user has said this session owns memory updates (last write wins)."
        $lines += "  - Full roster:  pwsh -NoProfile -File scripts\coord\sessions.ps1"
    }
} catch {
    exit 0
}

($lines -join "`n") | Write-Output
