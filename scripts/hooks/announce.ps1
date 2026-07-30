<#
.SYNOPSIS
    UserPromptSubmit hook: tell a new session to announce itself to the other sessions in THIS repo.

.DESCRIPTION
    The rest of the coordination system is pull-based -- a new session discovers its peers, but the
    peers learn nothing until one of them trips the collision gate. That is too late for the collision
    that actually costs the most: two sessions deciding to build the same thing, in different files,
    where nothing file-shaped can catch it. This closes that direction.

    WHY UserPromptSubmit AND NOT SessionStart. At SessionStart a session knows it exists and nothing
    else -- announcing then can only say "hello", which is the interrupt without the information. One
    prompt later it knows what it was asked to do, and the announcement can carry intent, which is the
    entire value. So this fires on the FIRST prompt of a session and never again.

    WHY IT IS A PROMPT AND NOT AN ACTION. Announcing means `ccd_session_mgmt send_message`, an MCP tool.
    Hooks are shell commands and cannot call MCP at all, so this hook cannot send anything itself. What
    it can do is put the instruction, the peer list, and the id-resolution rule in front of the model at
    the one moment they are actionable. Everything below stdout is injected into the chat.

    SCOPED TO THIS REPO, BY THE USER'S DECISION (2026-07-30). Peers come from Get-CoordPeers, which is
    already scoped to worktrees sharing this .git. A session in another repo is never a target.

    ONCE PER SESSION. Keyed on the harness session_id in a temp marker, so a re-prompt, a resume or a
    /clear does not re-announce. Silent when there is nobody to announce to.

    ALWAYS EXITS 0. A UserPromptSubmit hook that fails can block the user's prompt outright. Nothing
    here is worth doing that for.
#>
$ErrorActionPreference = "SilentlyContinue"

try {
    # --- once per session ---------------------------------------------------------------------
    $sid = "shared"
    $selfId = $null
    if ([Console]::IsInputRedirected) {
        try {
            $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
            if ($payload.session_id) {
                $selfId = [string]$payload.session_id
                # Sanitised only for use as a FILENAME. The unsanitised value is what identifies us to
                # the roster; scrubbing it there would stop it matching the registry.
                $clean = $selfId -replace '[^A-Za-z0-9._-]', ''
                if ($clean) { $sid = $clean }
            }
        } catch { }
    }
    $marker = Join-Path ([System.IO.Path]::GetTempPath()) "mefor-web-announced-$sid.flag"
    if (Test-Path -LiteralPath $marker) { exit 0 }

    . "$PSScriptRoot\..\coord\lib.ps1"
    $peers = @(Get-CoordPeers -SelfSessionId $selfId)
    # Nobody here. Do NOT write the marker: the next prompt should check again, because a peer that
    # starts thirty seconds from now is exactly the one worth announcing to.
    if ($peers.Count -eq 0) { exit 0 }

    Set-Content -LiteralPath $marker -Value (Get-Date -Format o) -Force
    Get-ChildItem (Join-Path ([System.IO.Path]::GetTempPath()) "mefor-web-announced-*.flag") -EA SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
        Remove-Item -Force -EA SilentlyContinue

    $branch = (& git branch --show-current 2>$null)
    $root = (& git rev-parse --show-toplevel 2>$null)

    $lines = @()
    $lines += "[ANNOUNCE YOURSELF - $($peers.Count) other session(s) are working in this repo]"
    $lines += ""
    $lines += "You are new here and they do not know you exist. Before you start substantive work,"
    $lines += "send each of them ONE short message via ccd_session_mgmt send_message saying:"
    $lines += "  - where you are   : $root"
    $lines += "                      (branch $branch)"
    $lines += "  - what you intend : one line on the task you were just given"
    $lines += "  - what you expect to touch, if you already know"
    $lines += "Then get on with the work -- do not wait for a reply."
    $lines += ""
    $lines += "Announce to these, and ONLY these (same repo):"
    foreach ($p in $peers) {
        $lines += "  worktree $($p.Label)  [$($p.Branch)]  $($p.Surface)"
        $lines += "      cwd: $($p.Worktree)"
    }
    $lines += ""
    $lines += "RESOLVING THEIR IDs -- READ THIS, THE OBVIOUS WAY IS WRONG."
    $lines += "  The id in the roster banner is the REGISTRY id. ccd_session_mgmt uses a DIFFERENT id"
    $lines += "  for the same session (verified 2026-07-30: registry 933195b8-... and MCP"
    $lines += "  local_938641cd-... were one session; note both begin '93', so they misread as equal)."
    $lines += "  Call list_sessions and match on the cwd printed above. NEVER pass a registry id to"
    $lines += "  send_message, and never assume a matching prefix means a matching session."
    $lines += ""
    $lines += "  A peer whose cwd does not appear in list_sessions is on a surface the MCP cannot see"
    $lines += "  (e.g. VS Code). It cannot be messaged -- skip it and say so rather than guessing."
    $lines += ""
    $lines += "Skip announcing only if this prompt is trivial (a question, a one-line read) and you"
    $lines += "will not be changing files. See CLAUDE.md, 'Parallel sessions'."

    ($lines -join "`n") | Write-Output
} catch {
    exit 0
}
exit 0
