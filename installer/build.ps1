# ====================================================================
#  Builds the Markdown Viewer installer locally.
#
#    1. Publishes a self-contained single-exe build to .\publish
#    2. Compiles installer\MarkdownViewer.iss into .\dist\MarkdownViewer-Setup-<ver>.exe
#
#  Usage (from the repo root or anywhere):
#    pwsh installer\build.ps1
#    pwsh installer\build.ps1 -Version 1.2.0
#
#  Requires: .NET 9 SDK and Inno Setup 6 (iscc.exe on PATH or in its
#  default install location).
# ====================================================================
param(
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

# Repo root = parent of this script's folder.
$repo = Split-Path -Parent $PSScriptRoot
$publishDir = Join-Path $repo "publish"

Write-Host "==> Publishing Markdown Viewer $Version ..." -ForegroundColor Cyan
dotnet publish (Join-Path $repo "MarkdownViewer.csproj") `
    -c Release -r win-x64 --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:Version=$Version `
    -o $publishDir
if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed." }

# Locate the Inno Setup compiler.
$iscc = (Get-Command iscc.exe -ErrorAction SilentlyContinue).Source
if (-not $iscc) {
    foreach ($p in @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles}\Inno Setup 6\ISCC.exe")) {
        if (Test-Path $p) { $iscc = $p; break }
    }
}
if (-not $iscc) {
    throw "Inno Setup (iscc.exe) not found. Install it from https://jrsoftware.org/isdl.php or 'winget install JRSoftware.InnoSetup'."
}

Write-Host "==> Compiling installer with $iscc ..." -ForegroundColor Cyan
& $iscc "/DMyAppVersion=$Version" (Join-Path $PSScriptRoot "MarkdownViewer.iss")
if ($LASTEXITCODE -ne 0) { throw "Inno Setup compile failed." }

Write-Host "==> Done. Installer is in $(Join-Path $repo 'dist')" -ForegroundColor Green
