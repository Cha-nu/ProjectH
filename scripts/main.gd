extends Node2D
## Honey Churros — Godot front end. Line-for-line port of web/render.js:
## input (keyboard / touch / gamepad), menus, HUD and rendering through the Canvas2D shim.

const HG := preload("res://scripts/honey_game.gd")
const Canvas2DScript := preload("res://scripts/canvas2d.gd")
const Motion := preload("res://scripts/visual_motion.gd")

const INK := "#5b3440"; const PAPER := "#fff8f5"; const PINK := "#ffd8d9"; const HOT := "#ef7f9e"; const GOLD := "#ffc94d"; const TEAL := "#3f7468"; const SHADOW := "#3a1f2a"
const DISPLAY := "'Black Han Sans','Malgun Gothic',sans-serif"
const BODY := "'Jua','Malgun Gothic',sans-serif"
const THEME := {"town": {"sky": ["#9fdcf4", "#e4f6ef"], "ground": "#a9cf8e", "top": "#d6ecb4", "edge": "#6f9a5b", "deep": "#7d6650"},
	"factory": {"sky": ["#f6d27d", "#fff1cf"], "ground": "#c9a067", "top": "#e8c58a", "edge": "#8a6235", "deep": "#6b4a2e"},
	"harbor": {"sky": ["#8fd2ef", "#e2f5f6"], "ground": "#b88f68", "top": "#d9b48a", "edge": "#7b5638", "deep": "#5c4436"},
	"fortress": {"sky": ["#9c90c6", "#e5ddf0"], "ground": "#8d8696", "top": "#b4adbd", "edge": "#5c5566", "deep": "#4a4352"}}
const FILES := {"aim": "characters/hero_aim_sheet.png", "menuFriends": "characters/menu_friends_v2.png", "bossCrew": "generated/boss_crew.png", "profile": "characters/profile.jpg", "profileRound": "generated/profile_round.png", "m4": "characters/m4_black.png", "fishAnim": "characters/fish_sheet.png", "bossParts": "characters/boss_parts.png", "hero": "characters/hero_sheet.png", "body": "characters/hero_body_sheet.png", "bodyP": "characters/hero_body_pistol.png", "runP": "generated/hero_run_pistol.png", "weapons": "characters/weapons_clean.png", "bee": "characters/honeybee.webp", "tank": "characters/tank.png", "bg": "backgrounds.png", "bgWrap": "generated/backgrounds_wrap.png", "roster": "generated/enemies.png", "upRun": "generated/hero_up_run.png", "menuBg": "generated/menu_bg_meadow.png", "menuGirl": "generated/menu_churros_sit.png", "menuFish": "generated/menu_gwamegi_peek.png", "menuBush": "generated/menu_bush_front.png", "menuTree": "generated/menu_tree_whole.png", "victory": "generated/hero_victory.png", "punch": "generated/hero_punch.png", "run": "generated/hero_run.png", "story": "generated/story_churros.png", "bodyHands": "generated/hero_body_hands.png", "runHands": "generated/hero_run_hands.png", "briefing": "generated/story_briefing.png", "pow": "generated/pow_tied.png", "cage": "generated/pow_cage.png", "items": "generated/items.png", "boom": "generated/explosion.png", "bossKing": "generated/boss_king.png", "bossCannon": "generated/boss_cannon.png", "bossBoat": "generated/boss_boat.png", "boss_walker": "generated/bosses/walker_ink.png", "boss_cannon": "generated/bosses/cannon_ink.png", "boss_ship": "generated/bosses/ship_ink.png", "boss_tank": "generated/bosses/tank_ink.png",
	"e_grunt": "generated/enemies/grunt.png", "e_hopper": "generated/enemies/hopper.png", "e_flyer": "generated/enemies/flyer.png", "e_shield": "generated/enemies/shield.png", "e_bomber": "generated/enemies/bomber.png", "e_heavy": "generated/enemies/heavy.png", "e_turret": "generated/enemies/turret.png", "chute": "generated/enemies/parachute.png",
	"g_town": "generated/ground/town.png", "g_factory": "generated/ground/factory.png", "g_harbor": "generated/ground/harbor.png", "g_fortress": "generated/ground/fortress.png"}
# 4x2 sheets generated with Codex. src = crop in cell units (may extend past the cell), base = feet line in cell units.
# scale = draw multiplier so every pose shows the fish body at the same on-screen size (the parachute cell packs a smaller fish).
# Enemy sheets (generated/enemies/*.png): 4x2 frames facing left — 0-3 walk, 4 idle, 5 windup, 6 attack, 7 hurt. base = feet line in cell units.
const EBASE := {"grunt": .80, "hopper": .88, "flyer": .88, "shield": .87, "bomber": .88, "heavy": .88, "turret": .87}
const ESCALE := 1.6
const ITEM := {"weapon": 0, "bomb": 1, "food": 2, "medal": 3, "ammo": 4, "barrel": 5, "crate": 6, "tied": 7}
const KEYMAP := {"ArrowLeft": "left", "KeyA": "left", "ArrowRight": "right", "KeyD": "right", "ArrowUp": "up", "KeyW": "up", "ArrowDown": "down", "KeyS": "down", "KeyZ": "fire", "KeyJ": "fire", "KeyX": "jump", "Space": "jump", "KeyC": "grenade", "KeyK": "grenade", "KeyQ": "swap", "ShiftLeft": "swap"}
const MENUKEY := {"ArrowUp": "up", "KeyW": "up", "ArrowDown": "down", "KeyS": "down", "ArrowLeft": "left", "KeyA": "left", "ArrowRight": "right", "KeyD": "right", "Enter": "ok", "NumpadEnter": "ok", "Space": "ok", "KeyZ": "ok", "Escape": "back", "Backspace": "back", "KeyX": "back"}
const PAD := {"x": 118, "y": 612, "r": 72}
const BTN := [{"a": "fire", "x": 1182, "y": 618, "r": 54, "label": "사격", "key": "Z"}, {"a": "jump", "x": 1068, "y": 656, "r": 40, "label": "점프", "key": "X"}, {"a": "grenade", "x": 1072, "y": 548, "r": 34, "label": "폭탄", "key": "C"}, {"a": "swap", "x": 1190, "y": 500, "r": 30, "label": "교체", "key": "Q"}]
# Timeline in seconds: peace (0-6) → alarm (6-8.5) → raid (8.5-15) → retreat (15-19) → resolve (19-25).
const STORY_LINES := [[.6, 3.2, "", "꽃과 꿀이 넘치는 허니츄러스 마을."], [3.2, 6, "", "허니비들은 오늘도 평화롭게 꿀을 모으고 있었어요…"], [6.2, 8.6, "", "그런데 그때——!"],
	[9.3, 10.5, "hero", "앗…! 내 허니비!!"],
	[10.6, 14.6, "commander", "꿀도, 허니비도 전부 우리 과메기단 거다~! 몽땅 실어라!"], [14.9, 18.6, "bee", "살려줘요~! 허니츄러스~!"], [19.2, 23, "hero", "…내 친구들을 돌려놔. 한 마리도 빠짐없이 구해낼 거야!"]]
const STORY_CUES := [[6, "alarm"], [6, "music:boss"], [8.7, "warning"], [9.3, "hurt"], [10, "explode"], [19.2, "click"], [21.4, "pistol"], [11, "slam"], [15, "charge"], [19, "music:title"], [22.6, "stamp"]]

var c: Canvas2D
var g
var audio
var tex := {}
var settings := {}
var records: Array = []
var progress := 0
var _cfg := ConfigFile.new()
const SAVE_PATH := "user://honey_web.cfg"

# ---------- input state ----------
var kb := {}
var pressedEv := {}
var releasedEv := {}
var touchHeld := {}
var padHeld := {}
var prevHeld := {}
var touchMode := false
var padPrev := {}
var ui := {"screen": "main", "titleAt": 0.0, "index": 0, "hover": -1, "hits": [], "fade": 1.0, "toast": "", "toastT": 0.0, "lastMode": "", "goT": 0.0, "cleared": 0, "from": "main", "tickNum": -1, "shownRow": -1, "modeT": 0.0, "stamped": false, "storyDone": {}, "newRecord": false, "bestAtStart": null}
var leanShift := {"x": 0.0, "y": 0.0}
var acc := 0.0
var lastBoss := false

# ---------- test / capture ----------
var _args := {}
var _capture := ""
var _capture_frames := 0
var _fixed_step := false
var _frame_ok := true
var _failures := 0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else true
	c = Canvas2DScript.new(get_canvas_item())
	var display: FontFile = load("res://assets/fonts/BlackHanSans-Regular.ttf")
	var body: FontFile = load("res://assets/fonts/Jua-Regular.ttf")
	var sys := SystemFont.new(); sys.font_names = PackedStringArray(["Malgun Gothic", "Segoe UI Symbol", "Segoe UI Emoji", "Noto Sans CJK KR", "sans-serif"])
	display.fallbacks = [sys]; body.fallbacks = [sys]
	c.set_font_files(display, body)
	for key in FILES: tex[key] = load("res://assets/" + FILES[key])
	tex.driveParts = load("res://assets/generated/bosses/drive_parts.png")
	tex.groundInk = load("res://assets/generated/ground_ink.png")
	for name in ["town", "factory", "harbor", "fortress"]:
		for i in range(6): tex["scene_%s_%d" % [name, i]] = load("res://assets/generated/scene_%s_%d.png" % [name, i])
	g = HG.new()
	if ResourceLoader.exists("res://scripts/honey_audio.gd"):
		audio = load("res://scripts/honey_audio.gd").new()
		add_child(audio)
	if not (_args.has("capture") or _args.has("render-test")): _cfg.load(SAVE_PATH)
	settings = {"difficulty": "normal", "master": 8, "music": 6, "sfx": 8, "voice": true, "shake": true, "touch": "auto"}
	var saved = store_get("honey-settings", {})
	if saved is Dictionary: settings.merge(saved, true)
	for k in ["master", "music", "sfx"]: settings[k] = int(settings[k])
	if not HG.DIFFICULTY.has(settings.difficulty): settings.difficulty = "normal"
	if _args.has("touch"): settings.touch = "on"  # capture helper: --touch shows the touch pad
	touchMode = settings.touch == "on"
	records = store_get("honey-records", [])
	if not (records is Array): records = []
	progress = int(store_get("honey-progress", 0))
	var best := float(store_get("honey-best", 0))
	for r in records: best = maxf(best, float(r.score))
	g.best = int(best)
	g.onSave = func(v): store_set("honey-best", v)
	g.sound = func(n): a_sfx(n)
	g.voice = func(t): a_voice(t)
	applySettings()
	if _args.has("render-test"):
		_run_render_test.call_deferred()
	elif _args.has("capture"):
		_capture = str(_args.capture); _fixed_step = true
		_setup_mode(str(_args.get("mode", "title")))

# ---------- audio wrappers (audio may be absent) ----------
func a_sfx(n) -> void:
	if audio: audio.sfx(n)
func a_voice(t) -> void:
	if audio: audio.voice(t)
func a_music(n) -> void:
	if audio: audio.music(n)
func a_stop() -> void:
	if audio: audio.stopMusic()
func a_set(o: Dictionary) -> void:
	if audio: audio.configure(o)
func a_ready() -> void:
	if audio: audio.ready()
func a_muted() -> bool:
	return bool(audio.opts.get("muted", false)) if audio else false

# ---------- persistence ----------
func store_get(k: String, d: Variant) -> Variant:
	if not _cfg.has_section_key("store", k): return d
	var v = _cfg.get_value("store", k)
	var parsed = JSON.parse_string(str(v))
	return d if parsed == null else parsed
func store_set(k: String, v: Variant) -> void:
	if _args.has("capture") or _args.has("render-test"): return  # checks never touch the player's save
	_cfg.set_value("store", k, JSON.stringify(v)); _cfg.save(SAVE_PATH)

func dif() -> Dictionary:
	return g.dif

func applySettings() -> void:
	g.difficulty = settings.difficulty; g.shakeScale = 1 if settings.shake else 0
	a_set({"master": settings.master / 10.0, "music": settings.music / 10.0, "sfx": settings.sfx / 10.0, "voice": settings.voice})
	store_set("honey-settings", settings)

func addRecord() -> void:
	if not g.score: return
	records.append({"score": g.score, "stage": g.stage + 1, "clear": g.mode == "victory", "dif": g.difficulty, "date": Time.get_date_string_from_system()})
	records.sort_custom(func(a, b): return a.score > b.score)
	records = records.slice(0, 5); store_set("honey-records", records)

# ---------- input ----------
func _code(e: InputEventKey) -> String:
	var k := e.physical_keycode
	if k >= KEY_A and k <= KEY_Z: return "Key" + char(k)
	match k:
		KEY_LEFT: return "ArrowLeft"
		KEY_RIGHT: return "ArrowRight"
		KEY_UP: return "ArrowUp"
		KEY_DOWN: return "ArrowDown"
		KEY_SPACE: return "Space"
		KEY_ENTER: return "Enter"
		KEY_KP_ENTER: return "NumpadEnter"
		KEY_ESCAPE: return "Escape"
		KEY_BACKSPACE: return "Backspace"
		KEY_SHIFT: return "ShiftLeft" if e.location != KEY_LOCATION_RIGHT else "ShiftRight"
		KEY_TAB: return "Tab"
		KEY_F11: return "F11"
	return ""

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var code := _code(event)
		if code == "": return
		get_viewport().set_input_as_handled()
		if event.pressed: _keydown(code, event.echo)
		else: _keyup(code)
	elif event is InputEventMouseButton:
		if event.device == InputEvent.DEVICE_ID_EMULATION or event.button_index != MOUSE_BUTTON_LEFT: return
		var p := _local(event)
		if event.pressed: _pointerdown(1, p, false)
		else: _pointerup(1)
	elif event is InputEventMouseMotion:
		if event.device == InputEvent.DEVICE_ID_EMULATION: return
		_pointermove(1, _local(event))
	elif event is InputEventScreenTouch:
		var p := _local(event)
		if event.pressed: _pointerdown(1000 + event.index, p, true)
		else: _pointerup(1000 + event.index)
	elif event is InputEventScreenDrag:
		_pointermove(1000 + event.index, _local(event))

func _local(event: InputEvent) -> Vector2:
	return make_input_local(event).position

func _keydown(code: String, repeat: bool) -> void:
	a_ready()
	if code == "F11" and not repeat: toggleFull(); return
	if code == "KeyM" and not repeat:
		a_set({"muted": not a_muted()}); toastUI("소리 끔" if a_muted() else "소리 켬"); return
	if g.mode == "play":
		if (code == "Escape" or code == "KeyP") and not repeat: openPause(); return
		if repeat: return
		var a = KEYMAP.get(code)
		if a: kb[a] = true; pressedEv[a] = true
		return
	var m = MENUKEY.get(code)
	if m: uiInput(m, repeat)
	if code == "KeyR" and not repeat and g.mode in ["pause", "continue"]:
		g.retry(); closeMenus()

func _keyup(code: String) -> void:
	var a = KEYMAP.get(code)
	if a: kb.erase(a); releasedEv[a] = true

func clearHeld() -> void:
	kb.clear(); touchHeld.clear()

func _exit_tree() -> void:
	if c: c.free_items()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and g != null and _capture == "":
		clearHeld()
		if g.mode == "play": openPause()

func touchActions(p: Vector2) -> Array:
	var dx := p.x - PAD.x; var dy := p.y - PAD.y
	if Vector2(dx, dy).length() < PAD.r * 1.5 and p.x < 300 and p.y > 480:
		if Vector2(dx, dy).length() < 12: return []
		var a := atan2(dy, dx); var out := []
		if cos(a) > .38: out.append("right")
		if cos(a) < -.38: out.append("left")
		if sin(a) < -.38: out.append("up")
		if sin(a) > .55: out.append("down")
		return out
	for b in BTN:
		if p.distance_to(Vector2(b.x, b.y)) < b.r + 10: return [b.a]
	return []

func setTouch(id: int, actions: Array) -> void:
	var old: Array = touchHeld.get(id, [])
	for a in actions:
		if not old.has(a): pressedEv[a] = true
	for a in old:
		if not actions.has(a):
			var other := false
			for k in touchHeld:
				if k != id and touchHeld[k].has(a): other = true
			if not other: releasedEv[a] = true
	if actions.size(): touchHeld[id] = actions
	else: touchHeld.erase(id)

func pauseHit(p: Vector2) -> bool: return p.distance_to(Vector2(1229, 51)) < 30

func _pointerdown(id: int, p: Vector2, touch: bool) -> void:
	a_ready()
	if touch and settings.touch == "auto": touchMode = true
	if g.mode == "play":
		if pauseHit(p): openPause(); return
		var acts := touchActions(p)
		if acts.size(): setTouch(id, acts)
		return
	uiPointer(p, true)

func _pointermove(id: int, p: Vector2) -> void:
	if touchHeld.has(id): setTouch(id, touchActions(p)); return
	if g.mode != "play": uiPointer(p, false)
	var hand: bool = pauseHit(p) if g.mode == "play" else ui.hover >= 0
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hand else Input.CURSOR_ARROW)

func _pointerup(id: int) -> void:
	if touchHeld.has(id): setTouch(id, [])

func toggleFull() -> void:
	var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)

# Gamepad (standard mapping): A jump, X fire, B grenade, Y swap, Start pause.
func pollPad() -> void:
	padHeld = {}
	var pads := Input.get_connected_joypads()
	if pads.is_empty(): return
	var d: int = pads[0]
	var b := func(i: int) -> bool: return Input.is_joy_button_pressed(d, i)
	var ax := Input.get_joy_axis(d, JOY_AXIS_LEFT_X); var ay := Input.get_joy_axis(d, JOY_AXIS_LEFT_Y)
	var lt := Input.get_joy_axis(d, JOY_AXIS_TRIGGER_LEFT) > .5; var rt := Input.get_joy_axis(d, JOY_AXIS_TRIGGER_RIGHT) > .5
	var now := {}
	now.left = b.call(JOY_BUTTON_DPAD_LEFT) or ax < -.4; now.right = b.call(JOY_BUTTON_DPAD_RIGHT) or ax > .4
	now.up = b.call(JOY_BUTTON_DPAD_UP) or ay < -.5; now.down = b.call(JOY_BUTTON_DPAD_DOWN) or ay > .5
	now.jump = b.call(JOY_BUTTON_A); now.fire = b.call(JOY_BUTTON_X) or rt; now.grenade = b.call(JOY_BUTTON_B) or lt
	now.swap = b.call(JOY_BUTTON_Y) or b.call(JOY_BUTTON_RIGHT_SHOULDER); now.start = b.call(JOY_BUTTON_START)
	var edge := func(k: String) -> bool: return now[k] and not padPrev.get(k, false)
	if g.mode == "play":
		for k in ["left", "right", "up", "down", "jump", "fire", "grenade", "swap"]:
			if now[k]: padHeld[k] = true
		if edge.call("start"): openPause()
	else:
		for k in ["up", "down", "left", "right"]:
			if edge.call(k): uiInput(k)
		if edge.call("jump") or edge.call("start"): uiInput("ok")
		if edge.call("grenade"): uiInput("back")
	padPrev = now

# ---------- UI / menus ----------
func toastUI(s: String) -> void: ui.toast = s; ui.toastT = 1.6
func closeMenus() -> void: ui.screen = "main"; ui.index = 0; a_set({"duck": false})
func openPause() -> void:
	if g.mode != "play": return
	g.pause(); ui.screen = "pause"; ui.index = 0; a_set({"duck": true}); a_sfx("click"); clearHeld()
func onOff(v) -> String: return "켜기" if v else "끄기"

func _vol(k: String) -> Dictionary:
	var S := settings
	return {"label": {"master": "전체 볼륨", "music": "음악", "sfx": "효과음"}[k], "value": "■".repeat(S[k]) + "□".repeat(10 - S[k]),
		"adjust": func(d): S[k] = clampi(S[k] + d, 0, 10); applySettings(); a_sfx("move"),
		"setTo": func(v): S[k] = clampi(v, 0, 10); applySettings(); a_sfx("move")}

func _dif_item() -> Dictionary:
	var S := settings
	return {"label": "난이도", "value": HG.DIFFICULTY[S.difficulty].label, "adjust": func(d):
		var k: Array = HG.DIFFICULTY.keys()
		S.difficulty = k[(k.find(S.difficulty) + d + k.size()) % k.size()]; applySettings(); a_sfx("move")}

func menu() -> Array:
	var S := settings
	match ui.screen:
		"main":
			return [{"label": "게임 시작", "go": func(): g.difficulty = S.difficulty; g.start(0, true)}, {"label": "스테이지 선택", "go": func(): open("stages")}, _dif_item(),
				{"label": "조작 방법", "go": func(): open("howto")}, {"label": "설정", "go": func(): open("settings")}]
		"stages":
			var out := []
			for i in range(HG.STAGES.size()):
				var s: Dictionary = HG.STAGES[i]
				out.append({"label": "MISSION %d  %s" % [i + 1, s.name], "locked": i > progress, "go": func():
					if i > progress:
						a_sfx("back"); toastUI("이전 미션을 먼저 클리어하세요"); return false
					g.difficulty = S.difficulty; g.start(i)
					return null})
			out.append({"label": "돌아가기", "go": func(): back()})
			return out
		"settings":
			var out := []
			if ui.from == "main": out.append(_dif_item())
			out.append_array([_vol("master"), _vol("music"), _vol("sfx"),
				{"label": "아나운서 음성", "value": onOff(S.voice), "adjust": func(_d):
					S.voice = not S.voice; applySettings(); a_sfx("move")
					if S.voice: a_voice("Mission start!")},
				{"label": "화면 흔들림", "value": onOff(S.shake), "adjust": func(_d): S.shake = not S.shake; applySettings(); a_sfx("move")},
				{"label": "터치 버튼", "value": {"auto": "자동", "on": "항상 표시", "off": "숨김"}[S.touch], "adjust": func(d):
					var k := ["auto", "on", "off"]; S.touch = k[(k.find(S.touch) + d + 3) % 3]; touchMode = S.touch == "on"; applySettings(); a_sfx("move")},
				{"label": "전체 화면", "value": "켜짐" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "꺼짐", "go": func(): toggleFull(); return false},
				{"label": "돌아가기", "go": func(): back()}])
			return out
		"pause":
			return [{"label": "계속하기", "go": func(): g.pause(); closeMenus()}, {"label": "미션 처음부터", "go": func(): g.retry(); closeMenus()},
				{"label": "설정", "go": func(): open("settings", "pause")}, {"label": "타이틀로 나가기", "go": func(): g.quit(); closeMenus()}]
		"howto", "records":
			return [{"label": "돌아가기", "go": func(): back()}]
	return []

func open(screen: String, from = null) -> void:
	ui.from = from if from else ui.screen; ui.screen = screen; ui.index = 0; a_sfx("select")
func back() -> void:
	var to := "pause" if ui.screen == "settings" and ui.from == "pause" else "main"
	ui.screen = to; ui.index = 2 if to == "pause" else 0; a_sfx("back")
func activate(item, dir := 1) -> void:
	if item == null: return
	if item.has("go"):
		var r = item.go.call()
		if not (r is bool and r == false) and not item.get("locked", false): a_sfx("select")
	elif item.has("adjust"): item.adjust.call(dir)
func menuActive() -> bool: return g.mode == "title" or g.mode == "pause"
func uiInput(a: String, repeat := false) -> void:
	if menuActive():
		var items := menu()
		if items.is_empty(): return
		if a == "up" or a == "down":
			ui.index = (ui.index + (-1 if a == "up" else 1) + items.size()) % items.size(); a_sfx("move")
		elif (a == "left" or a == "right") and ui.index < items.size() and items[ui.index].has("adjust"):
			items[ui.index].adjust.call(-1 if a == "left" else 1)
		elif a == "ok" and not repeat: activate(items[ui.index] if ui.index < items.size() else null)
		elif a == "back" and not repeat:
			if g.mode == "pause" and ui.screen == "pause": g.pause(); closeMenus()
			elif ui.screen != "main" and ui.screen != "pause": back()
		return
	if repeat: return
	if a == "ok": advance()
	elif a == "back" and g.mode == "continue": g.continueTime = 0
func advance() -> void:
	if g.mode == "result":
		if g.result.t < tallyEnd(): g.result.t = tallyEnd(); return
		g.confirm(); return
	if g.mode == "victory" and victoryT() < 3: return
	if g.mode in ["story", "briefing", "continue", "gameover", "victory"]: g.confirm(); a_sfx("select")
func uiPointer(p: Vector2, click: bool) -> void:
	var hit = null
	for h in ui.hits:
		if p.x >= h.x and p.x <= h.x + h.w and p.y >= h.y and p.y <= h.y + h.h: hit = h; break
	ui.hover = hit.i if hit else -1
	if hit and not click and menuActive() and ui.index != hit.i: ui.index = hit.i
	if not click: return
	if hit:
		if menuActive():
			ui.index = hit.i; var items := menu()
			var item = items[hit.i] if hit.i < items.size() else null
			if hit.has("bar") and item != null and item.has("setTo"): item.setTo.call(ceili((p.x - hit.bar[0]) / (hit.bar[1] - hit.bar[0]) * 10))
			else: activate(item, hit.get("dir", 1))
		elif hit.has("go"): hit.go.call()
		return
	if g.mode == "title":
		if ui.screen == "howto" or ui.screen == "records": back()
		return
	if not menuActive(): advance()

# ---------- drawing helpers ----------
func box(x: float, y: float, w: float, h: float, color: Variant, r: float = 10, border: Variant = null, lw: float = 2) -> void:
	if w <= 0 or h <= 0: return
	c.beginPath(); c.roundRect(x, y, w, h, r); c.fillStyle = color; c.fill()
	if border: c.strokeStyle = border; c.lineWidth = lw; c.stroke()
func text(s: Variant, x: float, y: float, size: float = 18, color: Variant = INK, align := "left", font := BODY) -> void:
	c.fillStyle = color; c.font = "%spx %s" % [size, font]; c.textAlign = align; c.textBaseline = "alphabetic"; c.fillText(str(s), x, y)
func outlined(s: Variant, x: float, y: float, size: float, fill: Variant = PAPER, stroke: Variant = SHADOW, align := "center", lw: float = 0, font := DISPLAY) -> void:
	c.font = "%spx %s" % [size, font]; c.textAlign = align; c.textBaseline = "alphabetic"; c.lineJoin = "round"; c.lineWidth = lw if lw else maxf(3, size * .16)
	c.strokeStyle = stroke; c.strokeText(str(s), x, y + size * .07); c.strokeText(str(s), x, y); c.fillStyle = fill; c.fillText(str(s), x, y)
func line(x: float, y: float, xx: float, yy: float, color: Variant, width: float = 2) -> void:
	c.beginPath(); c.moveTo(x, y); c.lineTo(xx, yy); c.strokeStyle = color; c.lineWidth = width; c.lineCap = "round"; c.stroke()
func circle(x: float, y: float, r: float, color: Variant) -> void:
	c.beginPath(); c.arc(x, y, maxf(0, r), 0, TAU); c.fillStyle = color; c.fill()
func ring(x: float, y: float, r: float, color: Variant, w: float = 2) -> void:
	c.beginPath(); c.arc(x, y, maxf(0, r), 0, TAU); c.strokeStyle = color; c.lineWidth = w; c.stroke()
func ellipse(x: float, y: float, rx: float, ry: float, color: Variant) -> void:
	c.beginPath(); c.ellipse(x, y, maxf(0, rx), maxf(0, ry), 0, 0, TAU); c.fillStyle = color; c.fill()
func poly(points: Array, color: Variant, border: Variant = null, w: float = 2) -> void:
	c.beginPath()
	for i in range(points.size()):
		if i: c.lineTo(points[i][0], points[i][1])
		else: c.moveTo(points[i][0], points[i][1])
	c.closePath(); c.fillStyle = color; c.fill()
	if border: c.strokeStyle = border; c.lineWidth = w; c.lineJoin = "round"; c.stroke()
func heart(x: float, y: float, s: float, color: Variant, border: Variant = SHADOW) -> void:
	c.beginPath(); c.moveTo(x, y + s * .35); c.bezierCurveTo(x, y - s * .1, x - s * .6, y - s * .1, x - s * .6, y + s * .3); c.bezierCurveTo(x - s * .6, y + s * .65, x, y + s * .85, x, y + s)
	c.bezierCurveTo(x, y + s * .85, x + s * .6, y + s * .65, x + s * .6, y + s * .3); c.bezierCurveTo(x + s * .6, y - s * .1, x, y - s * .1, x, y + s * .35); c.fillStyle = color; c.fill(); c.strokeStyle = border; c.lineWidth = 2; c.stroke()
func easeT(t: float) -> float: return 1 - pow(1 - clampf(t, 0, 1), 3)
func back3(t: float) -> float:
	t = clampf(t, 0, 1); var s := 1.7; return 1 + (s + 1) * pow(t - 1, 3) + s * pow(t - 1, 2)
func pad7(n: float) -> String: return str(int(floor(maxf(0, n)))).pad_zeros(7)
func lerpk(a: float, b: float, k: float) -> float: return a + (b - a) * clampf(k, 0, 1)
func fl(x: float) -> int: return int(floor(x))
func W_(t: Texture2D) -> float: return float(t.get_width())
func H_(t: Texture2D) -> float: return float(t.get_height())

# ---------- sprites ----------
func bee(x: float, y: float, size: float, alpha: float = 1, flip: float = 1) -> void:
	c.save(); c.globalAlpha *= alpha; c.translate(x, y); c.scale(flip, 1); c.drawImage(tex.bee, 50, 130, 370, 320, -size / 2, -size * .8, size, size * .8); c.restore()
func hero(x: float, y: float, size: float, frame: int = 4, face: float = 1, alpha: float = 1, modular := false, sheet: Texture2D = null) -> void:
	var t: Texture2D = sheet if sheet else ((tex.bodyP if g.weapon == HG.PISTOL else tex.body) if modular else tex.hero); var w := W_(t) / 4; var h := H_(t) / 2
	c.save(); c.translate(x, y); c.scale(face, 1); c.globalAlpha *= alpha; c.drawImage(t, (frame % 4) * w, (frame / 4) * h, w, h, -size / 2, -size, size, size); c.restore()
func fishSprite(x: float, y: float, size: float, frame: int = 4, facing: float = -1, opts := {}) -> void:
	var im: Texture2D = tex.fishAnim; var cw := W_(im) / 4; var ch := H_(im) / 2
	c.save(); c.translate(x, y)
	if opts.get("rot"): c.rotate(opts.rot)
	c.scale((-1 if facing > 0 else 1) * (opts.get("sx") if opts.get("sx") else 1), opts.get("sy") if opts.get("sy") else 1)
	if opts.get("alpha") != null: c.globalAlpha *= opts.alpha
	if opts.get("filter"): c.filter = opts.filter
	c.drawImage(im, (frame % 4) * cw, (frame / 4) * ch, cw, ch, -size / 2, -size * opts.get("anchor", 1.0), size, size); c.restore()
# Source crop size of each weapon in the atlas, so icons can be fitted without squashing.
func weaponSize(i: int) -> Array:
	if i == 2: return [.95 * W_(tex.m4), .74 * H_(tex.m4)]
	var r: Array = [[.343, .21], [.349, .14], [.287, .21], [.351, .17], [.229, .23], [.166, .18]][i]
	return [r[0] * W_(tex.weapons), r[1] * H_(tex.weapons)]
func weaponFit(i: int, x: float, y: float, w: float, h: float) -> void:
	var s := weaponSize(i); var k := minf(w / s[0], h / s[1]); var dw: float = s[0] * k; var dh: float = s[1] * k
	weaponIcon(i, x + (w - dw) / 2, y + (h - dh) / 2, dw, dh)
func weaponIcon(i: int, x: float, y: float, w: float, h: float) -> void:
	if i == 2:
		var m: Texture2D = tex.m4; c.drawImage(m, .025 * W_(m), .16 * H_(m), .95 * W_(m), .74 * H_(m), x, y, w, h); return
	var r: Array = [[.01, .28, .343, .21], [.351, .319, .349, .14], [.709, .28, .287, .21], [.026, .59, .351, .17], [.438, .58, .229, .23], [.775, .61, .166, .18]][i]
	var im: Texture2D = tex.weapons
	c.drawImage(im, r[0] * W_(im), r[1] * H_(im), r[2] * W_(im), r[3] * H_(im), x, y, w, h)
func bossPart(i: int, x: float, y: float, w: float, h: float) -> void:
	var r: Array = [[.01, .015, .62, .61], [.63, .23, .365, .31], [.125, .645, .247, .34], [.45, .68, .545, .30]][i]
	var im: Texture2D = tex.bossParts
	c.drawImage(im, r[0] * W_(im), r[1] * H_(im), r[2] * W_(im), r[3] * H_(im), x, y, w, h)
func cell(im: Texture2D, i: int, x: float, y: float, size: float, o := {}) -> void:
	var cw := W_(im) / 4; var ch := H_(im) / 2
	var src: Array = o.get("src") if o.get("src") else [0, 0, 1, 1]
	var a: float = src[0]; var b: float = src[1]; var c2: float = src[2]; var d: float = src[3]
	var base: float = o.get("base") if o.get("base") != null else .5
	var cx: float = o.get("cx") if o.get("cx") != null else .5
	c.save(); c.translate(x, y)
	if o.get("rot"): c.rotate(o.rot)
	c.scale((-1 if o.get("flip") else 1) * (o.get("sx") if o.get("sx") else 1), o.get("sy") if o.get("sy") else 1)
	if o.get("alpha") != null: c.globalAlpha *= o.alpha
	if o.get("filter"): c.filter = o.filter
	c.drawImage(im, (i % 4 + a) * cw, (i / 4 + b) * ch, (c2 - a) * cw, (d - b) * ch, (a - cx) * size, (b - base) * size, (c2 - a) * size, (d - b) * size); c.restore()
# Captured honeybee: same character as honeybee.webp, tied with rope.
func powTied(x: float, y: float, size: float, rot: float = 0) -> void:
	c.save(); c.translate(x, y); c.rotate(rot); c.drawImage(tex.pow, -size / 2, -size * .9, size, size); c.restore()
func enemySprite(kind: String, x: float, y: float, S: float, o := {}) -> void:
	var oo := o.duplicate()
	if kind == "para":
		parachute(x, y, S, o); kind = str(o.get("body", "grunt")); oo.frame = 4
	oo.base = EBASE[kind]
	cell(tex["e_" + kind], int(oo.get("frame", 4)), x, y, S * ESCALE, oo)
func parachute(x: float, y: float, S: float, o := {}) -> void:
	var s := S * 1.7
	c.save(); c.translate(x, y)
	if o.get("rot"): c.rotate(o.rot)
	if o.get("alpha") != null: c.globalAlpha *= o.alpha
	c.drawImage(tex.chute, -s / 2, -S * .62 - s * .95, s, s); c.restore()
func enemyFrame(e) -> int:
	if e.get("flash", 0) > 0: return 7
	if e.get("warn") and e.kind != "hopper": return 5
	if e.get("kick", 0) > 0 or e.get("stab", 0) > 0 or e.get("launch", 0) > 0: return 6
	if e.get("air"): return 2
	if e.kind == "flyer": return fl(e.t * 12) % 4
	if e.kind == "turret": return fl(e.t * 2.5) % 4
	if e.get("walk") or e.state == "enter": return fl(e.t * (12 if e.kind == "hopper" else 8)) % 4
	return 4
func bgPanel(stage: int, x: float, y: float, w: float, h: float, crop: float = .66) -> void:
	var cw := W_(tex.bg) / 2; var ch := H_(tex.bg) / 2
	c.drawImage(tex.bg, (stage % 2) * cw, (stage / 2) * ch, cw, ch * crop, x, y, w, h)

# ---------- world ----------
func theme() -> Dictionary: return THEME[HG.STAGES[g.stage].theme]
## Camera x for the parallax layers: while the harbor ship sails, the scenery keeps streaming past.
func viewCam() -> float:
	return g.camera + (float(g.ship.get("sail", 0.0)) if g.ship else 0.0)
func background() -> void:
	var T := theme(); var grad := c.createLinearGradient(0, 0, 0, 576); grad.addColorStop(0, T.sky[0]); grad.addColorStop(1, T.sky[1]); c.fillStyle = grad; c.fillRect(-40, -40, 1360, 800)
	var blend := Motion.scenery(g.zones, g.bossStart, g.x)
	# Opaque base + smooth overlay; no tiled edges or transparent holes.
	zoneBackdrop(blend.from, 1.0)
	if blend.mix > 0: zoneBackdrop(blend.to, blend.mix)
	ambient(false)
func zoneBackdrop(index: int, alpha: float) -> void:
	# Independent full-resolution plates with mipmaps: no tiny atlas cells or neighbor bleed.
	var im: Texture2D = tex["scene_%s_%d" % [HG.STAGES[g.stage].theme, index]]
	var start: float = g.zones[index].start if index < g.zones.size() else g.bossStart
	var end: float = g.zones[index].end if index < g.zones.size() else start + 1600
	var pan := clampf((viewCam() - start + 640) / (end - start + 1280), 0, 1)
	c.save(); c.globalAlpha *= alpha
	c.drawImage(im, 0, 0, W_(im), H_(im), -40 - pan * 200, -32, 1560, 640); c.restore()
# Painted near-ground lip aligned to the collision floor.
func ground() -> void:
	var im: Texture2D = tex.groundInk; var a: Array = Motion.GROUND_ART[g.stage]; var x0: float = g.camera - 40; var w := 1360.0; var tw := 920.0
	var i := floori(x0 / tw)
	while i * tw < x0 + w:
		c.drawImage(im, a[0], a[1], a[2] - a[0], a[3] - a[1], i * tw - .5, HG.FLOOR - 6, tw + 1, 156)
		i += 1
func ambient(front: bool) -> void:
	var th: String = HG.STAGES[g.stage].theme; var t: float = g.time; c.save()
	for i in range(6 if front else 14):
		var s := float(i * 977 % 1000) / 1000
		var x := fmod(i * 173 + t * (60 if front else 24) * (-1 if th == "harbor" else 1), 1400.0); var y := 0.0
		if x < 0: x += 1400
		x -= 60
		if th == "town":
			y = fmod(i * 91 + t * (30 + s * 30), 760.0) - 40; c.globalAlpha = .85 if front else .6
			c.save(); c.translate(x, y); c.rotate(t * 2 + i); ellipse(0, 0, 7 if front else 5, 4 if front else 3, "#ffc1d6"); c.restore()
		elif th == "factory":
			y = fmod(i * 67 + t * (50 + s * 40), 760.0) - 40; c.globalAlpha = .5; ellipse(x, y, 3, 5, "#ffbf49")
		elif th == "harbor":
			if front: continue
			y = 90 + i * 13 % 120 + sin(t * 2 + i) * 8; c.globalAlpha = .65; line(x - 9, y, x, y + 5, "#4c5a68", 2); line(x, y + 5, x + 9, y, "#4c5a68", 2)
		else:
			y = 720 - fmod(i * 83 + t * (40 + s * 30), 760.0); c.globalAlpha = .7; circle(x, y, 3 if front else 2, "#ffb07a")
	c.restore()

func world() -> void:
	var sh: float = g.shake * g.shake * 24 * g.shakeScale; var sx: float = sin(g.time * 34) * sh; var sy: float = cos(g.time * 27) * sh * .7  # slow enough to read as a rumble, not per-frame jitter
	c.save(); c.translate(sx, sy); background(); c.translate(-g.camera, 0); ground()
	for h in g.hazards: drawHazard(h)
	if g.ship: drawShip(g.ship)
	for p in g.platforms:
		if p.x > g.camera - 350 and p.x < g.camera + 1400: drawPlatform(p)
	for p in g.props:
		if p.hp > 0: drawProp(p)
	for p in g.pows: drawPow(p)
	for it in g.items: drawItem(it)
	drawSupplies()
	drawBossZones()
	if g.boss and g.boss.get("started"): drawBoss()
	for e in g.enemies: drawEnemy(e)
	for k in g.corpses: drawCorpse(k)
	for b in g.bullets: drawBullet(b)
	drawPlayer()
	drawParticles()
	for b in g.blasts: drawBlast(b)
	for p in g.popups:
		var big = p.get("big", false)
		var a: float = 1 - p.t / (1.4 if big else .9); var y: float = p.y - p.t * (50 if big else 70)
		c.save(); c.globalAlpha = clampf(a * 2, 0, 1); outlined(p.text, p.x, y, 30 if big else 20, PINK if big else GOLD, SHADOW); c.restore()
	c.restore()
	c.save(); c.translate(sx, sy); ambient(true); c.restore()
	var v := c.createRadialGradient(640, 360, 380, 640, 360, 820); v.addColorStop(0, "#00000000"); v.addColorStop(1, "#3a1f2a40"); c.fillStyle = v; c.fillRect(0, 0, 1280, 720)

func waveY(x: float, y0: float) -> float: return y0 + sin(g.time * 2.4 + x * .045) * 3 + sin(g.time * 1.3 + x * .017) * 2
func waterSurface(x0: float, w: float, y0: float, flow: float) -> void:
	if w <= 0: return
	var top := []; var bot := []; var x := x0
	while x <= x0 + w + 15:
		var xx := minf(x, x0 + w); top.append([xx, waveY(xx, y0)]); bot.push_front([xx, waveY(xx, y0) + 12]); x += 15
	poly(top + bot, "#9fe3ec")
	for i in range(top.size() - 1): line(top[i][0], top[i][1], top[i + 1][0], top[i + 1][1], "#e9fbff", 3)
	for i in range(int(w / 70)):
		var gx := x0 + fposmod(i * 70 + 37 * i * i - g.time * flow, w); var gy := y0 + 22 + (i % 3) * 24
		line(gx, gy, gx + 18 + (i % 2) * 10, gy, "#d4f3f7", 3)
func drawHazard(h) -> void:
	if h.kind == "water":
		var grad := c.createLinearGradient(0, h.y, 0, 720); grad.addColorStop(0, "#5fc0cf"); grad.addColorStop(1, "#2f7f9c"); c.fillStyle = grad; c.fillRect(h.x, h.y, h.w, h.h)
		waterSurface(h.x, h.w, h.y, 160.0 if h.get("sea", false) else 24.0)  # the open sea streams past the ship
		if h.get("sea", false):
			for i in range(int(h.w / 90)):
				var sx: float = h.x + h.w - fmod(g.time * 220 + i * 90, h.w); line(sx, h.y + 46 + (i % 3) * 30, sx + 34, h.y + 46 + (i % 3) * 30, "#bfeaf2", 3)
	elif h.kind == "honey" or h.kind == "puddle":
		honeyPuddle(h)
	elif h.kind == "fire":
		firePatch(h)
	else:
		box(h.x, h.y - 2, h.w, 16, "#5c5566", 4, SHADOW, 2)
		for j in range(4): box(h.x + 8 + j * 23, h.y + 2, 12, 6, "#3d3744", 2)
		var on := fmod(g.time, 3.0) < 1.2; var warn := fmod(g.time, 3.0) > 2.5
		if warn:
			for j in range(4): circle(h.x + 14 + j * 23, h.y - 6 - randf() * 6, 4, "#ffffffaa")
		if on:
			for j in range(6):
				var yy: float = h.y - 20 - fmod(g.time * 160 + j * 30, 120.0)
				circle(h.x + h.w / 2 + sin(g.time * 9 + j) * 24, yy, 16 + j * 2, "rgba(255,235,220,%s)" % (.75 - j * .1))
# Harbor boss arena: the big ship the player fights from. Deck at floor level from ship.x to the stage end; the stern
# (left end) faces the boss. Hull, deckhouse, bridge, funnel and mast are drawn behind the actors.
func drawShip(s) -> void:
	var FLOOR: float = HG.FLOOR; var x0: float = s.x; var x1: float = HG.STAGES[g.stage].length + 80; var t: float = g.time
	var sailing: bool = g.boss != null and g.boss.get("started", false); var cx := x1 - 520
	# mast and flag
	line(cx + 260, FLOOR - 440, cx + 260, FLOOR - 340, "#5b3440", 6); line(cx + 214, FLOOR - 400, cx + 306, FLOOR - 400, "#5b3440", 4)
	var flap := sin(t * 7) * 7
	poly([[cx + 260, FLOOR - 440], [cx + 322, FLOOR - 428 + flap], [cx + 314, FLOOR - 418 + flap * .6], [cx + 260, FLOOR - 410]], "#ef7f9e", SHADOW, 3)
	# funnel with smoke
	if sailing:
		for i in range(6):
			var a := fmod(t * .8 + i / 6.0, 1.0); circle(cx + 395 - a * 260, FLOOR - 400 - a * 110, 18 + a * 30, "rgba(90,74,74,%s)" % (.42 * (1 - a)))
	box(cx + 360, FLOOR - 400, 74, 136, "#ef7f9e", 10, SHADOW, 3); box(cx + 360, FLOOR - 400, 74, 24, "#3a1f2a", 8)
	circle(cx + 397, FLOOR - 318, 17, GOLD); ring(cx + 397, FLOOR - 318, 17, SHADOW, 3); text("♥", cx + 397, FLOOR - 311, 18, "#ef7f9e", "center")
	# bridge: window band, roof, radar
	box(cx + 30, FLOOR - 340, 240, 96, "#fff8f5", 14, SHADOW, 3)
	box(cx + 44, FLOOR - 322, 212, 36, "#3f6f8f", 9, SHADOW, 2)
	for i in range(1, 5): line(cx + 44 + i * 42.4, FLOOR - 322, cx + 44 + i * 42.4, FLOOR - 286, SHADOW, 2)
	for i in range(5): line(cx + 54 + i * 42.4, FLOOR - 316, cx + 66 + i * 42.4, FLOOR - 298, "#bfeaf2", 3)
	box(cx + 18, FLOOR - 352, 264, 18, "#e2574c", 7, SHADOW, 3)
	line(cx + 90, FLOOR - 352, cx + 90, FLOOR - 384, "#5b3440", 4)
	var spin := sin(t * 3) * 22; box(cx + 90 - absf(spin), FLOOR - 394, absf(spin) * 2 + 4, 10, "#d9c6b8", 4, SHADOW, 2)
	# deckhouse: portholes, door, lifebuoy
	box(cx - 20, FLOOR - 250, 380, 246, "#f1e6dc", 16, SHADOW, 3); box(cx - 20, FLOOR - 250, 380, 16, "#d9c6b8", 8)
	for i in range(5):
		var px: float = cx + 26 + i * 72; circle(px, FLOOR - 186, 15, "#5fa9c2"); ring(px, FLOOR - 186, 15, SHADOW, 3); ring(px, FLOOR - 186, 11, "#fff8f5", 2); line(px - 6, FLOOR - 192, px + 2, FLOOR - 184, "#bfeaf2", 3)
	box(cx + 150, FLOOR - 128, 60, 124, "#d9c6b8", 10, SHADOW, 3); circle(cx + 198, FLOOR - 66, 4, SHADOW); box(cx + 162, FLOOR - 116, 36, 26, "#5fa9c2", 6, SHADOW, 2)
	var lb: float = cx + 60
	ring(lb, FLOOR - 104, 22, "#e2574c", 11); ring(lb, FLOOR - 104, 28, SHADOW, 2); ring(lb, FLOOR - 104, 16, SHADOW, 2)
	for k in range(4):
		var ang := k * PI / 2 + PI / 4; box(lb + cos(ang) * 22 - 5, FLOOR - 104 + sin(ang) * 22 - 5, 10, 10, "#fff8f5", 3)
	# cargo crates by the deckhouse
	cell(tex.items, ITEM.crate, cx - 80, FLOOR + 58, 84, {"base": .88}); cell(tex.items, ITEM.crate, cx - 160, FLOOR + 58, 84, {"base": .88}); cell(tex.items, ITEM.crate, cx - 120, FLOOR + 2, 84, {"base": .88})
	# railing
	var rx := x0 + 4
	while rx < x1:
		box(rx, FLOOR - 40, 6, 34, "#fff8f5", 2, SHADOW, 1); rx += 48
	line(x0 + 4, FLOOR - 40, x1, FLOOR - 40, "#fff8f5", 6); line(x0 + 4, FLOOR - 22, x1, FLOOR - 22, "#fff8f5", 4)
	# hull: rounded stern, white stripe, portholes, red waterline band, name
	poly([[x0 - 52, FLOOR - 8], [x1, FLOOR - 8], [x1, 720], [x0 + 46, 720], [x0 + 14, 694], [x0 - 18, 656], [x0 - 40, 612]], "#2f4a6b", SHADOW, 3)
	poly([[x0 - 38, 604], [x1, 604], [x1, 616], [x0 - 32, 616]], "#fff8f5")
	poly([[x0 + 20, 682], [x1, 682], [x1, 720], [x0 + 46, 720]], "#e2574c")
	var hx := x0 + 210
	while hx < x1:
		circle(hx, 646, 10, "#bfeaf2"); ring(hx, 646, 10, SHADOW, 3); hx += 96
	text("HONEY-1", x0 + 300, 654, 22, "#fff8f5", "left", DISPLAY)
	box(x0 - 52, FLOOR - 10, x1 - x0 + 52, 14, "#c79a6a", 4, SHADOW, 2)
	var pk := x0 - 20
	while pk < x1:
		line(pk, FLOOR - 8, pk, FLOOR + 2, "#a77d5a", 2); pk += 44
	# wake churning off the stern while under way
	if sailing:
		for i in range(10):
			var a2 := fmod(t * 1.3 + i * .1, 1.0); circle(x0 - 30 - a2 * 260, 604 + sin(i * 1.7) * 26 + a2 * 10, 12 + a2 * 22, "rgba(233,251,255,%s)" % (.85 * (1 - a2)))
# Walker stomps shake platforms; crane crates are temporary platforms that blink before vanishing.
func drawPlatform(p) -> void:
	if p.has("life") and p.life < 1.5 and fl(p.life * 10) % 2: return
	var sy: float = sin(g.time * 70) * 5 * p.get("shake", 0.0)
	c.save(); c.translate(0, sy); drawPlatformBody(p); c.restore()
func drawPlatformBody(p) -> void:
	if p.type == "crate":
		cell(tex.items, ITEM.crate, p.x + p.w / 2, p.y + 58, 84, {"base": .88}); return
	var th: String = HG.STAGES[g.stage].theme
	if p.type == "belt":
		box(p.x, p.y, p.w, 20, "#4d4450", 8, SHADOW, 3)
		var j := 0
		while j < p.w / 26.0:
			var xx: float = p.x + fmod(j * 26 + g.time * 95, p.w); line(xx, p.y + 5, xx + 10, p.y + 15, "#ffc94d", 3); j += 1
		circle(p.x + 10, p.y + 10, 7, "#8a8090"); circle(p.x + p.w - 10, p.y + 10, 7, "#8a8090"); return
	if p.type == "boat":
		poly([[p.x - 14, p.y + 10], [p.x + p.w + 14, p.y + 10], [p.x + p.w - 18, p.y + 58], [p.x + 18, p.y + 58]], "#c4573f", SHADOW, 3)
		box(p.x - 8, p.y, p.w + 16, 14, "#e8d3b0", 5, SHADOW, 3); line(p.x + 5, p.y + 28, p.x + p.w - 5, p.y + 28, "#fff3", 4)
		# the waterline: water laps over the lower hull, with foam at bow and stern
		var top := []; var x: float = p.x - 20
		while x <= p.x + p.w + 20:
			top.append([x, waveY(x, 571)]); x += 12
		c.save(); c.globalAlpha = .85; poly(top + [[p.x + p.w + 20, p.y + 64], [p.x - 20, p.y + 64]], "#5fc0cf"); c.restore()
		for i in range(top.size() - 1): line(top[i][0], top[i][1], top[i + 1][0], top[i + 1][1], "#e9fbff", 3)
		for s in [-1, 1]:
			var fx: float = p.x - 14 if s < 0 else p.x + p.w + 14
			for i in range(3): circle(fx + s * (i * 9 - 4), 572 + sin(g.time * 5 + i) * 2, 7 - i * 1.5, "#f4fdff")
		return
	var col: String = {"town": "#79b38d", "factory": "#c98b4b", "harbor": "#9b6b47", "fortress": "#7d7690"}[th]
	box(p.x + 4, p.y + 8, p.w, p.h, "#3a1f2a33", 8)
	if th == "harbor" or th == "factory":
		for lx in [p.x + 20, p.x + p.w - 28]: box(lx, p.y + 10, 10, HG.FLOOR - p.y - 10, "#7a5236" if th == "harbor" else "#8b8494", 3, SHADOW, 2)
	else:
		line(p.x + 24, p.y + 18, p.x + 24, p.y + 60, "#5f7863", 8); line(p.x + p.w - 24, p.y + 18, p.x + p.w - 24, p.y + 60, "#5f7863", 8)
	box(p.x, p.y, p.w, p.h, col, 7, SHADOW, 3); line(p.x + 8, p.y + 5, p.x + p.w - 8, p.y + 5, "#ffffff66", 3)
func drawProp(p) -> void:
	ellipse(p.x, p.y + 3, 32, 6, "#3a1f2a33")
	var shake: float = sin(g.time * 90) * 3 if p.get("flash", 0) > 0 else 0.0
	cell(tex.items, ITEM[p.kind], p.x + shake, p.y, 84 if p.kind == "barrel" else 78, {"base": .88, "filter": "brightness(1.8)" if p.get("flash", 0) > 0 else null})
func drawPow(p) -> void:
	var bob := sin(p.t * 5) * 3
	if p.state == "leave":
		c.save(); c.globalAlpha = clampf(1 - p.t / 2.5, 0, 1); bee(p.x, p.y - 30 + sin(p.t * 14) * 4, 64, 1, -1); c.restore(); return
	if p.state == "thanks":
		var j := absf(sin(p.t * 10)) * 14; bee(p.x, p.y - j, 70); bubble(p.x, p.y - 104, "고마워요!", TEAL); return
	ellipse(p.x, p.y + 3, 30, 6, "#3a1f2a33")
	# A honeybee freed from a broken cage is no longer tied up: it just waits, bobbing, for the hero to come over.
	if p.state == "tied" and p.kind == "cage":
		bee(p.x, p.y + 2 - absf(sin(p.t * 4)) * 6, 84); return
	if p.state == "tied":
		powTied(p.x, p.y + 4, 92, sin(p.t * 3) * .05); bubble(p.x, p.y - 96 + bob, "HELP!", HOT); return
	# Caged honeybee: one illustrated cage sprite (pow_cage.png, feet line at 403/420 of the image).
	c.save()
	if p.get("flash", 0) > 0: c.filter = "brightness(1.6)"
	c.translate(p.x, p.y + 4); c.rotate(sin(p.t * 3) * .015); c.drawImage(tex.cage, -56, -112 * 403.0 / 420, 112, 112); c.restore(); bubble(p.x, p.y - 122 + bob, "HELP!", HOT)
func bubble(x: float, y: float, s: String, color: Variant) -> void:
	c.font = "15px " + DISPLAY; var w: float = c.measureText(s).width + 18
	box(x - w / 2, y - 18, w, 26, PAPER, 13, color, 2); poly([[x - 6, y + 7], [x + 6, y + 7], [x, y + 14]], PAPER); text(s, x, y, 15, color, "center", DISPLAY)
func drawItem(it) -> void:
	if it.life < 3 and fl(it.t * 10) % 2: return
	var y: float = it.y - (absf(sin(it.t * 4)) * 4 if it.get("grounded") else 0.0)
	ellipse(it.x, it.y + 2, 22, 5, "#3a1f2a33")
	if it.kind == "support":
		c.save(); c.shadowColor = "#bff8e0"; c.shadowBlur = 20; bee(it.x, y - 4, 58); c.restore(); return
	var size := 76.0 if it.kind == "weapon" else 62.0
	if it.kind == "weapon":
		c.save(); c.globalCompositeOperation = "lighter"; circle(it.x, y - 30, 34 + sin(it.t * 6) * 4, "#fff3a033"); c.restore()
	cell(tex.items, ITEM[it.kind], it.x, y, size, {"base": .88})
	if it.kind == "weapon": outlined(HG.WEAPONS[it.weapon].letter, it.x + .04 * size, y - .26 * size + 11, 30, HOT, SHADOW, "center", 5)
func drawEnemy(e) -> void:
	var S: float = HG.ENEMIES[e.kind].size; var t: float = e.t; var walk: bool = bool(e.get("walk")) or e.state == "enter"; var para: bool = e.state == "para"
	if e.kind != "flyer" and not para and not e.get("air"): ellipse(e.x, e.y + 3, S * .4, 7, "#3a1f2a2e")
	# The sheet frames carry the walk cycle; keep only a light squash so poses still breathe.
	var bob := absf(sin(t * 10)) * 2 if walk else sin(t * 3) * 1.0; var beat := sin(t * (10 if walk else 3))
	var sx := 1 + beat * (.015 if walk else .012); var sy := 1 - beat * (.015 if walk else .012); var rot := beat * .02 if walk else 0.0; var dx := 0.0
	if e.get("kick", 0) > 0: sx *= 1.08; sy *= .92; dx = e.facing * -6
	if e.get("warn") and e.kind != "hopper": sx *= .96; sy *= 1.04; rot += sin(g.time * 40) * .03
	if e.get("air") or e.get("launch", 0) > 0: sy *= 1.08; sx *= .94; rot = -e.facing * .2
	if e.kind == "shield" and e.get("peek", 0) > 0: rot += e.facing * .12
	var filter = "brightness(1.8)" if e.get("flash", 0) > 0 else null; var flip: bool = e.facing > 0; var frame := enemyFrame(e)
	if para: enemySprite("para", e.x, e.y, S, {"flip": flip, "filter": filter, "rot": sin(t * 2) * .08, "body": e.kind})
	elif e.kind == "turret":
		enemySprite("turret", e.x, e.y, S, {"flip": flip, "filter": filter, "frame": frame, "sx": 1.05 if e.get("kick", 0) > 0 else 1.0})
		box(e.x - 36, e.y - 128, 72, 8, "#3a1f2a66", 4); box(e.x - 36, e.y - 128, 72.0 * e.hp / e.max, 8, HOT, 4)
	else: enemySprite(e.kind, e.x + dx, e.y - (sin(t * 6) * 4 if e.kind == "flyer" else bob), S, {"flip": flip, "filter": filter, "sx": sx, "sy": sy, "rot": rot, "frame": frame})
	var top: float = e.y - S * (1.1 if e.kind == "turret" else .85)
	if e.get("warn") and e.kind != "hopper": outlined("!", e.x, top - 8 + sin(g.time * 30) * 2, 28, HOT, SHADOW)
	if e.get("startle", 0) > 0: outlined("!?", e.x, top - 12 - (.4 - e.startle) * 30, 24, GOLD, SHADOW)
func drawCorpse(k) -> void:
	if k.life < .5 and fl(k.life * 20) % 2: return
	var blast: bool = k.style == "explosion"; var grounded: bool = k.vy == 0; var s: float = 0.0 if blast else float(k.get("settle", 0))
	enemySprite(k.kind, k.x, k.y, k.size, {"frame": 7, "flip": k.facing > 0, "rot": k.rot + k.facing * .25 * s, "sx": 1 + .06 * s, "sy": 1 - .14 * s, "filter": "brightness(.5) saturate(.6)" if blast else "brightness(1.05) saturate(.85)", "alpha": clampf(k.life * 2, 0, 1)})
	if not blast and grounded:
		for i in range(3):
			var a: float = g.time * 6 + i * 2.1; text("★", k.x + cos(a) * 22, k.y - k.size * .6 + sin(a) * 7, 12, GOLD, "center")
func drawBullet(b) -> void:
	var FLOOR: float = HG.FLOOR
	if b.kind == "spray":
		c.save(); c.globalAlpha = minf(1, b.life * 2); circle(b.x, b.y, 9, "#ffbf49"); ring(b.x, b.y, 9, "#c47a17", 2); circle(b.x - 3, b.y - 3, 3, "#fff4c8"); c.restore(); return
	if b.kind == "fire":
		c.save(); c.translate(b.x, b.y); c.rotate(g.time * 10); circle(0, 0, 16, "#ff8a3d"); ring(0, 0, 16, SHADOW, 3); circle(-4, -4, 7, "#ffe08a"); c.restore()
		c.save(); c.globalCompositeOperation = "lighter"; circle(b.x, b.y, 26, "#ff6a2a44"); c.restore(); return
	if b.kind == "crate":
		line(b.x, b.y - 200, b.x, b.y, "#7a5a3a", 3); cell(tex.items, ITEM.crate, b.x, b.y + 56, 80, {"base": .88}); return
	if b.kind == "grenade":
		c.save(); c.translate(b.x, b.y); c.rotate(b.get("spin", 0)); ellipse(0, 0, 9, 11, "#5d7a52"); ring(0, 0, 10, SHADOW, 2.5); box(-4, -15, 8, 6, "#3d3540", 2); c.restore(); return
	if b.kind == "lob" or b.kind == "honey":
		c.save(); c.translate(b.x, b.y); c.rotate(g.time * 8); box(-12, -14, 24, 28, "#f3a531", 7, SHADOW, 3); box(-8, -18, 16, 6, "#c47a17", 3); c.restore(); return
	if b.kind == "bomb":
		circle(b.x, b.y, 10, "#3d3540"); ring(b.x, b.y, 10, SHADOW, 2); line(b.x, b.y - 10, b.x + 4, b.y - 16, GOLD, 3); circle(b.x + 5, b.y - 17, 3 + randf() * 2, "#ffdf7a"); return
	if b.kind == "shell2":
		circle(b.x, b.y, 13, "#3d3540"); ring(b.x, b.y, 13, SHADOW, 3); circle(b.x - 4, b.y - 4, 4, "#ffffff55"); return
	if b.kind == "wave":
		c.save(); c.globalAlpha = .85
		for i in range(3): ellipse(b.x - signf(b.vx) * i * 16, FLOOR - 10 - i * 4, 22 - i * 5, 18 - i * 4, "#efe2cfaa" if i else "#fff8e8")
		c.restore(); return
	if not b.friendly:
		var big: bool = b.kind == "shell"; var r := 11.0 if big else 8.0
		c.save(); c.globalCompositeOperation = "lighter"; circle(b.x, b.y, r + 7, "#ff6f9140"); c.restore(); circle(b.x, b.y, r, "#ff6f91"); ring(b.x, b.y, r, SHADOW, 2.5); circle(b.x - 2, b.y - 2, r * .4, PAPER); return
	var len := Vector2(b.vx, b.vy).length()
	if len == 0: len = 1
	var dx: float = b.vx / len; var dy: float = b.vy / len
	var wi = b.get("weapon"); var col: String = "#9bf4ce" if b.kind == "support" else HG.WEAPONS[wi if wi != null else 0].color
	if b.kind == "rocket":
		c.save(); c.translate(b.x, b.y); c.rotate(atan2(dy, dx)); box(-18, -6, 32, 12, "#7a8a5a", 5, SHADOW, 2); poly([[14, -6], [24, 0], [14, 6]], "#d9573f", SHADOW, 2)
		c.globalCompositeOperation = "lighter"; circle(-24, 0, 9 + randf() * 4, "#ffab62aa"); circle(-22, 0, 5, "#fff5be"); c.restore(); return
	var trail := 90.0 if b.kind == "sniper" else 14.0 if b.kind == "smg" else 12.0 if b.kind == "pistol" else 28.0
	c.save(); c.globalCompositeOperation = "lighter"; line(b.x - dx * trail, b.y - dy * trail, b.x, b.y, col + "66", 9 if b.kind == "sniper" else 7); c.restore()
	line(b.x - dx * trail * .6, b.y - dy * trail * .6, b.x, b.y, col, 3 if b.kind == "sniper" else 3.5); circle(b.x, b.y, 3.5 if b.kind == "pistol" else 3.0, PAPER)
# Metal Slug style victory loop: jump + fist pump, V-sign, wave (8 frames, top row baseline 1.0, bottom .958).
# Flat sticker-style honey puddle: wobbly mounded top, thick outline, glossy dabs and slow bubbles.
func honeyPuddle(h: Dictionary) -> void:
	var a: float = clampf(h.life, 0, 1) if h.get("life") != null else 1.0
	var x0: float = h.x; var x1: float = h.x + h.w; var top: float = h.y + 9; var base: float = h.y + 15
	var n: int = maxi(2, roundi(h.w / 34.0)); var seg: float = (h.w - 12) / n
	c.save(); c.globalAlpha = a; ellipse((x0 + x1) / 2, base + 2, h.w / 2 + 8, 5, "#3a1f2a22")
	for d in [[-9.0, 4.0], [h.w + 8.0, 3.5], [h.w + 17.0, 2.4]]:
		ellipse(x0 + d[0], base - 1, d[1] * 1.5, d[1], "#ffc23d"); c.beginPath(); c.ellipse(x0 + d[0], base - 1, d[1] * 1.5, d[1], 0, 0, PI * 2); c.strokeStyle = "#7a3b22"; c.lineWidth = 2.5; c.stroke()
	c.beginPath(); c.moveTo(x0 + 2, base); c.quadraticCurveTo(x0 - 5, top + 5, x0 + 6, top)
	for j in range(n):
		var bump: float = 2.2 + (j % 3) * .9 + sin(g.time * 2.2 + j * 1.7) * .7
		c.quadraticCurveTo(x0 + 6 + (j + .5) * seg, top - bump * 2, x0 + 6 + (j + 1) * seg, top)
	c.quadraticCurveTo(x1 + 5, top + 5, x1 - 2, base); c.quadraticCurveTo((x0 + x1) / 2, base + 5, x0 + 2, base); c.closePath()
	c.fillStyle = "#ffc23d"; c.fill(); c.strokeStyle = "#7a3b22"; c.lineWidth = 3; c.lineJoin = "round"; c.stroke()
	ellipse((x0 + x1) / 2, base - 1, h.w / 2 - 12, 1.8, "#f59a1e")
	for j in range(n):
		var cx: float = x0 + 6 + (j + .5) * seg; ellipse(cx - 4, top + 1, minf(8, seg * .24), 1.8, "#fff4c8")
		var p: float = fmod(g.time * .7 + j * .43, 1.0)
		if p < .45:
			var r: float = 1.5 + p * 7
			c.save(); c.globalAlpha *= 1 - p / .45; circle(cx + seg * .22, top + 3 - p * 6, r, "#ffe08a"); ring(cx + seg * .22, top + 3 - p * 6, r, "#7a3b22", 1.5); c.restore()
	c.restore()
func victoryPose(x: float, y: float, size: float, face: float = 1, speed: float = 7) -> void:
	# frames 0-3 are a hop: lift follows one smooth arc over them instead of stepping per frame
	var ff := fmod(g.time * speed, 8.0); var f := int(ff); var lift: float = maxf(0, sin(PI * (ff - .5) / 3)) * .3 * size if ff < 3.5 else 0.0
	cell(tex.victory, f, x, y - lift, size, {"base": 1.0 if f < 4 else .958, "flip": face < 0})
func drawPlayer() -> void:
	var FLOOR: float = HG.FLOOR
	if g.y < -150: return
	if g.mode == "celebrate" and g.dying <= 0 and g.grounded:
		ellipse(g.x, minf(FLOOR, g.y) + 4, 30, 6, "#3a1f2a40"); victoryPose(g.x, minf(FLOOR, g.y), 108, g.face); return
	var frame: int = HG.playerFrame(g); var blink: bool = g.invincible > 0 and g.dying <= 0 and fl(g.stageTime * 18) % 2 == 0; var alpha := .35 if blink else 1.0
	ellipse(g.x, minf(FLOOR, g.y) + 4, 30 * (1.0 if g.grounded else .7), 6, "#3a1f2a40")
	if g.dying > 0:
		c.save(); c.translate(g.x, g.y - 50); c.rotate(-g.face * (1.4 - g.dying) * 1.2); c.globalAlpha = .5 if fl(g.dying * 12) % 2 else 1.0; hero(0, 50, 108, 7, g.face, 1, true); c.restore(); return
	var squash: float = 1 - g.landed * 1.2 if g.landed > 0 else 1.0
	c.save(); c.translate(g.x, g.y); c.scale(1 / maxf(.85, squash) * (1.05 if g.landed > 0 else 1.0), squash); c.translate(-g.x, -g.y)
	var pose: Dictionary = HG.weaponPose(g); leanShift.x = 0.0; leanShift.y = 0.0
	var held := false; var lean := 0.0; var px := 0.0; var py := 0.0
	if g.knife > 0: punchPose(alpha)
	elif g.throwT > 0: throwPose(alpha)
	elif pose.up:
		var run: bool = pose.get("sheet") == "upRun"; var im: Texture2D = tex.upRun if run else tex.aim; var f: int = pose.sheetFrame if run else pose.aimFrame
		var w := W_(im) / 4; var h := H_(im) / (3 if run else 2)
		c.save(); c.translate(g.x + pose.bx, g.y + pose.by); c.scale(g.face, 1); c.globalAlpha = alpha; c.drawImage(im, (f % 4) * w, (f / 4) * h, w, h, -54, -108, 108, 108); c.restore()
	else:
		# Front-facing aim on the way up: lean the body back so head and gun rise together; the gun follows the hands.
		lean = g.face * pose.aim.y * .18 if pose.aim.y < 0 else 0.0; px = g.x + pose.bx; py = g.y + pose.by - 38
		leanShift.x = (pose.x - px) * (cos(lean) - 1) - (pose.y - py) * sin(lean); leanShift.y = (pose.x - px) * sin(lean) + (pose.y - py) * (cos(lean) - 1)
		bodyFrame(pose, frame, alpha, lean, px, py, false)
		# after the gun the hands sheet goes on top so her fists close over it (only near level aim, see bodyFrame)
		held = g.weapon != HG.PISTOL and absf(pose.aim.y) < .35
	if g.knife > 0:
		var t: float = 1 - g.knife / .22
		if t > .2 and t < .8:
			var k := (t - .2) / .6; c.save(); c.globalAlpha = alpha * (1 - k); c.translate(g.x + g.face * 48, g.y - 60); c.rotate(k * .6)
			for i in range(8):
				var a := i * PI / 4; var r0 := 10 + k * 14; var r1 := r0 + 12 + (i % 2) * 8
				line(cos(a) * r0, sin(a) * r0, cos(a) * r1, sin(a) * r1, GOLD if i % 2 else PAPER, 4)
			c.restore()
	elif g.throwT <= 0:
		drawGun(alpha, held)
		if held: bodyFrame(pose, frame, alpha, lean, px, py, true)
		drawMuzzle()
	c.restore()
	if g.y < 0:
		for i in range(5): circle(g.x + sin(g.time * 20 + i) * 20, maxf(10, g.y) - i * 24, 4, "#fff6c8aa")
	if g.support > 0:
		var bx: float = g.x - g.face * 75; var by: float = g.y - 100 + sin(g.time * 7) * 7
		c.save(); c.shadowColor = "#bff8e0"; c.shadowBlur = 16; bee(bx, by, 56, 1, -g.face); c.restore()
		box(bx - 26, by - 60, 52, 6, "#3a1f2a55", 3); box(bx - 26, by - 60, 52 * g.support / 22, 6, "#7fe0b3", 3)
# Melee punch (generated/hero_punch.png, 4 frames in a row facing right: wind-up, punch, impact, recover; feet at 88%, body centre at 45%).
func punchPose(alpha: float) -> void:
	var t: float = 1 - g.knife / .22; var f := 0 if t < .18 else (1 if t < .5 else (2 if t < .78 else 3))
	var im: Texture2D = tex.punch; var w := W_(im) / 4; var S := 126.0
	c.save(); c.translate(g.x, g.y); c.scale(g.face, 1); c.globalAlpha = alpha; c.drawImage(im, f * w, 0, w, H_(im), -S * .45, -S * .88, S, S); c.restore()
# Grenade throw on the punch sheet: wind-up with the grenade cocked in the back hand, the arm snaps forward at release, recover.
func throwPose(alpha: float) -> void:
	var t: float = 1 - g.throwT / HG.THROW_TIME; var f := 0 if t < .32 else (1 if t < .66 else 3)
	var im: Texture2D = tex.punch; var w := W_(im) / 4; var S := 126.0
	c.save(); c.translate(g.x, g.y); c.scale(g.face, 1); c.globalAlpha = alpha; c.drawImage(im, f * w, 0, w, H_(im), -S * .45, -S * .88, S, S)
	if f == 0: circle(-22, -44, 8, "#5d6b3c"); ring(-22, -44, 8, SHADOW, 2.5); box(-25, -56, 6, 6, GOLD, 1)
	c.restore()
# Rifle body frame (run sheet while running, body sheet otherwise), leaned back for upward aim. With hands = true it
# redraws the same frame from the hands sheet, which holds only her fists, so they close over the gun drawn in between.
func bodyFrame(pose: Dictionary, frame: int, alpha: float, lean: float, px: float, py: float, hands: bool) -> void:
	c.save(); c.translate(px, py); c.rotate(lean); c.translate(-px, -py)
	if frame < 4 and g.grounded and not g.crouch:
		var rf := fl(g.stageTime * 15) % 8; var im: Texture2D = tex.runHands if hands else (tex.runP if g.weapon == HG.PISTOL else tex.run); var w := W_(im) / 4; var h := H_(im) / 2
		c.save(); c.translate(g.x + pose.bx, g.y + pose.by); c.scale(g.face, 1); c.globalAlpha = alpha; c.drawImage(im, (rf % 4) * w, (rf / 4) * h, w, h, -54, -108, 108, 108); c.restore()
	else: hero(g.x + pose.bx, g.y + pose.by, 108, frame, g.face, alpha, true, tex.bodyHands if hands else null)
	c.restore()
func drawGun(alpha: float, held := false) -> void:
	var p: Dictionary = HG.weaponPose(g); c.save(); c.translate(p.x + leanShift.x, p.y + leanShift.y); c.rotate(p.angle); c.scale(p.face, 1); c.globalAlpha = alpha
	weaponIcon(g.weapon, -p.width * p.grip, -p.height * .48, p.width, p.height)
	# Without the hands layer, small hands sit in front of the receiver/foregrip so the weapon is held rather than pasted over arms.
	if not held:
		ellipse(0, p.height * .18, 3.2, 3.8, "#ffe9df")
		if g.weapon != 5: ellipse(minf(p.width * .28, 19), p.height * .12, 3.4, 3.5, "#ffe9df")
	c.restore()
func drawMuzzle() -> void:
	if g.muzzle <= 0: return
	var p: Dictionary = HG.weaponPose(g); var v: Dictionary = HG.VISUALS[g.lastShotWeapon]; var f: float = g.muzzle / .09
	var cols := ["#ffd079", "#fff1c0", "#beeaff", "#ffa662", "#ffc5e5", "#ffe3a7"]; var col: String = cols[g.lastShotWeapon]
	c.save(); c.translate(p.mx + leanShift.x, p.my + leanShift.y); c.rotate(atan2(p.aim.y, p.aim.x)); c.globalCompositeOperation = "lighter"; c.globalAlpha = f; circle(4, 0, v.flash * .9, col + "55")
	var len: float = v.flash * (1.2 + f)
	poly([[-3, -4], [len * .45, -v.flash * .45], [len * .36, -3], [len, 0], [len * .36, 3], [len * .45, v.flash * .45], [-3, 4]], col); circle(3, 0, 5, PAPER); c.restore()
func drawParticles() -> void:
	for p in g.particles:
		var a := clampf(p.life / p.max, 0, 1)
		var kind = p.get("kind")
		if kind == "bossdebris":
			bossDebrisDraw(p, a); continue
		if kind == "fish":
			fishSprite(p.x, p.y, p.size * 2, fl(g.time * 8 + p.size) % 4, 1 if p.vx > 0 else -1, {"rot": p.get("rot", 0), "anchor": .5}); continue
		if kind == "armor" or kind == "casing" or kind == "debris":
			var rot = p.get("rot", 0)
			c.save(); c.translate(p.x, p.y); c.rotate(rot if rot else p.life * 8); c.globalAlpha = minf(1, a * 2)
			box(-p.size / 2.0, -p.size / 3.0, p.size, p.size * .62, p.color, 1 if kind == "casing" else 3, null if kind == "casing" else SHADOW, 1.5); c.restore(); continue
		if kind == "smoke":
			c.save(); c.globalAlpha = a * .55; circle(p.x, p.y, p.size, p.color); c.restore(); continue
		if kind == "flash":
			c.save(); c.globalCompositeOperation = "lighter"; c.globalAlpha = a; circle(p.x, p.y, p.size * (1.2 - a * .4), "#fff6d0"); c.restore(); continue
		c.save(); c.globalAlpha = a; circle(p.x, p.y, p.size * (.4 + a * .6), p.color); c.restore()
func drawBlast(b) -> void:
	var t: float = b.t / b.max; var f := mini(7, fl(t * 8)); var size: float = b.r * 2.3
	c.save()
	if t < .15:
		c.globalAlpha = 1 - t / .15; c.globalCompositeOperation = "lighter"; circle(b.x, b.y, b.r * .8, "#fff6d0"); c.globalCompositeOperation = "source-over"
	c.globalAlpha = 1; ring(b.x, b.y, b.r * (.3 + t * 1.1), "rgba(255,240,200,%s)" % (.7 * (1 - t)), 8 * (1 - t) + 1)
	c.restore()
	cell(tex.boom, f, b.x, b.y, size, {"base": .56, "rot": fmod(b.x, 7.0) * .1, "alpha": (1 - t) / .15 if t > .85 else 1.0})
func _rgba_red(a: float) -> String: return "rgba(255,60,95,%s)" % a
# Telegraph: where the locked-in boss attack will hit, shown for the whole windup.
func drawBossZones() -> void:
	var b = g.boss; var FLOOR: float = HG.FLOOR
	if not b or not b.get("started") or b.get("dead") or b.state != "windup" or not b.get("zones"): return
	var p := .5 + .5 * sin(g.time * 18)
	c.save()
	for z in b.zones:
		if z.kind == "cone":
			var r: float = z.get("r", 1500.0); c.beginPath(); c.moveTo(z.x, z.y); c.arc(z.x, z.y, r, z.angle - z.spread / 2, z.angle + z.spread / 2); c.closePath()
			var gr := c.createRadialGradient(z.x, z.y, 20, z.x, z.y, r); gr.addColorStop(0, _rgba_red(.32 + .12 * p)); gr.addColorStop(1, _rgba_red(0)); c.fillStyle = gr; c.fill()
			for e in [-1, 1]:
				var a: float = z.angle + e * z.spread / 2; var rl := minf(r, 900); line(z.x, z.y, z.x + cos(a) * rl, z.y + sin(a) * rl, _rgba_red(.55 + .3 * p), 3)
		elif z.kind == "spot":
			ellipse(z.x, FLOOR + 2, z.r, z.r * .3, _rgba_red(.22 + .18 * p)); c.beginPath(); c.ellipse(z.x, FLOOR + 2, z.r, z.r * .3, 0, 0, TAU); c.strokeStyle = _rgba_red(.8); c.lineWidth = 3; c.setLineDash([10, 8]); c.stroke(); c.setLineDash([])
			c.fillStyle = _rgba_red(.07 + .05 * p); c.fillRect(z.x - z.r * .6, 0, z.r * 1.2, FLOOR); outlined("!", z.x, FLOOR - z.r * .3 - 14 - p * 6, 26, "#ff5f7e", SHADOW, "center", 5)
		elif z.kind == "lane":
			var x0: float = z.x if z.dir > 0 else g.camera - 40; var x1: float = g.camera + 1320 if z.dir > 0 else z.x
			c.fillStyle = _rgba_red(.2 + .15 * p); c.fillRect(x0, FLOOR - 28, x1 - x0, 28)
			var x: float = z.x
			while (x < x1 if z.dir > 0 else x > x0):
				outlined("▶" if z.dir > 0 else "◀", x + z.dir * 20, FLOOR - 6, 20, "#ff5f7e", SHADOW, "center", 4); x += z.dir * 70
		elif z.kind == "drop":
			ellipse(z.x, FLOOR + 2, 46, 12, _rgba_red(.25 + .15 * p)); outlined("▼", z.x, FLOOR - 70 - p * 12, 30, "#ff5f7e", SHADOW, "center", 5)
	c.restore()
func bossSprite(sheet: String, i: int, x: float, y: float, size: float, o := {}) -> void:
	var q := Motion.boss_art(sheet, i); var a: Array = q.source; var d: Array = q.dest; var k := size / 512
	c.save(); c.translate(x, y); c.rotate(o.get("rot", 0.0)); c.scale(o.get("sx", 1.0), o.get("sy", 1.0))
	if o.get("filter"): c.filter = o.filter
	c.drawImage(tex["boss_" + sheet], a[0], a[1], a[2] - a[0], a[3] - a[1], (d[0] - 512 * o.get("cx", .5)) * k, (d[1] - 512 * o.get("base", .5)) * k, (d[2] - d[0]) * k, (d[3] - d[1]) * k); c.restore()

func driveSprite(i: int, x: float, y: float, w: float, h: float, rot: float = 0) -> void:
	var a: Array = Motion.DRIVE_ART[i]; c.save(); c.translate(x, y); c.rotate(rot)
	c.drawImage(tex.driveParts, a[0], a[1], a[2] - a[0], a[3] - a[1], -w/2, -h/2, w, h); c.restore()

func trackFace(x: float, y: float, w: float, r: float, distance: float) -> void:
	for i in range(ceili(r * 2 / 13)):
		var v := -r + fposmod(-distance, 13) + i * 13
		if v >= r: continue
		var edge := sqrt(maxf(0, 1 - v*v/(r*r)))
		driveSprite(2, x + 4*(1-edge), y + v, w*(.55+.45*edge), 9)

func trackSidePoint(distance: float) -> Dictionary:
	var p := Motion.tread_point(distance, 200, 40); var t := clampf(p.x / 200, 0, 1)
	return {"x": p.x * .72, "y": p.y * (1 - .24*t) - p.x * .09, "visible": p.y > 0 or p.x > 200}

func drawBossTracks(b: Dictionary, r: Dictionary) -> void:
	# The choco tank sheet paints its own treads and fish wheels; only the cannon still gets the animated overlay.
	if b.type != "cannon": return
	var d: Array = Motion.boss_art(r.sheet, 0).dest; var w: float = d[2] - d[0]; var h: float = d[3] - d[1]
	var distance: float = b.get("track", 0.0) * (-1 if b.flip else 1) / r.k * 400 / w
	c.save(); c.translate(b.x + (d[0] - 256) * r.k, b.y + (d[1] - 512 * r.base) * r.k); c.scale(w * r.k / 400, h * r.k / 360)
	var cy := 310.0 if b.type == "cannon" else 306.0; var total := 400 + 80 * PI
	for i in range(40):
		var t := i * total / 40 + distance / .72; var p := trackSidePoint(t)
		if not p.visible: continue
		var q := trackSidePoint(t + .2); driveSprite(1, 224 + p.x, cy + p.y, 14, 8, atan2(q.y - p.y, q.x - p.x))
	trackFace(36, cy - 12, 40, 34, distance); trackFace(164, cy, 58, 43, distance)
	for wheel in [[0,0,29,40],[56,-6,25,36],[102,-12,23,33],[145,-18,20,30]]:
		c.save(); c.translate(224 + wheel[0], cy + wheel[1]); c.scale(wheel[2], wheel[3]); c.rotate(distance / wheel[3]); driveSprite(0, 0, 0, 2, 2); c.restore()
	c.restore()

func drawBossBody(b: Dictionary, r: Dictionary, flash: Variant) -> void:
	c.save()
	if b.dead:
		c.translate(b.x, b.y); c.scale(1, 1 - .32 * clampf(b.get("sink", 0.0) / .35, 0, 1)); c.translate(-b.x, -b.y)
	bossSprite(r.sheet, 1 if b.phase == 2 or b.dead else 0, b.x, b.y, 512 * r.k, {"base": r.base, "filter": flash})
	c.save()
	if flash: c.filter = flash
	drawBossTracks(b, r); c.restore(); c.restore()

func drawStoryTank(x: float, y: float, travel: float) -> void:
	var r: Dictionary = HG.BOSS_RIG.tank.duplicate(); r.k = .94
	var S: float = 512 * r.k; var b := {"type": "tank", "x": x, "y": y, "track": travel, "flip": false, "phase": 1, "dead": false}
	drawBossBody(b, r, null)
	for pname in ["B", "A"]:
		var P: Dictionary = r[pname]
		bossSprite("tank", 2 if pname == "A" else 4, x + (P.u - .5) * S, y + (P.v - r.base) * S, S * P.ps, {"cx": P.pu, "base": P.pv, "rot": P.get("rot", 0.0)})
func drawBoss() -> void:
	var b = g.boss; var r: Dictionary = HG.BOSS_RIG[b.type]; var S: float = 512.0 * r.k; var im: Texture2D = tex["boss_" + r.sheet]; var k: float = b.get("sink", 0.0); var FLOOR: float = HG.FLOOR
	var flash = "brightness(1.18)" if b.get("flash", 0) > 0 else null
	var pose := Motion.boss_pose(b); var ox: float = pose.x; var oy: float = pose.y; var rot: float = pose.rot; var sx: float = pose.sx; var sy: float = pose.sy; var alpha := 1.0
	if b.dead and b.get("burst", false): alpha = maxf(0, 1 - (HG.CELEBRATE_BURST - g.celebrate) / 1.2)
	if alpha <= 0: return
	var h: Dictionary = g.bossBox()
	if b.type != "boat" and not b.air: ellipse(b.x, FLOOR + 4, h.w * .48, 14, "#3a1f2a40")
	elif b.air: ellipse(b.x, FLOOR + 4, h.w * .3, 9, "#3a1f2a30")
	var mir := -1.0 if b.get("flip", false) else 1.0  # left-side bosses are drawn mirrored; rig points inside are raw
	c.save(); c.globalAlpha *= alpha; c.translate(b.x + ox * mir, b.y + oy); c.rotate(rot * mir); c.scale(sx * mir, sy); c.translate(-b.x, -b.y)
	# hatch pops out of the body while open
	var hc: Dictionary = b.hatch
	if hc.open > 0 and not b.dead:
		var P: Dictionary = r.H; var o: Dictionary = g.bossBodyPt(P.u, P.v, true); var pop := clampf(minf((1.6 - hc.open) / .25, hc.open / .25), 0, 1)
		bossSprite(r.sheet, 6, o.x, o.y + (1 - pop) * 40, S * P.ps, {"cx": P.pu, "base": P.pv, "sy": .4 + .6 * pop})
	drawBossBody(b, r, flash)
	if b.phase == 2 and not b.dead:
		var o2: Dictionary = g.bossBodyPt(r.core[0], r.core[1], true); var pulse := .5 + .5 * sin(g.time * 8)
		c.save(); c.globalCompositeOperation = "lighter"; circle(o2.x, o2.y, 34 + pulse * 14, "rgba(255,190,70,%s)" % (.25 + .25 * pulse)); circle(o2.x, o2.y, 16 + pulse * 6, "#fff2b099"); c.restore()
		for i in range(4):
			var a := fmod(b.t * .8 + i * .25, 1.0); circle(o2.x + 30 + i * 14, o2.y - 60 - a * 110, 10 + a * 18, "rgba(90,74,74,%s)" % (.45 * (1 - a)))
	for pname in ["B", "A"]:
		if b.dead and k > .35: continue
		var P: Dictionary = r[pname]; var p: Dictionary = b.parts[pname]; var pv: Dictionary = g.bossBodyPt(P.u, P.v, true)
		var pr: float = p.ang + P.get("rot", 0.0); var px: float = pv.x + p.recoil * 6; var py: float = pv.y
		if not p.dead:
			if b.type == "boat" and pname == "B": pr += sin(b.t * 1.5) * .08 + (-.2 if b.state == "attack" and b.pattern == 1 else 0.0)
			if b.type == "cannon" and pname == "A": pr += (-.12 if b.state == "windup" and b.pattern == 0 else 0.0) + sin(b.t * 2) * .02
			if b.type == "king" and pname == "B": pr += -.15 if b.state == "windup" and b.pattern == 1 else 0.0
		var idx := (3 if p.dead else 2) if pname == "A" else (5 if p.dead else 4)
		bossSprite(r.sheet, idx, px, py, S * P.ps, {"cx": P.pu, "base": P.pv, "rot": pr, "filter": "brightness(1.25)" if p.flash > 0 else flash})
		if not p.dead and p.recoil > .6:
			var m: Dictionary = g.bossMuzzle(pname, true); c.save(); c.globalCompositeOperation = "lighter"; circle(m.x, m.y, 26 * p.recoil, "#ffdf9b99"); circle(m.x, m.y, 12 * p.recoil, "#fff6da"); c.restore()
		if p.dead and not b.dead:
			var mb: Dictionary = g.bossPartBox(pname, true)
			for i in range(2):
				var a2 := fmod(b.t * .9 + i * .5, 1.0); circle(mb.x + mb.w * .5 + i * 12, mb.y + mb.h * .3 - a2 * 90, 8 + a2 * 14, "rgba(80,64,64,%s)" % (.5 * (1 - a2)))
	c.restore()
	if b.type == "boat":
		c.save(); c.globalAlpha = .9
		for i in range(12): line(b.x - 300 + i * 52, FLOOR + 6 + sin(g.time * 3 + i) * 4, b.x - 266 + i * 52, FLOOR + 6 + sin(g.time * 3 + i + 1) * 4, "#e9fbff", 4)
		c.restore()
	if b.get("warn") and not b.get("dead"):
		var m: Dictionary = g.bossMouth()
		var lbl: String = {"king": ["기관포 연사!", "미사일 폭격!", "점프 압살!"], "cannon": ["꿀 박격포!", "꿀 화염방사!", "돌진!"], "boat": ["함포 사격!", "크레인 투하!", "상륙 부대!"], "tank": ["주포 발사!", "개틀링 난사!", "전진 압박!"]}[b.type][b.pattern]
		bubble(clampf(m.x, g.camera + 120, g.camera + 1160), maxf(150, h.y - 30), lbl, HOT)
		c.save(); c.globalCompositeOperation = "lighter"; circle(m.x, m.y, 18 + sin(g.time * 6) * 4, "#ff6f9188"); c.restore()
# Supply bees from the boss hatch: a honeybee carrying a crate that drops an item near the player.
func drawSupplies() -> void:
	for s in g.supplies:
		var flip := 1 if s.state == "leave" else (1 if s.tx < s.x else -1); var bob := sin(s.t * 10) * 3
		if not s.dropped:
			line(s.x, s.y + bob + 4, s.x, s.y + bob + 22, "#b0814f", 3); cell(tex.items, ITEM.get(s.item, ITEM.crate), s.x, s.y + bob + 56, 46, {"base": .88})
		bee(s.x, s.y + bob, 62, 1, flip)
func bossDebrisDraw(p, a: float) -> void:
	var im: Texture2D = tex.get("boss_" + str(p.get("sheet", "")))
	if im == null: return
	var cw := W_(im) / 4; var ch := H_(im) / 2; var q: int = int(p.get("chunk", 0)) % 4
	c.save(); c.translate(p.x, p.y); c.rotate(p.get("rot", 0)); c.globalAlpha = minf(1, a * 2)
	c.drawImage(im, 3 * cw + (q % 2) * cw / 2, ch + (q / 2) * ch / 2, cw / 2, ch / 2, -p.size, -p.size, p.size * 2, p.size * 2); c.restore()
func firePatch(h) -> void:
	var a := clampf(h.get("life", 1.0), 0, 1); c.save(); c.globalAlpha = a; ellipse(h.x + h.w / 2, h.y + 8, h.w / 2, 7, "#5a2a1a88")
	for j in range(5):
		var fx: float = h.x + 12 + j * (h.w - 24) / 4; var f := sin(g.time * 14 + j * 1.7); var hh := 26 + f * 8
		poly([[fx - 12, h.y + 8], [fx, h.y + 8 - hh], [fx + 12, h.y + 8]], "#ff8a3d", SHADOW, 2); poly([[fx - 6, h.y + 8], [fx, h.y + 8 - hh * .55], [fx + 6, h.y + 8]], "#ffe08a")
	c.restore()

# ---------- HUD ----------
func hud() -> void:
	# Player card: bottom-left (lifted above the arms card when the touch pad owns that corner)
	var touchUI: bool = touchMode and settings.touch != "off"
	c.save()
	if touchUI: c.translate(470 - 14, 538 - 12)
	else: c.translate(0, 608 - 12)
	box(14, 12, 340, 100, "#fff8f5ee", 22, "#f2c4cf", 2)
	circle(62, 62, 38, PINK); ring(62, 62, 38, SHADOW, 3); c.drawImage(tex.profileRound, 28, 28, 68, 68)  # pre-cut round badge (the canvas shim can only clip rectangles)
	box(108, 22, 40, 22, HOT, 11); text("1P", 128, 39, 15, PAPER, "center", DISPLAY)
	text(pad7(g.score), 158, 42, 26, INK, "left", DISPLAY)
	var maxHp: int = dif().hp
	for i in range(maxHp): heart(118 + i * 26, 56, 18, HOT if i < g.hp else "#f3dfe3")
	box(270, 58, 72, 26, "#5b3440dd", 13); text("LIFE", 284, 76, 12, PINK, "left", DISPLAY); text("×" + str(maxi(0, g.lives)), 335, 77, 16, PAPER, "right", DISPLAY)
	box(108, 88, 234, 6, "#f3dfe3", 3)
	if g.combo > 1: box(108, 88, 234 * clampf(g.comboTimer / 2.8, 0, 1), 6, GOLD, 3)
	c.restore()
	# Arms card: bottom centre
	var pop: float = 1 + sin(g.weaponPop * 20) * .04 * g.weaponPop if g.weaponPop > 0 else 1.0
	c.save(); c.translate(640, 677); c.scale(pop, pop); c.translate(-170, -31); box(0, 0, 340, 62, "#fff8f5ee", 20, "#f2c4cf", 2)
	box(10, 8, 104, 46, PINK, 14); weaponFit(g.weapon, 16, 12, 92, 38)
	var ammo: int = g.ammo[g.weapon]
	text("ARMS", 126, 24, 12, "#a8707f", "left", DISPLAY); text("∞" if ammo < 0 else str(ammo), 126, 50, 24, HOT if ammo > 0 and ammo < 20 else INK, "left", DISPLAY)
	text("BOMB", 214, 24, 12, "#a8707f", "left", DISPLAY); text(str(g.grenades), 214, 50, 24, INK if g.grenades else HOT, "left", DISPLAY)
	if g.unlocked.size() > 1: box(282, 14, 48, 34, "#5b3440dd", 12); text("Q", 306, 37, 16, PAPER, "center", DISPLAY); text("교체", 306, 58, 10, "#a8707f", "center")
	c.restore()
	# Hi-score and pause
	box(970, 12, 212, 58, "#fff8f5ee", 20, "#f2c4cf", 2); text("HI-SCORE", 990, 34, 12, "#a8707f", "left", DISPLAY); text(pad7(maxf(g.best, g.score)), 1166, 58, 22, INK, "right", DISPLAY)
	circle(1229, 51, 26, "#fff8f5ee"); ring(1229, 51, 26, "#f2c4cf", 2); box(1219, 40, 7, 22, INK, 2); box(1232, 40, 7, 22, INK, 2)
	# Rescued tally: bottom-right (top-left when the touch buttons own that corner)
	if g.stageRescued > 0:
		var tw: float = 46 + g.stageRescued * 36; var tx: float = 14.0 if touchUI else 1266 - tw; var ty := 12.0 if touchUI else 668.0
		box(tx, ty, tw, 40, "#fff8f5dd", 20); text("POW", tx + 12, ty + 26, 12, "#a8707f", "left", DISPLAY)
		for i in range(g.stageRescued): bee(tx + 62 + i * 36, ty + 32, 32)
	# Combo
	if g.combo >= 2:
		var s: float = 1 + maxf(0, g.comboTimer - 2.4) * .8; c.save(); c.translate(1250, 210); c.scale(s, s); outlined(str(g.combo), 0, 0, 46, GOLD, SHADOW, "right"); outlined("COMBO", 0, 26, 18, PAPER, SHADOW, "right"); c.restore()
	if g.lock and g.lock.get("zone") != null and fl(g.time * 2) % 2 == 0: outlined("◀", 30, 380, 30, "#ffffffaa", SHADOW); outlined("▶", 1250, 380, 30, "#ffffffaa", SHADOW)
	if ui.goT > 0 and fl(ui.goT * 4) % 2 == 0: outlined("GO! ▶", 1150, 330 + sin(g.time * 8) * 6, 48, GOLD, SHADOW)
	if touchUI: touchControls()
func touchControls() -> void:
	c.save(); c.globalAlpha = .85; circle(PAD.x, PAD.y, PAD.r, "#fff8f544"); ring(PAD.x, PAD.y, PAD.r, "#ffffff99", 3)
	var held := heldSet(); var dir := {"left": [-1, 0], "right": [1, 0], "up": [0, -1], "down": [0, 1]}
	for k in dir: outlined({"left": "◀", "right": "▶", "up": "▲", "down": "▼"}[k], PAD.x + dir[k][0] * 46, PAD.y + dir[k][1] * 46 + 8, 22, HOT if held.has(k) else PAPER, SHADOW)
	circle(PAD.x, PAD.y, 22, "#ffd8d9cc")
	for b in BTN:
		circle(b.x, b.y + 4, b.r, "#3a1f2a33"); circle(b.x, b.y, b.r, HOT if held.has(b.a) else "#fff8f5dd"); ring(b.x, b.y, b.r, "#f2c4cf", 3); text(b.label, b.x, b.y + 5, 18 if b.r > 45 else 13, INK, "center", DISPLAY)
	text("×" + str(g.grenades), 1072, 505, 13, PAPER, "center", DISPLAY); c.restore()

# ---------- cinematics ----------
func cinematics() -> void:
	if g.mode == "play" and g.intro > 0:
		var t: float = 2.6 - g.intro; var o: float = g.intro / .4 if g.intro < .4 else 1.0; c.save(); c.globalAlpha = o
		var s1 := back3(t / .35); var s2 := back3((t - .35) / .35)
		box(0, 250, 1280, 150, "#3a1f2acc", 0)
		for i in range(26): box(fmod(i * 64 + g.time * 120, 1400.0) - 80, 250, 32, 6, PINK, 0)
		for i in range(26): box(fmod(fmod(i * 64 - g.time * 120, 1400.0) + 1400, 1400.0) - 80, 394, 32, 6, PINK, 0)
		outlined("MISSION %d" % (g.stage + 1), -400 + 1040 * s1, 335, 74, PINK, SHADOW, "center", 10)
		if t > .35: outlined("START!", 1680 - 680 * s2, 372, 46, GOLD, SHADOW, "center", 8)
		c.restore()
	var b = g.boss
	if b and b.get("started") and b.state == "enter" and not b.get("dead"):
		var on := fl(g.time * 5) % 2 == 0; c.save(); c.fillStyle = "#ff4d6d22"; c.fillRect(0, 0, 1280, 720)
		box(0, 240, 1280, 130, "#3a1f2add", 0)
		for i in range(20):
			var q := fmod(i * 90 + g.time * 200, 1500.0)
			poly([[q - 120, 240], [q - 80, 240], [q - 120, 280], [q - 160, 280]], "#ffc94d")
		if on: outlined("WARNING!!", 640, 340, 76, "#ff6f91", SHADOW, "center", 10)
		outlined(HG.BOSSES[b.type].title + " 접근 중", 640, 362, 18, PAPER, SHADOW, "center", 4); c.restore()
	if g.callout and (g.mode == "play" or g.mode == "celebrate") and not (b and b.state == "enter"):
		var t: float = g.callout.t; var s := back3(t / .25); var o := maxf(0, 1 - (t - 1.3) / .3) if t > 1.3 else 1.0
		c.save(); c.globalAlpha = o; c.translate(640, 320 if g.mode == "celebrate" else 236); c.scale(s, s); c.rotate(-.03)
		var big := 50.0 if g.callout.text.length() > 14 else 62.0; outlined(g.callout.text, 0, 0, big, PINK if g.mode == "celebrate" else GOLD, SHADOW, "center", 9)
		if g.callout.get("sub"): outlined(g.callout.sub, 0, 34, 20, PAPER, SHADOW, "center", 5)
		c.restore()
	if g.mode == "play" and g.bannerTime > 0 and not g.intro:
		# Big outlined banner, no panel: headline pops in, the part after " · " sits under it; enemy alerts in red-pink.
		var parts: PackedStringArray = g.banner.split(" · ", true, 1); var alarm: bool = parts[0].contains("적") or parts[0].contains("부대")
		var s := back3(minf(1, (g.bannerMax - g.bannerTime) / .3))
		c.save(); c.globalAlpha = minf(1, g.bannerTime * 3); c.translate(640, 176); c.scale(s, s)
		outlined(parts[0], 0, 0, 40, "#ff6f91" if alarm else GOLD, SHADOW, "center", 9)
		if parts.size() > 1: outlined(parts[1], 0, 32, 20, PAPER, SHADOW, "center", 5)
		c.restore()
	if g.mode == "celebrate":
		if g.celebrate < .8: c.save(); c.globalAlpha = minf(1, (.8 - g.celebrate) * 2); c.fillStyle = "#fff8f5"; c.fillRect(0, 0, 1280, 720); c.restore()

# ---------- screens ----------
func panelCard(x: float, y: float, w: float, h: float) -> void: box(x + 6, y + 10, w, h, "#3a1f2a33", 30); box(x, y, w, h, PAPER, 30, "#f2c4cf", 3)
func menuList(items: Array, x: float, y: float, w: float, gap: float = 58, size: float = 24) -> void:
	ui.hits = []
	for i in range(items.size()):
		var it: Dictionary = items[i]; var sel: bool = i == ui.index; var yy := y + i * gap; var bob := sin(g.time * 8) * 2 if sel else 0.0
		ui.hits.append({"x": x, "y": yy - gap * .4, "w": w, "h": gap * .82, "i": i})
		if sel:
			box(x + 4, yy - gap * .38 + 6, w, gap * .78, "#e7a7b866", gap * .39); box(x, yy - gap * .38, w, gap * .78, PINK, gap * .39, HOT, 3); outlined("▶", x + 26 + bob, yy + size * .36, size * .8, HOT, PAPER, "center", 4)
		var color := "#c9b1b7" if it.get("locked") else INK
		text(it.label + ("  🔒" if it.get("locked") else ""), x + 52, yy + size * .36, size, color, "left", DISPLAY)
		if it.get("value") != null:
			var val: String = it.value
			var font: String = BODY if "■" in val else DISPLAY
			var vs := size * .9; var vright := x + w - 26; var base := yy + size * .36; c.font = "%spx %s" % [vs, font]
			# Value sits in a chip so it reads clearly against the paper panel; adjustable rows always show their ◀ ▶ arrows.
			var vw: float = c.measureText(val).width; var aw: float = c.measureText("◀  ").width if it.has("adjust") else 0.0; var cx := vright - aw - vw - 12
			box(cx, yy - vs * .72, vw + 24, vs * 1.44, HOT if sel else "#f9cdd8", vs * .72, SHADOW if sel else "#e89bb0", 2)
			text(val, vright - aw, base, vs, PAPER if sel else INK, "right", font)
			if it.has("adjust"):
				text("◀", cx - 6, base, vs * .8, HOT if sel else "#c27088", "right", DISPLAY); text("▶", vright, base, vs * .8, HOT if sel else "#c27088", "right", DISPLAY)
			# Pointer targets for adjustable rows (registered even when not selected, so a single tap works on touch):
			# ◀ lowers, ▶ raises, and tapping a volume bar sets that level directly. They go first so they win over the row.
			if it.has("adjust"):
				c.font = "%spx %s" % [vs, font]
				var right := vright; var full: float = c.measureText("◀  " + val + "  ▶").width; var arrow: float = c.measureText("◀  ").width; var barw: float = c.measureText(val).width
				var hh := gap * .82; var top := yy - gap * .4
				ui.hits.push_front({"x": right - arrow, "y": top, "w": arrow + 16, "h": hh, "i": i, "dir": 1})
				ui.hits.push_front({"x": right - full - 10, "y": top, "w": arrow + 10, "h": hh, "i": i, "dir": -1})
				if it.has("setTo"): ui.hits.push_front({"x": right - arrow - barw, "y": top, "w": barw, "h": hh, "i": i, "bar": [right - arrow - barw, right - arrow]})
# Logo intro (plays once each time the title is entered, then holds still): the rounded (Jua) letters of
# "허니츄러스와" drop in one by one and settle upright on one baseline, then the "과메기단의 습격" warning plate slams down
# with a shake (the plate only, the title stays put) and a debris burst, and finally the honeybee flies in.
func logoLetters(s: String, x: float, y: float, size: float, depth: int, gap: float, start: float, t: float) -> Array:
	c.font = "%spx %s" % [size, BODY]; var out := []; var cx := x
	for i in range(s.length()):
		var ch := s[i]; var w: float = c.measureText(ch).width
		var p := clampf((t - start - i * .09) / .42, 0, 1); var side := 1.0 if i % 2 else -1.0
		out.append({"ch": ch, "w": w, "size": size, "depth": depth, "a": clampf(p * 5, 0, 1), "x": cx + w / 2, "y": y - (1 - back3(p)) * 120, "r": (1 - easeT(p)) * side * .12}); cx += w + gap
	return out
func _letterBegin(l: Dictionary) -> void:
	c.save(); c.globalAlpha *= l.a; c.translate(l.x, l.y); c.rotate(l.r); c.font = "%spx %s" % [l.size, BODY]
func drawLetters(L: Array, fill: Variant, rim: Variant) -> void:
	L = L.filter(func(l): return l.a > 0)
	c.textAlign = "center"; c.textBaseline = "alphabetic"; c.lineJoin = "round"
	# Passes run across all letters so a neighbour's rim never covers another letter's face.
	for l in L:
		_letterBegin(l); c.strokeStyle = PAPER; c.lineWidth = l.size * .34
		for d in range(l.depth, -1, -3): c.strokeText(l.ch, 0, d)
		c.restore()
	for l in L:
		_letterBegin(l); c.strokeStyle = SHADOW; c.lineWidth = l.size * .16; c.fillStyle = SHADOW
		for d in range(l.depth, 0, -3): c.strokeText(l.ch, 0, d); c.fillText(l.ch, 0, d)
		c.strokeText(l.ch, 0, 0); c.restore()
	for l in L:
		_letterBegin(l); c.fillStyle = rim; c.fillText(l.ch, 0, 0); c.fillStyle = fill; c.fillText(l.ch, 0, l.size * .05); c.restore()
func sparkle(x: float, y: float, r: float, color: Variant) -> void:
	poly([[x, y - r], [x + r * .28, y - r * .28], [x + r, y], [x + r * .28, y + r * .28], [x, y + r], [x - r * .28, y + r * .28], [x - r, y], [x - r * .28, y - r * .28]], color)
# Yellow/black caution tape; stripe corners are clamped to the tape so nothing pokes out of its ends.
func hazardTape(x: float, y: float, w: float, h: float) -> void:
	box(x, y, w, h, GOLD, 4)
	var sx := x
	while sx < x + w + h:
		poly([[clampf(sx, x, x + w), y], [clampf(sx + 14, x, x + w), y], [clampf(sx + 14 - h, x, x + w), y + h], [clampf(sx - h, x, x + w), y + h]], SHADOW); sx += 28
	box(x, y, w, h, "#ffffff00", 4, SHADOW, 3)
# "과메기단의 습격" as a red warning plate with torn ends over crossed caution tape; h = seconds since it started to fall;
# its right end lines up with the end of "와".
func raidBadge(h: float, right: float) -> void:
	if h <= 0: return
	var s1 := "과메기단의 "; var s2 := "습격"; c.font = "36px %s" % BODY; var t1: float = c.measureText(s1).width; c.font = "46px %s" % BODY; var t2: float = c.measureText(s2).width
	var W := 100 + t1 + t2; var x0 := right - W; var y0 := 44.0; var y1 := 110.0; var x1 := right; var cx := x0 + W / 2; var cy := (y0 + y1) / 2
	var p := clampf(h / .18, 0, 1); var sc := 2.4 - 1.4 * p * p; var imp := h - .18
	c.save(); c.translate(cx, cy); c.rotate(.06)
	if imp > 0 and imp < .45:
		var k := imp / .45; c.save(); c.globalAlpha *= 1 - k
		for i in range(14):
			var a := i / 14.0 * PI * 2; var r0 := W * .42 + k * 70; var r1 := r0 + 12 + 46 * (1 - k)
			poly([[cos(a - .05) * r0, sin(a - .05) * r0 * .45], [cos(a) * r1, sin(a) * r1 * .45], [cos(a + .05) * r0, sin(a + .05) * r0 * .45]], GOLD if i % 2 else PAPER)
		c.restore()
	c.globalAlpha *= p; c.scale(sc, sc); c.translate(-cx, -cy)
	c.save(); c.translate(cx, cy + 6); c.rotate(-.1); hazardTape(-W / 2 - 46, -12, W + 92, 24); c.restore()
	var L := [[x0, y0], [x0 + 12, y0 + 16], [x0 - 2, y0 + 33], [x0 + 12, y0 + 50], [x0, y1]]; var pts := L.duplicate()
	for j in range(L.size() - 1, -1, -1): pts.append([x0 + x1 - L[j][0], L[j][1]])
	var shade := []
	for q in pts: shade.append([q[0] + 6, q[1] + 8])
	poly(shade, "#3a1f2a55"); poly(pts, "#d8344c", SHADOW, 5); box(x0 + 18, y0 + 7, W - 36, 6, "#ff6b80", 3)
	var tx := x0 + 42; var ty := cy + 2; poly([[tx, ty - 20], [tx + 21, ty + 15], [tx - 21, ty + 15]], GOLD, SHADOW, 4); text("!", tx, ty + 12, 24, SHADOW, "center", DISPLAY)
	outlined(s1, x0 + 74, cy + 13, 36, PAPER, SHADOW, "left", 8, BODY); outlined(s2, x0 + 74 + t1, cy + 16, 46, GOLD, SHADOW, "left", 9, BODY)
	c.restore()
func titleLogo(s: float) -> void:
	var imp := s - 1.13; var shake := 1 - imp / .35 if imp > 0 and imp < .35 else 0.0
	c.save()
	var big := logoLetters("허니츄러스", 0, 8, 112, 14, 0, 0, s); var last: Dictionary = big[big.size() - 1]
	var wa := logoLetters("와", last.x + last.w / 2 + 2, 8, 80, 10, 0, .45, s)
	drawLetters(big + wa, HOT, "#ffd0dc")
	var w1: float = wa[0].x + wa[0].w / 2
	c.save(); c.translate(sin(s * 95) * 6 * shake, cos(s * 80) * 4 * shake); raidBadge(s - .95, w1); c.restore()
	var sx := [w1 + 28, w1 - 30, -16.0]; var sy := [-8.0, -96.0, -72.0]; var sr := [12.0, 9.0, 10.0]
	for i in range(3):
		var k := back3((s - 1.2 - i * .12) / .3)
		if k > 0: sparkle(sx[i], sy[i], sr[i] * k, PAPER if i == 1 else GOLD)
	var bp := easeT((s - 1.4) / .6)
	if bp > 0: bee(w1 + 30 + (1 - bp) * 560, -58 + sin(s * 3) * 4 * bp, 76)
	c.restore()
func title() -> void:
	var t: float = g.time
	# Layered menu scene: clean background, jealous gwamegi peeking from behind the tree, Honey Churros hugging a honeybee.
	var zoom := 1.02 + sin(t * .24) * .006; c.save(); c.translate(640, 360); c.scale(zoom, zoom); c.translate(-640, -360)
	c.drawImage(tex.menuBg, 0, 0, 1280, 720)
	# One jealous gwamegi slides out from behind the trunk to glare, then ducks back; the complete opaque tree is drawn over the character against a tree-free meadow.
	var out := clampf(sin(t * .8) * 1.8 + .4, 0, 1); var fs := 200.0
	c.drawImage(tex.menuFish, 1028 + 142 * (1 - out), 488 - .81 * fs + sin(t * 3) * 1.5, fs, fs)
	c.drawImage(tex.menuTree, 0, 0, 1280, 720)
	var breathe := sin(t * 2) * .012; c.save(); c.translate(850, 724); c.scale(1 - breathe * .4, 1 + breathe); c.drawImage(tex.menuGirl, -250, -476, 500, 500); c.restore()
	bee(860, 308 - breathe * 470 + sin(t * 3) * 2, 96)
	c.restore()
	for i in range(8):
		var x := fmod(i * 211 + t * 12, 1400.0) - 60; var y := fmod(i * 97 + t * 18, 780.0) - 40
		c.save(); c.globalAlpha = .4; c.translate(x, y); c.rotate(t * .5 + i); ellipse(0, 0, 7, 4, "#ffc1d6"); c.restore()
	var small: bool = not (ui.screen in ["main", "stages"]); c.save(); c.translate(62, 120 if small else 180); c.scale(.62 if small else 1.0, .62 if small else 1.0)
	titleLogo(t - ui.titleAt); c.restore()
	if ui.screen == "main": panelCard(48, 300, 440, 324); menuList(menu(), 68, 346, 400, 56, 24)
	elif ui.screen == "stages": panelCard(48, 280, 520, 410); text("스테이지 선택", 78, 322, 20, "#a8707f", "left", DISPLAY); menuList(menu(), 68, 370, 480, 58, 22)
	elif ui.screen == "settings": panelCard(48, 226, 640, 474); text("설정", 78, 266, 22, "#a8707f", "left", DISPLAY); menuList(menu(), 68, 312, 600, 42, 20)
	elif ui.screen == "howto": howto()
	elif ui.screen == "records": recordsScreen()
	text("v1.0", 1250, 24, 13, "#c9a2ad", "right", DISPLAY)
func keycap(k: String, x: float, y: float, w: float = 40) -> void:
	box(x, y - 24, w, 32, PAPER, 8, "#c9a2ad", 2); box(x, y + 4, w, 4, "#c9a2ad", 2); text(k, x + w / 2, y - 1, 15, INK, "center", DISPLAY)
func howto() -> void:
	panelCard(48, 230, 1184, 460); outlined("조작 방법", 90, 288, 30, INK, PAPER, "left", 6)
	var rows := [[["←", "→"], "이동"], [["↑", "↓"], "조준 (위 · 공중에서 아래)"], [["Z"], "사격 · 적에게 붙으면 나이프"], [["X", "Space"], "점프 (길게 누르면 높이)"], [["C"], "수류탄"], [["Q"], "무기 교체"], [["Esc"], "일시정지"], [["M"], "소리 켜기/끄기"]]
	for i in range(rows.size()):
		var x := 90.0 + (560.0 if i >= 4 else 0.0); var y := 350.0 + (i % 4) * 62; var kx := x
		for k in rows[i][0]:
			var w := 78.0 if k.length() > 2 else 42.0; keycap(k, kx, y, w); kx += w + 8
		text(rows[i][1], x + 150, y, 19, INK)
	box(90, 600, 1100, 62, PINK, 18); text("TIP  철창을 쏴서 부수고 허니비에게 다가가면 무기와 보급품을 줘요. 무기를 다 쓰면 권총으로 돌아가요.", 112, 638, 17, INK)
	text("게임패드 지원: A 점프 · X 사격 · B 수류탄 · Y 교체 · START 일시정지", 90, 684, 14, "#a8707f")
	ui.hits = []
func recordsScreen() -> void:
	panelCard(48, 230, 700, 460); outlined("명예의 전당", 90, 288, 30, INK, PAPER, "left", 6)
	if records.is_empty(): text("아직 기록이 없어요. 첫 기록을 세워 보세요!", 90, 360, 20, "#a8707f")
	for i in range(records.size()):
		var r: Dictionary = records[i]; var y := 350.0 + i * 60
		box(80, y - 34, 640, 50, PINK if i == 0 else "#fff1f3", 16); outlined(str(i + 1), 112, y, 28, HOT if i == 0 else INK, PAPER, "center", 5); text(pad7(r.score), 150, y, 26, INK, "left", DISPLAY)
		text(("ALL CLEAR" if r.get("clear") else "MISSION " + str(int(r.stage))) + " · " + str(HG.DIFFICULTY.get(r.get("dif", ""), {}).get("label", "")), 390, y - 2, 16, "#a8707f"); text(r.get("date", ""), 700, y - 2, 14, "#c9a2ad", "right")
	ui.hits = []
func overlayDim(a: float = .55) -> void: c.fillStyle = "rgba(58,31,42,%s)" % a; c.fillRect(0, 0, 1280, 720)
func pauseScreen() -> void:
	overlayDim(.6)
	if ui.screen == "settings": panelCard(300, 110, 680, 520); outlined("설정", 640, 170, 34, INK, PAPER, "center", 6); menuList(menu(), 330, 230, 620, 48, 20); return
	panelCard(390, 150, 500, 420); outlined("PAUSE", 640, 222, 52, HOT, SHADOW, "center", 8); text("MISSION %d · %s" % [g.stage + 1, HG.STAGES[g.stage].name], 640, 256, 16, "#a8707f", "center")
	menuList(menu(), 420, 312, 440, 62, 24)
	text("R 미션 재시작 · M 소리", 640, 548, 14, "#a8707f", "center")
func briefing() -> void:
	var t: float = g.briefTime if g.briefTime else 0.0; var S: Dictionary = HG.STAGES[g.stage]; var L: Dictionary = HG.LEVELS[g.stage]
	c.fillStyle = "#3a1f2a"; c.fillRect(0, 0, 1280, 720)
	c.save(); c.globalAlpha = .85; bgPanel(g.stage, -fmod(t * 12, 60.0), 0, 1400, 720, .7); c.restore()
	overlayDim(.45)
	var s := easeT(t / .5)
	c.save(); c.translate(-300 * (1 - s), 0); box(0, 160, 760, 400, "#fff8f5f2", 0); box(0, 160, 16, 400, HOT, 0)
	outlined("MISSION %d" % (g.stage + 1), 60, 250, 80, HOT, SHADOW, "left", 12); outlined(S.name, 64, 316, 40, INK, PAPER, "left", 6); text(S.sub, 66, 356, 19, "#7b5a63")
	for i in range(S.zones.size()):
		var y := 400.0 + i * 26; circle(76, y - 6, 9, PINK); text(str(i + 1), 76, y, 12, INK, "center", DISPLAY); text(S.zones[i], 96, y, 17, INK)
	text("TARGET", 440, 410, 13, "#a8707f", "left", DISPLAY); text(HG.BOSSES[L.boss].name, 440, 438, 22, INK, "left", DISPLAY); text(HG.BOSSES[L.boss].title, 440, 462, 15, "#a8707f")
	text("난이도 " + dif().label, 440, 500, 15, "#a8707f")
	var arms := []
	for i in HG.WEAPON_UNLOCK[g.stage]: arms.append(HG.WEAPONS[i].name)
	text("NEW ARMS · " + " · ".join(arms), 440, 530, 15, HOT, "left", DISPLAY); c.restore()
	cell(tex.briefing, 4 + g.stage, 1010, 650 + sin(t * 2) * 4, 440, {"base": .93})
	if t > .8 and fl(t * 2.5) % 2 == 0: outlined("ENTER로 출격!", 1050, 690, 26, PAPER, SHADOW, "center", 6)
	box(0, 700, 1280 * clampf(t / 6, 0, 1), 20, "#ffd8d944", 0)
func tallyEnd() -> float: return .6 + g.result.rows.size() * .7 + 1.2
func resultScreen() -> void:
	var R = g.result; var t: float = R.t
	c.fillStyle = "#fff3f5"; c.fillRect(0, 0, 1280, 720); c.save(); c.globalAlpha = .3; bgPanel(g.stage, 0, 0, 1280, 720, .7); c.restore()
	for i in range(14):
		var x := fmod(i * 211 + g.time * 30, 1400.0) - 60; var y := fmod(i * 97 + g.time * 40, 780.0) - 40
		c.save(); c.globalAlpha = .5; c.translate(x, y); c.rotate(g.time + i); ellipse(0, 0, 8, 5, "#ffc1d6"); c.restore()
	outlined("MISSION %d COMPLETE!" % (g.stage + 1), 640, 110, 58, HOT, SHADOW, "center", 10); text(HG.STAGES[g.stage].name, 640, 146, 20, "#a8707f", "center")
	panelCard(250, 180, 780, 420)
	var shown := 0
	for i in range(R.rows.size()):
		var r: Dictionary = R.rows[i]; var start := .6 + i * .7
		if t < start: continue
		var k := clampf((t - start) / .5, 0, 1); var v := fl(r.value * k); var y := 240.0 + i * 70; shown += v
		text(r.label, 290, y, 22, INK, "left", DISPLAY); text(r.detail, 560, y, 18, "#a8707f"); text(str(v), 990, y, 26, INK if v else "#c9b1b7", "right", DISPLAY); line(290, y + 18, 990, y + 18, "#f2c4cf", 2)
		if i > ui.shownRow: ui.shownRow = i
		if k < 1 and fl(t * 30) != ui.tickNum: ui.tickNum = fl(t * 30); a_sfx("tick")
	var done: bool = t >= .6 + R.rows.size() * .7
	text("BONUS", 290, 560, 22, HOT, "left", DISPLAY); text(str(R.bonus if done else shown), 990, 562, 32, HOT, "right", DISPLAY)
	if t > tallyEnd() - 1.0:
		var k := clampf((t - (tallyEnd() - 1)) / .25, 0, 1); var s := 3 - 2 * easeT(k)
		if not ui.stamped: ui.stamped = true; a_sfx("stamp")
		c.save(); c.translate(1090, 250); c.rotate(-.2); c.scale(s, s); c.globalAlpha = k; circle(0, 0, 78, "#ffffffcc"); ring(0, 0, 78, HOT, 8); ring(0, 0, 64, HOT, 3); outlined(R.rank, 0, 40, 110, HOT, PAPER, "center", 8); text("RANK", 0, -48, 16, HOT, "center", DISPLAY); c.restore()
	victoryPose(150, 700, 260, 1, 6)
	text("SCORE " + pad7(g.score), 640, 650, 26, INK, "center", DISPLAY)
	if t >= tallyEnd() and fl(g.time * 2.5) % 2 == 0: outlined("ENTER · 엔딩 보기" if g.stage >= 3 else "ENTER · 다음 미션", 640, 696, 24, PAPER, SHADOW, "center", 6)
func continueScreen() -> void:
	overlayDim(.75); var n := maxi(0, ceili(g.continueTime))
	if n != ui.tickNum: ui.tickNum = n; a_sfx("tick")
	outlined("CONTINUE?", 640, 230, 84, PINK, SHADOW, "center", 12)
	var frac: float = g.continueTime - floor(g.continueTime); var s := 1 + frac * .25; c.save(); c.translate(640, 420); c.scale(s, s); outlined(str(n), 0, 0, 180, GOLD, SHADOW, "center", 14); c.restore()
	text("ENTER · 이어서 하기 (점수 유지)", 640, 520, 24, PAPER, "center", DISPLAY); text("R · 이 미션 처음부터   ·   Esc · 포기", 640, 560, 17, "#ffd8d9", "center")
	hero(1010, 700, 230, 7, -1, .95, false)
	text("SCORE %s   ·   CREDIT %d" % [pad7(g.score), g.credits], 640, 620, 18, "#ffd8d9", "center", DISPLAY)
func gameoverScreen() -> void:
	c.fillStyle = "#2b1720"; c.fillRect(0, 0, 1280, 720)
	var s := back3((g.time - ui.modeT) / .6); c.save(); c.translate(640, 240); c.scale(s, s); outlined("GAME OVER", 0, 0, 110, HOT, PAPER, "center", 12); c.restore()
	text("방송 재연결이 필요해!", 640, 300, 22, PINK, "center")
	text("FINAL SCORE", 640, 380, 18, "#ffd8d9", "center", DISPLAY); outlined(pad7(g.score), 640, 440, 56, GOLD, SHADOW, "center", 8)
	if ui.newRecord: outlined("NEW RECORD!", 640, 494, 28, PINK, SHADOW, "center", 6)
	text("허니비 %d마리 구출 · 과메기 %d마리 처치 · MISSION %d" % [g.rescued, g.kills, g.stage + 1], 640, 548, 18, PAPER, "center")
	if fl(g.time * 2) % 2 == 0: text("ENTER · 타이틀로", 640, 640, 22, PAPER, "center", DISPLAY)
func victoryT() -> float: return g.time - ui.modeT
# Ending in three acts (seconds since the mode began): peace returns to the meadow (0-9.5), the final tally (9.5-16),
# then the staff roll over a dusk sky ending on THE END. Enter skips back to the title at any point.
const ENDING_LINES := [[.6, 3.6, "과메기단은 바다 저 멀리 도망쳤고…"], [3.6, 6.6, "구출된 허니비들은 모두 꽃밭으로 돌아왔어요."], [6.6, 9.6, "허니츄러스 마을에 다시 평화가 찾아왔습니다!"]]
const ENDING_CREDITS := [["STAFF", ""], ["주인공", "허니츄러스"], ["구출 대상", "허니비 여러분"], ["악당", "과메기단"], ["최종 보스", "오리고기 사령관"], ["기획 · 개발", "project-h"], ["아트", "Codex 이미지 생성"], ["음악", "Suno BGM"], ["엔진", "Godot 4 · HTML5 Canvas"], ["특별 감사", "플레이해 준 바로 당신!"]]
const ENDING_TALLY := 9.5
const ENDING_ROLL := 16.0
const ROLL_SPEED := 70.0
const ROLL_GAP := 66.0
func victory() -> void:
	var t := victoryT()
	# the meadow from the title, with the villain gone
	c.drawImage(tex.menuBg, 0, 0, 1280, 720); c.drawImage(tex.menuTree, 0, 0, 1280, 720)
	for i in range(10):
		var px := fmod(i * 211 + t * 14, 1400.0) - 60; var py := fmod(i * 97 + t * 20, 780.0) - 40
		c.save(); c.globalAlpha = .55; c.translate(px, py); c.rotate(t * .6 + i); ellipse(0, 0, 8, 4, "#ffc1d6"); c.restore()
	var dusk := clampf((t - ENDING_ROLL) / 2, 0, 1)
	if dusk > 0:
		c.save(); c.globalAlpha = dusk * .62; var gr := c.createLinearGradient(0, 0, 0, 720); gr.addColorStop(0, "#2b1d3f"); gr.addColorStop(1, "#7a3b56"); c.fillStyle = gr; c.fillRect(0, 0, 1280, 720); c.restore()
		for i in range(40):
			var tw := .5 + .5 * sin(t * 2 + i * 1.7); c.save(); c.globalAlpha = dusk * tw * .9; circle((i * 317) % 1280, (i * 137) % 330, 1.5 + (i % 3), "#fff6da"); c.restore()
	# the hero dances in the middle, the honeybees circle her and hearts drift up
	var hx := lerpk(640, 300, easeT(dusk)); var hs := lerpk(300, 230, easeT(dusk))
	ellipse(hx, 700, hs * .24, 10, "#3a1f2a33"); victoryPose(hx, 700, hs, 1, 8)
	for i in range(9):
		var a := t * 1.1 + i * PI * 2 / 9; var r := lerpk(150, 120, dusk) + sin(t * 2 + i) * 16
		bee(hx + cos(a) * r * 1.6, 560 - hs * .55 + sin(a) * r * .7, 44 + (i % 3) * 10, 1, -1.0 if sin(a) > 0 else 1.0)
	for i in range(6):
		var k := fmod(t * .35 + i / 6.0, 1.0); c.save(); c.globalAlpha = (1 - k) * .9; heart(hx - 120 + i * 48 + sin(t * 2 + i) * 12, 620 - k * 420, 18 + (i % 2) * 6, "#ffd8d9" if i % 2 else HOT); c.restore()
	if t < ENDING_TALLY:
		# act 1: title and story captions
		var s := back3(t / .6); var o := clampf((ENDING_TALLY - t) / .5, 0, 1)
		c.save(); c.globalAlpha = o; c.translate(640, 104); c.scale(s, s); outlined("ALL MISSION COMPLETE!", 0, 0, 62, HOT, SHADOW, "center", 10); c.restore()
		for ln in ENDING_LINES:
			if t >= ln[0] and t < ln[1]:
				var k2: float = minf(1, minf((t - ln[0]) / .4, (ln[1] - t) / .4)); c.save(); c.globalAlpha = k2; outlined(ln[2], 640, 186 + (1 - k2) * 10, 30, PAPER, SHADOW, "center", 7); c.restore()
	elif t < ENDING_ROLL:
		# act 2: the final tally
		var k3 := back3((t - ENDING_TALLY) / .5); var o2 := clampf((ENDING_ROLL - t) / .5, 0, 1); overlayDim(.35 * o2)
		c.save(); c.globalAlpha = o2; c.translate(640, 360); c.scale(k3, k3); c.translate(-640, -360); panelCard(340, 130, 600, 430)
		outlined("FINAL SCORE", 640, 196, 30, HOT, PAPER, "center", 6); outlined(pad7(g.score), 640, 262, 56, GOLD, SHADOW, "center", 8)
		var rows := [["구출한 허니비", str(g.rescued) + "마리"], ["처치한 과메기", str(g.kills) + "마리"], ["사용한 크레딧", str(g.credits)], ["난이도", dif().label]]
		for i in range(rows.size()):
			if t < ENDING_TALLY + .7 + i * .35: continue
			var y := 330.0 + i * 50; text(rows[i][0], 390, y, 21, "#a8707f", "left", DISPLAY); text(rows[i][1], 890, y, 26, INK, "right", DISPLAY); line(390, y + 15, 890, y + 15, "#f2c4cf", 2)
		if ui.newRecord and t > ENDING_TALLY + 2.4:
			var s2 := back3((t - ENDING_TALLY - 2.4) / .4); c.save(); c.translate(820, 540); c.rotate(-.12); c.scale(s2, s2); outlined("NEW RECORD!", 0, 0, 34, HOT, PAPER, "center", 7); c.restore()
		c.restore()
	else:
		# act 3: staff roll, then THE END
		var r2 := t - ENDING_ROLL; var x := 820.0
		for i in range(ENDING_CREDITS.size()):
			var y := 780 + i * ROLL_GAP - r2 * ROLL_SPEED
			if y < -40 or y > 760: continue
			c.save(); c.globalAlpha = clampf((y - 40) / 80, 0, 1) * clampf((720 - y) / 60, 0, 1)
			if i == 0: outlined(ENDING_CREDITS[i][0], x, y, 34, GOLD, SHADOW, "center", 7)
			else: text(ENDING_CREDITS[i][0], x, y - 6, 16, "#ffd8d9", "center", DISPLAY); outlined(ENDING_CREDITS[i][1], x, y + 22, 26, PAPER, SHADOW, "center", 6)
			c.restore()
		var endAt := (780 + (ENDING_CREDITS.size() - 1) * ROLL_GAP + 60) / ROLL_SPEED
		if r2 > endAt:
			var k4 := back3((r2 - endAt) / .8); c.save(); c.translate(x, 330); c.scale(k4, k4); outlined("THE END", 0, 0, 84, HOT, PAPER, "center", 12); c.restore()
			if r2 > endAt + 1: outlined("THANK YOU FOR PLAYING", x, 400, 26, PAPER, SHADOW, "center", 6)
			if r2 > endAt + 1.6: text("SCORE " + pad7(g.score), x, 444, 20, "#ffd8d9", "center", DISPLAY)
	if t > 2 and fl(g.time * 2) % 2 == 0: text("ENTER · 타이틀로", 1240, 700, 18, "#ffd8d9" if dusk > 0 else "#a8707f", "right", DISPLAY)
# ---------- intro cutscene ----------
func storyBee(i: int, t: float):
	var home := {"x": 180 + i * 150 + sin(t * 1.3 + i) * 30, "y": 300 + sin(t * 2 + i * 1.7) * 36 + (i % 2) * 60}; var grab := 9 + i * .55
	if t < grab: return {"x": home.x + (sin(t * 30 + i) * 4 if t > 6 else 0.0), "y": home.y, "state": "panic" if t > 6 else "happy"}
	var k := (t - grab) / 2.6
	if k >= 1: return null
	return {"x": lerpk(home.x, 1080, easeT(k)), "y": lerpk(home.y, 330, easeT(k)) - sin(k * PI) * 120, "state": "carried"}
func story() -> void:
	var t: float = g.storyTime if g.storyTime else 0.0
	for cue in STORY_CUES:
		var key: String = str(cue[0]) + str(cue[1])
		if t >= cue[0] and not ui.storyDone.has(key):
			ui.storyDone[key] = true
			if cue[1].begins_with("music:"): a_music(cue[1].substr(6))
			else: a_sfx(cue[1])
	var quake := (sin(t * 60) * 3 if t > 6 and t < 8.5 else 0.0) + (sin(t * 90) * 14 * (10.7 - t) if t > 10 and t < 10.7 else 0.0) + (sin(t * 40) * 2 if t > 9 and t < 11 else 0.0)
	var zoom := 1.0 if t < 19 else 1 + easeT((t - 19) / 1.5) * .55
	var heroX := 330.0 if t < 10 else (lerpk(330, 210, (t - 10) / .6) if t < 10.6 else 210.0)
	c.save(); c.translate(quake, quake * .5)
	if zoom > 1:
		var k := easeT((t - 19) / 1.5); c.translate(minf(heroX + (420 - heroX) * k, heroX * zoom), 600); c.scale(zoom, zoom); c.translate(-heroX, -600)
	g.camera = 0; background(); c.save(); ground(); c.restore()
	if t > 6:
		var k := clampf((t - 6) / 1.5, 0, 1) * (1.0 if t < 19 else clampf(1 - (t - 19) / 2, 0, 1)); c.fillStyle = "rgba(70,20,45,%s)" % (.28 * k); c.fillRect(-200, 0, 1700, 720)
		if t < 8.5 and fl(t * 6) % 2 == 0: c.fillStyle = "rgba(255,60,90,.12)"; c.fillRect(-200, 0, 1700, 720)
	# tank arrives, then backs away with its cargo
	var tankX := 1700.0 if t < 9 else (lerpk(1700, 1030, easeT((t - 9) / 2)) if t < 11 else (1030 + sin(t * 3) * 3 if t < 15 else lerpk(1030, 1800, pow(clampf((t - 15) / 4, 0, 1), 2))))
	if tankX < 1700:
		ellipse(tankX, 592, 230, 14, "#3a1f2a40"); drawStoryTank(tankX, 592, (1030.0 if t >= 11 and t < 15 else tankX) - 1700)
		for i in range(3):
			var a := fmod(t * 1.2 + i * .33, 1.0); circle(tankX + 160 + i * 8, 260 - a * 80, 10 + a * 16, "rgba(120,100,100,%s)" % (.4 * (1 - a)))
	# paratroopers drop in and stand guard
	for i in range(3):
		var x := 640.0 + i * 130; var land := 10.2 + i * .4
		var y := lerpk(-80, 576, (t - 8.6 - i * .3) / (land - 8.6 - i * .3)) if t < land else 576.0
		if t < 8.6 + i * .3 or t > 15.2: continue
		if t < land: enemySprite("para", x + sin(t * 2 + i) * 14, y, 92, {"rot": sin(t * 2 + i) * .08})
		else: enemySprite("grunt", x, 576, 92, {"sx": 1 + sin(t * 10 + i) * .03})
		if t > land and t < land + .6: outlined("!", x, 470, 26, HOT, SHADOW)
	# flyers swoop down and carry the honeybees off to the tank
	for i in range(6):
		var b = storyBee(i, t)
		if b == null: continue
		var grab := 9 + i * .55
		if b.state == "carried" or (t > grab - 1.1 and t < grab):
			var fx: float = b.x if b.state == "carried" else lerpk(1400, b.x, (t - (grab - 1.1)) / 1.1); var fy: float = b.y - 70 if b.state == "carried" else lerpk(60, b.y - 70, (t - (grab - 1.1)) / 1.1)
			enemySprite("flyer", fx, fy + 40, 80, {}); c.save(); c.globalAlpha = .5; var w := 30 * sin(g.time * 50); line(fx - w, fy - 38, fx + w, fy - 38, "#fff", 4); c.restore()
		if b.state == "carried": line(b.x, b.y - 60, b.x, b.y - 30, "#b0814f", 3); powTied(b.x, b.y + 34, 74, sin(t * 8 + i) * .15)
		else:
			bee(b.x, b.y, 64, 1, 1 if sin(t * 3 + i) > 0 else -1)
			if b.state == "panic":
				text("💦", b.x + 26, b.y - 50, 16, "#7fc8f8", "center")
				if i % 2 == 0: outlined("!", b.x, b.y - 64, 22, HOT, SHADOW)
			elif i % 3 == 0: box(b.x - 10, b.y - 6, 20, 16, GOLD, 5, SHADOW, 2)
	# our hero (story pose sheet): bee on head → bee snatched → knocked down → gets up → draws the Glock
	var D := 240.0
	var f := 1 if fl(t * .8) % 4 == 1 else 0; var hy := 576.0; var rot := 0.0
	if t >= 6 and t < 9.3: f = 2; hy = 576 - (absf(sin((t - 6) * 6)) * 24 if t < 6.6 else 0.0)
	elif t >= 9.3 and t < 10: f = 3
	elif t >= 10 and t < 10.6: f = 4; hy = 576 - sin((t - 10) / .6 * PI) * 70; rot = -(t - 10) * 1.2
	elif t >= 10.6 and t < 17: f = 4
	elif t >= 17 and t < 18.4: f = 5; hy = 576 - absf(sin((t - 17) * 5)) * (18 if t < 17.6 else 0)
	elif t >= 18.4 and t < 20: f = 6
	elif t >= 20: f = 7
	# Story sheet frames 0-5 face left; mirror them (except 3, reaching right toward the stolen bee) so she faces the threat on the right.
	var mirror := f < 6 and f != 3
	ellipse(heroX, 580, 48, 8, "#3a1f2a40"); cell(tex.story, f, heroX, hy, D, {"base": .98 if f < 4 else .93, "rot": rot, "flip": mirror})
	if t > 6.1 and t < 7.6: outlined("!", heroX, hy - D * .98 - 10, 40, HOT, SHADOW)
	if t > 10.6 and t < 17:
		for i in range(3):
			var a: float = g.time * 5 + i * 2.1; text("★", heroX + cos(a) * 30, hy - D * .78 + sin(a) * 8, 16, GOLD, "center")
	if t > 10 and t < 10.9:
		var k := (t - 10) / .9; cell(tex.boom, mini(7, fl(k * 8)), heroX + 80, 520, 260, {"base": .56})
	# a propeller trooper swoops in and snatches the bee off her head
	var head := Vector2(heroX + (-1 if mirror else 1) * D * .05, hy - D * .86)
	if t > 8.6 and t < 11.6:
		var k1 := clampf((t - 8.6) / .7, 0, 1); var k2 := clampf((t - 9.3) / 2.3, 0, 1)
		var fx := lerpk(1350, head.x, easeT(k1)) if t < 9.3 else lerpk(head.x, 1060, easeT(k2))
		var fy := lerpk(40, head.y - 60, easeT(k1)) if t < 9.3 else lerpk(head.y - 60, 300, easeT(k2)) - sin(k2 * PI) * 90
		enemySprite("flyer", fx, fy + 40, 84, {}); c.save(); c.globalAlpha = .5; var w := 30 * sin(g.time * 50); line(fx - w, fy - 40, fx + w, fy - 40, "#fff", 4); c.restore()
		if t >= 9.3: line(fx, fy + 20, fx, fy + 44, "#b0814f", 3); powTied(fx, fy + 108, 70, sin(t * 8) * .15)
	if t >= 19.9 and t < 20.1: ellipse(heroX + D * .45, hy - D * .57, 26, 12, "#fff6c8")
	if t >= 21.4 and t < 21.6:
		c.save(); c.globalCompositeOperation = "lighter"; circle(heroX + D * .43, hy - D * .57, 26, "#ffd079aa"); circle(heroX + D * .43, hy - D * .57, 12, "#fff6d0"); c.restore()
	if t > 14.9 and t < 18.6 and tankX < 1500:
		for i in range(2): bubble(tankX - 40 + i * 110, 300 + i * 16 + sin(t * 6 + i) * 4, "살려줘~!", HOT)
	c.restore()
	# letterbox, dialogue, skip hint
	var bar := 60 * easeT(t / .6); c.fillStyle = "#1d1016"; c.fillRect(0, 0, 1280, bar); c.fillRect(0, 720 - bar, 1280, bar)
	var cur = null
	for L in STORY_LINES:
		if t >= L[0] and t < L[1]: cur = L; break
	if cur:
		var a: float = cur[0]; var who: String = cur[2]; var full: String = cur[3]; var shown := full.substr(0, maxi(0, fl((t - a) * 22))); var y := 74.0
		box(160, y, 960, 92, "#fff8f5f2", 22, "#f2c4cf", 3)
		if who:
			circle(210, y + 46, 36, PINK); ring(210, y + 46, 36, SHADOW, 3); c.save(); c.beginPath(); c.arc(210, y + 46, 32, 0, TAU); c.clip()
			if who == "hero": c.drawImage(tex.profile, 220, 65, 440, 440, 178, y + 14, 64, 64)
			elif who == "commander": bossPart(2, 174, y + 8, 72, 78)
			else: bee(210, y + 74, 70)
			c.restore()
			text({"hero": "허니츄러스", "commander": "오리고기 사령관", "bee": "허니비들"}[who], 262, y + 32, 15, HOT, "left", DISPLAY); text(shown, 262, y + 66, 22, INK)
		else: text(shown, 640, y + 56, 24, INK, "center")
	if t > 22.4:
		var k := back3((t - 22.4) / .4); c.save(); c.translate(760, 250); c.scale(k, k); c.rotate(-.04); outlined("허니비 구출 작전", 0, 0, 84, PINK, SHADOW, "center", 12); outlined("OPERATION HONEY RESCUE", 0, 46, 24, GOLD, SHADOW, "center", 6); c.restore()
	if t > 24.2: c.fillStyle = "rgba(255,248,245,%s)" % clampf((t - 24.2) / .8, 0, 1); c.fillRect(0, 0, 1280, 720)
	if fl(g.time * 2) % 2 == 0: text("ENTER · 클릭  건너뛰기 ▶▶", 1250, 40, 15, "#ffffffcc", "right", DISPLAY)

# ---------- frame loop ----------
func heldSet() -> Dictionary:
	var s := {}
	for k in kb: s[k] = true
	for k in padHeld: s[k] = true
	for v in touchHeld.values():
		for a in v: s[a] = true
	return s
func musicFor():
	match g.mode:
		"title", "story", "briefing": return "title"
		"play", "pause": return "boss" if g.boss and g.boss.get("started") and not g.boss.get("dead") else HG.STAGES[g.stage].theme
		"celebrate": return "clear"
		"result": return "result"
		"gameover": return "gameover"
		"victory": return "victory"
	return null
func onModeChange(from: String, to: String) -> void:
	ui.modeT = g.time; ui.tickNum = -1; ui.stamped = false; ui.shownRow = -1; ui.hits = []; ui.hover = -1
	if not ((from == "play" and to == "pause") or (from == "pause" and to == "play")) and to != "celebrate": ui.fade = 1.0
	if to == "play" or to == "title": a_set({"duck": false})
	if to == "pause" and ui.screen != "settings": ui.screen = "pause"; ui.index = 0
	if to == "title" and from != "title": ui.screen = "main"; ui.index = 0; ui.titleAt = g.time
	if to == "story": ui.storyDone = {}
	if to == "briefing" and (from == "title" or from == "story"): ui.bestAtStart = g.best
	if to == "briefing": progress = maxi(progress, g.stage); store_set("honey-progress", progress)
	if to == "gameover" or to == "victory":
		var bas = ui.bestAtStart if ui.bestAtStart != null else g.best
		ui.newRecord = g.score > bas and g.score > (records[0].score if records.size() else 0); addRecord()
		if to == "victory": progress = 3; store_set("honey-progress", 3)
	var m = musicFor()
	if m: a_music(m)
	else: a_stop()

func _process(delta: float) -> void:
	# Capture helpers: --hold=up,left keeps actions held, --jumpat=N presses jump on frame N, --shots=a,b,c saves extra frames.
	if _capture != "" and g.mode == "play":
		for k in str(_args.get("hold", "")).split(",", false): kb[k] = true
		if _args.has("jumpat") and _capture_frames == int(_args.jumpat): kb["jump"] = true; pressedEv["jump"] = true
	_tick(1.0 / 60 if _fixed_step else delta)
	if _capture != "":
		_capture_frames += 1
		if str(_capture_frames) in str(_args.get("shots", "")).split(","):
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/godot-%s-%d.png" % [_capture, _capture_frames]); print("SHOT ", _capture_frames, " ", g.x - g.camera, " ", g.y)
		if _capture_frames == int(_args.get("frames", 90)): _save_capture()

func _tick(delta: float) -> void:
	_frame_ok = false
	var elapsed := minf(.1, delta); acc += elapsed
	pollPad()
	var first := true
	while acc >= 1.0 / 60 - 1e-6:
		var held := heldSet(); var input := {}
		for k in held: input[k] = true
		if first:
			for k in ["jump", "grenade", "swap", "fire"]: input[k + "Pressed"] = pressedEv.has(k) or (held.has(k) and not prevHeld.has(k))
			input.jumpReleased = releasedEv.has("jump") or (not held.has("jump") and prevHeld.has("jump"))
			if pressedEv.has("fire"): input.fire = true
			if pressedEv.has("jump") and not held.has("jump"): input.jumpReleased = false
			pressedEv.clear(); releasedEv.clear(); prevHeld = held; first = false
		g.update(1.0 / 60, input); acc -= 1.0 / 60
		if g.mode == "briefing" and g.briefTime > 6: g.confirm()
	ui.fade = maxf(0, ui.fade - elapsed * 2.5); ui.toastT -= elapsed; ui.goT = maxf(0, ui.goT - elapsed)
	var cleared := 0
	for z in g.zones:
		if z.cleared: cleared += 1
	if cleared > ui.cleared and g.mode == "play" and cleared < g.zones.size(): ui.goT = 2.5
	ui.cleared = cleared
	if ui.lastMode != g.mode: onModeChange(ui.lastMode, g.mode); ui.lastMode = g.mode
	var bossNow: bool = g.boss != null and bool(g.boss.get("started")) and not g.boss.get("dead")
	if bossNow != lastBoss:
		lastBoss = bossNow; var m = musicFor()
		if m: a_music(m)
	draw_frame()
	_frame_ok = true

func draw_frame() -> void:
	c.begin_frame()
	match g.mode:
		"title": title()
		"story": story()
		"briefing": briefing()
		"result": resultScreen()
		"gameover": gameoverScreen()
		"victory": victory()
		_:
			world(); hud(); cinematics()
			if g.mode == "pause": pauseScreen()
			if g.mode == "continue": continueScreen()
	if ui.toastT > 0:
		c.save(); c.globalAlpha = minf(1, ui.toastT * 3); c.font = "16px " + BODY; var w: float = c.measureText(ui.toast).width + 40
		box(640 - w / 2, 660, w, 36, "#3a1f2add", 18); text(ui.toast, 640, 684, 16, PAPER, "center"); c.restore()
	if ui.fade > 0: c.fillStyle = "rgba(255,240,243,%s)" % ui.fade; c.fillRect(0, 0, 1280, 720)

# ---------- capture / render test ----------
func _setup_mode(mode: String) -> void:
	match mode:
		"title": pass
		"stages", "settings", "howto", "records": ui.screen = mode
		"story": g.start(0, true); g.storyTime = float(_args.get("t", 12))
		"briefing": g.start(int(_args.get("stage", 1))); g.briefTime = 2.0
		"play", "pause", "continue":
			g.start(int(_args.get("stage", 0))); g.begin()
			if not _args.has("entry"): g.entering = false; g.x = float(_args.get("x", g.zones[0].start + 400))
			g.intro = 0; g.invincible = 1e9
			for i in range(30): g.update(1.0 / 60, {})
			for kind in HG.ENEMIES.keys():
				var e = g.spawnEnemy(g.camera + 700 + randf() * 300, HG.FLOOR, kind); e.alert = 1
			if _args.has("entry"): g.loadStage(); g.begin()
			if _args.has("support"): g.support = 22.0
			if _args.has("weapon"): g.giveWeapon(int(_args.weapon)); g.enemies = []
			if _args.has("punch"): g.enemies = []; g.invincible = 0; var pe = g.spawnEnemy(g.x + 50, HG.FLOOR, "grunt"); pe.state = "idle"; pe.hp = 999.0; pe.max = 999.0
			if mode == "pause": g.pause(); ui.screen = "pause"
			if mode == "continue": g.mode = "continue"; g.continueTime = 7.5
		"boss":
			# --enter keeps the entrance; --p2 drops it below half HP (armor break), --hatch opens the hatch now, --dead kills the boss.
			g.start(int(_args.get("stage", 3))); g.begin(); g.entering = false; g.invincible = 1e9; g.intro = 0; g.x = HG.STAGES[g.stage].length - 1000.0
			g.startBoss()
			if not _args.has("enter"):
				for i in range(600):
					if g.boss.state != "enter": break
					g.update(1.0 / 60, {})
			if _args.has("p2"): g.damageBoss(g.boss.max * .6); g.update(1.0 / 60, {})
			if _args.has("hatch"): g.boss.hatch.clock = 0.0; g.grenades = 0
			if _args.has("dead"): g.damageBoss(9999)
		"result":
			g.start(int(_args.get("stage", 0))); g.begin(); g.entering = false; g.invincible = 1e9
			g.startBoss(); g.updateBoss(3); g.damageBoss(9999)
			for i in range(900):
				if g.result != null: break
				g.update(1.0 / 60, {})
			g.result.t = 6.0
		"gameover": g.mode = "gameover"; g.score = 123450
		"victory": g.mode = "victory"; g.score = 523450
	ui.fade = 0.0

func _save_capture() -> void:
	await RenderingServer.frame_post_draw
	var path := "res://build/godot-%s.png" % _capture
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURED ", path)
	get_tree().quit()

func _frame_n(n := 1) -> void:
	for i in range(n):
		_tick(1.0 / 60)
		if not _frame_ok: _failures += 1

func _run_render_test() -> void:
	_frame_n()
	for s in ["stages", "settings", "howto", "records", "main"]: ui.screen = s; _frame_n()
	g.start(0, true)
	var st := 0.0
	while st < 25.5: g.storyTime = st; _frame_n(); st += .7
	g.start(0, true); _frame_n(); g.confirm(); g.mode = "title"
	g.confirm(); _frame_n(3); g.confirm(); _frame_n(3)
	for w in range(6):
		for face in [-1, 1]: g.giveWeapon(w); g.face = face; g.fireTimer = 0; g.shoot(); _frame_n()
	g.knife = .2; _frame_n(); g.knife = 0
	for stage in range(4):
		g.start(stage); g.begin(); g.invincible = 1e9
		for z in g.zones:
			for offset in [-400, 0, 400]:
				g.camera = maxf(0, z.start - 640 + offset); g.x = g.camera + 640; c.begin_frame(); background()
		g.camera = g.bossStart; g.x = g.bossStart + 640; c.begin_frame(); background(); g.camera = 0
		for z in g.zones:
			for w in z.waves: w.done = false
		g.x = g.zones[0].start + 400; _frame_n(5)
		for kind in HG.ENEMIES.keys():
			var e = g.spawnEnemy(g.camera + 700, 576, kind); e.alert = 1
		g.spawnWave("grunt", 2, "P", 0)
		g.dropItem(g.x + 100, 400, "weapon", 3); g.dropItem(g.x + 140, 400, "food"); g.dropItem(g.x + 180, 400, "medal"); g.dropItem(g.x + 220, 400, "support"); g.dropItem(g.x + 260, 400, "bomb"); g.dropItem(g.x + 300, 400, "ammo")
		g.explode(g.x + 200, 500, 150, 30); _frame_n(40)
		g.startBoss(); _frame_n(5); g.updateBoss(3)
		g.boss.hatch.clock = 0.0; g.grenades = 0; _frame_n(88)
		g.addBullet(g.x, 400, 0, 0, false, 1, "crate"); g.addBullet(g.x, 400, 0, 0, false, 1, "fire"); g.addBullet(g.x, 400, 0, 0, false, 1, "spray"); _frame_n(30)
		for p in range(3):
			g.boss.pattern = p; g.boss.state = "windup"; g.boss.warn = true; g.planBoss(); _frame_n(); g.bossAttack(); _frame_n(20)
		g.damageBoss(g.boss.max * .6); _frame_n(5); g.dying = 1; _frame_n(3); g.dying = 0; g.mode = "pause"; _frame_n(); ui.screen = "settings"; _frame_n(); ui.screen = "pause"; g.mode = "play"
		g.damageBoss(9999); _frame_n(30); _frame_n(400)
		if g.mode != "result": print("RENDER FAIL: stage %d ended in mode %s" % [stage, g.mode]); _failures += 1
		_frame_n(300)
	for mode in ["continue", "gameover", "victory", "briefing", "title"]: g.mode = mode; g.continueTime = 5; _frame_n(10)
	if _failures == 0: print("RENDER PASS: menus, story, every screen, enemy, item, weapon, four bosses")
	else: print("RENDER FAIL: %d frames errored" % _failures)
	get_tree().quit(0 if _failures == 0 else 1)
