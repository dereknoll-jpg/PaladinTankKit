$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$brandingRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'Branding'
$brandingSource = [Drawing.Image]::FromFile((Join-Path $brandingRoot 'PaladinTankKit-Master.png'))
try {
    if ($brandingSource.Width -ne $brandingSource.Height) { throw 'Brand source must be square.' }
    foreach ($brandingSize in @(400,128,64,32,24)) {
        $brandingBitmap = [Drawing.Bitmap]::new($brandingSize,$brandingSize,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $brandingGraphics = [Drawing.Graphics]::FromImage($brandingBitmap)
            $brandingAttributes = [Drawing.Imaging.ImageAttributes]::new()
            try {
                $brandingGraphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
                $brandingGraphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $brandingGraphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $brandingAttributes.SetWrapMode([Drawing.Drawing2D.WrapMode]::TileFlipXY)
                $brandingRectangle = [Drawing.Rectangle]::new(0,0,$brandingSize,$brandingSize)
                $brandingGraphics.DrawImage($brandingSource,$brandingRectangle,0,0,$brandingSource.Width,$brandingSource.Height,[Drawing.GraphicsUnit]::Pixel,$brandingAttributes)
            } finally { $brandingAttributes.Dispose(); $brandingGraphics.Dispose() }
            $brandingFilename = if ($brandingSize -eq 400) { 'PaladinTankKit-CurseForge-400.png' } else { 'PaladinTankKit-' + $brandingSize + '.png' }
            $brandingBitmap.Save((Join-Path $brandingRoot $brandingFilename),[Drawing.Imaging.ImageFormat]::Png)
            if ($brandingSize -eq 128) {
                # Uncompressed BGRA32, top origin; the game loads this via IconTexture.
                $brandingTgaPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'PaladinTankKit\Media\AddonIcon.tga'
                $brandingWriter = [IO.BinaryWriter]::new([IO.File]::Create($brandingTgaPath))
                try {
                    $brandingHeader = [byte[]]::new(18)
                    $brandingHeader[2]=2; $brandingHeader[12]=128; $brandingHeader[14]=128
                    $brandingHeader[16]=32; $brandingHeader[17]=0x28
                    $brandingWriter.Write($brandingHeader)
                    for ($brandingY=0; $brandingY -lt 128; $brandingY++) {
                        for ($brandingX=0; $brandingX -lt 128; $brandingX++) {
                            $brandingPixel = $brandingBitmap.GetPixel($brandingX,$brandingY)
                            $brandingWriter.Write([byte]$brandingPixel.B); $brandingWriter.Write([byte]$brandingPixel.G)
                            $brandingWriter.Write([byte]$brandingPixel.R); $brandingWriter.Write([byte]$brandingPixel.A)
                        }
                    }
                } finally { $brandingWriter.Dispose() }
            }
        } finally { $brandingBitmap.Dispose() }
    }
} finally { $brandingSource.Dispose() }
Write-Output 'Exported CurseForge PNG, game icon texture, and small-size previews.'
