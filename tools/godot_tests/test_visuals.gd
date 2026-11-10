extends SceneTree
const V = preload("res://scripts/visual_motion.gd")
const G = preload("res://scripts/honey_game.gd")

func _init() -> void:
	var checks := 0
	for stage in range(4):
		var g = G.new(); g.start(stage)
		for i in range(g.zones.size()):
			var z: Dictionary = g.zones[i]; var b := V.scenery(g.zones, g.bossStart, (z.start + z.end) / 2.0)
			assert((b.to if b.mix == 1 else b.from) == i); checks += 1
		for z in g.zones.slice(1):
			var b := V.scenery(g.zones, g.bossStart, z.start)
			assert(is_equal_approx(b.mix, .5)); assert(b.to == b.from + 1); checks += 1
	for rig in G.BOSS_RIG.values():
		var texture: Texture2D = load("res://assets/generated/bosses/" + rig.sheet + "_stable.png")
		var im := texture.get_image()
		assert(im != null and im.detect_alpha() != Image.ALPHA_NONE)
		var bottom := INF
		for f in range(8):
			var q := V.boss_rect(rig.sheet, f, rig); var a: Array = q.source
			assert(a[0] >= 0 and a[1] >= 0 and a[2] <= im.get_width() and a[3] <= im.get_height())
			assert(q.w > 0 and q.h > 0)
			if bottom != INF: assert(is_equal_approx(q.y + q.h, bottom))
			bottom = q.y + q.h; checks += 1
	var b := {"type": "king", "dead": false, "state": "idle", "t": 0.0, "clock": 1.0, "phase": 1, "pattern": 0, "air": false, "vy": 0.0, "charge": 0, "recoil": 0.0, "sink": 0.0}
	for f in range(600):
		b.t = f / 60.0; assert(V.boss_frame(b) == 0); var p := V.boss_pose(b)
		b.t += 1.0 / 60; var next := V.boss_pose(b); assert(absf(p.y - next.y) < .1); checks += 1
	b.phase = 2; b.state = "attack"; assert(V.boss_frame(b) == 6)
	var portal_tex: Texture2D = load("res://assets/generated/zone_portals.png"); var portal_image := portal_tex.get_image()
	for a in V.BOUNDS.portals:
		assert(portal_image.get_pixel(int((a[0] + a[2]) / 2), int(a[1] + (a[3] - a[1]) * .75)).a < .05, "doorway opening must be transparent")
	for stage in range(4):
		var g = G.new(); g.start(stage)
		for z in g.zones:
			z.cleared = true; var entries := V.portals(g.zones, g.bossStart, z.end - 640)
			assert(is_equal_approx(V.entrance_shade(entries, z.end), .3)); checks += 1
	assert(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter") == 2)
	print("PASS native visuals: ", checks, " checks, zone transitions, alpha, crop bounds, anchors and motion states")
	quit()
