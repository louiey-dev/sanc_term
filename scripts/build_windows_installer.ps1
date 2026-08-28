[CmdletBinding()]
param(
    [switch]$SkipFlutterBuild,
    [switch]$SkipVCRedist,
    [string]$InnoCompilerPath,
    [string]$OutputDirectory,
    [string]$CertificateThumbprint,
    [string]$SignToolPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$repositoryRoot = Split-Path -Parent $scriptDirectory
$pubspecPath = Join-Path $repositoryRoot 'pubspec.yaml'
$releaseDirectory = Join-Path $repositoryRoot 'build\windows\x64\runner\Release'
$installerScript = Join-Path $repositoryRoot 'installer\sanc_term.iss'
$cacheDirectory = Join-Path $repositoryRoot 'installer\cache'

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $repositoryRoot 'dist'
}

$versionLine = Select-String -LiteralPath $pubspecPath -Pattern '^version:\s*([^+\s]+)(?:\+(\d+))?\s*$'
if ($null -eq $versionLine) {
    throw 'Could not read the application version from pubspec.yaml.'
}

$versionName = $versionLine.Matches[0].Groups[1].Value
$buildNumber = $versionLine.Matches[0].Groups[2].Value
if ([string]::IsNullOrWhiteSpace($buildNumber)) {
    $buildNumber = '0'
}

$versionParts = @($versionName.Split('.'))
if ($versionParts.Count -ne 3) {
    throw "Expected a semantic version such as 1.2.3, found '$versionName'."
}
$versionQuad = "$($versionParts[0]).$($versionParts[1]).$($versionParts[2]).$buildNumber"

if (-not $SkipFlutterBuild) {
    Push-Location $repositoryRoot
    try {
        & flutter build windows --release --build-name $versionName --build-number $buildNumber
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter Windows build failed with exit code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }
}

$applicationExe = Join-Path $releaseDirectory 'sanc_term.exe'
if (-not (Test-Path -LiteralPath $applicationExe -PathType Leaf)) {
    throw "Release executable not found: $applicationExe"
}
if (-not (Test-Path -LiteralPath (Join-Path $releaseDirectory 'data') -PathType Container)) {
    throw "Flutter data directory not found under: $releaseDirectory"
}

if ([string]::IsNullOrWhiteSpace($InnoCompilerPath)) {
    $isccCommand = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($null -ne $isccCommand) {
        $InnoCompilerPath = $isccCommand.Source
    }
    else {
        $innoCandidates = @(
            'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
            'C:\Program Files\Inno Setup 6\ISCC.exe'
        )
        $InnoCompilerPath = $innoCandidates |
            Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
            Select-Object -First 1
    }
}
if ([string]::IsNullOrWhiteSpace($InnoCompilerPath)) {
    throw 'Inno Setup 6 compiler (ISCC.exe) was not found. Install Inno Setup or pass -InnoCompilerPath.'
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$vcredistPath = $null
if (-not $SkipVCRedist) {
    New-Item -ItemType Directory -Path $cacheDirectory -Force | Out-Null
    $vcredistPath = Join-Path $cacheDirectory 'vc_redist.x64.exe'
    if (-not (Test-Path -LiteralPath $vcredistPath -PathType Leaf)) {
        Write-Host 'Downloading the Microsoft Visual C++ 2015-2022 x64 Redistributable...'
        Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile $vcredistPath
    }
}

if (-not [string]::IsNullOrWhiteSpace($CertificateThumbprint)) {
    if ([string]::IsNullOrWhiteSpace($SignToolPath)) {
        $signToolCommand = Get-Command signtool.exe -ErrorAction SilentlyContinue
        if ($null -eq $signToolCommand) {
            throw 'signtool.exe was not found. Pass -SignToolPath or add it to PATH.'
        }
        $SignToolPath = $signToolCommand.Source
    }
    & $SignToolPath sign /sha1 $CertificateThumbprint /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $applicationExe
    if ($LASTEXITCODE -ne 0) {
        throw "Application signing failed with exit code $LASTEXITCODE."
    }
}

$isccArguments = @(
    "/DAppVersion=$versionName",
    "/DAppVersionQuad=$versionQuad",
    "/DReleaseDir=$releaseDirectory",
    "/DOutputDir=$OutputDirectory"
)
if ($null -ne $vcredistPath) {
    $isccArguments += "/DVCRedistPath=$vcredistPath"
}
$isccArguments += $installerScript

& $InnoCompilerPath @isccArguments
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup compilation failed with exit code $LASTEXITCODE."
}

$installerPath = Join-Path $OutputDirectory "sanc_term_setup_$versionName.exe"
if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
    throw "Installer output was not found: $installerPath"
}

if (-not [string]::IsNullOrWhiteSpace($CertificateThumbprint)) {
    & $SignToolPath sign /sha1 $CertificateThumbprint /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $installerPath
    if ($LASTEXITCODE -ne 0) {
        throw "Installer signing failed with exit code $LASTEXITCODE."
    }
}

Write-Host "Installer created: $installerPath"
