param(
    [Parameter(Mandatory=$true)][string]$FramesDirectory,
    [Parameter(Mandatory=$true)][string]$Destination,
    [int]$Width=960,
    [int]$DelayMilliseconds=180
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationCore,WindowsBase
$gifFiles=@(Get-ChildItem -LiteralPath $FramesDirectory -File | Where-Object Extension -Match '^\.(png|jpg|jpeg)$' | Sort-Object Name)
if ($gifFiles.Count -lt 2) { throw 'At least two captured frames are required.' }
$gifEncoder=[Windows.Media.Imaging.GifBitmapEncoder]::new()
foreach ($gifFile in $gifFiles) {
    $gifInput=[IO.File]::OpenRead($gifFile.FullName)
    try { $gifSource=[Windows.Media.Imaging.BitmapFrame]::Create($gifInput,[Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,[Windows.Media.Imaging.BitmapCacheOption]::OnLoad) }
    finally { $gifInput.Dispose() }
    $gifScale=[Math]::Min(1,$Width/$gifSource.PixelWidth)
    $gifScaled=[Windows.Media.Imaging.TransformedBitmap]::new($gifSource,[Windows.Media.ScaleTransform]::new($gifScale,$gifScale))
    $gifMetadata=[Windows.Media.Imaging.BitmapMetadata]::new('gif')
    $gifMetadata.SetQuery('/grctlext/Delay',[uint16][Math]::Max(2,[Math]::Round($DelayMilliseconds/10)))
    $gifMetadata.SetQuery('/grctlext/Disposal',[byte]2)
    $gifEncoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($gifScaled,$null,$gifMetadata,$null))
}
$gifOutput=[IO.File]::Create([IO.Path]::GetFullPath($Destination))
try { $gifEncoder.Save($gifOutput) } finally { $gifOutput.Dispose() }
# Add an infinite-loop application extension after the logical screen/global palette.
$gifBytes=[IO.File]::ReadAllBytes([IO.Path]::GetFullPath($Destination))
$gifOffset=13
if (($gifBytes[10] -band 128) -ne 0) { $gifOffset+=3*[Math]::Pow(2,($gifBytes[10] -band 7)+1) }
$gifLoop=[byte[]](33,255,11,78,69,84,83,67,65,80,69,50,46,48,3,1,0,0,0)
$gifJoined=[IO.MemoryStream]::new()
try {
    $gifJoined.Write($gifBytes,0,$gifOffset);$gifJoined.Write($gifLoop,0,$gifLoop.Length)
    $gifJoined.Write($gifBytes,$gifOffset,$gifBytes.Length-$gifOffset)
    [IO.File]::WriteAllBytes([IO.Path]::GetFullPath($Destination),$gifJoined.ToArray())
} finally { $gifJoined.Dispose() }
Write-Output ('Created looping GIF from '+$gifFiles.Count+' captured frames: '+[IO.Path]::GetFullPath($Destination))
