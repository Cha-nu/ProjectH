class_name HoneyAudio
extends Node
## Port of web/audio.js: recorded BGM with trimmed loop points, synthesized SFX and an English announcer voice.
## SFX recipes are rendered sample by sample (oscillators, noise, RBJ biquads, exponential ramps) into
## AudioStreamWAV buffers, so they match the Web Audio graph in the browser build.
## Synth fallback music for missing files is not ported: every track in web/music/tracks.js ships as an mp3.

const RATE := 44100
const TRACKS := ["title", "town", "factory", "harbor", "fortress", "boss", "clear", "result", "gameover", "victory"]
const ONE_SHOT := ["clear", "result", "gameover"]
## [loop start, loop end, file length] in seconds, same algorithm as loopPoints() in web/audio.js.
## Regenerate after replacing a track: Godot --headless --path . --script res://tools/compute_music_loops.gd
const LOOPS := {"boss": [0.15, 159.9, 160.8], "clear": [0.0, 3.95, 4.813], "factory": [0.05, 150.45, 151.16], "fortress": [0.1, 130.75, 131.6], "gameover": [0.0, 6.4, 6.813], "harbor": [0.0, 111.4, 112.0], "result": [0.0, 6.75, 8.413], "title": [0.0, 61.6, 62.8], "town": [0.0, 108.85, 109.6], "victory": [0.0, 89.85, 92.0]}
const SFX_NAMES := ["akm", "m4", "smg", "pistol", "sniper", "rocket", "throw", "bounce", "explode", "explodeSmall", "enemyShot", "enemyDie", "bigDie",
	"hurt", "die", "jump", "land", "knife", "ting", "thud", "crate", "alert", "rescue", "pickup", "weapon", "medal", "food", "click", "move", "select",
	"back", "tick", "stamp", "alarm", "warning", "charge", "bossFire", "slam", "bossDie", "combo", "clear", "start", "result", "victory", "gameover", "continue"]
const VARIANTS := 3  # noise-based sounds get a few renders, like the random noise offset on the web
# The browser master bus runs through a compressor (threshold -14 dB, ratio 4) at master*.7; baked in at default levels.
const COMP_LEVEL := 0.8 * 0.7 * 0.8

var opts := {"master": 0.8, "music": 0.55, "sfx": 0.8, "voice": true, "muted": false, "duck": false}
var current := ""  # == JS `playing`
var tracks: Array = TRACKS

var _bank := {}  # name -> Array[AudioStreamWAV] (empty array = silent recipe)
var _last := {}
var _pool: Array[AudioStreamPlayer] = []
var _next_player := 0
var _music: AudioStreamPlayer
var _fading: Array = []  # [player, gain] fading out
var _music_gain := 0.0  # per-track gain (fade in to .62)
var _bus_gain := -1.0  # smoothed music*(duck?.3:1)
var _token := 0
var _voice_id := ""
var _warm: Array = []
var _buf: PackedFloat32Array
var _noise_seed := 0

func _ready() -> void:
	for i in range(24):
		var p := AudioStreamPlayer.new(); add_child(p); _pool.append(p)
	_music = AudioStreamPlayer.new(); add_child(_music)
	_music.finished.connect(_on_music_finished)
	_pick_voice()
	_warm = SFX_NAMES.duplicate()

func ready() -> bool:
	return true

func configure(o: Dictionary) -> void:
	opts.merge(o, true)
	_apply()

func get_playing() -> String:
	return current

func _master() -> float:
	return 0.0 if opts.muted else float(opts.master) * 0.7

func _apply() -> void:
	for p in _pool: p.volume_db = linear_to_db(maxf(0.00001, _master() * float(opts.sfx)))

func _process(dt: float) -> void:
	# Pre-render one SFX per frame so the first shot never hitches.
	if not _warm.is_empty(): _render(_warm.pop_front())
	var target := float(opts.music) * (0.3 if opts.duck else 1.0)
	_bus_gain = target if _bus_gain < 0 else _bus_gain + (target - _bus_gain) * (1.0 - exp(-dt / 0.08))
	if _music.playing:
		_music_gain = minf(0.62, _music_gain + dt * 0.62 / 0.08)
		_music.volume_db = linear_to_db(maxf(0.00001, _music_gain * _bus_gain * _master()))
		if current != "" and not ONE_SHOT.has(current):
			var lp: Array = LOOPS[current]
			if _music.get_playback_position() >= lp[1]: _music.seek(lp[0])
	for f in _fading.duplicate():
		var p: AudioStreamPlayer = f[0]
		f[1] *= exp(-dt / 0.05); f[2] -= dt
		p.volume_db = linear_to_db(maxf(0.00001, f[1] * _bus_gain * _master()))
		if f[2] <= 0:
			p.queue_free(); _fading.erase(f)

# ================= music =================
func music(name: String) -> void:
	if current == name: return
	_stop_file()
	current = name
	if not LOOPS.has(name): return
	var stream: AudioStreamMP3 = load("res://assets/music/%s.mp3" % name)
	if stream == null: return
	stream.loop = false
	_music.stream = stream
	_music_gain = 0.0
	_music.volume_db = linear_to_db(0.00001)
	_music.play(0.0 if ONE_SHOT.has(name) else float(LOOPS[name][0]))

func stopMusic() -> void:
	_stop_file(); current = ""

func _stop_file() -> void:
	_token += 1
	if _music.playing:
		# Hand the old track to a throwaway player that fades out over .25s, like the web gain ramp.
		var old := AudioStreamPlayer.new(); add_child(old)
		old.stream = _music.stream; old.volume_db = _music.volume_db
		old.play(_music.get_playback_position())
		_fading.append([old, _music_gain, 0.25])
		_music.stop()

func _on_music_finished() -> void:
	if current != "" and not ONE_SHOT.has(current) and LOOPS.has(current):
		_music.play(float(LOOPS[current][0])); return
	current = ""

# ================= announcer =================
func _pick_voice() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH): return
	var voices := DisplayServer.tts_get_voices()
	var re_male := RegEx.create_from_string("(?i)male|david|guy|mark|daniel")
	for v in voices:
		if str(v.get("language", "")).to_lower().replace("_", "-").begins_with("en-us") and re_male.search(str(v.get("name", ""))):
			_voice_id = v.id; return
	for v in voices:
		if str(v.get("language", "")).to_lower().begins_with("en"):
			_voice_id = v.id; return

func voice(text: String) -> void:
	if text.is_empty() or not opts.voice or opts.muted or _voice_id.is_empty(): return
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, _voice_id, int(minf(1.0, float(opts.master) * 1.1) * 100), 0.55, 1.05)

# ================= sfx =================
func sfx(name: String) -> void:
	if not SFX_NAMES.has(name): return
	var now := Time.get_ticks_msec() / 1000.0
	if _last.has(name) and now - float(_last[name]) < 0.025: return
	_last[name] = now
	var variants: Array = _render(name)
	if variants.is_empty(): return
	var p := _pool[_next_player]; _next_player = (_next_player + 1) % _pool.size()
	p.stream = variants[randi() % variants.size()]
	p.volume_db = linear_to_db(maxf(0.00001, _master() * float(opts.sfx)))
	p.play()

func _render(name: String) -> Array:
	if _bank.has(name): return _bank[name]
	var out: Array = []
	for v in range(VARIANTS):
		_buf = PackedFloat32Array()
		var used_noise := _recipe(name)
		if _buf.is_empty(): break
		out.append(_to_wav(_buf))
		if not used_noise: break
	_bank[name] = out
	return out

func _to_wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray(); bytes.resize(buf.size() * 2)
	for i in range(buf.size()):
		var x := buf[i] * COMP_LEVEL
		var ax := absf(x)
		if ax > 0.2: x = signf(x) * (0.2 + (ax - 0.2) / 4.0)  # compressor knee
		bytes.encode_s16(i * 2, int(clampf(x / COMP_LEVEL, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = RATE; w.stereo = false; w.data = bytes
	return w

func _ensure(n: int) -> void:
	if _buf.size() < n:
		var old := _buf.size(); _buf.resize(n)
		for i in range(old, n): _buf[i] = 0.0

static func _hz(m: int) -> float: return 440.0 * pow(2.0, (m - 69) / 12.0)

static func _midi(n: String) -> int:
	var base := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
	var acc := 0; var o := n.substr(1)
	if o.begins_with("#"): acc = 1; o = o.substr(1)
	elif o.begins_with("b"): acc = -1; o = o.substr(1)
	return 12 * (int(o) + 1) + int(base[n[0]]) + acc

## Exponential ramp value like AudioParam.exponentialRampToValueAtTime, held after the end.
static func _exp(v0: float, v1: float, t: float, dur: float) -> float:
	if dur <= 0 or t >= dur: return v1
	return v0 * pow(v1 / v0, t / dur)

## Biquad coefficients matching the Web Audio spec (lowpass/highpass Q in dB, bandpass Q linear, 0 dB peak).
static func _coef(type: String, f: float, q: float) -> PackedFloat32Array:
	var w0 := TAU * clampf(f, 10.0, RATE * 0.49) / RATE
	var cw := cos(w0); var sw := sin(w0)
	var b0: float; var b1: float; var b2: float; var a1: float; var a2: float
	var alpha: float
	match type:
		"lowpass":
			alpha = sw / (2.0 * pow(10.0, q / 20.0))
			b0 = (1 - cw) / 2; b1 = 1 - cw; b2 = (1 - cw) / 2
		"highpass":
			alpha = sw / (2.0 * pow(10.0, q / 20.0))
			b0 = (1 + cw) / 2; b1 = -(1 + cw); b2 = (1 + cw) / 2
		_:
			alpha = sw / (2.0 * maxf(0.0001, q))
			b0 = alpha; b1 = 0; b2 = -alpha
	var a0 := 1 + alpha
	a1 = -2 * cw; a2 = 1 - alpha
	return PackedFloat32Array([b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0])

func _osc(type: String, f0: float, f1: float, dur: float, gain: float, at := 0.0, cut := 0.0) -> void:
	var start := int(at * RATE); var n := int((dur + 0.03) * RATE)
	_ensure(start + n)
	var phase := 0.0
	var c := _coef("lowpass", cut, 1.0) if cut > 0 else PackedFloat32Array()
	var x1 := 0.0; var x2 := 0.0; var y1 := 0.0; var y2 := 0.0
	var fend := maxf(20.0, f1)
	for i in range(n):
		var t := float(i) / RATE
		var f := _exp(f0, fend, t, dur) if f1 != 0 else f0
		var dt := f / RATE
		phase = fmod(phase + dt, 1.0)
		var s: float
		match type:
			"sine": s = sin(phase * TAU)
			"triangle": s = 1.0 - 4.0 * absf(phase - 0.5)
			"square":
				s = 1.0 if phase < 0.5 else -1.0
				s += _blep(phase, dt) - _blep(fmod(phase + 0.5, 1.0), dt)
			_:
				s = 2.0 * phase - 1.0 - _blep(phase, dt)
		if cut > 0:
			var y := c[0] * s + c[1] * x1 + c[2] * x2 - c[3] * y1 - c[4] * y2
			x2 = x1; x1 = s; y2 = y1; y1 = y; s = y
		_buf[start + i] += s * _exp(gain, 0.0008, t, dur)

static func _blep(t: float, dt: float) -> float:
	if t < dt:
		t /= dt; return t + t - t * t - 1.0
	if t > 1.0 - dt:
		t = (t - 1.0) / dt; return t * t + t + t + 1.0
	return 0.0

func _noise(dur: float, gain: float, type := "bandpass", freq := 1800.0, q := 1.0, at := 0.0, f1 := 0.0) -> void:
	var start := int(at * RATE); var n := int((dur + 0.03) * RATE)
	_ensure(start + n)
	var x1 := 0.0; var x2 := 0.0; var y1 := 0.0; var y2 := 0.0
	var c := _coef(type, freq, q)
	for i in range(n):
		var t := float(i) / RATE
		if f1 != 0 and i % 32 == 0: c = _coef(type, _exp(freq, f1, t, dur), q)
		var s := randf() * 2.0 - 1.0
		var y := c[0] * s + c[1] * x1 + c[2] * x2 - c[3] * y1 - c[4] * y2
		x2 = x1; x1 = s; y2 = y1; y1 = y
		_buf[start + i] += y * _exp(gain, 0.0008, t, dur)

func _arp(notes: Array, gap: float, type := "triangle", gain := 0.14, length := 0.16) -> void:
	for i in range(notes.size()): _osc(type, _hz(_midi(notes[i])), 0, length, gain, i * gap)

## Same recipes as the SFX table in web/audio.js. Returns true when the sound uses noise (random per play).
func _recipe(name: String) -> bool:
	match name:
		"akm": _noise(.09, .5, "bandpass", 1700, .9); _osc("square", 150, 50, .08, .12)
		"m4": _noise(.06, .42, "bandpass", 2300, 1); _osc("square", 190, 60, .06, .09)
		"smg": _noise(.045, .34, "bandpass", 3000, 1.2); _osc("square", 240, 90, .04, .06)
		"pistol": _noise(.07, .4, "bandpass", 2000, 1.1); _osc("square", 320, 80, .08, .1)
		"sniper": _noise(.35, .6, "lowpass", 2600, .7, 0, 300); _osc("sawtooth", 110, 28, .32, .2); _noise(.03, .4, "highpass", 5000)
		"rocket": _noise(.45, .45, "bandpass", 900, .8, 0, 300); _osc("sawtooth", 140, 40, .3, .16)
		"throw": _noise(.18, .18, "bandpass", 600, 2, 0, 2400)
		"bounce": _osc("triangle", 900, 500, .06, .08); return false
		"explode": _noise(.8, .9, "lowpass", 1400, .6, 0, 80); _osc("sine", 80, 28, .6, .6); _noise(.15, .4, "bandpass", 3000, .6)
		"explodeSmall": _noise(.4, .55, "lowpass", 1600, .6, 0, 120); _osc("sine", 110, 40, .3, .35)
		"enemyShot": _osc("square", 620, 220, .07, .045); return false
		"enemyDie": _osc("square", 700, 1500, .07, .06); _osc("triangle", 1300, 500, .14, .07, .06); return false
		"bigDie": _osc("square", 300, 60, .4, .12); _noise(.3, .3, "lowpass", 900)
		"hurt": _osc("sawtooth", 420, 140, .22, .16); _noise(.12, .25, "bandpass", 1200, 1)
		"die": _arp(["E5", "C5", "A4", "E4"], .09, "square", .1, .18); return false
		"jump": _osc("sine", 320, 720, .13, .12); return false
		"land": _noise(.07, .22, "lowpass", 500)
		"knife": _osc("sine", 190, 60, .09, .32); _noise(.08, .4, "lowpass", 900); _noise(.04, .18, "bandpass", 2200, 1.2)
		"ting": _osc("triangle", 2600, 0, .18, .12); _osc("sine", 3900, 0, .12, .06); return false
		"thud": _osc("sine", 160, 80, .07, .15); _noise(.05, .15, "lowpass", 700)
		"crate": _noise(.22, .45, "bandpass", 500, .8); _osc("square", 120, 60, .12, .08)
		"alert": _osc("square", 1300, 1700, .06, .035); return false
		"rescue": _arp(["C5", "E5", "G5", "C6"], .06, "triangle", .16); return false
		"pickup": _arp(["A5", "E6"], .05, "square", .06, .1); return false
		"weapon": _arp(["C5", "G5", "C6", "E6", "G6"], .045, "square", .07, .12); return false
		"medal": _osc("triangle", 1760, 0, .4, .12); _osc("triangle", 2637, 0, .4, .08, .06); return false
		"food": _arp(["E5", "G5", "B5"], .05, "sine", .16, .12); return false
		"click": _osc("square", 900, 0, .03, .05); return false
		"move": _osc("square", 700, 0, .03, .04); return false
		"select": _arp(["G5", "D6"], .05, "square", .06, .08); return false
		"back": _arp(["D5", "G4"], .05, "square", .05, .08); return false
		"tick": _osc("square", 1500, 0, .025, .035); return false
		"stamp": _osc("sine", 120, 40, .25, .4); _noise(.12, .35, "lowpass", 1200)
		"alarm":
			for i in range(3):
				_osc("square", 880, 660, .18, .05, i * .36); _osc("square", 660, 880, .18, .05, i * .36 + .18)
			return false
		"warning":
			for i in range(4): _osc("sawtooth", 520, 980, .4, .07, i * .5)
			return false
		"charge": _osc("sawtooth", 180, 520, .5, .05); return false
		"bossFire": _osc("sawtooth", 90, 35, .35, .25); _noise(.3, .4, "lowpass", 900, .7)
		"slam": _osc("sine", 70, 25, .5, .6); _noise(.35, .6, "lowpass", 600)
		"bossDie": _noise(1.6, .9, "lowpass", 1800, .5, 0, 60); _osc("sine", 60, 20, 1.4, .6)
		"combo": _arp(["C6", "E6", "G6"], .04, "square", .05, .08); return false
		"clear": _arp(["G5", "C6", "E6"], .08, "square", .06, .16); return false
		_: return false  # start/result/victory/gameover/continue are silent on the web too
	return true
