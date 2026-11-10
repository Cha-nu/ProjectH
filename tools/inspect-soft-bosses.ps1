# Read-only atlas registration: align generated sprites with the existing rig pivots.
param([string]$Variant = 'ink')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
public static class BossAtlasBounds {
    private static int Cut(Bitmap im, int wanted, int radius, int y0, int y1) {
        int best = wanted; double score = double.MaxValue;
        for (int x = Math.Max(1,wanted-radius); x < Math.Min(im.Width-1,wanted+radius); x++) {
            double n = Math.Abs(x-wanted)*.001;
            for (int y=y0;y<y1;y++) if(im.GetPixel(x,y).A>=64)n++;
            if(n<score){score=n;best=x;}
        }
        return best;
    }
    public static int[][] Read(string path, int columns = 4) {
        using (var im = new Bitmap(path)) {
            var result = new int[columns*2][];
            // Locate the empty row gutter, allowing for generation's uneven spacing.
            int mid = im.Height / 2, best = mid, score = int.MaxValue;
            for (int y = mid - im.Height/8; y < mid + im.Height/8; y++) {
                int n = 0; for (int x = 0; x < im.Width; x++) if (im.GetPixel(x,y).A > 32) n++;
                if (n < score) { score = n; best = y; }
            }
            for (int i = 0; i < result.Length; i++) {
                int col=i%columns, cw=im.Width/columns;
                int y0 = i < columns ? 0 : best, y1 = i < columns ? best : im.Height;
                int x0 = col==0 ? 0 : Cut(im,col*cw,cw/4,y0,y1);
                int x1 = col==columns-1 ? im.Width : Cut(im,(col+1)*cw,cw/4,y0,y1);
                int l = x1, t = y1, r = x0, b = y0;
                for (int y = y0; y < y1; y++) for (int x = x0; x < x1; x++) {
                    if (im.GetPixel(x,y).A < 64) continue;
                    l = Math.Min(l,x); t = Math.Min(t,y); r = Math.Max(r,x+1); b = Math.Max(b,y+1);
                }
                if (r <= l || b <= t) throw new Exception("Empty sprite: " + path);
                result[i] = new [] { l,t,r,b };
            }
            return result;
        }
    }
}
'@
$root = Split-Path $PSScriptRoot
$data = [ordered]@{}
foreach ($name in @('walker','cannon','ship','tank')) {
    $source = [BossAtlasBounds]::Read((Join-Path $root "assets/generated/bosses/${name}_${Variant}.png"))
    $original = [BossAtlasBounds]::Read((Join-Path $root "assets/generated/bosses/$name.png"))
    for ($i = 0; $i -lt 8; $i++) {
        $original[$i][0] -= ($i % 4) * 512; $original[$i][2] -= ($i % 4) * 512
        $original[$i][1] -= [Math]::Floor($i / 4) * 512; $original[$i][3] -= [Math]::Floor($i / 4) * 512
    }
    $original[1] = $original[0].Clone() # Damage must not change chassis registration.
    $data[$name] = @{source=$source; dest=$original}
}
$json = $data | ConvertTo-Json -Depth 8 -Compress
$driveBounds = [BossAtlasBounds]::Read((Join-Path $root 'assets/generated/bosses/drive_parts.png'),2)
$drive = ConvertTo-Json -InputObject $driveBounds -Depth 8 -Compress
foreach ($file in @('web/visuals.js','scripts/visual_motion.gd')) {
    $path = Join-Path $root $file; $body = [IO.File]::ReadAllText($path)
    $line = if ($file.EndsWith('.js')) { 'const SOFT_BOSSES=' + $json + ';' } else { 'const SOFT_BOSSES := ' + $json }
    $body = [regex]::Replace($body, '(?m)^const SOFT_BOSSES[^\r\n]*', $line)
    $driveLine = if ($file.EndsWith('.js')) { 'const DRIVE_ART=' + $drive + ';' } else { 'const DRIVE_ART := ' + $drive }
    $body = [regex]::Replace($body, '(?m)^const DRIVE_ART[^\r\n]*', $driveLine)
    [IO.File]::WriteAllText($path, $body, [Text.UTF8Encoding]::new($false))
}
Write-Output "Registered 32 $Variant boss sprites and 4 painted drive parts."
