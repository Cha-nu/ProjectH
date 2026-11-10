# Offline raster replay of either runtime's draw commands; does not change source artwork.
param([switch]$Native)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot
$inputName = if ($Native) { 'boss-preview-native-commands.json' } else { 'boss-preview-commands.json' }
$outputName = if ($Native) { 'soft-boss-native-review.png' } else { 'soft-boss-review.png' }
$ops = Get-Content (Join-Path $root "build/$inputName") -Raw -Encoding UTF8 | ConvertFrom-Json
$out = [Drawing.Bitmap]::new(1280,720); $gfx = [Drawing.Graphics]::FromImage($out)
$gfx.SmoothingMode = 'AntiAlias'; $gfx.InterpolationMode = 'HighQualityBicubic'; $gfx.Clear([Drawing.Color]::White)
$stack = [Collections.Generic.Stack[object]]::new(); $images = @{}; $fill = '#ffffff'; $stroke = '#000000'; $width = 1.0
function Ink($s) {
    if ($s -match '^rgba\(([^,]+),([^,]+),([^,]+),([^\)]+)\)$') { return [Drawing.Color]::FromArgb([int](255*[double]$Matches[4]),[int]$Matches[1],[int]$Matches[2],[int]$Matches[3]) }
    if ($s.StartsWith('#') -and $s.Length -eq 9) { return [Drawing.Color]::FromArgb([Convert]::ToInt32($s.Substring(7,2),16),[Convert]::ToInt32($s.Substring(1,2),16),[Convert]::ToInt32($s.Substring(3,2),16),[Convert]::ToInt32($s.Substring(5,2),16)) }
    return [Drawing.ColorTranslator]::FromHtml($s)
}
$path = [Drawing.Drawing2D.GraphicsPath]::new(); $px=0.0; $py=0.0
foreach ($cmd in $ops) {
    $a=$cmd.a
    switch ($cmd.op) {
        'save' { $stack.Push(@($gfx.Save(),$fill,$stroke,$width)) }
        'restore' { $s=$stack.Pop(); $gfx.Restore($s[0]); $fill=$s[1]; $stroke=$s[2]; $width=$s[3] }
        'translate' { $gfx.TranslateTransform($a[0],$a[1]) }
        'scale' { $gfx.ScaleTransform($a[0],$a[1]) }
        'rotate' { $gfx.RotateTransform($a[0]*180/[Math]::PI) }
        'set' { switch ($a[0]) { 'fillStyle' {$fill=$a[1]} 'strokeStyle' {$stroke=$a[1]} 'lineWidth' {$width=$a[1]} } }
        'beginPath' { $path.Reset() }
        'rect' { $path.AddRectangle([Drawing.RectangleF]::new($a[0],$a[1],$a[2],$a[3])) }
        'clip' { $gfx.SetClip($path,[Drawing.Drawing2D.CombineMode]::Intersect) }
        'closePath' { $path.CloseFigure() }
        'moveTo' { $px=$a[0]; $py=$a[1] }
        'lineTo' { $path.AddLine([single]$px,[single]$py,[single]$a[0],[single]$a[1]); $px=$a[0]; $py=$a[1] }
        'arc' { $r=$a[2]; $path.AddEllipse([single]($a[0]-$r),[single]($a[1]-$r),[single](2*$r),[single](2*$r)) }
        'ellipse' { $path.AddEllipse([single]($a[0]-$a[2]),[single]($a[1]-$a[3]),[single](2*$a[2]),[single](2*$a[3])) }
        'roundRect' {
            $x=$a[0]; $y=$a[1]; $w=$a[2]; $h=$a[3]; $r=[Math]::Min($a[4],[Math]::Min($w,$h)/2); $d=2*$r
            $path.AddArc([single]$x,[single]$y,[single]$d,[single]$d,180,90)
            $path.AddArc([single]($x+$w-$d),[single]$y,[single]$d,[single]$d,270,90)
            $path.AddArc([single]($x+$w-$d),[single]($y+$h-$d),[single]$d,[single]$d,0,90)
            $path.AddArc([single]$x,[single]($y+$h-$d),[single]$d,[single]$d,90,90); $path.CloseFigure()
        }
        'fill' { $brush=[Drawing.SolidBrush]::new((Ink $fill)); $gfx.FillPath($brush,$path); $brush.Dispose() }
        'stroke' { $pen=[Drawing.Pen]::new((Ink $stroke),[single]$width); $gfx.DrawPath($pen,$path); $pen.Dispose() }
        'drawImage' {
            if (-not $images.ContainsKey($a[0])) { $images[$a[0]]=[Drawing.Bitmap]::new((Join-Path $root $a[0])) }
            $dest=[Drawing.RectangleF]::new($a[5],$a[6],$a[7],$a[8]); $src=[Drawing.RectangleF]::new($a[1],$a[2],$a[3],$a[4])
            $gfx.DrawImage($images[$a[0]],$dest,$src,[Drawing.GraphicsUnit]::Pixel)
        }
    }
}
$out.Save((Join-Path $root "build/$outputName"),[Drawing.Imaging.ImageFormat]::Png)
$path.Dispose(); $gfx.Dispose(); $out.Dispose(); foreach ($im in $images.Values) {$im.Dispose()}
Write-Output "Saved build/$outputName (offline replay, not an engine screenshot)."
