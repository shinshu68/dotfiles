# Set up the Windows side of shinshu68's dotfiles.
# Run it again at any time: already-applied settings and installed packages are skipped.
#
# This file is kept ASCII-only. Windows PowerShell 5.1 reads BOM-less UTF-8 as the
# system code page, and `irm | iex` may not decode it as UTF-8 either.

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

$baseUrl = 'https://shinshu68.github.io/dotfiles'

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

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget not found. Install "App Installer" from Microsoft Store first.'
}

Invoke-WinGetConfigure 'windows/base.dsc.yaml'
