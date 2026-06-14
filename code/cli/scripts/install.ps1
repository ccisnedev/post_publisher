$ErrorActionPreference = 'Stop'

$repo = 'ccisnedev/post_publisher'
$installDir = Join-Path $env:LOCALAPPDATA 'post_publisher'
$binDir = Join-Path $installDir 'bin'

if ($env:OS -ne 'Windows_NT') {
    Write-Error 'LinkedIn CLI currently supports Windows only in install.ps1.'
    exit 1
}

if ([System.Environment]::Is64BitOperatingSystem -eq $false) {
    Write-Error 'LinkedIn CLI requires a 64-bit operating system.'
    exit 1
}

Write-Host '>>> Fetching latest release...'
$releaseUrl = "https://api.github.com/repos/$repo/releases/latest"
$headers = @{ Accept = 'application/vnd.github+json' }

if ($env:GITHUB_TOKEN) {
    $headers['Authorization'] = "Bearer $env:GITHUB_TOKEN"
}

$release = Invoke-RestMethod -Uri $releaseUrl -Headers $headers
$asset = $release.assets | Where-Object { $_.name -like 'linkedin-windows-x64*.zip' } | Select-Object -First 1

if (-not $asset) {
    Write-Error "No linkedin-windows-x64 asset found in release $($release.tag_name)."
    exit 1
}

$tempZip = Join-Path $env:TEMP "linkedin-$($release.tag_name).zip"

Write-Host '>>> Downloading...'
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip -Headers $headers

if (Test-Path $installDir) {
    Write-Host '>>> Removing previous installation...'
    Remove-Item -Recurse -Force $installDir
}

Write-Host '>>> Extracting...'
Expand-Archive -Path $tempZip -DestinationPath $installDir -Force
Remove-Item $tempZip

Write-Host '>>> Creating linkedin alias...'
Set-Content -Path (Join-Path $binDir 'linkedin.cmd') -Value '@"%~dp0linkedin.exe" %*' -Encoding ASCII

$userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
if ($userPath -notlike "*$binDir*") {
    [System.Environment]::SetEnvironmentVariable('PATH', "$userPath;$binDir", 'User')
    $env:PATH = "$env:PATH;$binDir"
}

Write-Host '>>> Verifying installation...'
& (Join-Path $binDir 'linkedin.exe') version

Write-Host ''
Write-Host '>>> LinkedIn CLI installed successfully!'
Write-Host "    Location: $installDir"