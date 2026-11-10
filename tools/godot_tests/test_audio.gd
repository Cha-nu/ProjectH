extends SceneTree
## Headless check for scripts/honey_audio.gd: every SFX renders to a finite, non-clipping buffer and music/voice calls are safe.
## Run: tools/godot/Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tools/godot_tests/test_audio.gd
func _init() -> void:
	var a = load("res://scripts/honey_audio.gd").new()
	root.add_child(a)
	await process_frame
	var silent := ["start", "result", "victory", "gameover", "continue"]
	var ok := 0
	for name in a.SFX_NAMES:
		var v: Array = a._render(name)
		if silent.has(name):
			assert(v.is_empty(), name); continue
		assert(not v.is_empty(), "empty " + name)
		for w in v:
			var d: PackedByteArray = w.data
			assert(d.size() > 200, "short " + name)
			var peak := 0
			for i in range(0, d.size(), 2): peak = maxi(peak, absi(d.decode_s16(i)))
			assert(peak > 50 and peak <= 32767, "%s peak %d" % [name, peak])
		a.sfx(name); ok += 1
	for t in a.TRACKS:
		a.music(t); assert(a.current == t)
		for i in range(3): await process_frame
		assert(a._music.playing, "not playing " + t)
	a.configure({"duck": true, "music": 0.3}); a.configure({"muted": true}); a.configure({"muted": false, "duck": false, "master": 1.0})
	for i in range(20): await process_frame
	a.stopMusic(); assert(a.current == "")
	a.voice("Mission one. Start!"); a.configure({"voice": false}); a.voice("Game over")
	for i in range(20): await process_frame
	print("AUDIO PASS: %d sfx rendered, %d tracks played" % [ok, a.TRACKS.size()])
	quit()
