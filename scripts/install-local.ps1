$ErrorActionPreference='Stop'
$installProjectRoot=Split-Path -Parent $PSScriptRoot
$installSource=Join-Path $installProjectRoot 'PaladinTankKit'
$installTarget='E:\World of Warcraft\_forever_\Interface\AddOns\PaladinTankKit'
$installExpectedParent='E:\World of Warcraft\_forever_\Interface\AddOns'
if ([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($installTarget)) -ne $installExpectedParent) { throw 'Unexpected installation target.' }
if (-not (Test-Path -LiteralPath (Join-Path $installSource 'PaladinTankKit.toc'))) { throw 'Source addon missing.' }
if (Get-Process Wow -ErrorAction SilentlyContinue) { Write-Output 'WoW is open: reload the UI after this addon-only file update.' }
if (Test-Path -LiteralPath $installTarget) {
    $installBackup=Join-Path $installProjectRoot ('backups\before-1.0-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $installBackup -Force | Out-Null
    Copy-Item -LiteralPath $installTarget -Destination $installBackup -Recurse
    Write-Output ('Backup: '+$installBackup)
}
New-Item -ItemType Directory -Path $installTarget -Force | Out-Null
foreach ($installItem in Get-ChildItem -LiteralPath $installSource) { Copy-Item -LiteralPath $installItem.FullName -Destination $installTarget -Recurse -Force }
foreach ($installFile in Get-ChildItem -LiteralPath $installSource -Recurse -File) {
    $installRelative=$installFile.FullName.Substring($installSource.Length+1)
    if ((Get-FileHash -LiteralPath $installFile.FullName).Hash -ne (Get-FileHash -LiteralPath (Join-Path $installTarget $installRelative)).Hash) { throw ('Verification failed: '+$installRelative) }
}
Write-Output 'Installed and verified Paladin TankKit 1.0.0, including the new AddOns-list logo.'
