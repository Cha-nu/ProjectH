extends SceneTree
const G = preload("res://scripts/honey_game.gd")
const V = preload("res://scripts/visual_motion.gd")

func _init() -> void:
	for stage in [1, 3]:
		var g = G.new(); g.start(stage); g.begin(); g.invincible = 1e9; g.startBoss(); var b: Dictionary = g.boss
		var x: float = b.x; var track: float = b.track; g.updateBoss(1.0 / 60)
		assert(b.track < track and is_equal_approx(b.track - track, b.x - x))
		b.state = "attack"; b.clock = 10.0; b.pattern = 2; b.charge = 1; b.chargeDir = -1; b.x = b.home
		x = b.x; track = b.track; g.updateBoss(1.0 / 60); assert(b.track < track and is_equal_approx(b.track - track, b.x - x))
		b.chargeDir = 1; track = b.track; g.updateBoss(1.0 / 60); assert(b.track > track)
		b.charge = 0; b.state = "windup"; b.clock = 10.0; track = b.track; g.updateBoss(.1); assert(b.track == track)
		b.phase = 2; b.state = "attack"; b.charge = 1; b.chargeDir = -1; track = b.track; g.updateBoss(1.0 / 60); assert(b.track < track)
		b.charge = 0; b.air = true; b.y = 200.0; b.vx = 100.0; track = b.track; g.updateBoss(1.0 / 60); assert(b.track == track)
		b.dead = true; g.updateBoss(.1); assert(b.track == track)
	for distance in range(-2000, 2000, 7):
		var p := V.tread_point(distance, 180, 27); var q := V.tread_point(distance + 360 + TAU * 27, 180, 27)
		assert(is_equal_approx(p.x, q.x) and is_equal_approx(p.y, q.y))
	for sheet in V.SOFT_BOSSES:
		var im: Image = load("res://assets/generated/bosses/" + sheet + "_ink.png").get_image()
		assert(im.detect_alpha() != Image.ALPHA_NONE)
		for i in range(8):
			var a: Array = V.boss_art(sheet, i).source
			assert(a[0] >= 0 and a[1] >= 0 and a[2] <= im.get_width() and a[3] <= im.get_height())
	print("PASS native boss tracks: movement, reverse, parked, damage, air, wreck, belt wrap and art alpha/crops")
	quit()
