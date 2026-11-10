# Offline raster QA of the original generated pixels and measured frame crops.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot
$bounds = Get-Content (Join-Path $root 'build/motion-bounds.json') -Raw | ConvertFrom-Json
$out = [System.Drawing.Bitmap]::new(1536, 1024)
$g = [System.Drawing.Graphics]::FromImage($out)
$g.Clear([System.Drawing.Color]::FromArgb(255, 246, 239))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = [System.Drawing.Font]::new('Arial', 11)
$ink = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(70, 45, 40))
$names = @('walker', 'cannon', 'ship', 'tank')
$themes = @('town', 'factory', 'harbor', 'fortress')
$frames = @(0, 1, 2, 3, 4, 7)
$labels = @('IDLE', 'MOVE', 'WINDUP', 'RECOIL', 'SPECIAL', 'WRECK')
for ($row = 0; $row -lt 4; $row++) {
    $im = [System.Drawing.Bitmap]::new((Join-Path $root "assets/generated/bosses/$($names[$row])_stable.png"))
    $bg = [System.Drawing.Bitmap]::new((Join-Path $root "assets/generated/zones_$($themes[$row]).png"))
    $ref = $bounds.($names[$row])[0]
    $scale = 194.0 / [Math]::Max($ref[2] - $ref[0], $ref[3] - $ref[1])
    for ($col = 0; $col -lt 6; $col++) {
        $x = $col * 256; $y = $row * 256
        $dest = [System.Drawing.RectangleF]::new($x, $y, 256, 256)
        $src = [System.Drawing.RectangleF]::new($bg.Width / 2 + 4, $bg.Height * 2 / 3 + 4, $bg.Width / 2 - 8, $bg.Height / 3 - 8)
        $g.DrawImage($bg, $dest, $src, [System.Drawing.GraphicsUnit]::Pixel)
        $a = $bounds.($names[$row])[$frames[$col]]
        $w = ($ref[2] - $ref[0]) * $scale; $h = ($ref[3] - $ref[1]) * $scale * $(if ($frames[$col] -eq 7) { .68 } else { 1.0 })
        $dest = [System.Drawing.RectangleF]::new(($x + 128 - $w / 2), ($y + 238 - $h), $w, $h)
        $src = [System.Drawing.RectangleF]::new($a[0], $a[1], ($a[2] - $a[0]), ($a[3] - $a[1]))
        $g.DrawImage($im, $dest, $src, [System.Drawing.GraphicsUnit]::Pixel)
        $g.FillRectangle([System.Drawing.Brushes]::WhiteSmoke, $x, $y, 256, 26)
        $g.DrawString("$($names[$row]) / $($labels[$col])", $font, $ink, ($x + 8), ($y + 4))
    }
    $im.Dispose(); $bg.Dispose()
}
$out.Save((Join-Path $root 'build/motion-asset-review.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $out.Dispose()
$out = [System.Drawing.Bitmap]::new(1280, 960)
$g = [System.Drawing.Graphics]::FromImage($out)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$portal = [System.Drawing.Bitmap]::new((Join-Path $root 'assets/generated/zone_portals.png'))
for ($i = 0; $i -lt 4; $i++) {
    $x = ($i % 2) * 640; $y = [Math]::Floor($i / 2) * 480
    $bg = [System.Drawing.Bitmap]::new((Join-Path $root "assets/generated/zones_$($themes[$i]).png"))
    $g.DrawImage($bg, [System.Drawing.RectangleF]::new($x, $y, 640, 480), [System.Drawing.RectangleF]::new(($bg.Width / 2 + 4), 4, ($bg.Width / 2 - 8), ($bg.Height / 3 - 8)), [System.Drawing.GraphicsUnit]::Pixel)
    $a = $bounds.portals[$i]
    $g.DrawImage($portal, [System.Drawing.RectangleF]::new(($x + 140), ($y + 70), 360, 390), [System.Drawing.RectangleF]::new($a[0], $a[1], ($a[2] - $a[0]), ($a[3] - $a[1])), [System.Drawing.GraphicsUnit]::Pixel)
    $g.FillRectangle([System.Drawing.Brushes]::WhiteSmoke, $x, $y, 640, 26)
    $g.DrawString("$($themes[$i]) / ENTRANCE ASSET", $font, $ink, ($x + 8), ($y + 4))
    $bg.Dispose()
}
$out.Save((Join-Path $root 'build/entrance-asset-review.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $out.Dispose(); $portal.Dispose(); $font.Dispose(); $ink.Dispose()
Write-Output 'Saved build/motion-asset-review.png'
