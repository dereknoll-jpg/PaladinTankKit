$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$mediaRoot=Join-Path (Split-Path -Parent $PSScriptRoot) 'release/media'
$gallery=Join-Path $mediaRoot 'gallery'
$frames=Join-Path $mediaRoot 'gif-frames'
New-Item -ItemType Directory -Force -Path $gallery,$frames | Out-Null
function Export-Crop($source,$destination,$x,$y,$width,$height) {
    $original=[Drawing.Bitmap]::new($source)
    try {
        $crop=$original.Clone([Drawing.Rectangle]::new($x,$y,$width,$height),[Drawing.Imaging.PixelFormat]::Format24bppRgb)
        try { $crop.Save($destination,[Drawing.Imaging.ImageFormat]::Png) } finally { $crop.Dispose() }
    } finally { $original.Dispose() }
}
foreach($name in @('01-overview','02-ability-timers','03-dungeon-marking','04-appearance')) {
    Export-Crop (Join-Path $mediaRoot "originals/$name.jpg") (Join-Path $gallery "$name.png") 1314 398 812 652
}
Export-Crop (Join-Path $mediaRoot 'originals/05-hud-preview.jpg') (Join-Path $gallery '05-in-game-preview.png') 1214 480 920 174
foreach($frame in Get-ChildItem -LiteralPath (Join-Path $mediaRoot 'raw-gif') -Filter '*.jpg' | Sort-Object Name) {
    Export-Crop $frame.FullName (Join-Path $frames ($frame.BaseName+'.png')) 1214 480 920 174
}
$times=Get-Content -LiteralPath (Join-Path $mediaRoot 'raw-gif/timing.json') -Raw | ConvertFrom-Json
$delay=[int][Math]::Round(($times[-1]-$times[0])/($times.Count-1))
& (Join-Path $PSScriptRoot 'make-gif.ps1') -FramesDirectory $frames -Destination (Join-Path $gallery '06-in-game-preview.gif') -Width 920 -DelayMilliseconds $delay
Write-Output ('Native capture average frame interval: '+$delay+' ms')
