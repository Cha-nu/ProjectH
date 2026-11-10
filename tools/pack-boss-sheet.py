"""Register a regenerated boss parts sheet (4 columns x 2 rows, any size) with the game's boss rig tables.

Frames: 0 body, 1 damaged body, 2 weapon A, 3 A broken, 4 weapon B, 5 B broken, 6 hatch, 7 debris.
For each frame the source rect is the alpha bounds inside its cell. Damaged/broken frames reuse the size of their intact
frame (aligned to the main silhouette's bottom-centre) so swapping frames does not jump; extra smoke or fragments
outside that box are cropped. The dest rect (512-unit rig space) keeps the old dest box: the new art is fitted inside
it (bodies bottom-aligned so they stand on the same floor, parts centred), so hitboxes and attach points stay put.

Usage: python tools/pack-boss-sheet.py <sheet-name> [...]   e.g. walker tank ship
Rewrites the SOFT_BOSSES entries of those sheets in web/visuals.js and scripts/visual_motion.gd.
(BOUNDS there measures the legacy *_stable.png sheets and is left alone.)
"""
import json, re, sys
import numpy as np
from PIL import Image

ALPHA = 24


def bbox(mask):
    ys, xs = np.nonzero(mask)
    return [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]


def main_bbox(mask):
    """Bounds of the largest connected blob (ignores loose fragments and smoke puffs)."""
    from collections import deque
    h, w = mask.shape
    seen = np.zeros_like(mask, bool); best = None
    for y0, x0 in zip(*np.nonzero(mask[::4, ::4])):
        y0 *= 4; x0 *= 4
        if seen[y0, x0]: continue
        q = deque([(y0, x0)]); seen[y0, x0] = True; pts = []
        while q:
            y, x = q.popleft(); pts.append((y, x))
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = y + dy, x + dx
                if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True; q.append((ny, nx))
        if best is None or len(pts) > len(best): best = pts
    ys = [p[0] for p in best]; xs = [p[1] for p in best]
    return [min(xs), min(ys), max(xs) + 1, max(ys) + 1]


def fit(src, box, bottom):
    sw, sh = src[2] - src[0], src[3] - src[1]
    bw, bh = box[2] - box[0], box[3] - box[1]
    s = min(bw / sw, bh / sh); w, h = sw * s, sh * s
    x0 = (box[0] + box[2]) / 2 - w / 2
    y0 = box[3] - h if bottom else (box[1] + box[3]) / 2 - h / 2
    return [round(x0), round(y0), round(x0 + w), round(y0 + h)]


def pack(name, old_dest):
    im = np.asarray(Image.open(f"assets/generated/bosses/{name}_ink.png").convert("RGBA"))
    H, W = im.shape[:2]; cw, ch = W // 4, H // 2
    src, main = [], []
    for f in range(8):
        cx, cy = (f % 4) * cw, (f // 4) * ch
        m = im[cy:cy + ch, cx:cx + cw, 3] > ALPHA
        b, mb = bbox(m), main_bbox(m)
        src.append([b[0] + cx, b[1] + cy, b[2] + cx, b[3] + cy]); main.append([mb[0] + cx, mb[1] + cy, mb[2] + cx, mb[3] + cy])
    for broken, intact in ((1, 0), (3, 2), (5, 4)):
        w, h = src[intact][2] - src[intact][0], src[intact][3] - src[intact][1]
        m = main[broken]; mx = (m[0] + m[2]) // 2
        src[broken] = [int(v) for v in (mx - w // 2, m[3] - h, mx - w // 2 + w, m[3])]
    dest = [fit(src[f], old_dest[f], f in (0, 1)) for f in range(8)]
    dest[1] = dest[0]
    return {"dest": dest, "source": src}


def rewrite(path, const, sep, names, tables):
    text = open(path, encoding="utf-8").read()
    m = re.search(rf"const {const}\s*{sep}\s*(\{{.*?\}});?\n", text)
    data = json.loads(m.group(1))
    for n in names: data[n] = tables[n]
    text = text[:m.start(1)] + json.dumps(data, separators=(",", ":")) + text[m.end(1):]
    open(path, "w", encoding="utf-8", newline="\n").write(text)


names = sys.argv[1:]
js = open("web/visuals.js", encoding="utf-8").read()
soft = json.loads(re.search(r"const SOFT_BOSSES=(\{.*?\});\n", js).group(1))
soft_new = {}
for n in names:
    soft_new[n] = pack(n, soft[n]["dest"])
    print(n, "dest", soft_new[n]["dest"])
    print(n, "source", soft_new[n]["source"])
rewrite("web/visuals.js", "SOFT_BOSSES", "=", names, soft_new)
rewrite("scripts/visual_motion.gd", "SOFT_BOSSES", ":=", names, soft_new)
