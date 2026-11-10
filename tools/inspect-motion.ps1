# Read-only pixel inspection; does not alter the generated sprite atlases.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
public static class MotionBounds {
    private static int Cut(Bitmap im, bool horizontal, int wanted, int radius, int lo, int hi) {
        int best = wanted; double score = double.MaxValue;
        int limit = horizontal ? im.Height : im.Width;
        for (int at = Math.Max(1, wanted - radius); at < Math.Min(limit - 1, wanted + radius); at++) {
            double n = Math.Abs(at - wanted) * .001;
            for (int v = lo; v < hi; v++) {
                var p = horizontal ? im.GetPixel(v, at) : im.GetPixel(at, v);
                if (p.A >= 32) n++;
            }
            if (n < score) { score = n; best = at; }
        }
        return best;
    }
    public static int[][] Read(string path, int columns, int countRows) {
        using (var im = new Bitmap(path)) {
            int cw = im.Width / columns, ch = im.Height / countRows;
            var frames = new int[columns * countRows][];
            var rows = new int[countRows + 1]; rows[countRows] = im.Height;
            for (int y = 1; y < countRows; y++) rows[y] = Cut(im, true, y * ch, ch / 4, 0, im.Width);
            for (int f = 0; f < frames.Length; f++) {
                int row = f / columns, col = f % columns;
                int ox = col == 0 ? 0 : Cut(im, false, col * cw, cw / 6, rows[row], rows[row + 1]);
                int ex = col == columns - 1 ? im.Width : Cut(im, false, (col + 1) * cw, cw / 6, rows[row], rows[row + 1]);
                int left = im.Width, top = im.Height, right = 0, bottom = 0, clear = 0;
                for (int y = rows[row]; y < rows[row + 1]; y++) for (int x = ox; x < ex; x++) {
                    var pixel = im.GetPixel(x, y);
                    if (pixel.A < 8) clear++;
                    if (pixel.A < 64) continue;
                    left = Math.Min(left, x); top = Math.Min(top, y);
                    right = Math.Max(right, x + 1); bottom = Math.Max(bottom, y + 1);
                }
                if (clear < cw * ch / 10 || right <= left) throw new Exception("Invalid alpha/frame: " + path + " cell " + f);
                frames[f] = new [] {left, top, right, bottom};
            }
            return frames;
        }
    }
}
'@
$data = [ordered]@{}
foreach ($name in @('walker', 'cannon', 'ship', 'tank')) {
    $path = Join-Path $PSScriptRoot "../assets/generated/bosses/${name}_stable.png"
    $data[$name] = [MotionBounds]::Read($path, 4, 2)
}
$data['portals'] = [MotionBounds]::Read((Join-Path $PSScriptRoot '../assets/generated/zone_portals.png'), 2, 2)
$json = $data | ConvertTo-Json -Depth 5 -Compress
[System.IO.File]::WriteAllText((Join-Path $PSScriptRoot '../build/motion-bounds.json'), $json, [System.Text.UTF8Encoding]::new($false))
foreach ($file in @('../web/visuals.js', '../scripts/visual_motion.gd')) {
    $path = Join-Path $PSScriptRoot $file
    $text = [System.IO.File]::ReadAllText($path)
    $line = if ($file.EndsWith('.js')) { 'const BOUNDS=' + $json + ';' } else { 'const BOUNDS := ' + $json }
    $text = [regex]::Replace($text, '(?m)^const BOUNDS[^\r\n]*', $line)
    [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))
}
Write-Output 'PASS: 32 boss poses and 4 portals with real transparency; source rectangles synchronized in both runtimes'
