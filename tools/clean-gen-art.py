"""Clean up image-generator artefacts on transparent sprites ("자글거림"):
- near-opaque interiors (alpha 240-254) become fully opaque, faint haze (alpha <= 10) around shapes is cleared;
- colour speckle/grain is smoothed with an edge-preserving median filter (outlines stay crisp);
- the soft alpha edge is kept so silhouettes stay anti-aliased.
Usage: python tools/clean-gen-art.py in.png [out.png] [--strength 3|5] [--alpha-only]   (PIL only)"""
import sys
from PIL import Image, ImageFilter
args = [a for a in sys.argv[1:] if not a.startswith('--')]
src = args[0]; dst = args[1] if len(args) > 1 else src
ALPHA_ONLY = "--alpha-only" in sys.argv
k = 5 if '--strength' in sys.argv and sys.argv[sys.argv.index('--strength') + 1] == '5' else 3
im = Image.open(src).convert('RGBA')
r, g, b, a = im.split()
a = a.point(lambda v: 0 if v <= 10 else (255 if v >= 240 else v))
rgb = Image.merge("RGB", (r, g, b)) if ALPHA_ONLY else Image.merge("RGB", (r, g, b)).filter(ImageFilter.MedianFilter(k))
# keep original colour on the anti-aliased rim so the outline does not bleed into transparency
rim = a.point(lambda v: 255 if 0 < v < 255 else 0)
rgb = Image.composite(Image.merge('RGB', (r, g, b)), rgb, rim)
out = Image.merge('RGBA', (*rgb.split(), a)); out.save(dst)
h = a.histogram(); print(dst, 'opaque', h[255], 'semi', sum(h[1:255]))
