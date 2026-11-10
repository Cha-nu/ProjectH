extends SceneTree
## Verify imported sampling data and record the real native backdrop placement for raster QA.
const View = preload("res://scripts/main.gd")
const G = preload("res://scripts/honey_game.gd")

class Recorder extends Canvas2D:
	var ops: Array = []
	func _init() -> void: super(RID())
	func drawImage(img: Texture2D, a: float, b: float, c: float = NAN, d: float = NAN, e: float = NAN, f: float = NAN, g: float = NAN, h: float = NAN) -> void:
		ops.append({"path": img.resource_path.trim_prefix("res://"), "source": [a,b,c,d], "dest": [e,f,g,h], "alpha": globalAlpha})

func _init() -> void:
	var view := View.new(); var recorder := Recorder.new(); view.c = recorder
	var failures := 0
	for stage in range(4):
		var game = G.new(); game.start(stage); view.g = game
		var theme: String = G.STAGES[stage].theme
		for i in range(6):
			var path := "res://assets/generated/scene_%s_%d.png" % [theme, i]
			var texture: Texture2D = load(path)
			if texture == null:
				push_error("Missing background: " + path); failures += 1; continue
			if texture.get_width() < 1560 or texture.get_height() < 640 or not texture.get_image().has_mipmaps():
				push_error("Background requires full resolution and mipmaps: " + path); failures += 1
			view.tex["scene_%s_%d" % [theme, i]] = texture
			game.camera = (game.zones[i].start if i < game.zones.size() else game.bossStart) + 200.5
			view.zoneBackdrop(i, 1.0)
	for op in recorder.ops:
		var d: Array = op.dest
		if d[0] > -24 or d[0] + d[2] < 1304 or d[1] > -24 or d[1] + d[3] < 600:
			push_error("Background does not cover viewport shake"); failures += 1
	var file := FileAccess.open("res://build/background-native-commands.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(recorder.ops)); file.close()
	view.free()
	print("PASS: 24 native backgrounds have mipmaps, full resolution and viewport coverage." if failures == 0 else "FAIL background assets: %d" % failures)
	quit(0 if failures == 0 else 1)
