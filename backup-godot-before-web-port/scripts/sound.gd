extends Node
## Small synthesized soundtrack and effects; no external samples.
var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var beat := 0.0
var step := 0
var muted := false

func _ready() -> void:
	for i in range(14):
		var p := AudioStreamPlayer.new()
		add_child(p)
		voices.append(p)
	for kind in ["shot", "akm", "sniper", "m4", "smg", "pistol", "heavy", "rocket", "jump", "hit", "rescue", "pickup", "explode", "click"]:
		sounds[kind] = synth(kind)

func synth(kind: String) -> AudioStreamWAV:
	var duration := 0.12
	if kind=="sniper": duration=.3
	if kind=="m4": duration=.07
	if kind=="smg": duration=.045
	if kind in ["explode", "rescue", "pickup"]: duration = 0.38
	var data := PackedByteArray()
	var count := int(22050 * duration)
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / 22050.0
		var e := pow(1.0 - t / duration, 2.0)
		var v := 0.0
		match kind:
			"akm": v=(sin(t*1100-t*t*2500)*.4+randf_range(-.6,.6))*e
			"m4": v=(sin(t*2300)*.45+randf_range(-.35,.35))*e
			"smg": v=(sin(t*3200)*.5+randf_range(-.3,.3))*e
			"pistol": v=(sin(t*1900-t*t*4000)*.55+randf_range(-.4,.4))*e
			"sniper": v=(sin(t*420)*.65+randf_range(-.6,.6))*e
			"shot": v = (sin(t * 1400.0 - t*t*2400.0) * 0.4 + randf_range(-0.6, 0.6)) * e
			"heavy", "rocket", "explode": v = (sin(t * 340.0) * 0.5 + randf_range(-0.5, 0.5)) * e
			"jump": v = sin(TAU * (350.0*t+1600.0*t*t)) * e
			"rescue", "pickup": v = sin(TAU * (660.0 + floor(t * 12.0) * 110.0) * t) * e * 0.6
			"hit": v = sin(t * (1200.0-t*4000.0)) * e
			_: v = sin(t * 2800.0) * e
		data.encode_s16(i * 2, int(clampf(v * 13000.0, -32767, 32767)))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.data = data
	return wav

func play(kind: String, volume := -15.0) -> void:
	if muted or not sounds.has(kind): return
	for p in voices:
		if not p.playing:
			p.stream = sounds[kind]
			p.volume_db = volume
			p.pitch_scale = randf_range(0.94, 1.06)
			p.play()
			return

func music(delta: float, intense: bool) -> void:
	if muted: return
	beat -= delta
	if beat > 0.0: return
	beat = 0.18 if intense else 0.23
	var notes := [0, 7, 12, 7, 3, 10, 15, 10, 5, 12, 17, 12, 7, 14, 19, 14]
	var freq := 130.81 * pow(2.0, float(notes[step % 16]) / 12.0)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var d := PackedByteArray()
	d.resize(6000)
	for i in range(3000):
		var t := float(i) / 22050.0
		var v := sin(TAU*freq*t) + 0.25*sin(TAU*freq*2.0*t)
		d.encode_s16(i*2, int(v*2000.0*pow(1.0-float(i)/3000.0, 2.0)))
	wav.data = d
	for p in voices:
		if not p.playing:
			p.stream = wav
			p.pitch_scale = 1.0
			p.volume_db = -13.0
			p.play()
			break
	step += 1
