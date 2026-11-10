# Repository Guidelines

## Project Structure & Module Organization

This game has matching browser Canvas and Godot 4.7.1 implementations.
- `web/game.js`, `web/render.js`, and `web/audio.js` contain browser simulation, presentation/input, and audio.
- `scripts/honey_game.gd`, `scripts/main.gd`, and `scripts/honey_audio.gd` are their Godot counterparts; `scripts/canvas2d.gd` adapts Canvas drawing. `scenes/main.tscn` is the entry scene.
- `assets/` holds artwork; `web/music/` and `web/fonts/` hold browser media. `docs/` records art and music prompts.
- `tools/` contains tests, asset utilities, and packaging scripts. `build/` holds outputs; `backup-*/` directories are historical snapshots.

Keep gameplay rules synchronized across both implementations. Keep browser simulation independent of DOM, rendering, and audio APIs.

## Build, Test, and Development Commands

Run commands from the repository root with Node.js and Godot 4.7.1 available.
- `.\Play-Web.cmd`: start the local server and open `http://127.0.0.1:8787`.
- `node tools/serve.cjs`: run the browser server directly.
- Open `project.godot` and press **F5** to run the Godot project.
- `node tools/package-web.cjs`: assemble static files in `build/web-standalone/`.
- Browser checks:

```powershell
node tools/test-game.cjs
node tools/test-touch.cjs
node tools/test-render.cjs
node tools/test-aim-poses.cjs
```

Run Godot logic tests with:

```powershell
& .\tools\godot\Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tools/godot_tests/test_game.gd
```

Substitute `test_audio.gd` for audio checks. The engine directory is ignored; install the matching executable if absent.

## Coding Style & Naming Conventions

Use UTF-8 as specified by `.editorconfig`. Match surrounding indentation: tabs in GDScript and compact space-indented JavaScript. Preserve existing camelCase gameplay APIs across ports, uppercase constants, and snake_case GDScript filenames. No formatter or linter configuration is present; avoid unrelated reformatting.

## Testing Guidelines

JavaScript tests use Node assertions; Godot tests use custom SceneTree checks. Name tests `test-*.cjs` or `test_*.gd` and describe observable behavior. Add corresponding regression checks for gameplay changes. No numeric coverage threshold is configured. Renderer checks validate Canvas calls; manually inspect visual changes in both runtimes.

## Commit & Pull Request Guidelines

This checkout lacks Git metadata, so historical conventions cannot be verified. Use short imperative subjects, such as `Fix boat collision at harbor`. PRs should describe behavior changes, affected runtimes, test results, related issues when available, and screenshots for visual changes.
