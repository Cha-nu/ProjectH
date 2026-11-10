"""Remove pieces of neighbouring frames that bleed into a sprite-sheet cell.
In each cell the largest opaque blob is the character; any other blob that touches the cell border is a
sliver of the next/previous frame and is erased. Small blobs fully inside the cell (sparkles, sweat) are kept.
Usage: python tools/clean-sheet-cells.py sheet.png cols rows [out.png]   (PIL only)"""
import sys
from collections import deque
from PIL import Image
path, cols, rows = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
out = sys.argv[4] if len(sys.argv) > 4 else path
im = Image.open(path).convert('RGBA'); W, H = im.size; cw, ch = W // cols, H // rows
alpha = im.getchannel('A'); removed = 0
for r in range(rows):
    for c in range(cols):
        box = (c * cw, r * ch, c * cw + cw, r * ch + ch)
        A = alpha.crop(box).tobytes(); n = cw * ch
        lab = [0] * n; comps = []
        for i in range(n):
            if A[i] <= 12 or lab[i]: continue
            cid = len(comps) + 1; lab[i] = cid; q = deque([i]); members = []; touches = False
            while q:
                p = q.popleft(); members.append(p); y, x = divmod(p, cw)
                if y == 0 or x == 0 or y == ch - 1 or x == cw - 1: touches = True
                for dy in (-1, 0, 1):
                    yy = y + dy
                    if yy < 0 or yy >= ch: continue
                    for dx in (-1, 0, 1):
                        xx = x + dx
                        if 0 <= xx < cw:
                            k = yy * cw + xx
                            if A[k] > 12 and not lab[k]: lab[k] = cid; q.append(k)
            comps.append((members, touches))
        if len(comps) < 2: continue
        main = max(range(len(comps)), key=lambda k: len(comps[k][0]))
        cell = alpha.crop(box); px = cell.load()
        for k, (members, touches) in enumerate(comps):
            if k == main or not touches: continue
            for p in members:
                y, x = divmod(p, cw); px[x, y] = 0
            removed += len(members)
        alpha.paste(cell, box)
im.putalpha(alpha); im.save(out)
print(path, 'removed px', removed)
