extends SceneTree
## Offline: decodes res://assets/music/*.mp3 and prints loop points with the same algorithm as web/audio.js loopPoints().
## Run: tools/godot/Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tools/compute_music_loops.gd
## then paste the printed LOOPS dictionary into scripts/honey_audio.gd.
func _init() -> void:
	var out := {}
	for name in ["title","town","factory","harbor","fortress","boss","clear","result","gameover","victory"]:
		var s: AudioStreamMP3 = load("res://assets/music/%s.mp3" % name)
		s.loop = false
		var pb := s.instantiate_playback()
		pb.start(0.0)
		var rate := 44100.0
		var win := int(rate * .05)
		var rms: Array[float] = []
		while true:
			var buf: PackedVector2Array = pb.mix_audio(1.0, win)
			if buf.size() < win or not pb.is_playing(): break
			var acc := 0.0
			for j in range(0, win, 4): acc += buf[j].x * buf[j].x
			rms.append(sqrt(acc / (win / 4.0)))
		var sorted := rms.duplicate(); sorted.sort()
		var med: float = sorted[sorted.size() / 2] if sorted.size() else 0.0
		var peak: float = sorted[-1] if sorted.size() else 0.0
		var a := 0
		for i in rms.size():
			if rms[i] > peak * .05: a = i; break
		var b := rms.size() - 1
		while b > a and rms[b] < med * .6: b -= 1
		out[name] = [snappedf(a * win / rate, 0.001), snappedf(maxf((b + 1) * win / rate, a * win / rate + 1), 0.001), snappedf(s.get_length(), 0.001)]
	print("LOOPS=", JSON.stringify(out))
	quit()
