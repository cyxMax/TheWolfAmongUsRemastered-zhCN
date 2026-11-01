param([string]$GamePath = "")

. (Join-Path $PSScriptRoot "common.ps1")

$manifest = Read-PatchManifest
$gameRoot = Find-GameRoot -ExplicitPath $GamePath
$archivesRoot = Join-Path $gameRoot "Archives"
$originalCount = 0
$patchedCount = 0
$failures = New-Object System.Collections.Generic.List[string]

foreach ($item in @($manifest.archives)) {
    $target = Join-Path $archivesRoot $item.archive
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        $failures.Add("missing: $($item.archive)")
        continue
    }
    $actual = Get-Sha256 -Path $target
    if ($actual -eq $item.original_sha256.ToLowerInvariant()) {
        $originalCount++
        Write-Host "ORIGINAL $($item.archive)"
    }
    elseif ($actual -eq $item.patched_sha256.ToLowerInvariant()) {
        $patchedCount++
        Write-Host "PATCHED  $($item.archive)"
    }
    else {
        $failures.Add("unknown hash: $($item.archive) ($actual)")
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR $_" }
    exit 1
}
if ($originalCount -gt 0 -and $patchedCount -gt 0) {
    throw "Mixed installation state: $patchedCount patched archives and $originalCount original archives."
}
Write-Host "Verification passed: $patchedCount patched, $originalCount original."
