"""Cut the hero's fists out of the rifle body sheets into matching "hands" sheets.
The renderer draws body -> gun -> hands, so the gun sits inside her own drawn fists instead of being pasted over them.
Fists are the small skin-coloured blobs in front of the torso (the face, ear and legs are excluded by size and position);
each blob is grown a few px to take its ink outline along.
Usage: python tools/bake_hands.py .   (writes assets/generated/hero_body_hands.png and hero_run_hands.png)"""
import sys
from collections import deque
from PIL import Image, ImageFilter

ROOT = sys.argv[1]
SHEETS = [('assets/characters/hero_body_sheet.png', 'assets/generated/hero_body_hands.png', 4, 2),
          ('assets/generated/hero_run.png', 'assets/generated/hero_run_hands.png', 4, 2)]

def skin(p):
    r, g, b, a = p
    return a > 200 and r > 225 and g > 195 and b > 180 and r - b < 70 and r - g < 45

def blobs(px, x0, y0, w, h):
    seen = set(); out = []
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            if (x, y) in seen or not skin(px[x, y]): continue
            q = deque([(x, y)]); seen.add((x, y)); pts = []
            while q:
                cx, cy = q.popleft(); pts.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if x0 <= nx < x0 + w and y0 <= ny < y0 + h and (nx, ny) not in seen and skin(px[nx, ny]):
                        seen.add((nx, ny)); q.append((nx, ny))
            out.append(pts)
    return out

for src, dst, cols, rows in SHEETS:
    im = Image.open(ROOT + '/' + src).convert('RGBA'); px = im.load()
    W, H = im.width // cols, im.height // rows
    mask = Image.new('L', im.size, 0); mp = mask.load()
    for f in range(cols * rows):
        x0, y0 = (f % cols) * W, (f // cols) * H
        bl = blobs(px, x0, y0, W, H)
        face = max(bl, key=len)
        fy = max(y for _, y in face)  # chin line
        fx = sum(x for x, _ in face) / len(face)
        keep = []
        for pts in bl:
            n = len(pts); cx = sum(x for x, _ in pts) / n; cy = sum(y for _, y in pts) / n
            # fists: modest blobs, below the chin, in front of the face's centre, above the skirt
            if 40 < n < W * H * .02 and cy > fy - H * .04 and cy < y0 + H * .66 and cx > fx - W * .05:
                keep.append(pts)
        keep = sorted(keep, key=len, reverse=True)[:2]  # the two fists; smaller hits are shirt/collar highlights
        print(src.split('/')[-1], f, 'fists', [(round(sum(x for x, _ in p) / len(p) - x0), round(sum(y for _, y in p) / len(p) - y0), len(p)) for p in keep])
        for pts in keep:
            for x, y in pts: mp[x, y] = 255
    grown = mask.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(1.2))
    out = Image.new('RGBA', im.size); out.paste(im, (0, 0), grown)
    out.save(ROOT + '/' + dst, optimize=True)
