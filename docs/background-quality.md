# In-game background quality

## Diagnosis

The four previous `zones_*_ink.png` files each packed six scenes into a 1672 x 941 image. `zoneBackdrop` sampled approximately 828 x 306 pixels after its atlas inset, then stretched the sample to 1560 x 640 logical pixels (about 1.9x horizontally and 2.1x vertically). Small roof tiles, foliage marks, window grids and railings were visibly enlarged. Fractional parallax changes how these edges are sampled while moving.

The Godot Canvas2D adapter already requested linear filtering with mipmaps, but these backgrounds and `ground_ink.png` were imported with `mipmaps/generate=false`. Thus the requested mipmap sampling could not help when the window was reduced. Browser Canvas smoothing and device-pixel-ratio sizing were already enabled and are preserved.

## Replacement

- 24 standalone generated paintings: `assets/generated/scene_{town,factory,harbor,fortress}_{0..5}.png`.
- Each painting is roughly 1942 x 809 pixels (minor generated dimension differences are allowed), larger than its 1560 x 640 logical destination.
- The generated style uses fewer small repeated details, broad color shapes, medium-weight outlines and quieter distant silhouettes.
- Both renderers sample the full independent image. Neighboring atlas scenes can no longer bleed into its edges.
- Keep existing fractional parallax, zone blending, shake overscan and gameplay geometry. Integer rounding would introduce an unnecessary stepping motion.
- Enable actual imported mipmaps for all 24 paintings and the existing ground atlas. Retain lossless texture import.
- Built-in image_gen was used. Exact prompts are in `background-generation-prompts.json`; the initial small town-atlas experiment was discarded.

## Validation commands

`node tools/test-render.cjs` checks all 24 backgrounds, no low-resolution enlargement, finite drawing coordinates and coverage through zone transitions.

`Godot --headless --path . --log-file build/background-assets.log --script res://tools/godot_tests/test_backgrounds.gd` checks imported dimensions and actual mipmap presence, and records native draw positions.

`node tools/record-background-preview.cjs` records browser positions. `tools/render-background-preview.ps1` (optionally `-Native`) replays those commands into review sheets. These are offline raster reviews, not live screenshots or a temporal aliasing measurement.

## Results (2026-11-10)

- All 24 final PNGs are 1939–1942 pixels wide and 809–811 pixels tall (34.1 MiB total).
- Browser renderer, touch controls and visual transition checks: PASS.
- Native background import/resolution/mipmap/coverage test: PASS.
- Native full render test: RENDER PASS; the headless process also reports existing certificate-store and shutdown resource warnings.
- Compared all 24 native/browser source rectangles and destination coordinates: match within 1e-8.
- Inspected `build/background-browser-review.png` and `build/background-native-review.png`.
- Rebuilt `build/web-standalone/` and checked that all 24 images are included.
- Live motion inspection remains unverified; the preceding task established that the browser access host is unavailable and graphical Godot capture terminates with `winrt::hresult_error`. The completed visual review uses the actual render helper commands replayed offline.
