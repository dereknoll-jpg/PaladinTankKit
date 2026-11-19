$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$addonPath = Join-Path $projectRoot 'PaladinTankKit'
$distributionPath = Join-Path $projectRoot 'dist'
New-Item -ItemType Directory -Path $distributionPath -Force | Out-Null
$tocContents = Get-Content -LiteralPath (Join-Path $addonPath 'PaladinTankKit.toc') -Raw
$versionMatch = [regex]::Match($tocContents, '(?m)^## Version: ([\w.\-]+)\s*$')
if (-not $versionMatch.Success) { throw 'Missing addon version in TOC.' }
$archivePath = Join-Path $distributionPath ('PaladinTankKit-' + $versionMatch.Groups[1].Value + '.zip')
Compress-Archive -LiteralPath $addonPath -DestinationPath $archivePath -Force
Write-Output $archivePath
