extends SceneTree
## Record the real native boss draw helpers for offline visual review without a GPU window.
const View = preload("res://scripts/main.gd")
const G = preload("res://scripts/honey_game.gd")

class Recorder extends Canvas2D:
	var ops: Array = []
	func _init() -> void: super(RID())
	func record(op: String, a: Array = []) -> void: ops.append({"op": op, "a": a})
	func save() -> void: super.save(); record("save")
	func restore() -> void: super.restore(); record("restore")
	func translate(x: float, y: float) -> void: record("translate", [x,y])
	func scale(x: float, y: float) -> void: record("scale", [x,y])
	func rotate(a: float) -> void: record("rotate", [a])
	func beginPath() -> void: record("beginPath")
	func rect(x: float, y: float, w: float, h: float) -> void: record("rect", [x,y,w,h])
	func clip() -> void: record("clip")
	func closePath() -> void: record("closePath")
	func fillText(s: Variant, x: float, y: float) -> void: record("fillText", [s,x,y])
	func moveTo(x: float, y: float) -> void: record("moveTo", [x,y])
	func lineTo(x: float, y: float) -> void: record("lineTo", [x,y])
	func arc(x: float, y: float, r: float, a0: float, a1: float, ccw := false) -> void: record("arc", [x,y,r,a0,a1,ccw])
	func ellipse(x: float, y: float, rx: float, ry: float, rot: float, a0: float, a1: float, ccw := false) -> void: record("ellipse", [x,y,rx,ry,rot,a0,a1,ccw])
	func roundRect(x: float, y: float, w: float, h: float, radii: Variant = 0.0) -> void: record("roundRect", [x,y,w,h,radii])
	func fill() -> void: record("set", ["fillStyle",fillStyle]); record("fill")
	func stroke() -> void: record("set", ["strokeStyle",strokeStyle]); record("set", ["lineWidth",lineWidth]); record("stroke")
	func drawImage(img: Texture2D, a: float, b: float, c: float = NAN, d: float = NAN, e: float = NAN, f: float = NAN, g: float = NAN, h: float = NAN) -> void:
		record("drawImage", [img.resource_path.trim_prefix("res://"),a,b,c,d,e,f,g,h])

func _init() -> void:
	var view := View.new(); var c := Recorder.new(); view.c = c
	view.tex.driveParts = load("res://assets/generated/bosses/drive_parts.png")
	view.tex.groundInk = load("res://assets/generated/ground_ink.png")
	view.tex.hero = load("res://assets/characters/hero_sheet.png")
	view.tex.items = load("res://assets/generated/items.png")
	for theme in ["town", "factory", "harbor", "fortress"]:
		for i in range(6): view.tex["scene_%s_%d" % [theme, i]] = load("res://assets/generated/scene_%s_%d.png" % [theme, i])
	for sheet in ["walker", "cannon", "ship", "tank"]: view.tex["boss_" + sheet] = load("res://assets/generated/bosses/" + sheet + "_ink.png")
	for stage in range(4):
		var g = G.new(); g.start(stage); g.begin(); g.startBoss(); view.g = g
		g.camera = G.STAGES[stage].length - 1280.0
		var b: Dictionary = g.boss; b.x = g.camera + (350.0 if stage == 2 else 950.0); b.y = G.FLOOR; b.air = false; b.state = "idle"; b.warn = false; b.track = stage * 17.0
		c.save(); c.translate((stage % 2) * 640, floori(stage / 2.0) * 360); c.scale(.5, .5)
		c.beginPath(); c.rect(0,0,1280,720); c.clip()
		view.zoneBackdrop(5, 1); c.translate(-g.camera, 0)
		if stage != 2: view.ground()
		else: view.drawShip(g.ship)
		view.hero(g.camera + (1000.0 if stage == 2 else 210.0), G.FLOOR, 108, 4, -1 if stage == 2 else 1)
		view.drawBoss(); c.restore()
	var file := FileAccess.open("res://build/boss-preview-native-commands.json", FileAccess.WRITE); file.store_string(JSON.stringify(c.ops)); file.close()
	view.free(); print("Recorded native boss drawing for four review panels."); quit()
