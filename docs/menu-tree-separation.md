# Menu tree separation — 2026-11-10

Generated with the built-in image_gen tool, using assets/generated/menu_bg_clean.png as reference for both images.

## Saved assets
- assets/generated/menu_bg_meadow.png — tree-free background plate
- assets/generated/menu_tree_whole.png — complete foreground tree with generated transparency preserved

Both web/render.js and scripts/main.gd render background, peeking character, whole tree, then heroine. Character x moves from 1028 (peek) to 1170 (hidden), at size 200. Previous partial trunk mask is no longer referenced by either runtime.

## Background prompt
Use case: precise-object-edit. Edit target: supplied game menu background. Produce a 16:9 full landscape background plate. Remove the entire large foreground tree on the right, including ALL its trunk, roots, branches, overhead canopy and its cast shadow. Reconstruct the revealed area with continuous blue sky, distant hills, distant slim trees and shrubs, sunny grassy meadow and small flowers matching the existing scene. Preserve the composition, lake, little golden domed village, foreground flowers, bright colors and clean outlined hand-painted cartoon game style. No foreground trees anywhere, no characters, no text, no UI. This will be the back plate behind a separately rendered foreground tree.

## Tree prompt
Use case: background-extraction. Reference: supplied cartoon game background for exact tree style and placement. Generate ONLY its large right foreground tree as a complete separate RGBA layer on truly transparent background. Wide 16:9 canvas, keep tree at original layout: broad green leafy canopy across upper right from x38% to right edge, thick solid golden brown trunk along right edge with left silhouette near x90% at middle height, roots flaring left to x77% near y76%, trunk joins right edge, foliage and branches clipped at top and right canvas edges like original. Entire trunk and entire canopy fully opaque, with clean dark outer contour and smooth continuous left trunk silhouette. Root base around 79% canvas height, lower remainder transparent. Regenerate the whole tree as one coherent foreground object, no holes or translucent bark. Warm sunlight dapples, playful outlined hand painted cartoon style matches reference. No ground, no flowers, no grass, no sky, no hills, no village, no characters, no text, no shadow backdrop. Everywhere outside the tree must be genuinely transparent. This tree will occlude a character moving behind its left edge.

## Verification
- node tools/test-render.cjs: PASS
- Godot --headless --path . --log-file build/menu-render-test.log -- --render-test: RENDER PASS (exit cleanup warnings)
- Inspected offline composites at matching draw positions: build/menu-peek-review.png and build/menu-hidden-review.png.
- Live browser capture unavailable: browser access host unavailable.
- Godot graphical capture unavailable: winrt::hresult_error with both default and OpenGL rendering. Headless render check succeeded.
