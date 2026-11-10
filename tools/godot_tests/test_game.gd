extends SceneTree
## GDScript port of tools/test-game.cjs. Run:
## tools/godot/Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tools/godot_tests/test_game.gd

const G := preload("res://scripts/honey_game.gd")
const FLOOR := 576
const PISTOL := 5

var count := 0
var failed := 0
var current := ""
var current_ok := true
var checks := 0

func ok(cond: bool, msg := "") -> void:
	checks += 1
	if not cond:
		current_ok = false
		printerr("  assertion failed in '%s' %s" % [current, msg])

func test(name: String, run: Callable) -> void:
	current = name; current_ok = true; checks = 0
	run.call()
	if checks == 0: current_ok = false
	if current_ok:
		count += 1; print("PASS ", name)
	else:
		failed += 1; print("FAIL ", name)

func game(stage := 0):
	var g = G.new(); g.start(stage); g.begin(); g.entering = false; g.x = 180.0; g.enemies = []
	for z in g.zones:
		for w in z.waves: w.done = true
	return g

func boss_ready(stage: int):
	var g = game(stage); g.invincible = 1e9; g.startBoss()
	var i := 0
	while i < 600 and g.boss.state == "enter":
		g.update(1.0 / 60, {}); i += 1
	ok(g.boss.state == "idle")
	return g

func steps(g, n: int, input := {}) -> void:
	for i in range(n): g.update(1.0 / 60, input)

func _init() -> void:
	test("stage opens with the hero running in from the left, no blink, controls locked until the mark", func():
		var g = G.new(); g.start(0); g.begin(); ok(g.entering); ok(g.x < g.camera); ok(g.invincible == 0)
		steps(g, 10, {"left": true, "fire": true}); ok(g.x > g.camera - 70); ok(g.bullets.size() == 0)
		steps(g, 90); ok(not g.entering); ok(g.x >= 170 and g.x < 230); var x = g.x; steps(g, 30, {"right": true}); ok(g.x > x))
	test("winning in mid-air lands before the victory dance", func():
		var g = game(0); g.invincible = 1e9; g.startBoss()
		var i := 0
		while i < 900 and g.boss.state == "enter":
			g.update(1.0 / 60, {}); i += 1
		g.y = 300; g.vy = -200; g.grounded = false; g.damageBoss(1e9); ok(g.mode == "celebrate"); ok(not g.grounded)
		steps(g, 60); ok(g.grounded); ok(g.y == G.FLOOR))
	test("squads arrive staggered and spread out instead of piling up", func():
		var g = game(0); g.invincible = 1e9; g.spawnWave("grunt", 3, "R", 0); ok(g.enemies.size() == 1)
		g.spawnWave("shield", 1, "R", 0, false, .3); g.spawnWave("heavy", 1, "R", 0, false, .6); g.spawnWave("bomber", 1, "R", 0, false, .9); g.spawnWave("grunt", 2, "P", 0)
		steps(g, 900)
		var live = g.enemies.filter(func(e): return e.hp > 0 and e.kind != "flyer" and not e.air and e.state != "para" and e.state != "enter")
		ok(live.size() >= 6)
		for a in live:
			for b in live:
				if a != b and absf(a.y - b.y) < 30: ok(absf(a.x - b.x) >= 40, "%s %s %f" % [a.kind, b.kind, absf(a.x - b.x)]))
	test("T-entry snipers drop onto a platform and stay on it", func():
		var g = game(0); g.invincible = 1e9; g.spawnWave("grunt", 2, "T", 0); steps(g, 300)
		var up = g.enemies.filter(func(e): return e.hp > 0 and e.y < G.FLOOR - 50)
		ok(up.size() >= 1)
		for e in up:
			ok(e.y == e.floor); ok(e.x >= e.perchL and e.x <= e.perchR))
	test("jumping straight up under a high platform lands on it", func():
		var g = game(0); g.platforms = [{"x": g.x - 60, "base": g.x - 60, "y": 396.0, "w": 120.0, "h": 20.0, "type": "normal"}]
		g.update(1.0 / 60, {"jumpPressed": true, "jump": true}); steps(g, 90, {"jump": true}); ok(g.grounded); ok(g.y == 396.0))
	test("down + jump drops through a platform; coyote jump works just after walking off", func():
		var g = game(0); g.platforms = [{"x": g.x - 60, "base": g.x - 60, "y": 396.0, "w": 120.0, "h": 20.0, "type": "normal"}]
		g.y = 396.0; g.grounded = true; steps(g, 5); ok(g.y == 396.0)
		g.update(1.0 / 60, {"down": true, "jumpPressed": true, "jump": true}); steps(g, 60); ok(g.y == FLOOR); ok(g.grounded)
		var c = game(0); c.platforms = [{"x": c.x - 60, "base": c.x - 60, "y": 396.0, "w": 120.0, "h": 20.0, "type": "normal"}]
		c.y = 396.0; c.grounded = true; steps(c, 2); c.x = c.platforms[0].x + 150; steps(c, 7); ok(not c.grounded)
		c.update(1.0 / 60, {"jumpPressed": true, "jump": true}); ok(c.vy < 0))
	test("continuous bullet collision cannot tunnel through thin targets", func():
		ok(G.intersects({"x": 0, "y": 10}, {"x": 200, "y": 10}, {"x": 100, "y": 0, "w": 3, "h": 20}))
		ok(not G.intersects({"x": 0, "y": 30}, {"x": 200, "y": 30}, {"x": 100, "y": 0, "w": 3, "h": 20})))
	test("flow: title → briefing → play → pause → play", func():
		var g = G.new(); ok(g.mode == "title"); g.confirm(); ok(g.mode == "briefing"); g.confirm(); ok(g.mode == "play"); g.pause()
		var x = g.x; steps(g, 30, {"right": true}); ok(g.x == x); g.pause(); ok(g.mode == "play"))
	test("movement, variable jump and landing", func():
		var a = game(); var b = game(); a.platforms = []; b.platforms = []; steps(a, 40, {"right": true}); ok(a.x > 300)
		a.update(1.0 / 60, {"jumpPressed": true}); b.update(1.0 / 60, {"jumpPressed": true}); b.update(1.0 / 60, {"jumpReleased": true})
		steps(a, 12); steps(b, 11); ok(a.y < b.y); steps(a, 100); ok(a.y == FLOOR); ok(a.grounded))
	test("camera only scrolls forward outside scroll locks", func():
		var g = game(); steps(g, 70, {"right": true}); ok(g.lock == null); var cam = g.camera; ok(cam > 0)
		steps(g, 120, {"left": true}); ok(g.camera >= cam - 1e-6); ok(g.x >= g.camera + 29))
	test("aim sweeps toward up and diagonal-down instead of snapping", func():
		var g = game(); g.update(1.0 / 60, {"up": true}); var mid = g.aim(); ok(mid.y < 0 and mid.y > -1)
		steps(g, 20, {"up": true}); ok(g.aim().y < -.99); g.grounded = false; g.y = 300.0
		steps(g, 30, {"down": true, "right": true}); var a = g.aim(); ok(a.x > 0 and a.y > 0))
	test("pistol is infinite; heavy weapons run dry and fall back to pistol", func():
		var g = game(); ok(g.weapon == PISTOL); g.shoot(); ok(g.ammo[PISTOL] == -1); g.giveWeapon(2); ok(g.weapon == 2)
		g.ammo[2] = 1; g.shoot(); ok(g.weapon == PISTOL); ok(not g.unlocked.has(2)))
	test("picking the same weapon stacks ammo", func():
		var g = game(); g.giveWeapon(3); g.ammo[3] = 5; g.giveWeapon(3); ok(g.ammo[3] == 5 + G.WEAPONS[3].ammo))
	test("each weapon fires its own projectile, sound and muzzle position", func():
		var g = game(); var heard := []; g.sound = func(k): heard.append(k)
		for w in range(5):
			g.giveWeapon(w); g.fireTimer = 0.0; g.muzzle = 0.0; var pose = G.weaponPose(g); g.shoot(); var b = g.bullets.back()
			ok(b.weapon == w); ok(b.kind == G.VISUALS[w].kind); ok(heard.has(G.VISUALS[w].sound)); ok(b.x == pose.mx); ok(b.y == pose.my))
	test("weapon grip and muzzle mirror for every weapon and pose", func():
		var g = game(); g.x = 700.0; g.y = float(FLOOR)
		for w in range(6):
			for pose in ["idle", "walk", "crouch", "jump", "hurt"]:
				g.weapon = w; g.crouch = pose == "crouch"; g.grounded = pose != "jump"; g.vx = 300.0 if pose == "walk" else 0.0
				g.hurtTimer = .2 if pose == "hurt" else 0.0; g.muzzle = .06; g.aimLocal = 0.0; g.face = 1.0
				var r = G.weaponPose(g); g.face = -1.0; var l = G.weaponPose(g)
				ok(absf(r.x + l.x - 1400) < 1e-8, "x %s %s" % [w, pose]); ok(absf(r.mx + l.mx - 1400) < 1e-8, "mx %s %s" % [w, pose]); ok(r.y == l.y))
	test("knife replaces shooting at point blank", func():
		var g = game(); var e = g.spawnEnemy(g.x + 40, FLOOR, "grunt"); e.alert = 1; var hp = e.hp; g.shoot()
		ok(e.hp < hp); ok(g.knife > 0); ok(g.bullets.size() == 0))
	test("shield blocks frontal shots but not explosions", func():
		var g = game(); var e = g.spawnEnemy(g.x + 400, FLOOR, "shield"); e.facing = -1.0; e.peek = 0.0; var hp = e.hp
		var r = g.damageEnemy(e, 5, "shot", {"vx": 1000, "vy": 0}); ok(r is String and r == "block"); ok(e.hp == hp)
		g.damageEnemy(e, 5, "explosion"); ok(e.hp < hp))
	test("kills create corpses, combo score and popups", func():
		var g = game()
		for i in range(3):
			var e = g.spawnEnemy(g.x + 300 + i * 30, FLOOR, "grunt"); g.damageEnemy(e, 99, "shot", {"vx": 1, "vy": 0})
		ok(g.corpses.size() == 3); ok(g.combo == 3); ok(g.score >= 600); ok(g.popups.size() >= 3))
	test("every enemy archetype acts without errors and stays finite", func():
		for kind in G.ENEMIES.keys():
			var g = game(1); g.invincible = 999.0; var e = g.spawnEnemy(g.x + 380, FLOOR, kind); e.alert = 1; steps(g, 400)
			ok(is_finite(e.x) and is_finite(e.y), kind))
	test("caged POW needs breaking, then touch rescues and drops a reward once", func():
		var g = game(0); var p = null
		for q in g.pows:
			if q.kind == "cage": p = q; break
		if p == null: p = g.pows[0]
		p.kind = "cage"; p.state = "caged"; p.reward = "bomb"; g.x = p.x; g.collectPows(); ok(g.rescued == 0)
		g.damageCage(p, 99); ok(p.state == "tied"); g.x = p.x; g.collectPows(); ok(g.rescued == 1); g.collectPows(); ok(g.rescued == 1)
		steps(g, 60); ok(g.items.any(func(i): return i.kind == "bomb") or g.grenades > 10))
	test("items apply their effects", func():
		var g = game(); g.hp = 1; g.takeItem({"kind": "food"}); ok(g.hp == 3); var b = g.grenades; g.takeItem({"kind": "bomb"}); ok(g.grenades == b + 10)
		g.takeItem({"kind": "support"}); ok(g.support == 22); g.takeItem({"kind": "weapon", "weapon": 1}); ok(g.weapon == 1))
	test("special support bee fires at enemies ahead", func():
		var g = game(); g.support = 22.0; var e = g.spawnEnemy(g.x + 300, FLOOR, "grunt"); e.alert = 1; g.update(1.0 / 60, {})
		var found = null
		for b in g.bullets:
			if b.kind == "support": found = b; break
		ok(found != null and found.vx > 0))
	test("grenades bounce then explode with area damage", func():
		var g = game(); g.update(1.0 / 60, {"grenadePressed": true}); ok(g.grenades == 9); ok(g.throwT > 0 and not g.bullets.any(func(b): return b.kind == "grenade"), "wind-up first"); steps(g, 8); ok(g.bullets.any(func(b): return b.kind == "grenade"))
		steps(g, 150); ok(not g.bullets.any(func(b): return b.kind == "grenade"))
		var e = g.spawnEnemy(g.x + 200, FLOOR, "heavy"); g.explode(e.x, e.y - 40, 150, 99); ok(g.enemies.filter(func(x): return x.hp > 0).size() == 0))
	test("the melee swing grants brief invincibility", func():
		var g = game(); g.invincible = 0.0; g.knife = .2; var hp0: int = g.hp; g.hurt(); ok(g.hp == hp0); g.knife = 0.0; g.hurt(); ok(g.hp == hp0 - 1))
	test("a grenade explodes on contact with an enemy", func():
		var g = game(); g.enemies = []; var e = g.spawnEnemy(g.x + 60, FLOOR, "heavy"); e.state = "idle"; var hp0: float = e.hp
		g.bullets.append({"x": e.x - 30, "y": e.y - 40, "vx": 400.0, "vy": 0.0, "friendly": true, "damage": 22.0, "life": 1.6, "kind": "grenade", "pierce": 0, "hit": [], "bounces": 0, "spin": 0.0})
		steps(g, 6); ok(not g.bullets.any(func(b): return b.kind == "grenade"), "detonated before bouncing"); ok(e.hp < hp0))
	test("explosive barrels detonate", func():
		var g = game(); var p = null
		for q in g.props:
			if q.kind == "barrel": p = q; break
		var e = g.spawnEnemy(p.x + 40, FLOOR, "grunt"); g.damageProp(p, 99); ok(p.hp <= 0); ok(e.hp <= 0))
	test("arena stragglers left off-screen walk back in instead of stalling the lock", func():
		var g = game(); var z = g.zones[0]; g.x = float(z.end - 700); g.updateZones(0); ok(g.lock != null); g.camera = g.lock.cam; g.enemies = []
		var e = g.spawnEnemy(g.camera + 1280 + 400, FLOOR - 120.0, "grunt"); e.arena = true; e.zone = g.lock.zone; e.air = true
		for i in range(400): g.updateEnemies(1.0 / 60)
		ok(e.x < g.camera + 1280 - 40); ok(e.y == e.floor))
	test("scroll-lock arena spawns waves and releases when cleared", func():
		var g = game(); var z = g.zones[0]; g.x = float(z.end - 700); g.camera = g.x - 470; g.updateZones(0); ok(g.lock != null)
		var guard := 0
		while not z.cleared and guard < 600:
			guard += 1; g.updateZones(.5)
			for e in g.enemies: e.hp = 0.0
			g.enemies = []
		ok(z.cleared); ok(g.lock == null); ok(z.arenaWave == z.arena.size() - 1))
	test("damage, death animation, respawn and continue", func():
		var g = game(); g.invincible = 0.0; g.hurt(); ok(g.hp == g.dif.hp - 1); g.hurt(); ok(g.hp == g.dif.hp - 1)
		g.hp = 1; g.invincible = 0.0; g.giveWeapon(3); g.hurt(); ok(g.dying > 0); ok(g.weapon == PISTOL); steps(g, 100); ok(g.dying <= 0 and g.hp == g.dif.hp)
		g.lives = 1; g.hp = 1; g.invincible = 0.0; g.hurt(); steps(g, 100); ok(g.mode == "continue"); var score = g.score; g.confirm()
		ok(g.mode == "play"); ok(g.credits == 1); ok(g.score == score)
		g.lives = 1; g.hp = 1; g.invincible = 0.0; g.hurt(); steps(g, 100); steps(g, 700); ok(g.mode == "gameover"); g.confirm(); ok(g.mode == "title"))
	test("difficulty changes health and lives", func():
		var g = G.new(); g.difficulty = "easy"; g.start(); ok(g.hp == 7); ok(g.lives == 5); g.difficulty = "hard"; g.start(); ok(g.hp == 3))
	test("four stages with hazards: conveyors, honey, water, boats and steam", func():
		ok(G.STAGES.size() == 4); var f = game(1); var s = game(2); var k = game(3)
		ok(f.platforms.any(func(p): return p.type == "belt")); ok(f.hazards.any(func(h): return h.kind == "honey")); ok(s.hazards.any(func(h): return h.kind == "water"))
		var boat = null
		for p in s.platforms:
			if p.type == "boat": boat = p; break
		var x = boat.x; steps(s, 30); ok(boat.x != x); ok(k.hazards.any(func(h): return h.kind == "steam"))
		for i in range(4): ok(G.LEVELS[i].zones.size() in [5, 6]))
	test("every boss enters, cycles all attacks, breaks armor and ends in a tally", func():
		for stage in range(4):
			var g = game(stage); g.invincible = 1e9; g.startBoss(); var b = g.boss; var states := {}; var patterns := {}
			for i in range(1500):
				g.invincible = 1e9; g.update(1.0 / 60, {}); states[b.state] = true; patterns[b.pattern] = true
			for st in ["enter", "idle", "windup", "attack", "recover"]: ok(states.has(st), "%d %s" % [stage, st])
			ok(patterns.size() == 3); g.damageBoss(b.max * .6); steps(g, 2); ok(b.phase == 2); g.damageBoss(9999); ok(b.dead); ok(g.mode == "celebrate")
			steps(g, 420); ok(g.mode == "result"); ok(g.result.rows.size() == 4 and "SABC".contains(g.result.rank)))
	test("boss weapons are destructible parts; a destroyed weapon stops its attack", func():
		for stage in range(4):
			var g = boss_ready(stage); var b = g.boss; var bhp: float = b.hp
			var pb = g.bossPartBox("A"); g.addBullet(pb.x + pb.w - 4, pb.y + pb.h / 2, -900, 0, true, 1e4, "pistol"); steps(g, 10)
			ok(b.parts.A.dead, "stage %d part A shot off" % stage); ok(b.hp < bhp, "core chipped")
			var seen := {}
			for i in range(1400):
				g.invincible = 1e9; g.update(1.0 / 60, {})
				if b.state == "attack": seen[b.pattern] = true
			ok(not seen.has(0), "stage %d weapon A no longer attacks" % stage); ok(seen.size() >= 1))
	test("boss phase 2: destroying both weapons exposes the core and armor no longer reduces damage", func():
		for stage in range(4):
			var g = boss_ready(stage); var b = g.boss
			var before: float = b.hp; g.hitBossBody(10); ok(absf(before - b.hp - 3) < 1e-6, "armored body takes 30%")
			g.damageBossPart("A", 1e6); g.damageBossPart("B", 1e6); steps(g, 12); ok(b.phase == 2)
			var h: float = b.hp; g.hitBossBody(10); ok(absf(h - b.hp - 10) < 1e-6, "exposed core takes full damage"))
	test("MISSION COMPLETE only shows after the wreck finishes exploding", func():
		var g = boss_ready(0); g.damageBoss(1e9); ok(g.mode == "celebrate"); ok(g.callout == null)
		var burst_at := -1; var call_at := -1
		for i in range(400):
			g.update(1.0 / 60, {})
			if burst_at < 0 and g.boss.burst: burst_at = i
			if call_at < 0 and g.callout != null and g.callout.text == "MISSION COMPLETE!": call_at = i
		ok(burst_at >= 0 and call_at > burst_at + 60, "callout %d after burst %d" % [call_at, burst_at]))
	test("harbor boss surfaces on the left behind the sailing ship and attacks toward the deck", func():
		var g = game(2); ok(g.ship != null); var len: float = G.STAGES[2].length
		for z in g.zones: z.cleared = true
		g.boss = {"started": false}; g.x = g.ship.x - 200; steps(g, 2); ok(not g.boss.started, "still on the dock")
		g.x = g.ship.x + 100; steps(g, 2); ok(g.boss.started, "boarding the ship starts the fight")
		var i := 0
		while i < 600 and g.boss.state == "enter":
			g.invincible = 1e9; g.update(1.0 / 60, {}); i += 1
		var b = g.boss; ok(b.flip); ok(b.x < g.ship.x and b.x > len - G.W); ok(g.ship.sea.w == G.SHIP_SEA, "sea opened behind the ship")
		var h = g.bossBox(); ok(h.x + h.w < g.ship.x + 40, "boss stays off the deck")
		steps(g, 30, {"left": true}); ok(g.x >= g.ship.x + 19, "player can't walk off the stern")
		var m = g.bossMuzzle("A"); ok(m.x > b.x, "deck gun faces right")
		b.pattern = 2; b.state = "windup"; b.clock = 0.0; g.planBoss(); steps(g, 1)
		for z in b.zones: ok(z.x > b.x, "landing party drops in front of the boss")
		steps(g, 120)
		for e in g.enemies: ok(e.x > g.ship.x - 30, "troops end up on the deck"))
	test("harbor troops ride the ferry across a wide channel to reach the player", func():
		var g = game(2); var hz = null
		for h in g.hazards:
			if h.kind == "water" and h.w > 240: hz = h; break
		g.camera = hz.x - 400; g.x = hz.x - 100; g.invincible = 1e9
		var e = g.spawnEnemy(hz.x + hz.w + 60, G.FLOOR, "grunt"); e.alert = 1
		var rode := false; var i := 0
		while i < 1500 and not (e.x < hz.x and not e.air):
			g.invincible = 1e9; g.x = hz.x - 100; g.update(1.0 / 60, {}); i += 1
			if e.get("boat") != null and not e.air: rode = true
		ok(rode, "boarded the boat"); ok(e.x < hz.x and e.hp > 0, "crossed to the player's bank (x=%d)" % e.x))
	test("boss hatch releases soldiers and a supply bee whose item drops", func():
		for stage in range(4):
			var g = boss_ready(stage); var b = g.boss; g.enemies = []; g.grenades = 0; b.hatch.clock = 0.0
			var released := 0; var drops := false
			for i in range(400):
				g.invincible = 1e9; g.update(1.0 / 60, {}); released = maxi(released, g.enemies.size())
				for s in g.supplies:
					if s.dropped: drops = true
			ok(b.hatch.count >= 1); ok(released >= 1, "soldiers released"); ok(drops, "supply bee dropped its item"))
	test("every boss can be shot down to the tally", func():
		for stage in range(4):
			var g = boss_ready(stage); var b = g.boss
			var i := 0
			while i < 4000 and not b.dead:
				g.invincible = 1e9; var h = g.bossBox(); g.addBullet(h.x - 20, h.y + h.h * .5, 900, 0, true, 25, "rocket")
				g.update(1.0 / 60, {}); i += 1
			ok(b.dead, "stage %d boss defeated" % stage); ok(g.mode == "celebrate"); steps(g, 420); ok(g.mode == "result"))
	test("full campaign reaches the ending", func():
		var g = G.new(); g.start()
		for i in range(4):
			ok(g.stage == i); g.begin(); g.startBoss(); g.boss.state = "idle"; g.damageBoss(9999); steps(g, 420); ok(g.mode == "result"); g.confirm()
			if i < 3: ok(g.mode == "briefing")
		ok(g.mode == "victory"); ok(g.best >= g.score and g.score > 0); g.confirm(); ok(g.mode == "title"))
	test("long simulation stays finite and bounds transient objects", func():
		var g = game(2)
		for z in g.zones:
			for w in z.waves: w.done = false
		for i in range(3600):
			if g.mode == "continue": g.confirm()
			g.update(1.0 / 60, {"right": i % 300 < 240, "left": i % 300 >= 240, "fire": true, "jumpPressed": i % 55 == 0, "grenadePressed": i % 200 == 0, "up": i % 120 < 20})
			ok(is_finite(g.x) and is_finite(g.y) and is_finite(g.camera)); ok(g.particles.size() <= 320))
	print("\n%d gameplay tests passed, %d failed." % [count, failed])
	quit(1 if failed else 0)
