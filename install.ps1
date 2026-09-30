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

# Returns $true when WSL was installed now (the setup continues inside Ubuntu).
# Any Ubuntu distro counts as installed, since the existing one may be named just "Ubuntu".
function Install-Wsl {
    $env:WSL_UTF8 = '1'   # otherwise wsl.exe prints UTF-16 and the names cannot be matched
    $installed = @()
    # Without WSL, wsl.exe may print an error, which PowerShell 5.1 turns into an exception under 'Stop'
    try {
        $installed = @(wsl.exe --list --quiet 2>$null)
        if ($LASTEXITCODE -ne 0) { $installed = @() }
    } catch {
        $installed = @()
    }
    if ($installed | Where-Object { $_ -match '^Ubuntu' }) { return $false }

    Write-Host '==> install WSL and Ubuntu-24.04'
    # --no-launch: creating the Linux user is done later, when Ubuntu is started
    wsl.exe --install --distribution Ubuntu-24.04 --no-launch | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'wsl --install failed' }
    return $true
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

$wslInstalled = Install-Wsl

Write-Output ''
Write-Output 'Done. Next steps:'
if ($wslInstalled) {
    Write-Output '  1. Restart Windows if wsl --install asked for it'
    Write-Output '  2. Start "Ubuntu 24.04" from the Start menu and create the Linux user'
    Write-Output '  3. Run the Linux side of the dotfiles in Ubuntu:'
} else {
    Write-Output '  Run the Linux side of the dotfiles in Ubuntu, if not done yet:'
}
Write-Output "     bash -c `"`$(curl -fsSL $baseUrl/install)`""
