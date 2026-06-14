$ErrorActionPreference = 'Stop'

$repo = 'ccisnedev/post_publisher'
$installDir = Join-Path $env:LOCALAPPDATA 'post_publisher'
$binDir = Join-Path $installDir 'bin'

if ($env:OS -ne 'Windows_NT') {
    Write-Error 'Post Publisher currently supports Windows only in install.ps1.'
    exit 1
}

if ([System.Environment]::Is64BitOperatingSystem -eq $false) {
    Write-Error 'Post Publisher requires a 64-bit operating system.'
    exit 1
}

Write-Host '>>> Fetching latest release...'
$releaseUrl = "https://api.github.com/repos/$repo/releases/latest"
$headers = @{ Accept = 'application/vnd.github+json' }

if ($env:GITHUB_TOKEN) {
    $headers['Authorization'] = "Bearer $env:GITHUB_TOKEN"
}

$release = Invoke-RestMethod -Uri $releaseUrl -Headers $headers
$asset = $release.assets | Where-Object { $_.name -like 'post-publisher-windows-x64*.zip' } | Select-Object -First 1

if (-not $asset) {
    Write-Error "No post-publisher-windows-x64 asset found in release $($release.tag_name)."
    exit 1
}

$tempZip = Join-Path $env:TEMP "post-publisher-$($release.tag_name).zip"

Write-Host '>>> Downloading...'
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip -Headers $headers

if (Test-Path $installDir) {
    Write-Host '>>> Removing previous installation...'
    Remove-Item -Recurse -Force $installDir
}

Write-Host '>>> Extracting...'
Expand-Archive -Path $tempZip -DestinationPath $installDir -Force
Remove-Item $tempZip

Write-Host '>>> Creating command aliases (post-publisher, pp)...'
Set-Content -Path (Join-Path $binDir 'post-publisher.cmd') -Value '@"%~dp0post-publisher.exe" %*' -Encoding ASCII
Set-Content -Path (Join-Path $binDir 'pp.cmd') -Value '@"%~dp0post-publisher.exe" %*' -Encoding ASCII

$userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
if ($userPath -notlike "*$binDir*") {
    [System.Environment]::SetEnvironmentVariable('PATH', "$userPath;$binDir", 'User')
    $env:PATH = "$env:PATH;$binDir"
}

Write-Host '>>> Verifying installation...'
& (Join-Path $binDir 'post-publisher.exe') version

Write-Host ''
Write-Host '>>> Post Publisher installed successfully!'
Write-Host '    Commands: post-publisher (alias: pp)'
Write-Host "    Location: $installDir"