$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$cliRoot = Split-Path -Parent $scriptDir
$buildDir = Join-Path $cliRoot 'build'
$installDir = Join-Path $env:LOCALAPPDATA 'post_publisher'
$binDir = Join-Path $installDir 'bin'

Write-Host '>>> Building from source...'
& "$scriptDir\build.ps1"

if (Test-Path $installDir) {
    Write-Host '>>> Removing previous installation...'
    Remove-Item -Recurse -Force $installDir
}

Write-Host ">>> Installing to $installDir..."
New-Item -ItemType Directory -Force -Path $binDir | Out-Null
Copy-Item (Join-Path $buildDir 'bin' 'linkedin.exe') (Join-Path $binDir 'linkedin.exe')

if (Test-Path (Join-Path $buildDir 'assets')) {
    Copy-Item -Recurse (Join-Path $buildDir 'assets') (Join-Path $installDir 'assets')
}

Write-Host '>>> Creating linkedin alias...'
Set-Content -Path (Join-Path $binDir 'linkedin.cmd') -Value '@"%~dp0linkedin.exe" %*' -Encoding ASCII

$userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')

$entries = @()
if (-not [string]::IsNullOrWhiteSpace($userPath)) {
    $entries = @(
        $userPath -split ';' | Where-Object { $_ -and $_ -ne $binDir }
    )
}

$updatedUserPath = (@($binDir) + $entries) -join ';'
if ($userPath -ne $updatedUserPath) {
    [System.Environment]::SetEnvironmentVariable('PATH', $updatedUserPath, 'User')
}

if (($env:PATH -split ';') -notcontains $binDir) {
    $env:PATH = "$binDir;$env:PATH"
}

Write-Host '>>> Verifying...'
& (Join-Path $binDir 'linkedin.exe') version

Write-Host ''
Write-Host '>>> Installed from source successfully!'
Write-Host "    Location: $installDir"