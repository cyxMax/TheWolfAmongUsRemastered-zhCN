param(
    [string]$GamePath = "",
    [switch]$RemoveBackup
)

. (Join-Path $PSScriptRoot "common.ps1")

$manifest = Read-PatchManifest

if ([string]::IsNullOrWhiteSpace($GamePath)) {
    $candidates = New-Object System.Collections.Generic.List[string]
    try {
        $candidates.Add((Find-GameRoot))
    }
    catch {
    }
    $candidates.Add("D:\game\steamapps\common\The Wolf Among Us Remastered")
    $gameRoot = $null
    foreach ($candidate in $candidates) {
        if ((Test-GameRoot -Path $candidate) -and
            (Test-Path -LiteralPath (Join-Path $candidate ".wolf_zhcn_backup\install_state.json"))) {
            $gameRoot = (Resolve-Path -LiteralPath $candidate).Path
            break
        }
    }
    if ($null -eq $gameRoot) {
        throw "Installed patch backup was not found. Re-run with -GamePath pointing to the game folder."
    }
}
else {
    $gameRoot = Find-GameRoot -ExplicitPath $GamePath
}

Assert-GameNotRunning
$archivesRoot = Join-Path $gameRoot "Archives"
$backupRoot = Join-Path $gameRoot ".wolf_zhcn_backup"
$backupArchives = Join-Path $backupRoot "original"
$statePath = Join-Path $backupRoot "install_state.json"

if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    throw "Install state is missing: $statePath"
}
$state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
if ([string]$state.package_version -ne [string]$manifest.version) {
    throw "Backup belongs to a different patch version: $($state.package_version)"
}

$restore = New-Object System.Collections.Generic.List[string]
foreach ($item in @($manifest.archives)) {
    $backup = Join-Path $backupArchives $item.archive
    $target = Join-Path $archivesRoot $item.archive
    Assert-FileHash -Path $backup -Expected $item.original_sha256
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        throw "Current game archive is missing: $target"
    }
    $current = Get-Sha256 -Path $target
    if ($current -eq $item.patched_sha256.ToLowerInvariant()) {
        $restore.Add($item.archive)
    }
    elseif ($current -ne $item.original_sha256.ToLowerInvariant()) {
        throw "Cannot safely uninstall because this archive was changed after installation: $($item.archive)"
    }
}

foreach ($name in $restore) {
    $backup = Join-Path $backupArchives $name
    $target = Join-Path $archivesRoot $name
    $temporary = Join-Path $archivesRoot ("." + $name + ".zhcn-restore.tmp")
    Copy-Item -LiteralPath $backup -Destination $temporary -Force
    $item = @($manifest.archives) | Where-Object { $_.archive -eq $name } | Select-Object -First 1
    Assert-FileHash -Path $temporary -Expected $item.original_sha256
    try {
        [System.IO.File]::Replace($temporary, $target, $null)
    }
    catch {
        Copy-Item -LiteralPath $temporary -Destination $target -Force
        Remove-Item -LiteralPath $temporary -Force
    }
    Assert-FileHash -Path $target -Expected $item.original_sha256
    Write-Host "Restored $name"
}

$state.status = "uninstalled"
$state | Add-Member -NotePropertyName uninstalled_at -NotePropertyValue ((Get-Date).ToString("o")) -Force
$state | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $statePath -Encoding UTF8
Write-Host ""
Write-Host "The original game archives are restored."

if ($RemoveBackup) {
    $resolvedBackup = (Resolve-Path -LiteralPath $backupRoot).Path
    if ([System.IO.Path]::GetFileName($resolvedBackup) -ne ".wolf_zhcn_backup") {
        throw "Refusing to remove an unexpected backup path: $resolvedBackup"
    }
    Remove-Item -LiteralPath $resolvedBackup -Recurse -Force
    Write-Host "The verified backup folder was removed."
}
else {
    Write-Host "The verified backup was kept at: $backupRoot"
}
