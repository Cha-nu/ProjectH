# Offline replay of measured runtime draw commands, not a live engine screenshot.
param([switch]$Native)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot
$runtime = if ($Native) { 'native' } else { 'browser' }
$ops = Get-Content (Join-Path $root "build/background-$runtime-commands.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$out = [Drawing.Bitmap]::new(1536,1212)
$gfx = [Drawing.Graphics]::FromImage($out)
$gfx.Clear([Drawing.Color]::WhiteSmoke)
$gfx.InterpolationMode = 'HighQualityBicubic'
$font = [Drawing.Font]::new('Arial',10)
for ($i=0; $i -lt $ops.Count; $i++) {
    $op=$ops[$i]; $x=($i%4)*384; $y=[Math]::Floor($i/4)*202
    $gfx.DrawString(($op.path -replace '^.*/scene_','' -replace '.png$',''),$font,[Drawing.Brushes]::Black,$x+8,$y+2)
    $state=$gfx.Save()
    $gfx.TranslateTransform($x,$y+22); $gfx.ScaleTransform(.3,.3)
    $gfx.SetClip([Drawing.RectangleF]::new(0,0,1280,600))
    $im=[Drawing.Bitmap]::new((Join-Path $root $op.path))
    $s=$op.source; $d=$op.dest
    $gfx.DrawImage($im,[Drawing.RectangleF]::new($d[0],$d[1],$d[2],$d[3]),[Drawing.RectangleF]::new($s[0],$s[1],$s[2],$s[3]),[Drawing.GraphicsUnit]::Pixel)
    $gfx.Restore($state); $im.Dispose()
}
$out.Save((Join-Path $root "build/background-$runtime-review.png"))
$gfx.Dispose(); $out.Dispose(); $font.Dispose()
Write-Output "Saved background-$runtime-review.png (offline runtime replay)"
