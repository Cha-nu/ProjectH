extends Node2D
## Deterministic fixed-step arcade simulation. Coordinates are world-space pixels.
const W := 1280.0
const H := 720.0
const FLOOR := 576.0
const SPEED := 300.0
const GRAVITY := 1650.0
const STAGES := [
	{"name":"방송국 습격", "sub":"꽃과 꿀의 마을 · 끊어진 방송을 되찾아라", "length":4580.0, "zones":["꽃길 입구","방송 장비 거리","송신탑 광장"], "color":Color("85bf9e")},
	{"name":"꿀 저장고 탈환", "sub":"벌집 공장 · 컨베이어와 꿀 함정을 돌파하라", "length":5680.0, "zones":["꿀 운송장","컨베이어 홀","벌집 정제실","저장고 관제실"], "color":Color("d5a94d")},
	{"name":"과메기 해안기지", "sub":"해안과 항구 · 수륙양용 부대를 격파하라", "length":4580.0, "zones":["해변 초소","부두 창고","상륙정 선착장"], "color":Color("68afb6")},
	{"name":"과메기단 본부", "sub":"해산물 요새 · 오리고기의 초거대 전차", "length":5680.0, "zones":["요새 외벽","해산물 병영","중앙 보급로","오리고기 사령부"], "color":Color("8c829f")}
]
const WEAPONS := [
	{"name":"AKM", "rate":0.14, "damage":2.0, "speed":1050.0, "ammo":150, "color":Color("ffc45c")},
	{"name":"Kar98k", "rate":0.65, "damage":10.0, "speed":1600.0, "ammo":24, "color":Color("e6f7dd")},
	{"name":"M4", "rate":0.10, "damage":2.0, "speed":1250.0, "ammo":180, "color":Color("b5e3cf")},
	{"name":"RPG-26", "rate":0.8, "damage":18.0, "speed":650.0, "ammo":9, "color":Color("ff966f")},
	{"name":"FMG-9", "rate":0.065, "damage":1.0, "speed":950.0, "ammo":220, "color":Color("f4a9c8")},
	{"name":"Glock 19", "rate":0.24, "damage":2.0, "speed":1000.0, "ammo":-1, "color":Color("fbdfa5")}
]
const VISUALS := [
 {"width":88.0,"ratio":.40,"grip":.36,"recoil":4.0,"flash":18.0,"kind":"akm"},
 {"width":108.0,"ratio":.26,"grip":.44,"recoil":9.0,"flash":31.0,"kind":"sniper"},
 {"width":90.0,"ratio":.40,"grip":.35,"recoil":3.0,"flash":15.0,"kind":"m4"},
 {"width":104.0,"ratio":.37,"grip":.47,"recoil":12.0,"flash":34.0,"kind":"rocket"},
 {"width":62.0,"ratio":.66,"grip":.43,"recoil":2.0,"flash":11.0,"kind":"smg"},
 {"width":43.0,"ratio":.68,"grip":.28,"recoil":5.0,"flash":13.0,"kind":"pistol"}
]
var zones: Array[Dictionary] = []
var zone_index := 0
var hurt_timer := 0.0
var weapon_pop := 0.0
var gate_toast := 0.0
var last_shot_weapon := 0
var celebration := 0.0
var m4_tex: Texture2D
var fish_anim: Texture2D
var boss_parts: Texture2D
var mode := "title"
var stage := 0
var time := 0.0
var stage_time := 0.0
var pos := Vector2(180, FLOOR)
var vel := Vector2.ZERO
var face := 1.0
var grounded := true
var crouch := false
var invincible := 0.0
var entering := false
var fire_timer := 0.0
var grenade_timer := 0.0
var muzzle := 0.0
var coyote := 0.0
var jump_buffer := 0.0
var hp := 5
var lives := 3
var score := 0
var best := 0
var rescued := 0
var stage_rescued := 0
var weapon := 0
var ammo: Array[int] = []
var unlocked: Array[int] = [0, 5]
var grenades := 6
var camera_x := 0.0
var checkpoint := 180.0
var shake := 0.0
var combo := 0
var combo_timer := 0.0
var support := 0.0
var support_timer := 0.0
var banner := ""
var banner_time := 0.0
var muted := false
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var cages: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var platforms: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var props: Array[Dictionary] = []
var boss: Dictionary = {}
var tank_tex: Texture2D
var hero_tex: Texture2D
var aim_tex: Texture2D
var crew_tex: Texture2D
var menu_tex: Texture2D
var profile_tex: Texture2D
var body_tex: Texture2D
var weapons_tex: Texture2D
var bee_tex: Texture2D
var enemy_tex: Texture2D
var bg_tex: Texture2D
var font: Font
var audio: Node
var view: Node2D
var smoke_test := false
var rig_preview := false
var test_step := 0

func _ready() -> void:
	randomize()
	DisplayServer.window_set_title("허니츄러스와 과메기단의 습격")
	m4_tex = load("res://assets/characters/m4_black.png")
	fish_anim = load("res://assets/characters/fish_sheet.png")
	boss_parts = load("res://assets/characters/boss_parts.png")
	font = load("res://assets/fonts/korean.ttf")
	hero_tex = load("res://assets/characters/hero_sheet.png")
	aim_tex = load("res://assets/characters/hero_aim_sheet.png")
	crew_tex = load("res://assets/generated/boss_crew.png")
	menu_tex = load("res://assets/characters/menu_friends.png")
	profile_tex = load("res://assets/characters/profile.jpg")
	body_tex = load("res://assets/characters/hero_body_sheet.png")
	weapons_tex = load("res://assets/characters/weapons_clean.png")
	bee_tex = load("res://assets/characters/honeybee.webp")
	enemy_tex = load("res://assets/characters/enemy.webp")
	if ResourceLoader.exists("res://assets/characters/tank.png"): tank_tex = load("res://assets/characters/tank.png")
	if ResourceLoader.exists("res://assets/backgrounds.png"): bg_tex = load("res://assets/backgrounds.png")
	audio = load("res://scripts/sound.gd").new()
	add_child(audio)
	view = load("res://scripts/presentation.gd").new()
	view.g = self
	add_child(view)
	bind("left", [KEY_A, KEY_LEFT]); bind("right", [KEY_D, KEY_RIGHT])
	bind("up", [KEY_W, KEY_UP]); bind("down", [KEY_S, KEY_DOWN])
	bind("fire", [KEY_Z, KEY_J]); bind("jump", [KEY_SPACE, KEY_X])
	bind("grenade", [KEY_C, KEY_K]); bind("swap", [KEY_Q])
	bind("pause_game", [KEY_ESCAPE, KEY_P]); bind("confirm", [KEY_ENTER])
	bind("mute_game", [KEY_M]); bind("retry", [KEY_R])
	var save := ConfigFile.new()
	if save.load("user://honey_save.cfg") == OK: best = int(save.get_value("score", "best", 0))
	reset_ammo()
	load_stage()
	mode = "title"
	if "--smoke-test" in OS.get_cmdline_user_args():
		smoke_test = true
		mode = "play"
	if "--capture" in OS.get_cmdline_user_args():
		mode = "play"
		pos.x = 180
		camera_x = 0
		invincible = 0
		if "--boss" in OS.get_cmdline_user_args():
			stage = 3; load_stage(); start_boss(); pos.x = 4680; camera_x = 4400; invincible = 0
			zone_index=zones.size()-1
			for z in zones: z.cleared=true; z.entered=true
		if "--title" in OS.get_cmdline_user_args(): mode = "title"
		if "--aim-preview" in OS.get_cmdline_user_args(): Input.action_press("up")
		if "--rig-preview" in OS.get_cmdline_user_args(): mode="pause"; rig_preview=true
		if mode == "play":
			if "--boss" in OS.get_cmdline_user_args(): enemies = enemies.filter(func(e): return absf(e.p.x-pos.x)>400)
			Input.action_press("fire")
		get_tree().create_timer(1.0).timeout.connect(capture)

func capture() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/gameplay.png")
	get_tree().quit()

func bind(action: String, keys: Array) -> void:
	if InputMap.has_action(action): return
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)

func reset_ammo() -> void:
	ammo.clear()
	for w in WEAPONS: ammo.append(w.ammo)

func new_game() -> void:
	stage = 0; score = 0; rescued = 0; lives = 3; hp = 5; grenades = 6
	weapon = 0; unlocked = [0, 5]; reset_ammo(); load_stage()
	mode = "briefing"

# Metal Slug-style opening: the hero runs in from off-screen left; control starts at the start mark.
func enter_stage() -> void:
	mode = "play"; entering = true; pos.x = camera_x-70; vel.x = 0; face = 1

func load_stage() -> void:
	enemies.clear(); bullets.clear(); particles.clear(); cages.clear(); pickups.clear()
	platforms.clear(); hazards.clear(); props.clear(); boss.clear()
	pos = Vector2(180, FLOOR); vel = Vector2.ZERO; camera_x = 0; checkpoint = 180
	grounded = true; crouch = false; invincible = 0.0; entering = false; stage_time = 0
	stage_rescued = 0; support = 0; combo = 0
	zones.clear(); zone_index=0; hurt_timer=0; weapon_pop=0; gate_toast=0; celebration=0
	for z in range(STAGES[stage].zones.size()):
		var start := z*1100.0
		zones.append({"name":STAGES[stage].zones[z],"start":start,"end":start+1100,"cleared":false,"entered":z==0})
		for i in range(5):
			spawn_enemy(Vector2(start+440+i*125,FLOOR),(i+z+stage)%4)
			enemies[-1].zone=z; enemies[-1].guard=i>=3
		cages.append({"p":Vector2(start+460,FLOOR),"hp":4.0,"open":false,"taken":false,"special":z==2,"t":0.0})
		platforms.append({"rect":Rect2(start+260,441,190,20),"type":"normal","base":start+260})
		platforms.append({"rect":Rect2(start+600,396,190,20),"type":"normal","base":start+600})
		props.append({"p":Vector2(start+580,FLOOR),"hp":4.0,"kind":0})
		props.append({"p":Vector2(start+820,FLOOR),"hp":4.0,"kind":0})
		pickups.append({"p":Vector2(start+680,365),"kind":"weapon","weapon":(z+stage+1)%5,"t":0.0})
		if stage==1:
			platforms.append({"rect":Rect2(start+640,564,310,20),"type":"belt","base":start+640})
			hazards.append({"rect":Rect2(start+330,568,100,12),"kind":"honey"})
		if stage==2:
			hazards.append({"rect":Rect2(start+560,571,185,150),"kind":"water"})
			platforms.append({"rect":Rect2(start+590,531,160,20),"type":"boat","base":start+590})
		if stage==3: hazards.append({"rect":Rect2(start+570,568,100,12),"kind":"steam"})
	if cages.size()<4: cages.append({"p":Vector2(3020,FLOOR),"hp":4.0,"open":false,"taken":false,"special":false,"t":0.0})
	banner = "MISSION %02d · %s" % [stage+1, STAGES[stage].name]; banner_time = 3.8

func spawn_enemy(p: Vector2, kind: int) -> void:
	enemies.append({"p":p, "v":Vector2.ZERO, "hp":float(5+stage*2+(5 if kind==2 else 0)), "kind":kind, "t":randf_range(0,2), "shot":randf_range(1.2,2.5), "flash":0.0, "warn":0.0,"facing":-1.0,"walk":0.0,"kick":0.0,"zone":-1,"guard":false,"launch":0.0,"launch_v":Vector2.ZERO})

var pointer_actions: Dictionary = {}

func pointer_action(p: Vector2) -> String:
	if p.x<195 and p.y>530:
		var d:=p-Vector2(110,619)
		return ("left" if d.x<0 else "right") if absf(d.x)>absf(d.y) else ("up" if d.y<0 else "down")
	if p.distance_to(Vector2(1180,620))<53: return "fire"
	if p.distance_to(Vector2(1078,650))<39: return "jump"
	if p.distance_to(Vector2(1085,553))<34: return "grenade"
	if Rect2(244,96,36,44).has_point(p): return "swap"
	return ""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		var id: int=event.index if event is InputEventScreenTouch else -1
		if not event.pressed and pointer_actions.has(id):
			Input.action_release(pointer_actions[id]); pointer_actions.erase(id)
		elif event.pressed and mode=="play":
			var action:=pointer_action(event.position)
			if not action.is_empty(): pointer_actions[id]=action; Input.action_press(action); return
	if event.is_action_pressed("mute_game"):
		muted = not muted; audio.muted = muted
	if event.is_action_pressed("pause_game"):
		if mode == "play": mode = "pause"
		elif mode == "pause": mode = "play"
	if event.is_action_pressed("confirm"):
		match mode:
			"title", "gameover", "victory": new_game()
			"briefing": enter_stage()
			"pause": mode = "play"
			"clear":
				stage += 1
				if stage > 3: stage = 3; mode = "victory"; save_best()
				else:
					hp = 5; grenades = mini(9, grenades+3); reset_ammo(); load_stage(); mode = "briefing"
	if event.is_action_pressed("retry") and mode in ["pause", "gameover"]:
		hp = 5; lives = maxi(lives, 3); reset_ammo(); grenades = 6; load_stage(); enter_stage()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mode=="play" and Rect2(1202,24,54,54).has_point(get_global_mouse_position()):
			mode="pause"
			return
		if mode in ["title", "briefing", "clear", "victory", "gameover", "pause"]:
			var ev := InputEventAction.new(); ev.action = "confirm"; ev.pressed = true; _unhandled_input(ev)

func _physics_process(dt: float) -> void:
	time += dt
	if mode=="celebrate":
		celebration-=dt
		for p in particles: p.life-=dt; p.p+=p.v*dt; p.v.y+=400*dt
		particles=particles.filter(func(p): return p.life>0)
		if celebration<=0: mode="clear"
	if mode == "play":
		stage_time += dt
		update_game(dt)
		audio.music(dt, not boss.is_empty() and boss.get("active", false))
	if smoke_test:
		test_step += 1
		if test_step == 2:
			assert(cages.size() == 4); assert(enemies.size() >= 9)
			shoot(); assert(bullets.size() > 0)
		if test_step == 5:
			damage_cage(cages[0], 9); assert(cages[0].open)
			pos = cages[0].p; collect_cages(); assert(rescued == 1)
			for i in range(6): weapon = i; shoot()
		if test_step == 10:
			stage = 3; load_stage(); start_boss(); damage_boss(9999)
			assert(boss.dead); assert(mode == "celebrate")
			print("SMOKE PASS: shooting, six weapons, cages, rescue reward, final boss defeat")
			get_tree().quit()
	view.queue_redraw()

func update_game(dt: float) -> void:
	hurt_timer=maxf(0,hurt_timer-dt); weapon_pop=maxf(0,weapon_pop-dt); gate_toast-=dt
	invincible = maxf(0, invincible-dt); fire_timer -= dt; grenade_timer -= dt; muzzle -= dt
	combo_timer -= dt; banner_time -= dt; shake = maxf(0, shake-dt*22)
	if combo_timer <= 0: combo = 0
	var ctl := not entering
	var axis := Input.get_axis("left", "right") if ctl else (1.0 if pos.x < 180 else 0.0)
	if entering and axis == 0: entering = false
	crouch = ctl and grounded and Input.is_action_pressed("down")
	if axis != 0: face = signf(axis)
	if ctl and Input.is_action_just_pressed("jump"): jump_buffer = 0.12
	jump_buffer -= dt; coyote = 0.1 if grounded else coyote-dt
	if jump_buffer > 0 and coyote > 0:
		vel.y = -660; grounded = false; jump_buffer = 0; coyote = 0
		audio.play("jump"); burst(pos, 6, Color("fff0cd"), 120)
	if ctl and Input.is_action_just_released("jump") and vel.y < -260: vel.y = -260
	vel.x = move_toward(vel.x, axis * (95 if crouch else SPEED), 2400*dt)
	var old_y := pos.y
	vel.y += GRAVITY*dt; pos += vel*dt; grounded = false
	for platform in platforms:
		if platform.type == "boat": platform.rect.position.x = platform.base + sin(time*1.3)*52
		var r: Rect2 = platform.rect
		if pos.x > r.position.x-12 and pos.x < r.end.x+12 and old_y <= r.position.y+3 and pos.y >= r.position.y and vel.y >= 0:
			pos.y = r.position.y; vel.y = 0; grounded = true
			if platform.type == "belt": pos.x += 95*dt
			if platform.type == "boat": pos.x += cos(time*1.3)*67.6*dt
	var in_water := false
	for hazard in hazards:
		var r: Rect2 = hazard.rect
		if pos.x > r.position.x and pos.x < r.end.x and pos.y >= FLOOR-12:
			if hazard.kind == "water": in_water = true
			elif hazard.kind == "honey": vel.x *= 0.75
			elif fmod(time, 3.0) < 1.2: hurt()
	if pos.y >= FLOOR and not in_water: pos.y = FLOOR; vel.y = 0; grounded = true
	if pos.y > H+80: hurt(true)
	pos.x = clampf(pos.x, zones[-1].end+25 if not boss.is_empty() and boss.active else (-100.0 if entering else 30.0), STAGES[stage].length-70)
	if ctl and Input.is_action_pressed("fire") and fire_timer <= 0: shoot()
	if ctl and Input.is_action_just_pressed("grenade") and grenades > 0 and grenade_timer <= 0:
		grenades -= 1; grenade_timer = 0.45
		bullets.append({"p":pos+Vector2(face*25,-65), "v":Vector2(face*430,-580), "friendly":true, "damage":22.0, "life":1.45, "kind":"grenade", "pierce":0, "hit":[]})
		audio.play("rocket")
	if ctl and Input.is_action_just_pressed("swap"):
		weapon = unlocked[(unlocked.find(weapon)+1)%unlocked.size()]; weapon_pop=1; muzzle=0; audio.play("click"); toast(WEAPONS[weapon].name)
	update_enemies(dt); update_boss(dt); update_bullets(dt); collect_cages(); update_pickups(dt); update_zones()
	for p in particles:
		p.life -= dt; p.p += p.v*dt; p.v.y += 400*dt
	particles = particles.filter(func(p): return p.life > 0)
	if particles.size() > 260: particles = particles.slice(particles.size()-260)
	if support > 0:
		support -= dt; support_timer -= dt
		if support_timer < 0:
			support_timer = 0.32
			var origin := pos+Vector2(-face*55,-95)
			var aim := Vector2(face,0.15).normalized()
			for e in enemies:
				if (e.p.x-pos.x)*face > 0 and e.p.distance_to(pos) < 600:
					aim = (e.p+Vector2(0,-30)-origin).normalized()
					break
			add_bullet(origin, aim*900, true, 3, "support")
	if boss.is_empty() and zones.all(func(z): return z.cleared) and pos.x>zones[-1].end+110: start_boss()
	var target := clampf(pos.x-370, 0, STAGES[stage].length-W)
	if not boss.is_empty() and boss.get("active", false): target = STAGES[stage].length-W
	camera_x = lerpf(camera_x, target, 1.0-exp(-dt*5.5))

func player_frame() -> int:
	if hurt_timer>0: return 7
	if crouch: return 5
	if not grounded: return 6
	if absf(vel.x)>30: return int(stage_time*12)%4
	return 4

func aim_direction() -> Vector2:
	if Input.is_action_pressed("up"): return Vector2(0,-1) if absf(Input.get_axis("left","right"))<.1 else Vector2(face,-1).normalized()
	if Input.is_action_pressed("down") and not grounded: return Vector2(0,1) if absf(Input.get_axis("left","right"))<.1 else Vector2(face,1).normalized()
	return Vector2(face,0)

func weapon_pose() -> Dictionary:
	var frame := player_frame()
	var anchors := [Vector2(.52,.55),Vector2(.53,.55),Vector2(.54,.54),Vector2(.51,.55),Vector2(.52,.54),Vector2(.55,.67),Vector2(.55,.49),Vector2(.55,.53)]
	var visual: Dictionary=VISUALS[weapon]
	var aim:=aim_direction()
	var up: bool=aim.y<-.4 and hurt_timer<=0
	var aim_frame: int=(5 if muzzle>.045 else 4) if absf(aim.x)>.2 else 6 if not grounded else 7 if crouch else 2+int(stage_time*9)%2 if absf(vel.x)>30 else 1 if muzzle>.045 else 0
	var rear: Array=[Vector2(.69,.30),Vector2(.70,.34),Vector2(.72,.29),Vector2(.77,.30),Vector2(.74,.35),Vector2(.78,.36),Vector2(.70,.28),Vector2(.77,.42)]
	if up: anchors[frame]=rear[aim_frame]
	var recoil: float=maxf(0,muzzle)/.09*visual.recoil*.35
	var offset: Vector2=-aim*recoil+Vector2(0,sin(stage_time*3)*.65 if grounded and absf(vel.x)<30 else 0)
	var origin: Vector2=pos+Vector2((anchors[frame].x-.5)*108*face,(anchors[frame].y-1)*108)+offset
	var reach: float=visual.width*.75*(1-visual.grip)
	var normal: float=-visual.width*.75*visual.ratio*.13*face
	return {"up":up,"aim_frame":aim_frame,"offset":offset,"origin":origin,"muzzle":origin+aim*reach+Vector2(-aim.y,aim.x)*normal,"aim":aim,"angle":(aim*face).angle(),"width":visual.width*.75,"height":visual.width*.75*visual.ratio,"grip":visual.grip}

func shoot() -> void:
	if ammo[weapon]==0: weapon=5; weapon_pop=1; toast("탄약 소진 · Glock 19")
	var w: Dictionary=WEAPONS[weapon]
	var visual: Dictionary=VISUALS[weapon]
	if ammo[weapon]>0: ammo[weapon]-=1
	var pose:=weapon_pose()
	add_bullet(pose.muzzle,pose.aim*w.speed,true,w.damage,visual.kind)
	bullets[-1].weapon=weapon; bullets[-1].color=w.color
	fire_timer=w.rate; muzzle=.09; last_shot_weapon=weapon
	audio.play(visual.kind,-15)
	burst(pose.muzzle,12 if weapon==3 else 3,w.color,180 if weapon==3 else 100)
	if weapon!=3: particles.append({"p":pose.origin-Vector2(0,9),"v":Vector2(-face*100+randf_range(-30,30),-randf_range(100,180)),"life":.6,"max":.6,"color":Color("efc17c"),"size":3.0,"kind":"casing"})
	for enemy in enemies:
		if enemy.p.distance_to(pos)<90: enemy.hp-=4; enemy.flash=.12; burst(enemy.p-Vector2(0,30),5,Color("fff4be"),180)

func update_zones() -> void:
	if not boss.is_empty(): return
	for i in range(zones.size()):
		var z: Dictionary=zones[i]
		if not z.entered and pos.x>=z.start+20:
			z.entered=true; zone_index=i; checkpoint=z.start+100
			for j in range(2):
				spawn_enemy(Vector2(z.start+580+j*100,120-j*80),0)
				enemies[-1].zone=i; enemies[-1].launch=2; enemies[-1].launch_v=Vector2(-40,50)
			toast("AREA %d / %d · %s"%[i+1,zones.size(),z.name])
		var guards:=0
		for e in enemies:
			if e.zone==i and e.guard and e.hp>0: guards+=1
		if not z.cleared and guards==0 and pos.x>=z.end-280:
			z.cleared=true; score+=300; audio.play("rescue")
			toast("전 구역 확보! · 보스 구역으로 진입" if i==zones.size()-1 else "구역 확보! · 다음 구역으로 이동")
		if not z.cleared and pos.x>z.end-70:
			pos.x=z.end-70; vel.x=0
			if gate_toast<=0: toast("통로 봉쇄 · 경비 %d마리 남음"%guards); gate_toast=2.5
			break

func add_bullet(p: Vector2, v: Vector2, friendly: bool, damage: float, kind: String) -> void:
	bullets.append({"p":p, "v":v, "friendly":friendly, "damage":damage, "life":2.5, "kind":kind, "pierce":3 if kind=="sniper" else 0, "hit":[]})

func update_enemies(dt: float) -> void:
	for e in enemies:
		e.t += dt; e.flash = maxf(0,e.flash-dt); e.kick=maxf(0,e.kick-dt)
		if e.hp <= 0: continue
		if e.p.x > camera_x+W+100 or e.p.x < camera_x-250: continue
		var dx: float = pos.x-e.p.x
		var dir := signf(dx)
		e.shot -= dt; e.facing=dir if dir!=0 else e.facing; e.walk=1.0 if absf(dx)>300 else 0.0
		if e.launch>0:
			e.launch-=dt; e.launch_v.y+=1250*dt; e.p+=e.launch_v*dt
			if e.p.y>=FLOOR: e.p.y=FLOOR; e.launch=0; e.kick=.25
		elif e.kind == 1:
			e.p.y = FLOOR-150+sin(e.t*2.5)*65
			e.p.x += dir*45*dt
		elif e.kind == 3:
			e.p.x += dir*125*dt
			e.p.y = FLOOR-absf(sin(e.t*3))*55
		elif absf(dx) > 300:
			e.p.x += dir*(45+stage*9)*dt
		if e.shot < 0.45: e.warn = 1.0
		if e.shot <= 0:
			e.shot = randf_range(1.9,3.0)-stage*0.16; e.warn = 0.0; e.kick=.22
			var origin: Vector2 = e.p+Vector2(dir*24,-30)
			var aim: Vector2 = (pos+Vector2(0,-45)-origin).normalized()
			add_bullet(origin, aim*(250+stage*22), false, 1, "enemy")
			if e.kind == 2:
				add_bullet(origin, aim.rotated(0.18)*250, false, 1, "enemy")
				add_bullet(origin, aim.rotated(-0.18)*250, false, 1, "enemy")
		if absf(dx) < 35 and absf(e.p.y-pos.y) < 65: hurt()
	for e in enemies:
		if e.hp <= 0:
			kill_reward(e.p)
			if randf() < 0.17: pickups.append({"p":e.p-Vector2(0,30), "kind":"ammo", "weapon":0, "t":0.0})
	enemies = enemies.filter(func(e): return e.hp > 0)

func kill_reward(p: Vector2) -> void:
	combo += 1; combo_timer = 2.8; score += 100*mini(combo,5)
	burst(p-Vector2(0,30), 16, Color("ffc86a"), 230)
	audio.play("hit", -19)

func update_bullets(dt: float) -> void:
	var explosions: Array[Vector2] = []
	for b in bullets:
		b.life -= dt
		var old: Vector2 = b.p
		if b.kind in ["grenade", "honey"]: b.v.y += 950*dt
		b.p += b.v*dt
		if b.kind=="rocket" and randf()<.6: particles.append({"p":b.p,"v":Vector2(-b.v.x*.08,randf_range(-15,15)),"life":.35,"max":.35,"color":Color("d8c5c0"),"size":randf_range(5,10),"kind":"smoke"})
		if b.kind == "grenade" and b.p.y >= FLOOR-8:
			b.p.y = FLOOR-8; b.v.y *= -0.48; b.v.x *= 0.75
		if b.kind == "honey" and b.p.y >= FLOOR-8:
			b.life = 0; burst(b.p, 14, Color("ffbf49"), 220)
			if b.p.distance_to(pos) < 95: hurt()
		if b.kind == "grenade" and b.life <= 0: explosions.append(b.p)
		if b.friendly and b.kind != "grenade":
			for e in enemies:
				if e.hp <= 0 or b.hit.has(e): continue
				if segment_hit(old, b.p, Rect2(e.p+Vector2(-38,-68),Vector2(76,68))):
					e.hp -= b.damage; e.flash = 0.12; b.hit.append(e)
					burst(b.p, 5, Color("fff1b7"), 140)
					if b.kind == "rocket": explosions.append(b.p)
					if b.pierce <= 0: b.life = 0; break
					b.pierce -= 1
			if b.life > 0:
				for cage in cages:
					if not cage.open and segment_hit(old,b.p,Rect2(cage.p+Vector2(-43,-95),Vector2(86,95))):
						damage_cage(cage,b.damage); b.life=0; break
			if b.life > 0:
				for prop in props:
					if prop.hp > 0 and segment_hit(old,b.p,Rect2(prop.p+Vector2(-26,-54),Vector2(52,54))):
						prop.hp -= b.damage; b.life = 0
						if prop.hp <= 0: explosions.append(prop.p-Vector2(0,20)); score += 50
			if b.life > 0 and not boss.is_empty() and not boss.dead:
				var size := Vector2(540,440) if stage == 3 else Vector2(350,300)
				if segment_hit(old,b.p,Rect2(boss.p-size+Vector2(size.x/2,0),size)):
					damage_boss(b.damage); b.life=0
					if b.kind == "rocket": explosions.append(b.p)
		elif not b.friendly:
			var rect := Rect2(pos+Vector2(-14,-35 if crouch else -69),Vector2(28,35 if crouch else 69))
			if segment_hit(old,b.p,rect): hurt(); b.life=0
		if b.p.x < camera_x-300 or b.p.x > camera_x+W+500 or b.p.y < -100: b.life=0
	bullets = bullets.filter(func(b): return b.life > 0)
	for p in explosions: explode(p)

func segment_hit(a: Vector2, b: Vector2, r: Rect2) -> bool:
	if r.has_point(a) or r.has_point(b): return true
	var steps := maxi(1,int(a.distance_to(b)/12))
	for i in range(1,steps):
		if r.has_point(a.lerp(b,float(i)/steps)): return true
	return false

func explode(p: Vector2) -> void:
	burst(p, 35, Color("ffad51"), 340); shake = maxf(shake,7); audio.play("explode",-10)
	for e in enemies:
		if e.p.distance_to(p) < 165: e.hp -= 22; e.flash=0.2
	for cage in cages:
		if cage.p.distance_to(p) < 150: damage_cage(cage,9)
	if not boss.is_empty() and not boss.dead and boss.p.distance_to(p) < 330: damage_boss(25)

func damage_cage(cage: Dictionary, damage: float) -> void:
	if cage.open: return
	cage.hp -= damage
	if cage.hp <= 0:
		cage.open = true; burst(cage.p-Vector2(0,40),14,Color("bee9d0"),180)

func collect_cages() -> void:
	for cage in cages:
		if cage.open and not cage.taken and pos.distance_to(cage.p) < 85:
			cage.taken = true; rescued += 1; stage_rescued += 1; score += 500; audio.play("rescue",-10)
			if cage.special:
				support = 22; toast("특수 허니비 구출! · 22초 지원 사격")
			else:
				hp = mini(5,hp+1); grenades = mini(9,grenades+1)
				var found := (rescued+stage)%5
				give_weapon(found); toast("허니비 구출! +500 · "+WEAPONS[found].name)

func update_pickups(dt: float) -> void:
	for item in pickups:
		item.t += dt
		if pos.distance_to(item.p+Vector2(0,35)) < 72:
			if item.kind == "weapon": give_weapon(item.weapon); toast(WEAPONS[item.weapon].name+" 획득!")
			else: ammo[weapon] = mini(WEAPONS[weapon].ammo,ammo[weapon]+50); score += 100
			item.t = -99; audio.play("pickup")
	pickups = pickups.filter(func(p): return p.t >= 0)

func give_weapon(index: int) -> void:
	if not unlocked.has(index): unlocked.append(index)
	ammo[index] = WEAPONS[index].ammo; weapon = index; weapon_pop=1.2; muzzle=0

func hurt(fall := false) -> void:
	if (invincible > 0 or entering) and not fall: return
	hp -= 1; invincible = 1.8; hurt_timer=.25; shake = 7; combo = 0; audio.play("hit",-10)
	burst(pos-Vector2(0,40),12,Color("ffafc3"),200)
	if fall:
		pos = Vector2(checkpoint,FLOOR-150); vel = Vector2.ZERO
	if hp <= 0:
		lives -= 1
		if lives <= 0: mode = "gameover"; save_best()
		else:
			hp = 5; pos = Vector2(checkpoint,FLOOR-100); vel = Vector2.ZERO
			invincible = 3.0; grenades = maxi(grenades,3); toast("다시 출동! · 남은 목숨 %d"%lives)

func start_boss() -> void:
	var health:=620.0 if stage==3 else 150.0+stage*55
	var home: float=STAGES[stage].length-330
	boss={"p":Vector2(STAGES[stage].length+300,FLOOR),"home":home,"hp":health,"max":health,"active":true,"dead":false,"t":0.0,"phase":1,"flash":0.0,"warn":false,"pattern":0,"state":"enter","clock":2.2,"recoil":0.0,"track":0.0}
	toast("WARNING · "+["방송 방해 장갑차","꿀 공장 파괴자","과메기 상륙정","오리고기 · 초거대 과메기 전차"][stage]); shake=5

func update_boss(dt: float) -> void:
	if boss.is_empty() or boss.dead: return
	boss.t+=dt; boss.clock-=dt; boss.flash=maxf(0,boss.flash-dt); boss.recoil=maxf(0,boss.recoil-dt*3)
	boss.track+=dt*(8 if boss.state=="enter" else 2); boss.warn=boss.state=="windup"
	if boss.state=="enter":
		boss.p.x=lerpf(boss.p.x,boss.home,1-exp(-dt*3))
		if boss.clock<=0: boss.p.x=boss.home; boss.state="idle"; boss.clock=1.2
		return
	if boss.hp<boss.max*.5 and boss.phase==1:
		boss.phase=2; boss.state="break"; boss.clock=1.3; shake=12
		for i in range(12): particles.append({"p":boss.p+Vector2(randf_range(-200,170),-randf_range(60,210)),"v":Vector2(randf_range(-260,220),randf_range(-400,-120)),"life":1.8,"max":1.8,"color":Color("8c9b70"),"size":randf_range(14,26),"kind":"armor"})
		toast("장갑 파괴! · 과메기 본체 노출")
	if boss.state=="idle":
		boss.p.x=boss.home+sin(boss.t*1.2)*12
		if boss.clock<=0: boss.state="windup"; boss.clock=.9 if boss.phase==1 else .65
	elif boss.state=="windup" and boss.clock<=0: boss.state="attack"; boss.clock=.48; boss_attack()
	elif boss.state=="attack" and boss.clock<=0: boss.state="recover"; boss.clock=.7
	elif boss.state in ["recover","break"] and boss.clock<=0:
		boss.pattern=(boss.pattern+1)%3; boss.state="idle"; boss.clock=1.15 if boss.phase==1 else .55
	if pos.x>boss.p.x-180 and pos.y>416: hurt()

func boss_attack() -> void:
	var origin: Vector2=boss.p+Vector2(-277,-212)*(1.0 if stage==3 else .68)
	boss.recoil=1.0; shake=4
	if boss.pattern==0:
		for i in range(5 if boss.phase==1 else 8): add_bullet(origin,Vector2.from_angle(PI-.46+i*.13)*305,false,1,"enemy")
	elif boss.pattern==1:
		for i in range(2 if boss.phase==1 else 3):
			spawn_enemy(origin-Vector2(i*40,0),3); enemies[-1].launch=1.5; enemies[-1].launch_v=Vector2(-220-i*75,-260-i*80)
		burst(origin,18,Color("fff1aa"),250)
	else:
		for i in range(3): add_bullet(origin,Vector2(-220-i*115,-550-i*45),false,1,"honey")
	audio.play("heavy",-11)

func damage_boss(amount: float) -> void:
	if boss.is_empty() or boss.dead: return
	boss.hp -= amount; boss.flash=0.08; score+=5
	if boss.hp <= 0:
		boss.dead=true; boss.active=false; score+=5000+stage_rescued*500
		for bullet in bullets: bullet.life = 0
		enemies.clear()
		for i in range(55):
			particles.append({"p":boss.p+Vector2(randf_range(-180,120),randf_range(-200,-70)),"v":Vector2(randf_range(-400,300),randf_range(-600,-150)),"life":4.0,"max":4.0,"color":Color.WHITE,"size":randf_range(20,38),"kind":"fish"})
		shake=14; audio.play("rescue",-8); mode="celebrate"; celebration=3.0; save_best()

func burst(p: Vector2, count: int, color: Color, speed: float) -> void:
	for i in range(count):
		var life := randf_range(0.2,0.65)
		particles.append({"p":p,"v":Vector2.from_angle(randf()*TAU)*randf_range(speed*0.3,speed),"life":life,"max":life,"color":color,"size":randf_range(2,7),"kind":"spark"})

func toast(message: String) -> void:
	banner=message; banner_time=2.5

func save_best() -> void:
	best=maxi(best,score)
	var save := ConfigFile.new(); save.set_value("score","best",best); save.save("user://honey_save.cfg")
