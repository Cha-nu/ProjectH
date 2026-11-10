"""Re-fit an edited sprite sheet to the frame layout of its source sheet.
Image edits (e.g. Codex) sometimes redraw characters slightly bigger/lower so they cross cell borders.
Every opaque blob of the edited sheet is assigned to the cell holding its centre; each cell's group is then
scaled and moved so its bounding box matches the source frame's box (same height, bottom and centre x).
Usage: python tools/realign-sheet.py source.png edited.png cols rows out.png   (PIL only)"""
import sys
from collections import deque
from PIL import Image
src, edited, cols, rows, out = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
S = Image.open(src).convert('RGBA'); E = Image.open(edited).convert('RGBA'); W, H = S.size
cw, ch = W // cols, H // rows
A = E.getchannel('A').tobytes(); lab = [0] * (W * H); groups = {}
for i in range(W * H):
    if A[i] <= 20 or lab[i]: continue
    cid = i + 1; lab[i] = cid; q = deque([i]); xs = ys = 0; n = 0; x0 = y0 = 10**9; x1 = y1 = -1
    while q:
        p = q.popleft(); y, x = divmod(p, W); n += 1; xs += x; ys += y
        x0 = min(x0, x); x1 = max(x1, x); y0 = min(y0, y); y1 = max(y1, y)
        for k in (p - 1, p + 1, p - W, p + W, p - W - 1, p - W + 1, p + W - 1, p + W + 1):
            if 0 <= k < W * H and A[k] > 20 and not lab[k] and abs(k % W - x) <= 1:
                lab[k] = cid; q.append(k)
    cx, cy = xs / n, ys / n
    cell = (min(rows - 1, int(cy // ch)), min(cols - 1, int(cx // cw)))
    if n < 30: continue  # specks
    g = groups.setdefault(cell, [10**9, 10**9, -1, -1])
    g[0] = min(g[0], x0); g[1] = min(g[1], y0); g[2] = max(g[2], x1); g[3] = max(g[3], y1)
    groups.setdefault(('ids',) + cell, []).append(cid)
outim = Image.new('RGBA', (W, H), (0, 0, 0, 0))
SA = S.getchannel('A').point(lambda v: 255 if v > 40 else 0)
for r in range(rows):
    for c in range(cols):
        if (r, c) not in groups: continue
        sb = SA.crop((c * cw, r * ch, c * cw + cw, r * ch + ch)).getbbox()
        if not sb: continue
        gx0, gy0, gx1, gy1 = groups[(r, c)]
        ids = set(groups[('ids', r, c)])
        mask = Image.new('L', (gx1 - gx0 + 1, gy1 - gy0 + 1), 0); mp = mask.load()
        for y in range(gy0, gy1 + 1):
            row = y * W
            for x in range(gx0, gx1 + 1):
                if lab[row + x] in ids: mp[x - gx0, y - gy0] = 255
        piece = E.crop((gx0, gy0, gx1 + 1, gy1 + 1)); piece.putalpha(Image.composite(piece.getchannel('A'), Image.new('L', piece.size, 0), mask))
        k = (sb[3] - sb[1]) / (gy1 - gy0 + 1)
        piece = piece.resize((max(1, round(piece.width * k)), max(1, round(piece.height * k))), Image.LANCZOS)
        px = c * cw + (sb[0] + sb[2]) / 2 - piece.width / 2; py = r * ch + sb[3] - piece.height
        px = int(round(min(max(px, c * cw), c * cw + cw - piece.width))); py = int(round(max(py, r * ch)))
        cellimg = Image.new('RGBA', (cw, ch), (0, 0, 0, 0)); cellimg.alpha_composite(piece, (px - c * cw, py - r * ch))
        outim.alpha_composite(cellimg, (c * cw, r * ch))
outim.save(out); print(out, 'cells', len([g for g in groups if g[0] != 'ids']))
