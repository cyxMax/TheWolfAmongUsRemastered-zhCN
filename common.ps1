Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:ExpectedGameFolder = "The Wolf Among Us Remastered"
$script:ExpectedExeName = "TheWolfAmongUsRemastered.exe"

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            $bytes = $sha.ComputeHash($stream)
        }
        finally {
            $sha.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }
    return ([System.BitConverter]::ToString($bytes) -replace "-", "").ToLowerInvariant()
}

function Assert-FileHash {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Expected
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required file not found: $Path"
    }
    $actual = Get-Sha256 -Path $Path
    if ($actual -ne $Expected.ToLowerInvariant()) {
        throw "SHA-256 mismatch for $Path`nExpected: $($Expected.ToLowerInvariant())`nActual:   $actual"
    }
}

function Test-GameRoot {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }
    try {
        $root = (Resolve-Path -LiteralPath $Path).Path
    }
    catch {
        return $false
    }
    return (
        (Test-Path -LiteralPath (Join-Path $root $script:ExpectedExeName) -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $root "Archives") -PathType Container)
    )
}

function Find-GameRoot {
    param([string]$ExplicitPath = "")

    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
        if (Test-GameRoot -Path $ExplicitPath) {
            return (Resolve-Path -LiteralPath $ExplicitPath).Path
        }
        $nested = Join-Path $ExplicitPath $script:ExpectedGameFolder
        if (Test-GameRoot -Path $nested) {
            return (Resolve-Path -LiteralPath $nested).Path
        }
        throw "The supplied game path is invalid: $ExplicitPath"
    }

    $steamRoots = New-Object System.Collections.Generic.List[string]
    $steamKey = "HKCU:\Software\Valve\Steam"
    if (Test-Path -LiteralPath $steamKey) {
        $properties = Get-ItemProperty -LiteralPath $steamKey
        if ($properties.PSObject.Properties.Name -contains "SteamPath") {
            $steamRoots.Add([string]$properties.SteamPath)
        }
    }
    foreach ($fallback in @("D:\game", "C:\Program Files (x86)\Steam", "C:\Program Files\Steam")) {
        $steamRoots.Add($fallback)
    }

    $libraryRoots = New-Object System.Collections.Generic.List[string]
    foreach ($steamRoot in $steamRoots) {
        $libraryRoots.Add($steamRoot)
        $libraryFile = Join-Path $steamRoot "steamapps\libraryfolders.vdf"
        if (Test-Path -LiteralPath $libraryFile -PathType Leaf) {
            $text = [System.IO.File]::ReadAllText($libraryFile)
            foreach ($match in [regex]::Matches($text, '"path"\s+"([^"]+)"')) {
                $libraryRoots.Add($match.Groups[1].Value.Replace("\\", "\"))
            }
        }
    }

    $seen = @{}
    foreach ($libraryRoot in $libraryRoots) {
        if (-not $seen.ContainsKey($libraryRoot)) {
            $seen[$libraryRoot] = $true
            $candidate = Join-Path $libraryRoot ("steamapps\common\" + $script:ExpectedGameFolder)
            if (Test-GameRoot -Path $candidate) {
                return (Resolve-Path -LiteralPath $candidate).Path
            }
        }
    }

    $known = "D:\game\steamapps\common\The Wolf Among Us Remastered"
    if (Test-GameRoot -Path $known) {
        return (Resolve-Path -LiteralPath $known).Path
    }
    throw "Game installation not found. Re-run with -GamePath pointing to the game folder."
}

function Assert-GameNotRunning {
    $process = Get-Process -Name "TheWolfAmongUsRemastered" -ErrorAction SilentlyContinue
    if ($null -ne $process) {
        throw "The game is running. Close it completely before continuing."
    }

    $steamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue
    if ($null -ne $steamProcess) {
        throw "Steam is running and may hold archive files open. Exit Steam completely before continuing."
    }
}

function Read-PatchManifest {
    $path = Join-Path $PSScriptRoot "manifest.json"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "manifest.json is missing from the patch folder."
    }
    return (Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json)
}
