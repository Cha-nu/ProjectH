# Soft boss art and driven tracks — 2026-10-27

The four bosses now use the heroine's warm brown contours, muted sage/cream armor and simple cel shading. Intact bodies, damaged bodies, weapons, broken weapons, hatches and debris all come from the same new modular atlases, generated with the built-in `image_gen` tool (no CLI/API fallback).

Runtime assets:

- `assets/generated/bosses/walker_soft.png`
- `assets/generated/bosses/cannon_soft.png`
- `assets/generated/bosses/ship_soft.png`
- `assets/generated/bosses/tank_soft.png`

The former `*_stable.png` sheets remain as historical assets but are no longer loaded. `tools/inspect-soft-bosses.ps1` reads alpha bounds without altering artwork and registers all 32 new sprites against the original atlas positions. Both runtimes use identical source/destination metadata. Gameplay hit boxes, gun pivots, muzzles and damage rules are unchanged.

Tank and cannon belts now have moving perimeter links, moving front tread bars and rotating wheel spokes. The existing `boss.track` field measures signed ground travel instead of elapsed time: enter/charge/reverse follow actual displacement, parked/airborne/wreck states stop advancing it. No Canvas/DOM APIs are introduced into simulation. The introduction tank reuses the same new body, guns and tracks. Continuous body anticipation, recoil, breathing and wreck collapse remain procedural.

Validation: browser gameplay (43), native gameplay (41), touch, aim, browser/native visual tests, full renderer smoke tests and new browser/native track regressions. The track regressions cover entrance, charge, reverse, stop, phase 2, air, wreck, belt wrap, transparency and atlas bounds.

Live graphical capture is blocked in this execution environment (Godot raises `winrt::hresult_error`; headless Chrome's GPU process exits). Both real renderers' boss draw commands were independently recorded and rasterized offline with System.Drawing. The four-panel outputs were visually inspected and are pixel-identical. This checks geometry, layering, palette and registration, but is not a GPU screenshot or live motion review.

Offline review commands:

```powershell
node tools/record-boss-preview.cjs
powershell -NoProfile -ExecutionPolicy Bypass -File tools/render-boss-preview.ps1
& ./tools/godot/Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tools/godot_tests/record_boss_preview.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/render-boss-preview.ps1 -Native
```

Outputs: `build/soft-boss-review.png` and `build/soft-boss-native-review.png`.

## Generation prompts

bossPrompt

Edit target: FIRST image, the tank modular sprite atlas. Style reference only: SECOND image, pink-haired heroine sprite sheet. Redraw EVERY sprite in the first atlas to exactly match the heroine's soft flat 2D chibi game illustration: smooth confident dark warm burgundy-brown outlines, muted sage green armor, cream and pastel honey yellow trim, dusty cocoa face and pink cheeks, one simple cel shadow, very sparse soft highlights. Remove ALL noisy camouflage, mottling, scratched metal, specular glare, photorealistic shading, excessive tiny rivets. Preserve original character identity, fish insignia, honey motif and captured bees. CRITICAL keep EXACT atlas layout: 4 equal square columns by 2 rows on 2:1 canvas, same sprite positions, sizes, silhouettes and transparent gutters as first image. Top row: intact tank BODY with NO main gun attached, damaged tank body, separate main cannon, broken main cannon. Bottom row: separate small gatling, broken gatling, open hatch with bee, debris. Each sprite stays in its own cell, never add a gun onto the body. Tank track and wheel positions exactly as original so game can overlay animated tread links. No text, no ground, no new elements. Actual transparent background. Output same 2048x1024 layout.

walkerPrompt

Edit target: FIRST image, WALKER modular sprite atlas. Style reference only: SECOND image, pink-haired heroine. Redraw ALL eight sprites to match that heroine: soft flat pastel 2D chibi illustration, smooth thick dark warm burgundy-brown contours, muted sage armor, cream and soft honey-yellow trim, dusty cocoa face, blush cheeks, simple two-tone cel shading. Remove the original's gritty miniature-metal rendering, camouflage mottling, harsh black shadows, excessive rivets and intense orange glare. Big clean readable color shapes. Preserve identity, pose, silhouette, fish insignia, honey motif. EXACT first-image composition: 4 equal square columns x 2 rows, 2:1 aspect, same sprite scale and transparent margins, no sprite crosses a cell. Top row intact four-legged walker BODY with no attached extra weapons, damaged walker body, detached twin gun, destroyed twin gun. Bottom row detached six-tube launcher, destroyed launcher, open hatch with bee, debris. Preserve every part's size/orientation and mounting position. Actual transparent background, no labels, no ground. Match the heroine's gentle color range decisively.

cannonPrompt

Edit target FIRST image cannon boss modular atlas. SECOND image heroine is mandatory style target. THIRD image pastel walker is palette consistency reference. Redraw all sprites of FIRST using heroine's clean soft flat chibi outlines and walker palette: muted pale sage armor, warm cream plates, soft pastel honey yellow, dusty cocoa face pink cheeks, dark burgundy brown thick contours, simple two-tone cel shading and very few highlights. Remove camouflage speckles, metallic gloss, hard black contrast and noisy detail. Preserve design/identity, fish insignia, honey theme and EXACT original 4 square columns x 2 rows atlas layout, same relative scale and positions, transparent gutters. Top row intact tracked cannon BODY without the main mortar attached, damaged body, detached mortar, broken mortar. Bottom row detached flamethrower, broken flamethrower, open hatch with bee, debris. Preserve track/wheel location so an animated track layer can cover them. No new components, no text, no ground. Real transparent background. 2:1 canvas. The body and ALL separate weapons should have identical soft flat shading; same pastel world as the heroine.

shipPrompt

Edit target FIRST image ship boss modular sprite atlas. SECOND image heroine mandatory art-style reference. THIRD image pastel walker palette reference. Restyle all eight sprites decisively to soft flat chibi anime game art matching heroine: muted pale sage armor, warm cream trim, soft pastel honey yellow, dusty cocoa face with pink cheeks, warm burgundy brown clean thick outlines and one simple cel shade. NO saturated emerald, orange shine, camouflage noise, realistic metallic texture, dramatic shadows. Preserve ship identity, fish flag, honey theme, geometry, same silhouettes and EXACT original 4 columns x 2 rows, square cells, 2:1 atlas layout. Top row intact ship BODY no attached gun/crane, damaged body, detached twin deck gun, broken deck gun. Bottom row detached crane claw, broken crane, open hatch with cute crew, debris. Every sprite same size and position relative to original cell with transparent gaps. ALL parts including broken weapons match body style. No text, no ground, no grids, no added items. Actual transparent background.

tankFinalPrompt

FIRST image is edit target tank modular sprite atlas. SECOND heroine is line/shading reference. THIRD pastel walker atlas is EXACT palette reference. Make the first atlas as pale, soft and flat as THIRD: armor muted pale sage (#a6ae96), trims warm cream (#fff0cc), honey soft butter yellow (#ffdc89), face dusty cocoa rose, outlines warm burgundy brown. Replace EVERY strong emerald green, dark olive, saturated gold/amber and black metallic shadow. Flat chibi two tone cel shade, minimal highlights, no metallic gloss/camouflage textures. Preserve all tank parts, captured bees, fish flag and original silhouettes/positions in EXACT 4 square columns x 2 rows 2:1 layout. Same sizes and gutters. Top intact body, damaged body, main cannon, broken cannon; bottom gatling, broken gatling, hatch, debris. No weapons added to body. Preserve track and wheel geometry. True transparent background. Keep original target composition. This is style/palette correction only; all eight sprites MUST match the third reference's soft pastel palette.
