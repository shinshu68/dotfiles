# Set up the Windows side of shinshu68's dotfiles.
# Run it again at any time: already-applied settings and installed packages are skipped.
#
# This file is kept ASCII-only. Windows PowerShell 5.1 reads BOM-less UTF-8 as the
# system code page, and `irm | iex` may not decode it as UTF-8 either.

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

$baseUrl = 'https://shinshu68.github.io/dotfiles'

# Remembers whether this PC is a personal one, so the question is asked only once.
# Delete this file to answer again.
$settingsPath = Join-Path $env:USERPROFILE '.dotfiles-windows.json'

# Use the local file when this script runs from a clone (e.g. while testing a branch),
# otherwise download it from GitHub Pages (when run via `irm | iex`).
function Get-DotfilesFile([string]$path) {
    if ($PSScriptRoot) {
        $local = Join-Path $PSScriptRoot ($path -replace '/', '\')
        if (Test-Path -LiteralPath $local) { return $local }
    }
    $dest = Join-Path $env:TEMP ('dotfiles-' + (Split-Path $path -Leaf))
    Invoke-WebRequest -UseBasicParsing -Uri "$baseUrl/$path" -OutFile $dest
    return $dest
}

function Invoke-WinGetConfigure([string]$path) {
    $file = Get-DotfilesFile $path
    Write-Output "==> winget configure: $path"
    winget configure --file $file --accept-configuration-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) { throw "winget configure failed: $path" }
}

function Get-IsPersonal {
    if (Test-Path -LiteralPath $settingsPath) {
        $settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
        return [bool]$settings.personal
    }

    while ($true) {
        $answer = Read-Host 'Is this a personal PC? Personal apps will also be installed. [y/N]'
        if ($answer -match '^(y|yes)$') { $personal = $true;  break }
        if ($answer -match '^(n|no)?$') { $personal = $false; break }
    }
    @{ personal = $personal } | ConvertTo-Json | Set-Content -LiteralPath $settingsPath -Encoding ASCII
    # Write-Host, not Write-Output: output from a function is mixed into its return value
    Write-Host "Saved to $settingsPath (delete it to answer again)"
    return $personal
}

# Cica is not in winget, so install it for the current user from GitHub Releases.
# (Written here instead of a separate .ps1, because a downloaded script can be blocked by the execution policy)
# The paths are parameters so that it can be tried against a temporary place
# (installed fonts are locked while signed in and cannot be removed to test it)
function Install-Cica(
    [string]$fontsDir = (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'),
    [string]$regPath  = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
) {
    $version = 'v5.0.3'
    $names   = 'Cica-Regular', 'Cica-Bold', 'Cica-RegularItalic', 'Cica-BoldItalic'

    $missing = $names | Where-Object { -not (Test-Path -LiteralPath (Join-Path $fontsDir "$_.ttf")) }
    if (-not $missing) { return }

    Write-Output "==> install Cica $version"
    $zip = Join-Path $env:TEMP "Cica_$version.zip"
    $dir = Join-Path $env:TEMP "Cica_$version"
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/miiton/Cica/releases/download/$version/Cica_$version.zip" -OutFile $zip
    Expand-Archive -Force -LiteralPath $zip -DestinationPath $dir

    New-Item -ItemType Directory -Force -Path $fontsDir | Out-Null
    # New-Item -Force on an existing key recreates it and drops the other fonts' entries
    if (-not (Test-Path -LiteralPath $regPath)) { New-Item -Path $regPath | Out-Null }
    foreach ($name in $names) {
        $dest = Join-Path $fontsDir "$name.ttf"
        Copy-Item -Force -LiteralPath (Join-Path $dir "$name.ttf") -Destination $dest
        New-ItemProperty -Force -Path $regPath -Name "$name (TrueType)" -Value $dest -PropertyType String | Out-Null
    }
    Remove-Item -Recurse -Force -LiteralPath $zip, $dir
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget not found. Install "App Installer" from Microsoft Store first.'
}

# Ask before installing anything, so the script does not stop halfway to wait for an answer
$isPersonal = Get-IsPersonal

Invoke-WinGetConfigure 'windows/base.dsc.yaml'
if ($isPersonal) {
    Invoke-WinGetConfigure 'windows/personal.dsc.yaml'
}

Install-Cica
