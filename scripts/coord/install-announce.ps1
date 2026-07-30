<#
.SYNOPSIS
    Wire (or remove) the UserPromptSubmit hook that makes a new session announce itself to its peers.

.DESCRIPTION
    The other two coordination hooks were already installed machine-wide before this repo had any
    scripts for them to find. This one is new, so it needs installing -- and it is scripted rather than
    hand-edited so it is reproducible, reversible, and reviewable in a PR.

    USER LEVEL, LIKE THE OTHERS. `/.claude/` is not delivered by git, so a project-level hook never
    reaches a worktree created outside the harness -- which is half of them. `~/.claude/settings.json`
    loads everywhere.

    NO INSTALLED COPY. The hook is a one-line shim that locates scripts/hooks/announce.ps1 in a
    checkout and runs it, so a merge updates the behaviour everywhere with nothing to fall stale. In a
    repo that has no such file -- every other project on this machine -- the shim resolves nothing and
    exits 0, so this is inert outside this repo.

    ITS OWN MARKER, DELIBERATELY. The engine repo's install-coordination.ps1 strips every entry marked
    `mefor-coord` for the events it manages before re-adding its own. Sharing that marker would put
    this hook one re-install away from silent deletion. `mefor-web-announce` is untouched by it.

    Idempotent: re-running replaces our entry and leaves every other hook alone.

.EXAMPLE
    pwsh -NoProfile -File scripts\coord\install-announce.ps1 -Status
    pwsh -NoProfile -File scripts\coord\install-announce.ps1
    pwsh -NoProfile -File scripts\coord\install-announce.ps1 -Uninstall
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Status,
    [switch]$Uninstall,
    # Settings file to modify. Tests point this at a fixture instead of the real user settings.
    [string]$SettingsPath = (Join-Path $env:USERPROFILE ".claude\settings.json")
)

$ErrorActionPreference = "Stop"

$MARKER = "mefor-web-announce"
$EVENT = "UserPromptSubmit"
$SCRIPT_REL = "scripts/hooks/announce.ps1"

# Resolves the PRIMARY checkout first, current worktree second: coordination is infrastructure and has
# to be uniform, so a session on a branch that predates this merge still runs the current protocol.
$SHIM = (
    "# $MARKER`n" +
    '$c = (& git rev-parse --path-format=absolute --git-common-dir 2>$null); ' +
    'if ($LASTEXITCODE -eq 0 -and $c) { ' +
    '$bases = @((Split-Path $c.Trim() -Parent), (& git rev-parse --path-format=absolute --show-toplevel 2>$null)); ' +
    'foreach ($b in $bases) { ' +
    'if (-not $b) { continue } ' +
    "`$s = Join-Path `$b.Trim() '$SCRIPT_REL'; " +
    'if (Test-Path -LiteralPath $s) { & $s; break } } }'
)

function Read-Settings {
    if (-not (Test-Path -LiteralPath $SettingsPath)) { return [ordered]@{} }
    $raw = Get-Content -LiteralPath $SettingsPath -Raw
    if (-not $raw.Trim()) { return [ordered]@{} }
    # Fail loudly rather than overwrite. Settings we cannot parse are settings we must not rewrite:
    # a bad write does not error at startup, it silently disables every setting in the file.
    return ($raw | ConvertFrom-Json -AsHashtable)
}

function Test-IsOurs([hashtable]$Entry) {
    foreach ($h in @($Entry.hooks)) { if ([string]$h.command -match [regex]::Escape($MARKER)) { return $true } }
    return $false
}

$settings = Read-Settings
if (-not $settings.hooks) { $settings.hooks = [ordered]@{} }

if ($Status) {
    $ours = @(@($settings.hooks[$EVENT]) | Where-Object { $_ -and (Test-IsOurs $_) })
    Write-Host ""
    Write-Host "Announce hook in ${SettingsPath}:"
    Write-Host ("  {0,-18} {1,-28} {2}" -f $EVENT, $SCRIPT_REL, $(if ($ours.Count -gt 0) { "INSTALLED" } else { "missing" }))
    Write-Host ""
    exit 0
}

# Strip ours first -- this is both the uninstall path and the idempotency of a re-install.
if ($settings.hooks[$EVENT]) {
    $kept = @(@($settings.hooks[$EVENT]) | Where-Object { $_ -and -not (Test-IsOurs $_) })
    if ($kept.Count -gt 0) { $settings.hooks[$EVENT] = $kept } else { $settings.hooks.Remove($EVENT) }
}

if (-not $Uninstall) {
    $entry = [ordered]@{
        hooks = @(
            [ordered]@{
                type          = "command"
                command       = $SHIM
                shell         = "powershell"
                timeout       = 20
                statusMessage = "Announcing to sessions in this repo"
            }
        )
    }
    $settings.hooks[$EVENT] = @(@($settings.hooks[$EVENT]) | Where-Object { $_ }) + @($entry)
}

$backup = "$SettingsPath.bak-web-announce"
if ($PSCmdlet.ShouldProcess($SettingsPath, $(if ($Uninstall) { "remove announce hook" } else { "install announce hook" }))) {
    if (Test-Path -LiteralPath $SettingsPath) { Copy-Item -LiteralPath $SettingsPath -Destination $backup -Force }
    $json = $settings | ConvertTo-Json -Depth 12
    # Validate BEFORE replacing the file, for the reason given in Read-Settings.
    try { $null = $json | ConvertFrom-Json } catch { throw "Refusing to write: generated settings JSON is invalid. $_" }
    Set-Content -LiteralPath $SettingsPath -Value $json -Encoding UTF8

    Write-Host ""
    if ($Uninstall) { Write-Host "Announce hook REMOVED from $SettingsPath" -ForegroundColor Yellow }
    else { Write-Host "Announce hook INSTALLED (user level -- loads in every worktree)" -ForegroundColor Green }
    Write-Host "  backup: $backup"
    Write-Host "  Takes effect in NEWLY STARTED sessions; existing ones keep the config they booted with."
    Write-Host ""
}
