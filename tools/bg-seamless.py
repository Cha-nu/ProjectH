"""Bake assets/generated/backgrounds_wrap.png: each stage panel of assets/backgrounds.png made horizontally tileable.

The panel's right end is overlapped onto its left start and the two are joined along a minimum-error vertical cut
(image quilting), so the scenery repeats without a mirror seam. Each cell gets a PAD-pixel gutter of wrapped / edge
pixels so bilinear sampling never bleeds a neighbouring panel. Prints the tile widths for BG_WRAP in main.gd/render.js.
"""
import numpy as np
from PIL import Image

PAD = 4
FEATHER = 3
# Overlap search range per stage: wide overlaps line up repeating art (town, factory, harbor); the castle's
# towers get sliced by long overlaps, so it keeps a short one.
OVERLAP = {0: (100, 520), 1: (100, 520), 2: (100, 520), 3: (100, 300)}
CROP = .7  # only the visible top of the panel drives the cut choice (the rest is flat ground)

src = np.asarray(Image.open("assets/backgrounds.png").convert("RGB")).astype(np.float32)
H, W = src.shape[:2]
cw, ch = W // 2, H // 2


def min_cut(err):
    """Vertical path (one column per row) through err with the least total cost."""
    h, w = err.shape
    cost = err.copy()
    for y in range(1, h):
        prev = cost[y - 1]
        left = np.r_[np.inf, prev[:-1]]
        right = np.r_[prev[1:], np.inf]
        cost[y] += np.minimum(np.minimum(left, prev), right)
    path = np.zeros(h, int)
    path[-1] = int(np.argmin(cost[-1]))
    for y in range(h - 2, -1, -1):
        x = path[y + 1]
        lo, hi = max(0, x - 1), min(w, x + 2)
        path[y] = lo + int(np.argmin(cost[y, lo:hi]))
    return path, float(cost[-1].min()) / h


def seamless(p, lo, hi):
    rows = int(ch * CROP)
    best = None
    for o in range(lo, hi + 1, 10):
        a, b = p[:, cw - o:], p[:, :o]
        err = ((a - b) ** 2).sum(2)
        # keep the cut away from the overlap edges so the feather has room
        err[:, :FEATHER + 2] += 1e7; err[:, -FEATHER - 2:] += 1e7
        path, score = min_cut(err[:rows])
        if best is None or score < best[0]: best = (score, o, path)
    score, o, path = best
    a, b = p[:, cw - o:], p[:, :o]
    path = np.r_[path, np.full(ch - len(path), path[-1])]
    xs = np.arange(o)[None, :]
    t = np.clip((xs - path[:, None] + FEATHER) / (2 * FEATHER), 0, 1)[..., None]  # 0 = A (wraps from tile end), 1 = B
    head = a * (1 - t) + b * t
    tile = np.concatenate([head, p[:, o:cw - o]], 1)
    return tile, o, score


tiles = []
for s in range(4):
    p = src[(s // 2) * ch:(s // 2 + 1) * ch, (s % 2) * cw:(s % 2 + 1) * cw]
    tile, o, score = seamless(p, *OVERLAP[s])
    tiles.append(tile)
    print(f"stage {s}: overlap {o}px, cut error {score:.0f}, tile width {tile.shape[1]}")

cellW = max(t.shape[1] for t in tiles) + 2 * PAD
cellH = ch + 2 * PAD
out = np.zeros((cellH * 2, cellW * 2, 3), np.float32)
for s, t in enumerate(tiles):
    n = t.shape[1]
    wrapped = np.concatenate([t[:, n - PAD:], t, t[:, :PAD]], 1)
    wrapped = np.concatenate([np.repeat(wrapped[:1], PAD, 0), wrapped, np.repeat(wrapped[-1:], PAD, 0)], 0)
    ox, oy = (s % 2) * cellW, (s // 2) * cellH
    out[oy:oy + cellH, ox:ox + wrapped.shape[1]] = wrapped
Image.fromarray(out.round().clip(0, 255).astype(np.uint8)).save("assets/generated/backgrounds_wrap.png")
print("cell", cellW, cellH, "pad", PAD, "widths", [t.shape[1] for t in tiles], "height", ch)
