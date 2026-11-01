param(
    [string]$GamePath = "",
    [switch]$DryRun
)

. (Join-Path $PSScriptRoot "common.ps1")

$manifest = Read-PatchManifest
$gameRoot = Find-GameRoot -ExplicitPath $GamePath
$archivesRoot = Join-Path $gameRoot "Archives"
$packageArchives = Join-Path $PSScriptRoot "archives"
$backupRoot = Join-Path $gameRoot ".wolf_zhcn_backup"
$backupArchives = Join-Path $backupRoot "original"
$statePath = Join-Path $backupRoot "install_state.json"

foreach ($name in @(
    "Fables_pc_zhCNtest_ar_all.ttarch2",
    "_resdesc_50_zhCNtest.lua",
    "Fables_pc_zhCN_ar_all.ttarch2",
    "_resdesc_50_zhCN.lua"
)) {
    if (Test-Path -LiteralPath (Join-Path $archivesRoot $name)) {
        throw "A previous sidecar test was found: $name. Remove it before installing."
    }
}

foreach ($item in @($manifest.archives)) {
    $source = Join-Path $archivesRoot $item.archive
    $payload = Join-Path $packageArchives $item.archive
    Assert-FileHash -Path $payload -Expected $item.patched_sha256
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Game archive is missing: $source"
    }
    $current = Get-Sha256 -Path $source
    if ($current -eq $item.patched_sha256.ToLowerInvariant()) {
        if (Test-Path -LiteralPath $statePath -PathType Leaf) {
            Write-Host "Patch is already installed. Nothing changed."
            exit 0
        }
        throw "The archive is already patched but no safety backup exists: $($item.archive)"
    }
    if ($current -ne $item.original_sha256.ToLowerInvariant()) {
        throw "Unsupported game version or modified archive: $($item.archive)`nExpected: $($item.original_sha256)`nActual:   $current"
    }
}

if ($DryRun) {
    Write-Host "Preflight passed for $($gameRoot). No files were changed."
    exit 0
}

Assert-GameNotRunning

if (Test-Path -LiteralPath $backupRoot) {
    throw "Backup folder already exists. Do not mix installations: $backupRoot"
}

$requiredBytes = [int64]$manifest.required_free_bytes
$driveRoot = [System.IO.Path]::GetPathRoot($gameRoot)
$freeBytes = (New-Object System.IO.DriveInfo($driveRoot)).AvailableFreeSpace
if ($freeBytes -lt $requiredBytes) {
    throw "Not enough free space. Required: $requiredBytes bytes; available: $freeBytes bytes."
}

New-Item -ItemType Directory -Path $backupArchives -Force | Out-Null
$installed = New-Object System.Collections.Generic.List[string]
$temporaryFiles = New-Object System.Collections.Generic.List[string]

try {
    foreach ($item in @($manifest.archives)) {
        $source = Join-Path $archivesRoot $item.archive
        $backup = Join-Path $backupArchives $item.archive
        Copy-Item -LiteralPath $source -Destination $backup
        Assert-FileHash -Path $backup -Expected $item.original_sha256
    }

    $pendingState = [ordered]@{
        status = "installing"
        package_version = [string]$manifest.version
        game_root = $gameRoot
        started_at = (Get-Date).ToString("o")
        archives = @($manifest.archives | ForEach-Object {
            [ordered]@{
                archive = [string]$_.archive
                original_sha256 = [string]$_.original_sha256
                patched_sha256 = [string]$_.patched_sha256
            }
        })
    }
    $pendingState | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $statePath -Encoding UTF8

    foreach ($item in @($manifest.archives)) {
        $target = Join-Path $archivesRoot $item.archive
        $payload = Join-Path $packageArchives $item.archive
        $temporary = Join-Path $archivesRoot ("." + $item.archive + ".zhcn.tmp")
        $temporaryFiles.Add($temporary)
        Copy-Item -LiteralPath $payload -Destination $temporary -Force
        Assert-FileHash -Path $temporary -Expected $item.patched_sha256
        try {
            [System.IO.File]::Replace($temporary, $target, $null)
        }
        catch {
            Copy-Item -LiteralPath $temporary -Destination $target -Force
        }
        $installed.Add($item.archive)
        Assert-FileHash -Path $target -Expected $item.patched_sha256
        Write-Host "Installed $($item.archive)"
    }

    $completeState = [ordered]@{
        status = "installed"
        package_version = [string]$manifest.version
        game_root = $gameRoot
        installed_at = (Get-Date).ToString("o")
        backup_root = $backupRoot
        archives = @($manifest.archives | ForEach-Object {
            [ordered]@{
                archive = [string]$_.archive
                original_sha256 = [string]$_.original_sha256
                patched_sha256 = [string]$_.patched_sha256
            }
        })
    }
    $completeState | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $statePath -Encoding UTF8
    Write-Host ""
    Write-Host "Simplified Chinese patch installed successfully."
    Write-Host "Original archives were backed up to: $backupArchives"
    Write-Host "Run uninstall.ps1 to restore the original files."
}
catch {
    $failure = $_
    Write-Warning "Installation failed. Attempting to restore every changed archive."
    foreach ($name in $installed) {
        $backup = Join-Path $backupArchives $name
        $target = Join-Path $archivesRoot $name
        if ((Test-Path -LiteralPath $backup -PathType Leaf) -and (Test-Path -LiteralPath $target -PathType Leaf)) {
            Copy-Item -LiteralPath $backup -Destination $target -Force
        }
    }
    throw $failure
}
finally {
    foreach ($temporary in $temporaryFiles) {
        if (Test-Path -LiteralPath $temporary -PathType Leaf) {
            Remove-Item -LiteralPath $temporary -Force
        }
    }
}
