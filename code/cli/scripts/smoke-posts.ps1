[CmdletBinding()]
param(
    [string]$Message = 'Hello, LinkedIn!',
    [string]$OrganizationUrn,
    [string]$AltText = 'Hello, LinkedIn! test image',
    [string]$DocumentTitle = 'hello-linkedin.pdf',
    [switch]$SkipDoctor,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$cliRoot = Split-Path -Parent $PSScriptRoot
$artifactDir = Join-Path $cliRoot 'build\smoke-posts'
$imagePath = Join-Path $artifactDir 'hello-linkedin.png'
$documentPath = Join-Path $artifactDir 'hello-linkedin.pdf'

function New-SmokeImage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $pngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO5qvV0AAAAASUVORK5CYII='
    [IO.File]::WriteAllBytes($Path, [Convert]::FromBase64String($pngBase64))
}

function ConvertTo-PdfLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    return $Text.Replace('\', '\\').Replace('(', '\(').Replace(')', '\)')
}

function New-SmokePdf {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $pdfText = ConvertTo-PdfLiteral -Text $Text
    $contentStream = "BT`n/F1 24 Tf`n72 720 Td`n($pdfText) Tj`nET"
    $objects = @(
        '<< /Type /Catalog /Pages 2 0 R >>',
        '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>',
        "<< /Length $($contentStream.Length) >>`nstream`n$contentStream`nendstream",
        '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'
    )

    $builder = New-Object System.Text.StringBuilder
    $offsets = New-Object System.Collections.Generic.List[int]
    $ascii = [System.Text.Encoding]::ASCII

    [void]$builder.Append("%PDF-1.4`n")

    for ($index = 0; $index -lt $objects.Count; $index++) {
        $offsets.Add($ascii.GetByteCount($builder.ToString()))
        [void]$builder.Append("$($index + 1) 0 obj`n")
        [void]$builder.Append($objects[$index])
        [void]$builder.Append("`nendobj`n")
    }

    $xrefOffset = $ascii.GetByteCount($builder.ToString())
    [void]$builder.Append("xref`n")
    [void]$builder.Append("0 $($objects.Count + 1)`n")
    [void]$builder.Append("0000000000 65535 f `n")

    foreach ($offset in $offsets) {
        [void]$builder.Append(([string]::Format('{0:0000000000} 00000 n `n', $offset)))
    }

    [void]$builder.Append("trailer`n")
    [void]$builder.Append("<< /Size $($objects.Count + 1) /Root 1 0 R >>`n")
    [void]$builder.Append("startxref`n")
    [void]$builder.Append("$xrefOffset`n")
    [void]$builder.Append("%%EOF`n")

    [IO.File]::WriteAllText($Path, $builder.ToString(), $ascii)
}

function Get-CommonArgs {
    if ([string]::IsNullOrWhiteSpace($OrganizationUrn)) {
        return @()
    }

    return @('--organization', $OrganizationUrn)
}

function Invoke-LinkedInCli {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    Write-Host ">>> $Label"
    Write-Host "    dart run bin/main.dart $($Arguments -join ' ')"

    if ($DryRun) {
        return
    }

    & dart run bin/main.dart @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "The CLI command failed with exit code $LASTEXITCODE."
    }
}

if (Test-Path $artifactDir) {
    Remove-Item -Recurse -Force $artifactDir
}

New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null
New-SmokeImage -Path $imagePath
New-SmokePdf -Path $documentPath -Text $Message

$commonArgs = Get-CommonArgs

Push-Location $cliRoot

try {
    Write-Host '>>> Smoke test assets ready.'
    Write-Host "    Image: $imagePath"
    Write-Host "    Document: $documentPath"

    if (-not $SkipDoctor) {
        Invoke-LinkedInCli -Label 'Checking CLI health' -Arguments @('doctor')
    }

    Invoke-LinkedInCli -Label 'Checking authentication state' -Arguments @('auth', 'status')
    Invoke-LinkedInCli -Label 'Posting hello world text' -Arguments (@('post', 'text', '--message', $Message) + $commonArgs)
    Invoke-LinkedInCli -Label 'Posting hello world image' -Arguments (@('post', 'image', '--file', $imagePath, '--message', $Message, '--alt-text', $AltText) + $commonArgs)
    Invoke-LinkedInCli -Label 'Posting hello world document' -Arguments (@('post', 'document', '--file', $documentPath, '--title', $DocumentTitle, '--message', $Message) + $commonArgs)

    if ($DryRun) {
        Write-Host '>>> Dry run complete. No posts were published.'
    } else {
        Write-Host '>>> Smoke post sequence complete.'
    }
}
finally {
    Pop-Location
}