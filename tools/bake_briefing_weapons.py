"""Bake the mission briefing poses: one per stage, the hero holding that stage's signature gun.
Cell 4: Glock (story_churros cell 7 as drawn), 5: M4, 6: AKM, 7: AWM (the Kar98k sprite re-stocked in olive with a scope).
The long guns are swapped into story_churros cell 6 (low ready): the Glock is erased, the rifle drawn with its grip in
the hand, and the hand redrawn on top. Writes a 4x2 sheet (cells 0-3 empty) so render code can keep using cell().
Usage: python tools/bake_briefing_weapons.py . assets/generated/story_briefing.png"""
import sys, colorsys
from PIL import Image, ImageDraw

ROOT = sys.argv[1]; OUT = sys.argv[2]
C = 295; SC = 4  # cell size; work at 4x for smoother rotation, then shrink back
sheet = Image.open(ROOT + '/assets/generated/story_churros.png').convert('RGBA')
weapons = Image.open(ROOT + '/assets/characters/weapons_clean.png').convert('RGBA')

def gray(p):
    r, g, b, a = p
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    return a > 0 and s < .22 and v < .62

def awm():
    """Kar98k sprite with an olive stock and a scope on top."""
    gun = weapons.crop((547, 327, 1075, 470)); pad = 44
    out = Image.new('RGBA', (gun.width, gun.height + pad)); out.alpha_composite(gun, (0, pad))
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if not a: continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if .02 < h < .13 and s > .35:  # wood -> olive drab
                r2, g2, b2 = colorsys.hsv_to_rgb(.19, s * .55, v * .78); px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
    d = ImageDraw.Draw(out); ink = (34, 24, 28, 255); body = (52, 52, 58, 255); lite = (110, 110, 120, 255)
    top = pad + 14  # receiver top line
    for mx in (180, 252): d.rectangle((mx - 7, top - 12, mx + 7, top + 4), fill=body, outline=ink, width=4)
    d.rounded_rectangle((146, top - 30, 300, top - 10), 9, fill=body, outline=ink, width=4)
    d.rounded_rectangle((282, top - 36, 322, top - 4), 8, fill=body, outline=ink, width=4)   # objective bell
    d.rounded_rectangle((128, top - 34, 156, top - 6), 7, fill=body, outline=ink, width=4)   # eyepiece
    d.rounded_rectangle((206, top - 38, 226, top - 28), 3, fill=body, outline=ink, width=3)  # turret
    d.line((158, top - 24, 278, top - 24), fill=lite, width=3)
    return out, (142, pad + 72)

# (image, grip point in that image's px, drawn width in cell px)
GUNS = {
    5: (Image.open(ROOT + '/assets/characters/m4_black.png').convert('RGBA'), (585, 560), 210),
    6: (weapons.crop((15, 287, 534, 502)), (150, 120), 196),
    7: (*awm(), 222),
}

JACKET = (232, 212, 182, 255)

def pose(gun, grip, gw, ang=-22):
    cell = sheet.crop((2 * C, C, 3 * C, 2 * C)).resize((C * SC, C * SC), Image.LANCZOS); px = cell.load()
    gx0, gy0, gx1, gy1 = [v * SC for v in (138, 143, 190, 197)]  # erase the Glock
    for y in range(C * SC):  # the source cell's edges catch slivers of the neighbouring pose
        for x in [*range(10 * SC), *range((C - 6) * SC, C * SC)]: px[x, y] = (0, 0, 0, 0)
    holes = [(x, y) for y in range(gy0, gy1) for x in range(gx0, gx1) if gray(px[x, y])]
    for q in holes: px[q] = (0, 0, 0, 0)
    hx0, hy0, hx1, hy1 = [v * SC for v in (124, 158, 152, 188)]
    hand = cell.crop((hx0, hy0, hx1, hy1))
    for q in holes: px[q] = JACKET  # what the gun doesn't cover reads as blazer, not a hole
    k = gw * SC / gun.width; g = gun.resize((round(gun.width * k), round(gun.height * k)), Image.LANCZOS); gp = (grip[0] * k, grip[1] * k)
    pad = g.width; canvas = Image.new('RGBA', (g.width + 2 * pad, g.height + 2 * pad)); canvas.alpha_composite(g, (pad, pad))
    rot = canvas.rotate(ang, resample=Image.BICUBIC, center=(pad + gp[0], pad + gp[1]))
    HAND = (141 * SC, 176 * SC)
    layer = Image.new('RGBA', cell.size); layer.paste(rot, (round(HAND[0] - pad - gp[0]), round(HAND[1] - pad - gp[1])), rot)
    out = Image.new('RGBA', cell.size); out.alpha_composite(cell); out.alpha_composite(layer); out.alpha_composite(hand, (hx0, hy0))
    return out.resize((C, C), Image.LANCZOS)

res = Image.new('RGBA', (4 * C, 2 * C))
res.paste(sheet.crop((3 * C, C, 4 * C, 2 * C)), (0, C))  # cell 4: the original Glock pose
for i, (gun, grip, gw) in GUNS.items(): res.paste(pose(gun, grip, gw), ((i - 4) * C, C))
res.save(OUT, optimize=True)
