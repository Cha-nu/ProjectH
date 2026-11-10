extends Node2D
var g: Node2D
const INK := Color("69444f")
const PAPER := Color("fff8f5")
const PINK := Color("FFD8D9")
const GOLD := Color("f4a7b8")
const TEAL := Color("35685e")

func region_texture(rect: Rect2, tex: Texture2D, region: Rect2, tint: Color = Color.WHITE) -> void:
	draw_texture_rect_region(tex, rect, region, tint)

func _draw() -> void:
	if g.rig_preview:
		draw_rig_preview()
		return
	background()
	if g.mode == "title":
		title_screen()
		return
	var j := Vector2(sin(g.time*83)*g.shake, cos(g.time*71)*g.shake*0.6)
	draw_set_transform(Vector2(-g.camera_x,0)+j)
	world()
	draw_set_transform(Vector2.ZERO)
	hud()
	if g.mode in ["briefing","pause","clear","gameover","victory"]: overlay()

func box(rect: Rect2, color: Color, radius := 12, border: Color = Color.TRANSPARENT, width := 0) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color=color
	s.set_corner_radius_all(radius)
	s.border_color=border
	s.set_border_width_all(width)
	draw_style_box(s,rect)

func text_at(text: String, p: Vector2, size: int, color: Color = PAPER) -> void:
	draw_string(g.font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func center(text: String, p: Vector2, size: int, color: Color = PAPER) -> void:
	var width: float = g.font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	text_at(text,p-Vector2(width/2,0),size,color)

func image(tex: Texture2D, rect: Rect2, tint: Color = Color.WHITE) -> void:
	if tex: draw_texture_rect(tex,rect,false,tint)

func bee(p: Vector2, size: float, tint: Color = Color.WHITE) -> void:
	# Source has intentional transparent padding: crop only at rendering time.
	if g.bee_tex: region_texture(Rect2(p-Vector2(size/2,size*0.80),Vector2(size,size*0.8)),g.bee_tex,Rect2(50,130,370,320),tint)

func fish(p: Vector2, size: float, tint: Color = Color.WHITE) -> void:
	if g.enemy_tex: region_texture(Rect2(p-Vector2(size/2,size*0.58),Vector2(size,size*0.58)),g.enemy_tex,Rect2(25,185,465,295),tint)

func world_transform() -> Transform2D:
	var shake:=Vector2(sin(g.time*83)*g.shake,cos(g.time*71)*g.shake*.6) if g.mode=="play" else Vector2.ZERO
	return Transform2D(0,Vector2(-g.camera_x,0)+shake)

func hero(p: Vector2, size: float, frame: int, facing := 1.0, tint: Color = Color.WHITE, modular := false) -> void:
	var texture: Texture2D=g.body_tex if modular else g.hero_tex
	var cell: Vector2=texture.get_size()/Vector2(4,2)
	var region:=Rect2(Vector2(frame%4,frame/4)*cell,cell)
	var base:=world_transform() if modular else Transform2D.IDENTITY
	draw_set_transform_matrix(base*Transform2D(0,Vector2(facing,1),0,p))
	region_texture(Rect2(-size/2,-size,size,size),texture,region,tint)
	draw_set_transform_matrix(base)

func weapon_icon(index: int, dest: Rect2, tint: Color = Color.WHITE) -> void:
	if index==2:
		var size: Vector2=g.m4_tex.get_size()
		region_texture(dest,g.m4_tex,Rect2(size*Vector2(.025,.16),size*Vector2(.95,.74)),tint)
		return
	var regions := [Rect2(.01,.28,.343,.21),Rect2(.351,.319,.349,.14),Rect2(.709,.28,.287,.21),Rect2(.026,.59,.351,.17),Rect2(.438,.58,.229,.23),Rect2(.775,.61,.166,.18)]
	var r: Rect2=regions[index]
	r.position*=g.weapons_tex.get_size(); r.size*=g.weapons_tex.get_size()
	region_texture(dest,g.weapons_tex,r,tint)

func gun(tint: Color) -> void:
	var p: Dictionary=g.weapon_pose()
	draw_set_transform_matrix(world_transform()*Transform2D(p.angle,Vector2(g.face,1),0,p.origin))
	weapon_icon(g.weapon,Rect2(-p.width*p.grip,-p.height*.48,p.width,p.height),tint)
	draw_circle(Vector2(0,p.height*.18),3.3,Color("ffe9df"))
	if g.weapon!=5: draw_circle(Vector2(minf(p.width*.28,19),p.height*.12),3.4,Color("ffe9df"))
	draw_set_transform_matrix(world_transform())

func muzzle_flash() -> void:
	if g.muzzle<=0: return
	var p: Dictionary=g.weapon_pose()
	var v: Dictionary=g.VISUALS[g.last_shot_weapon]
	var f: float=g.muzzle/.09
	var colors: Array[Color]=[Color("ffd079"),Color("fff1c0"),Color("beeaff"),Color("ffa662"),Color("ffc5e5"),Color("ffe3a7")]
	draw_set_transform_matrix(world_transform()*Transform2D(p.aim.angle(),p.muzzle))
	var col: Color=colors[g.last_shot_weapon]; col.a=f*.4
	draw_circle(Vector2(4,0),v.flash*.7,col)
	var length: float=v.flash*(1.1+f)
	col.a=f
	draw_colored_polygon(PackedVector2Array([Vector2(-3,-4),Vector2(length*.45,-v.flash*.4),Vector2(length*.36,-3),Vector2(length,0),Vector2(length*.36,3),Vector2(length*.45,v.flash*.4),Vector2(-3,4)]),col)
	draw_circle(Vector2(3,0),4,PAPER)
	draw_set_transform_matrix(world_transform())

func projectile(b: Dictionary) -> void:
	var dir: Vector2=b.v.normalized()
	var index: int=b.get("weapon",0)
	var color: Color=Color("9bf4ce") if b.kind=="support" else g.WEAPONS[index].color
	if b.kind=="rocket":
		draw_set_transform_matrix(world_transform()*Transform2D(dir.angle(),b.p))
		box(Rect2(-17,-5,30,10),Color("636c54"),4,Color("493b3c"),2)
		draw_line(Vector2(-18,0),Vector2(-40,0),Color("ffab62"),7)
		draw_circle(Vector2(-34,0),4,Color("fff5be"))
		draw_set_transform_matrix(world_transform()); return
	var trail:=72.0 if b.kind=="sniper" else 12.0 if b.kind=="smg" else 9.0 if b.kind=="pistol" else 24.0
	var dim:=color; dim.a=.27
	draw_line(b.p-dir*trail,b.p,dim,8 if b.kind=="sniper" else 6)
	draw_line(b.p-dir*trail*.7,b.p,color,2.5 if b.kind=="sniper" else 3)
	draw_circle(b.p,3 if b.kind=="pistol" else 2.5,PAPER)

func background() -> void:
	var sky: Color = [Color("b8dfd4"),Color("805c43"),Color("96cfcd"),Color("675a77")][g.stage]
	draw_rect(Rect2(0,0,1280,720),sky)
	if g.bg_tex:
		var cell: Vector2 = g.bg_tex.get_size()/2.0
		var region := Rect2(Vector2(g.stage%2,g.stage/2)*cell,cell)
		var offset: float = fmod(round(g.camera_x*0.12),1280)
		for i in range(2):
			var flip: bool=(int(g.camera_x*0.12/1280)+i)%2==1
			draw_set_transform(Vector2(i*1280-offset+(1280 if flip else 0),0),0,Vector2(-1 if flip else 1,1))
			region_texture(Rect2(0,0,1280,576),g.bg_tex,region)
		draw_set_transform(Vector2.ZERO)
	else:
		for i in range(12):
			var x := fmod(i*170-g.camera_x*0.2+10000,1600)-120
			draw_circle(Vector2(x,420),150,Color("a5c8a1"))

func world() -> void:
	var length: float = g.STAGES[g.stage].length
	var ground_color: Color = [Color("a6c58e"),Color("bda06d"),Color("8b7971"),Color("7d7883")][g.stage]
	draw_rect(Rect2(g.camera_x-30,576,1340,144),INK)
	draw_rect(Rect2(g.camera_x-30,581,1340,139),ground_color)
	draw_rect(Rect2(g.camera_x-30,593,1340,127),Color(0.24,0.18,0.18,0.22))
	for hazard in g.hazards:
		var r: Rect2 = hazard.rect
		if hazard.kind=="water":
			draw_rect(r,Color("5caaa8"))
			for j in range(6): draw_line(Vector2(r.position.x+8+j*32,589+sin(g.time*3+j)*3),Vector2(r.position.x+29+j*32,589),PAPER,2)
		elif hazard.kind=="honey":
			box(Rect2(r.position.x,570,r.size.x,17),GOLD,8)
			for j in range(5): draw_circle(Vector2(r.position.x+15+j*25,576+sin(g.time*3+j)*3),4,Color("fff2b6"))
		else:
			box(Rect2(r.position.x,565,r.size.x,15),INK,3)
			if fmod(g.time,3)<1.2:
				for j in range(5): draw_circle(Vector2(r.position.x+12+j*19,535-sin(g.time*10+j)*20),13,Color(1,0.8,0.55,0.55))
	for platform in g.platforms:
		var r: Rect2 = platform.rect
		if r.position.x < g.camera_x-250 or r.position.x > g.camera_x+1400: continue
		box(Rect2(r.position+Vector2(2,5),r.size),INK,6)
		box(r,TEAL if platform.type=="normal" else Color("ab804f"),6,INK,3)
		draw_line(r.position+Vector2(8,4),r.position+Vector2(r.size.x-8,4),Color("d4e4b4"),3)
		if platform.type=="belt":
			for j in range(10):
				var xx: float=r.position.x+fmod(j*34+g.time*90,r.size.x)
				draw_line(Vector2(xx,r.position.y+8),Vector2(xx+8,r.position.y+14),GOLD,3)
		elif platform.type=="boat":
			draw_colored_polygon(PackedVector2Array([r.position+Vector2(-12,12),r.position+Vector2(r.size.x+12,12),r.end+Vector2(-25,26),r.position+Vector2(25,46)]),Color("805546"))
		else:
			draw_line(r.position+Vector2(25,20),r.position+Vector2(25,68),Color("5f7863"),9)
			draw_line(r.position+Vector2(r.size.x-25,20),r.position+Vector2(r.size.x-25,68),Color("5f7863"),9)
	for prop in g.props:
		if prop.hp<=0: continue
		var p: Vector2=prop.p
		box(Rect2(p-Vector2(26,54),Vector2(52,54)),Color("c99152"),6,INK,3)
		draw_line(p+Vector2(-20,-48),p+Vector2(20,-6),Color("f6ce86"),5)
		draw_line(p+Vector2(20,-48),p+Vector2(-20,-6),Color("f6ce86"),5)
		center("꿀",p+Vector2(0,-19),18,INK)
	for cage in g.cages: draw_cage(cage)
	for item in g.pickups:
		var p: Vector2=item.p+Vector2(0,sin(g.time*4)*5)
		draw_circle(p,28,Color(1,0.88,0.4,0.2))
		box(Rect2(p-Vector2(23,21),Vector2(46,42)),GOLD,8,INK,3)
		center("W" if item.kind=="weapon" else "+",p+Vector2(0,8),23,INK)
		if item.kind=="weapon": center(g.WEAPONS[item.weapon].name,p+Vector2(0,-32),13,INK)
	for enemy in g.enemies: draw_enemy(enemy)
	if not g.boss.is_empty(): draw_boss()
	for b in g.bullets:
		var p: Vector2=b.p
		if b.kind=="grenade":
			draw_circle(p,10,INK); draw_circle(p,7,TEAL); draw_line(p+Vector2(0,-8),p+Vector2(5,-14),GOLD,3)
		elif b.kind=="honey":
			box(Rect2(p-Vector2(13,17),Vector2(26,34)),GOLD,5,INK,3)
		elif b.friendly:
			projectile(b)
		else:
			draw_circle(p,10,INK); draw_circle(p,7,Color("ff8465")); draw_circle(p-Vector2(2,2),3,PAPER)
	var frame: int=g.player_frame()
	var tint:=Color.WHITE
	if g.invincible>0: tint.a=.45 if int(g.stage_time*16)%2==0 else 1.0
	draw_set_transform_matrix(world_transform())
	ellipse_shape(g.pos+Vector2(0,4),Vector2(31,6),Color(0.15,0.12,0.12,0.25))
	var pose: Dictionary=g.weapon_pose()
	if pose.up:
		var cell: Vector2=g.aim_tex.get_size()/Vector2(4,2)
		draw_set_transform_matrix(world_transform()*Transform2D(0,Vector2(g.face,1),0,g.pos+pose.offset))
		region_texture(Rect2(-54,-108,108,108),g.aim_tex,Rect2(Vector2(pose.aim_frame%4,pose.aim_frame/4)*cell,cell),tint)
		draw_set_transform_matrix(world_transform())
	else: hero(g.pos+pose.offset,108,frame,g.face,tint,true)
	gun(tint); muzzle_flash()
	if g.support>0:
		bee(g.pos+Vector2(-g.face*75,-95+sin(g.time*7)*7),57)
		center("SUPPORT",g.pos+Vector2(-g.face*75,-150),11,TEAL)
	for p in g.particles:
		if p.kind=="fish": fish(p.p,p.size*2)
		elif p.kind in ["armor","casing"]:
			draw_set_transform_matrix(world_transform()*Transform2D(p.life*8,p.p))
			box(Rect2(-p.size/2,-p.size/3,p.size,p.size*.65),p.color,2)
			draw_set_transform_matrix(world_transform())
		else:
			var c: Color=p.color; c.a=clampf(p.life/p.max,0,1)
			draw_circle(p.p,p.size*c.a,c)
	for i in range(g.zones.size()):
		var z: Dictionary=g.zones[i]
		var guards:=0
		for e in g.enemies:
			if e.zone==i and e.guard and e.hp>0: guards+=1
		box(Rect2(z.end-29,365,32,211),Color("afdbb8") if z.cleared else PINK,14,Color("946375"),2)
		draw_circle(Vector2(z.end-13,393),8,Color("568466") if z.cleared else Color("e77894"))
		if not z.cleared:
			for y in range(430,560,27): draw_line(Vector2(z.end-65,y),Vector2(z.end+35,y-12),Color("ffb8c6aa"),7)
		box(Rect2(z.end-106,318,190,35),PAPER,17)
		center("구역 확보 ✓" if z.cleared else "경비 %d · 통로 봉쇄"%guards,Vector2(z.end-11,341),13,INK)

func ellipse_shape(p: Vector2, radii: Vector2, color: Color) -> void:
	var points:=PackedVector2Array()
	for i in range(32): points.append(p+Vector2(cos(i*TAU/32)*radii.x,sin(i*TAU/32)*radii.y))
	draw_colored_polygon(points,color)

func draw_cage(c: Dictionary) -> void:
	if c.taken: return
	var p: Vector2=c.p
	bee(p+Vector2(0,-12+sin(g.time*5)*3),67)
	if not c.open:
		box(Rect2(p-Vector2(46,96),Vector2(92,96)),Color(0.15,0.25,0.23,0.16),9,INK,5)
		for j in range(4): draw_line(p+Vector2(-30+j*20,-91),p+Vector2(-30+j*20,-7),Color("7d8b78"),5)
		draw_line(p+Vector2(-42,-20),p+Vector2(42,-20),INK,4)
		box(Rect2(p-Vector2(10,52),Vector2(20,22)),GOLD,3,INK,2)
		center("HELP!" if not c.special else "SPECIAL",p+Vector2(0,-111),13,INK)
	else:
		center("고마워!",p+Vector2(0,-90),15,TEAL)
		draw_line(p+Vector2(-43,-4),p+Vector2(43,-4),INK,4)
		center("가까이 가서 구출",p+Vector2(0,23),12,INK)

func draw_enemy(e: Dictionary) -> void:
	var size:=105.0 if e.kind==2 else 92.0
	var frame:=6 if e.launch>0 or (e.kind==3 and e.p.y<550) else 7 if e.kick>0 else 5 if e.warn else int(e.t*9)%4 if e.walk else 4
	var cell: Vector2=g.fish_anim.get_size()/Vector2(4,2)
	var beat: float=sin(e.t*9)
	var amount:=.035 if e.walk else .015
	var sx:=1+amount*beat; var sy:=1-amount*beat
	ellipse_shape(e.p+Vector2(0,4),Vector2(size*.36,6),Color("261f1f2a"))
	draw_set_transform_matrix(world_transform()*Transform2D(.025*beat if e.walk else 0,Vector2(-sx if e.facing>0 else sx,sy),0,e.p))
	region_texture(Rect2(-size/2,-size,size,size),g.fish_anim,Rect2(Vector2(frame%4,frame/4)*cell,cell),Color(1.6,1.6,1.6) if e.flash>0 else Color.WHITE)
	draw_set_transform_matrix(world_transform())
	if e.kind==1:
		draw_line(e.p+Vector2(-32,-85),e.p+Vector2(32,-85),INK,3)
		draw_line(e.p+Vector2(-40*sin(g.time*40),-92),e.p+Vector2(40*sin(g.time*40),-92),TEAL,4)
	if e.kind==2: box(Rect2(e.p+Vector2(-45,-38),Vector2(12,37)),Color("829b89"),5,INK,2)
	if e.guard: box(Rect2(e.p+Vector2(-17,-112),Vector2(34,20)),PINK,10); center("★",e.p+Vector2(0,-97),13,INK)
	if e.warn: center("!",e.p+Vector2(0,-119),27,Color("d64c71"))

func boss_part(index: int, dest: Rect2) -> void:
	var regions: Array[Rect2]=[Rect2(.01,.015,.62,.61),Rect2(.63,.23,.365,.31),Rect2(.125,.645,.247,.34),Rect2(.45,.68,.545,.30)]
	var r:=regions[index]; r.position*=g.boss_parts.get_size(); r.size*=g.boss_parts.get_size()
	region_texture(dest,g.boss_parts,r)

func draw_boss() -> void:
	var b: Dictionary=g.boss
	if g.stage<3:
		var size:=400.0
		var cell: Vector2=g.crew_tex.get_size()/Vector2(3,1)
		var bob:=sin(b.t*5)*2
		draw_set_transform_matrix(world_transform()*Transform2D(sin(b.t*2)*.012,b.p+Vector2(b.recoil*12,bob)))
		region_texture(Rect2(-size/2,-size*.97,size,size),g.crew_tex,Rect2(Vector2(g.stage*cell.x,0),cell),Color(1.4,1.4,1.4) if b.flash>0 else Color.WHITE)
		draw_set_transform_matrix(world_transform())
		return
	var scale_amount:=1.0 if g.stage==3 else .68
	var base: Transform2D=world_transform()*Transform2D(0,Vector2.ONE*scale_amount,0,b.p)
	draw_set_transform_matrix(base)
	ellipse_shape(Vector2(0,6),Vector2(285,18),Color("291c2638"))
	if b.dead:
		boss_part(3,Rect2(-285,-130,570,130))
		for i in range(16): fish(Vector2(sin(i*2.1)*250,-absf(sin(g.time*2+i))*190),60)
		draw_set_transform_matrix(world_transform()); return
	boss_part(3,Rect2(-285,-170,570,170))
	for i in range(21):
		var angle: float=fmod(i/21.0+b.track*.13,1)*TAU
		var p:=Vector2(cos(angle)*252,-77+sin(angle)*63)
		draw_set_transform_matrix(base*Transform2D(angle+PI/2,p))
		box(Rect2(-11,-4,22,8),Color("6d4b41"),3,Color("34262b"),1)
	var bob: float=sin(b.t*7)*2+(sin(b.t*16)*1.5 if b.state=="windup" else 0)
	var pitch: float=sin(b.t*2)*.009-b.recoil*.014
	var body: Transform2D=base*Transform2D(pitch,Vector2(0,bob))
	draw_set_transform_matrix(body)
	boss_part(0,Rect2(-260,-445,520,355))
	fish(Vector2(68,-295+sin(b.t*4)*2),66)
	fish(Vector2(174,-246+sin(b.t*4+1)*2),60)
	if b.phase==2:
		fish(Vector2(-70,-120),360)
		for i in range(6): draw_circle(Vector2(80+i*18,-290-fmod(b.t*35+i*23,120)),14+(i%3)*5,Color("6f515655"))
	var commander: Transform2D=body*Transform2D(sin(b.t*2)*.035+(-.08 if b.state=="windup" else 0),Vector2(-105,-350-sin(b.t*3)*3-b.recoil*4))
	draw_set_transform_matrix(commander); boss_part(2,Rect2(-55,-120,110,120))
	var cannon: Transform2D=body*Transform2D(-.025*sin(b.t*1.5)+(-.035 if b.state=="windup" else 0),Vector2(-115+b.recoil*27,-212))
	draw_set_transform_matrix(cannon); boss_part(1,Rect2(-162,-83,260,167))
	if b.recoil>.6: draw_circle(Vector2(-157,0),32*b.recoil,Color("ffdf9b99")); draw_circle(Vector2(-162,0),15*b.recoil,Color("fff6da"))
	draw_set_transform_matrix(base)
	for i in range(4):
		var a: float=fmod(b.t*.7+i*.25,1)
		draw_circle(Vector2(160+i*6,-345-a*95),7+a*16,Color("927c8130"))
	if b.warn:
		box(Rect2(-220,-480,250,39),PINK,20)
		center(["포격 준비!","과메기 발사!","꿀통 투척!"][b.pattern],Vector2(-95,-454),17,INK)
	draw_set_transform_matrix(world_transform())

func panel(rect: Rect2, color: Color = PAPER) -> void:
	box(Rect2(rect.position+Vector2(0,5),rect.size),Color("713e5012"),22)
	box(rect,color,22,Color("ffffffcc"),1)

func draw_rig_preview() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("fff0f2"))
	center("WEAPON RIG · 좌우 손잡이 / 총구 정렬 검증",Vector2(640,47),25,INK)
	var saved: Dictionary={"pos":g.pos,"face":g.face,"weapon":g.weapon,"vel":g.vel,"crouch":g.crouch,"grounded":g.grounded,"stage_time":g.stage_time,"camera_x":g.camera_x,"muzzle":g.muzzle}
	g.camera_x=0; g.muzzle=0; g.stage_time=.18
	for w in range(6):
		var x:=24+(w%3)*418; var y:=78+(w/3)*310
		panel(Rect2(x,y,396,288))
		center(g.WEAPONS[w].name,Vector2(x+198,y+34),21,INK)
		g.weapon=w; g.crouch=w==2; g.grounded=w!=3; g.vel=Vector2(300,0) if w in [1,4,5] else Vector2.ZERO
		for side in range(2):
			g.face=1.0 if side==0 else -1.0; g.pos=Vector2(x+104+side*188,y+231)
			hero(g.pos,108,g.player_frame(),g.face,Color.WHITE,true); gun(Color.WHITE)
			var pose: Dictionary=g.weapon_pose()
			draw_circle(pose.origin,3,Color("ee628f")); draw_circle(pose.muzzle,3,TEAL)
			center("RIGHT →" if side==0 else "← LEFT",Vector2(g.pos.x,y+264),12,INK)
	for key in saved: g.set(key,saved[key])
	draw_set_transform( Vector2.ZERO)

func hud() -> void:
	draw_circle(Vector2(57,55),33,PAPER)
	var points:=PackedVector2Array(); var uvs:=PackedVector2Array()
	for i in range(64):
		var unit:=Vector2(cos(i*TAU/64),sin(i*TAU/64)); points.append(Vector2(57,55)+unit*27); uvs.append((Vector2(440,285)+unit*220)/g.profile_tex.get_size())
	draw_polygon(points,PackedColorArray([Color.WHITE]),uvs,g.profile_tex)
	box(Rect2(96,25,192,24),Color("69444fbb"),12); text_at("허니츄러스     × %d"%g.lives,Vector2(109,42),13,PAPER)
	box(Rect2(96,56,192,16),PAPER,8); box(Rect2(99,59,186*g.hp/5.0,10),Color("ed96ae"),5)
	box(Rect2(25,96,263,42),Color("fff8f5e8"),21); weapon_icon(g.weapon,Rect2(38,105,65,25)); text_at(g.WEAPONS[g.weapon].name,Vector2(114,112),12,INK)
	text_at("∞" if g.ammo[g.weapon]<0 else str(g.ammo[g.weapon]),Vector2(114,130),17,Color("b65c7d")); box(Rect2(244,104,28,26),PINK,13); center("Q",Vector2(258,122),12,INK)
	box(Rect2(480,22,320,32),Color("69444fbb"),16); center("0%d  %s"%[g.stage+1,g.STAGES[g.stage].name],Vector2(640,44),15,PAPER)
	center("%s  ·  %d / %d"%[g.zones[g.zone_index].name,g.zone_index+1,g.zones.size()],Vector2(640,74),12,INK)
	text_at("%07d"%g.score,Vector2(1030,45),23,INK); bee(Vector2(1083,96),30); text_at("× %d"%g.rescued,Vector2(1104,90),14,INK)
	draw_circle(Vector2(1229,51),25,PAPER); center("Ⅱ",Vector2(1229,58),19,INK)
	draw_circle(Vector2(110,619),67,Color("fff8f550")); draw_circle(Vector2(110,619),51,Color("fff8f560")); draw_circle(Vector2(110,619),26,Color("FFD8D9bb"))
	center("←",Vector2(64,625),21,INK); center("→",Vector2(156,625),21,INK); center("↑",Vector2(110,579),19,INK); center("↓",Vector2(110,667),19,INK)
	for action in [[1180,620,49,"사격","Z"],[1078,650,35,"점프","X"],[1085,553,30,"수류탄","C"]]:
		var p:=Vector2(action[0],action[1]); draw_circle(p+Vector2(0,4),action[2],Color("69444f22")); draw_circle(p,action[2],Color("fff8f5d9")); draw_circle(p,action[2]-5,Color("FFD8D9cc")); center(action[3],p+Vector2(0,4),14,INK); center(action[4],p+Vector2(0,22),10,Color("a76f85"))
	center("× %d"%g.grenades,Vector2(1085,521),13,INK)
	if g.combo>=2: text_at("%d COMBO!"%g.combo,Vector2(32,176),23,Color("b65c7d"))
	if g.weapon_pop>0:
		box(Rect2(430,550,420,40),PINK,20); center("WEAPON GET!  "+g.WEAPONS[g.weapon].name,Vector2(640,577),20,INK)
	if not g.boss.is_empty() and not g.boss.dead:
		box(Rect2(350,98,580,30),Color("69444fcc"),15); text_at("BOSS",Vector2(367,118),11,PAPER); box(Rect2(420,108,490,9),Color("f0dbe0"),5); box(Rect2(420,108,490*maxf(0,g.boss.hp/g.boss.max),9),Color("ed96ae"),5)
	var intro: bool=g.stage_time<2.5 and g.boss.is_empty()
	var warning: bool=not g.boss.is_empty() and not g.boss.dead and g.boss.state=="enter"
	var win: bool=g.mode=="celebrate"
	if intro or warning or win:
		box(Rect2(0,207,1280,105),Color("69444fe6"),0)
		for i in range(24): box(Rect2(fmod(i*70+g.time*70,1400)-70,207,40,5),PINK,0)
		center("WARNING" if warning else "MISSION COMPLETE!" if win else "MISSION %d  START!"%(g.stage+1),Vector2(640,267),42,PINK)
		center("거대 장갑차 접근 · 전투 준비" if warning else "허니비 구출 성공!" if win else "허니비를 구출하고 전진하세요!",Vector2(640,296),15,PAPER)
	elif g.banner_time>0:
		box(Rect2(440,150,400,36),Color("fff8f5e8"),18); center(g.banner,Vector2(640,174),14,INK)
	if g.boss.is_empty() and g.zones[g.zone_index].cleared: center("GO! →",Vector2(1180,300+sin(g.time*6)*6),30,Color("b65c7d"))

func title_screen() -> void:
	image(g.menu_tex,Rect2(0,0,1280,720))
	draw_rect(Rect2(0,0,570,720),Color("fff0f244"))
	box(Rect2(26,24,560,490),Color("fff8f570"),36)
	text_at("HONEY CHURROS   /   RESCUE OPERATION",Vector2(66,76),15,TEAL)
	box(Rect2(1043,48,166,31),TEAL,15)
	center("RUN & GUN · 01",Vector2(1126,69),12,PAPER)
	text_at("허니츄러스와",Vector2(66,159),52,INK)
	text_at("과메기단의 습격",Vector2(63,226),60,INK)
	draw_line(Vector2(70,246),Vector2(400,246),PINK,7)
	text_at("방송은 멈출 수 없어!",Vector2(68,293),25,TEAL)
	text_at("납치된 허니비를 구하고, 꿀 저장고를 되찾아라.",Vector2(69,333),18,INK)
	text_at("장난감 총 한 자루로 시작하는 달콤살벌한 구출 작전.",Vector2(69,363),17,Color("7b6667"))
	box(Rect2(67,401,295,67),Color("d995aa"),28)
	box(Rect2(67,394,295,67),PINK,28,Color("f2b7c5"),2)
	center("구출 작전 시작   →",Vector2(214,436),23,INK)
	text_at("ENTER 또는 클릭으로 출동",Vector2(79,491),13,Color("7b6667"))
	text_at("BEST  %07d"%g.best,Vector2(381,436),17,TEAL)
	var names: Array=["01  방송국 습격","02  꿀 저장고 탈환","03  과메기 해안기지","04  과메기단 본부"]
	for i in range(4):
		var r:=Rect2(65+i*293,535,271,104)
		panel(r,PAPER)
		if g.bg_tex:
			var cell: Vector2=g.bg_tex.get_size()/2
			region_texture(Rect2(r.position+Vector2(4,4),Vector2(263,58)),g.bg_tex,Rect2(Vector2(i%2,i/2)*cell,cell))
		text_at(names[i],r.position+Vector2(13,87),16,INK)
	center("방향키 / WASD 이동   ·   Z 사격   ·   X / Space 점프   ·   C 수류탄   ·   Q 무기 교체",Vector2(640,675),13,Color("7b6667"))

func overlay() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("50374699"))
	box(Rect2(322,177,636,377),Color("713e5030"),32)
	box(Rect2(315,168,636,377),PAPER,32,Color("efbac9"),2)
	var heading: String={"briefing":"MISSION %02d"%(g.stage+1),"pause":"잠깐, 꿀 충전!","clear":"MISSION COMPLETE!","gameover":"방송 재연결이 필요해!","victory":"방송 재개! 구출 작전 성공"}[g.mode]
	center(heading,Vector2(635,226),29,INK)
	var line1: String=""
	var line2: String=""
	var button: String=""
	match g.mode:
		"briefing":
			line1=g.STAGES[g.stage].name
			line2=g.STAGES[g.stage].sub
			button="ENTER · 작전 시작"
		"pause":
			line1="숨을 고르고, 허니비를 구하러 가요."
			line2="ESC / Enter 계속하기    ·    R 스테이지 재시작    ·    M 소리"
			button="계속하기 →"
		"clear":
			line1="허니비 %d / 4 구출   ·   점수 %07d"%[g.stage_rescued,g.score]
			line2="전차 속 과메기들이 우르르! 방송국에 다시 평화가 찾아옵니다." if g.stage==3 else "한 걸음 더 가까워졌어. 다음 구출 지점으로!"
			button="ENTER · "+("작전 결과" if g.stage==3 else "다음 스테이지")
		"gameover":
			line1="점수 %07d   ·   허니비 %d마리 구출"%[g.score,g.rescued]
			line2="R 현재 스테이지 재도전    ·    Enter 처음부터"
			button="다시 도전하기 →"
		"victory":
			line1="허니비 %d마리 구출!   총점 %07d"%[g.rescued,g.score]
			line2="꿀 저장고도, 방송도, 모두 되찾았어. 함께해 줘서 고마워!"
			button="ENTER · 다시 플레이"
	center(line1,Vector2(635,289),24,INK)
	center(line2,Vector2(635,332),14,Color("80676c"))
	if g.mode=="briefing": center("우리를 쏘고 가까이 가면 보상!  반짝이는 허니비는 지원 사격.",Vector2(635,368),14,INK)
	box(Rect2(444,410,384,67),Color("edb9c7"),26)
	box(Rect2(444,405,384,67),PINK,26,Color.WHITE,2)
	center(button,Vector2(636,447),22,INK)
	center("HONEY CHURROS · RESCUE OPERATION",Vector2(635,516),11,Color("9a8281"))
