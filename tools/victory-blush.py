"""Victory sheet face pass: the puffed left cheek of the original character art plus strong round blush.
Usage: python tools/victory-blush.py assets/generated/source/hero_victory_before_blush.png assets/generated/hero_victory.png [preview.png]
Always run on the untouched source sheet (running it twice paints twice)."""
import sys
from PIL import Image, ImageDraw, ImageFilter
src, dst = sys.argv[1], sys.argv[2]
prev = sys.argv[3] if len(sys.argv) > 3 else None
im = Image.open(src).convert('RGBA'); cw, ch = im.width // 4, im.height // 2
# cheek centres (cell px): left, right
C = [((146,134),(213,132)),((142,116),(203,113)),((143,115),(222,112)),((150,152),(225,150)),
     ((137,121),(207,118)),((136,119),(205,117)),((146,112),(212,110)),((150,121),(215,118))]
# frames whose art lacks the puffed cheek: frame -> (face edge x, cheek y)
PUFF = {1: (128, 116), 6: (136, 112)}  # 2, 4, 5: the raised hand already covers that cheek
SS = 4
for i, (ex, ey) in PUFF.items():
    ox, oy = (i % 4) * cw, (i // 4) * ch
    line = im.getpixel((ox + ex, oy + ey))[:3]
    skin = (255, 244, 238)
    cx, cy, rx, ry, ow = ex - 3, ey + 2, 9.5, 10.5, 3.2
    box = (ox + int(cx - 20), oy + int(cy - 20), ox + int(cx + 20), oy + int(cy + 20))
    w, h = box[2] - box[0], box[3] - box[1]
    lay = Image.new('RGBA', (w * SS, h * SS), (0, 0, 0, 0)); d = ImageDraw.Draw(lay)
    lx, ly = (ox + cx - box[0]) * SS, (oy + cy - box[1]) * SS
    ring = Image.new('RGBA', lay.size, (0, 0, 0, 0)); dr = ImageDraw.Draw(ring)
    dr.ellipse([lx - (rx + ow) * SS, ly - (ry + ow) * SS, lx + (rx + ow) * SS, ly + (ry + ow) * SS], fill=line + (255,))
    clip = Image.new('L', lay.size, 0); ImageDraw.Draw(clip).rectangle([0, 0, (ox + ex + 1 - box[0]) * SS, lay.height], fill=255)
    lay.paste(ring, (0, 0), Image.composite(ring, Image.new('RGBA', lay.size), clip).getchannel('A'))
    d.ellipse([lx - rx * SS, ly - ry * SS, lx + rx * SS, ly + ry * SS], fill=skin + (255,))
    lay = lay.resize((w, h), Image.LANCZOS)
    patch = im.crop(box); patch.alpha_composite(lay); im.paste(patch, box)
    C[i] = ((ex + 3, C[i][0][1] + 1), C[i][1])
RX, RY = 17, 10.5
blush = Image.new('L', im.size, 0); d = ImageDraw.Draw(blush)
for i, (l, r) in enumerate(C):
    ox, oy = (i % 4) * cw, (i // 4) * ch
    for (x, y) in (l, r): d.ellipse([ox + x - RX, oy + y - RY, ox + x + RX, oy + y + RY], fill=255)
blush = blush.filter(ImageFilter.GaussianBlur(1.4))
px = im.load(); bp = blush.load(); tgt = (240, 122, 140)
for y in range(im.height):
    for x in range(im.width):
        a = bp[x, y]
        if not a: continue
        r, g, b, al = px[x, y]; lum = (r + g + b) / 3
        if al < 200 or lum < 150: continue
        k = a / 255 * 0.92 * min(1, (lum - 150) / 60)
        px[x, y] = (int(r + (tgt[0] - r) * k), int(g + (tgt[1] - g) * k), int(b + (tgt[2] - b) * k), al)
im.save(dst)
if prev:
    pv = Image.new('RGBA', (1200, 600), (255, 255, 255, 255))
    for i in range(8):
        x0, y0 = (i % 4) * cw, (i // 4) * ch
        c = im.crop((x0 + 60, y0 + 50, x0 + 260, y0 + 200)).resize((300, 225))
        pv.paste(c, ((i % 4) * 300, (i // 4) * 300), c)
    pv.save(prev)
