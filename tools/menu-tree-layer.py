"""Cut the tree trunk out of the title background so a gwamegi can hide behind it.
Usage: python tools/menu-tree-layer.py assets/generated/menu_bg_clean.png assets/generated/menu_tree_front.png [y0 y1 xmin xmax]
The layer keeps the background's RGB everywhere (alpha only marks the trunk) so mipmaps never darken its edge.
The mask follows the bark (closed solid, so the trunk never has see-through holes) and starts inside the trunk's dark
left outline, so the peeking gwamegi slides over that outline instead of being cut by it."""
import sys, statistics, colorsys
from PIL import Image, ImageDraw, ImageFilter, ImageChops
src, dst = sys.argv[1], sys.argv[2]
y0, y1, xmin, xmax = (int(v) for v in sys.argv[3:7]) if len(sys.argv) > 6 else (450, 706, 1360, 1580)
im = Image.open(src).convert('RGBA'); px = im.load()
def trunkish(p):
    r, g, b, _ = p
    return r > 110 and 45 < g < 205 and b < 150 and r - g > 35  # includes sunlit dapples
edges = {}
for y in range(y0 - 10, y1 + 8):
    for x in range(xmin, xmax):
        if all(trunkish(px[x + k, y]) for k in range(0, 12, 3)):
            edges[y] = x; break
mask = Image.new('L', im.size, 0); d = ImageDraw.Draw(mask)
for y in edges:
    if y0 <= y <= y1:
        x = statistics.median([edges[k] for k in range(y - 7, y + 8) if k in edges])
        d.line([(x + 6, y), (im.width, y)], fill=int(255 * min(1, (y - y0) / 30)))
def bark(p):
    r, g, b, _ = p
    h, sat, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    return 10 / 360 < h < 37 / 360 and sat > .3 and v > .38  # warm brown bark incl. shadows; excludes outline, grass, yellow/pink petals
bm = Image.new('L', im.size, 0); bp = bm.load()
for y in range(y0 - 10, min(im.height, y1 + 8)):
    for x in range(xmin - 20, im.width):
        if bark(px[x, y]): bp[x, y] = 255
bm = bm.filter(ImageFilter.MaxFilter(25)).filter(ImageFilter.MinFilter(25)).filter(ImageFilter.MinFilter(3))  # close every hole (dapples, flowers on the bark) so nothing behind shows through, then pull in off the outline
mask = ImageChops.multiply(mask, bm)
mask = mask.filter(ImageFilter.GaussianBlur(.8))
out = im.copy(); out.putalpha(mask); out.save(dst)
print('trunk rows', len(edges), 'edge x range', min(edges.values()) if edges else None, max(edges.values()) if edges else None)
