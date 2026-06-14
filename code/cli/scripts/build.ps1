$ErrorActionPreference = 'Stop'

$cliRoot = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $cliRoot 'build'

if (Test-Path $buildDir) {
    Remove-Item -Recurse -Force $buildDir
}

New-Item -ItemType Directory -Force -Path (Join-Path $buildDir 'bin') | Out-Null

Write-Host '>>> Compiling linkedin.exe...'
$binOutput = Join-Path (Join-Path $buildDir 'bin') 'linkedin.exe'
Push-Location $cliRoot
dart compile exe bin/main.dart -o $binOutput
Pop-Location

if (Test-Path (Join-Path $cliRoot 'assets')) {
    Write-Host '>>> Copying assets...'
    Copy-Item -Recurse (Join-Path $cliRoot 'assets') (Join-Path $buildDir 'assets')
}

Write-Host '>>> Build complete.'
Write-Host "    Binary: $binOutput"