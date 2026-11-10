const fs=require('node:fs');let s=fs.readFileSync('scripts/game.gd','utf8');
function replace(a,b){if(!s.includes(a))throw Error(a.slice(0,70));s=s.replace(a,b);}
function section(a,b,v){let x=s.indexOf(a),y=s.indexOf(b,x);if(x<0||y<0)throw Error(a);s=s.slice(0,x)+v+s.slice(y);}
replace('"length":4400.0','"length":4580.0, "zones":["꽃길 입구","방송 장비 거리","송신탑 광장"]');
replace('"length":4800.0','"length":5680.0, "zones":["꿀 운송장","컨베이어 홀","벌집 정제실","저장고 관제실"]');
replace('"length":5000.0','"length":4580.0, "zones":["해변 초소","부두 창고","상륙정 선착장"]');
replace('"length":5200.0','"length":5680.0, "zones":["요새 외벽","해산물 병영","중앙 보급로","오리고기 사령부"]');
replace('var mode :=',`const VISUALS := [
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
var mode :=`);
replace('\tfont = load(', '\tm4_tex = load("res://assets/characters/m4_black.png")\n\tfish_anim = load("res://assets/characters/fish_sheet.png")\n\tboss_parts = load("res://assets/characters/boss_parts.png")\n\tfont = load(');
replace('pos.x = 4200; camera_x = 3920;', 'pos.x = 4680; camera_x = 4400;');
section('\tvar length: float = STAGES[stage].length','\tbanner = "MISSION',`\tzones.clear(); zone_index=0; hurt_timer=0; weapon_pop=0; gate_toast=0; celebration=0
\tfor z in range(STAGES[stage].zones.size()):
\t\tvar start := z*1100.0
\t\tzones.append({"name":STAGES[stage].zones[z],"start":start,"end":start+1100,"cleared":false,"entered":z==0})
\t\tfor i in range(5):
\t\t\tspawn_enemy(Vector2(start+440+i*125,FLOOR),(i+z+stage)%4)
\t\t\tenemies[-1].zone=z; enemies[-1].guard=i>=3
\t\tcages.append({"p":Vector2(start+460,FLOOR),"hp":4.0,"open":false,"taken":false,"special":z==2,"t":0.0})
\t\tplatforms.append({"rect":Rect2(start+260,441,190,20),"type":"normal","base":start+260})
\t\tplatforms.append({"rect":Rect2(start+600,396,190,20),"type":"normal","base":start+600})
\t\tprops.append({"p":Vector2(start+580,FLOOR),"hp":4.0,"kind":0})
\t\tprops.append({"p":Vector2(start+820,FLOOR),"hp":4.0,"kind":0})
\t\tpickups.append({"p":Vector2(start+680,365),"kind":"weapon","weapon":(z+stage+1)%5,"t":0.0})
\t\tif stage==1:
\t\t\tplatforms.append({"rect":Rect2(start+640,564,310,20),"type":"belt","base":start+640})
\t\t\thazards.append({"rect":Rect2(start+330,568,100,12),"kind":"honey"})
\t\tif stage==2:
\t\t\thazards.append({"rect":Rect2(start+560,571,185,150),"kind":"water"})
\t\t\tplatforms.append({"rect":Rect2(start+590,531,160,20),"type":"boat","base":start+590})
\t\tif stage==3: hazards.append({"rect":Rect2(start+570,568,100,12),"kind":"steam"})
\tif cages.size()<4: cages.append({"p":Vector2(3020,FLOOR),"hp":4.0,"open":false,"taken":false,"special":false,"t":0.0})
`);
replace('"warn":0.0})','"warn":0.0,"facing":-1.0,"walk":0.0,"kick":0.0,"zone":-1,"guard":false,"launch":0.0,"launch_v":Vector2.ZERO})');
replace('\ttime += dt\n','\ttime += dt\n\tif mode=="celebrate":\n\t\tcelebration-=dt\n\t\tfor p in particles: p.life-=dt; p.p+=p.v*dt; p.v.y+=400*dt\n\t\tparticles=particles.filter(func(p): return p.life>0)\n\t\tif celebration<=0: mode="clear"\n');
replace('assert(mode == "clear")', 'assert(mode == "celebrate")');
replace('\tinvincible = maxf(0, invincible-dt);','\thurt_timer=maxf(0,hurt_timer-dt); weapon_pop=maxf(0,weapon_pop-dt); gate_toast-=dt\n\tinvincible = maxf(0, invincible-dt);');
replace('pos.x = clampf(pos.x, maxf(30, camera_x-80), STAGES[stage].length-70)', 'pos.x = clampf(pos.x, zones[-1].end+25 if not boss.is_empty() and boss.active else 30.0, STAGES[stage].length-70)');
section('\tif pos.x > checkpoint+1000', '\tif Input.is_action_pressed("fire")','');
replace('weapon = unlocked[(unlocked.find(weapon)+1)%unlocked.size()];', 'weapon = unlocked[(unlocked.find(weapon)+1)%unlocked.size()]; weapon_pop=1; muzzle=0;');
replace('update_bullets(dt); collect_cages(); update_pickups(dt)', 'update_bullets(dt); collect_cages(); update_pickups(dt); update_zones()');
replace('if boss.is_empty() and pos.x > STAGES[stage].length-1050: start_boss()', 'if boss.is_empty() and zones.all(func(z): return z.cleared) and pos.x>zones[-1].end+110: start_boss()');
section('func shoot() -> void:','func add_bullet(',`func player_frame() -> int:
\tif hurt_timer>0: return 7
\tif crouch: return 5
\tif not grounded: return 6
\tif absf(vel.x)>30: return int(stage_time*12)%4
\treturn 4

func aim_direction() -> Vector2:
\tif Input.is_action_pressed("up"): return Vector2(0,-1) if absf(Input.get_axis("left","right"))<.1 else Vector2(face,-1).normalized()
\tif Input.is_action_pressed("down") and not grounded: return Vector2(0,1) if absf(Input.get_axis("left","right"))<.1 else Vector2(face,1).normalized()
\treturn Vector2(face,0)

func weapon_pose() -> Dictionary:
\tvar frame := player_frame()
\tvar anchors := [Vector2(.52,.55),Vector2(.53,.55),Vector2(.54,.54),Vector2(.51,.55),Vector2(.52,.54),Vector2(.55,.67),Vector2(.55,.49),Vector2(.55,.53)]
\tvar visual: Dictionary=VISUALS[weapon]
\tvar aim:=aim_direction()
\tvar recoil: float=maxf(0,muzzle)/.09*visual.recoil
\tvar origin: Vector2=pos+Vector2((anchors[frame].x-.5)*144*face,(anchors[frame].y-1)*144)-aim*recoil
\tvar reach: float=visual.width*(1-visual.grip)
\tvar normal: float=-visual.width*visual.ratio*.13*face
\treturn {"origin":origin,"muzzle":origin+aim*reach+Vector2(-aim.y,aim.x)*normal,"aim":aim,"angle":(aim*face).angle(),"width":visual.width,"height":visual.width*visual.ratio,"grip":visual.grip}

func shoot() -> void:
\tif ammo[weapon]==0: weapon=5; weapon_pop=1; toast("탄약 소진 · Glock 19")
\tvar w: Dictionary=WEAPONS[weapon]
\tvar visual: Dictionary=VISUALS[weapon]
\tif ammo[weapon]>0: ammo[weapon]-=1
\tvar pose:=weapon_pose()
\tadd_bullet(pose.muzzle,pose.aim*w.speed,true,w.damage,visual.kind)
\tbullets[-1].weapon=weapon; bullets[-1].color=w.color
\tfire_timer=w.rate; muzzle=.09; last_shot_weapon=weapon
\taudio.play(visual.kind,-15)
\tburst(pose.muzzle,12 if weapon==3 else 3,w.color,180 if weapon==3 else 100)
\tif weapon!=3: particles.append({"p":pose.origin-Vector2(0,9),"v":Vector2(-face*100+randf_range(-30,30),-randf_range(100,180)),"life":.6,"max":.6,"color":Color("efc17c"),"size":3.0,"kind":"casing"})
\tfor enemy in enemies:
\t\tif enemy.p.distance_to(pos)<90: enemy.hp-=4; enemy.flash=.12; burst(enemy.p-Vector2(0,30),5,Color("fff4be"),180)

func update_zones() -> void:
\tif not boss.is_empty(): return
\tfor i in range(zones.size()):
\t\tvar z: Dictionary=zones[i]
\t\tif not z.entered and pos.x>=z.start+20:
\t\t\tz.entered=true; zone_index=i; checkpoint=z.start+100
\t\t\ttoast("AREA %d / %d · %s"%[i+1,zones.size(),z.name])
\t\tvar guards:=0
\t\tfor e in enemies:
\t\t\tif e.zone==i and e.guard and e.hp>0: guards+=1
\t\tif not z.cleared and guards==0 and pos.x>=z.end-280:
\t\t\tz.cleared=true; score+=300; audio.play("rescue")
\t\t\ttoast("전 구역 확보! · 보스 구역으로 진입" if i==zones.size()-1 else "구역 확보! · 다음 구역으로 이동")
\t\tif not z.cleared and pos.x>z.end-70:
\t\t\tpos.x=z.end-70; vel.x=0
\t\t\tif gate_toast<=0: toast("통로 봉쇄 · 경비 %d마리 남음"%guards); gate_toast=2.5
\t\t\tbreak

`);
replace('e.t += dt; e.flash = maxf(0,e.flash-dt)', 'e.t += dt; e.flash = maxf(0,e.flash-dt); e.kick=maxf(0,e.kick-dt)');
replace('\t\te.shot -= dt\n\t\tif e.kind == 1:', '\t\te.shot -= dt; e.facing=dir if dir!=0 else e.facing; e.walk=1.0 if absf(dx)>300 else 0.0\n\t\tif e.launch>0:\n\t\t\te.launch-=dt; e.launch_v.y+=1250*dt; e.p+=e.launch_v*dt\n\t\t\tif e.p.y>=FLOOR: e.p.y=FLOOR; e.launch=0; e.kick=.25\n\t\telif e.kind == 1:');
replace('e.warn = 0.0\n', 'e.warn = 0.0; e.kick=.22\n');
replace('\t\tb.p += b.v*dt\n', '\t\tb.p += b.v*dt\n\t\tif b.kind=="rocket" and randf()<.6: particles.append({"p":b.p,"v":Vector2(-b.v.x*.08,randf_range(-15,15)),"life":.35,"max":.35,"color":Color("d8c5c0"),"size":randf_range(5,10),"kind":"smoke"})\n');
replace('ammo[index] = WEAPONS[index].ammo; weapon = index', 'ammo[index] = WEAPONS[index].ammo; weapon = index; weapon_pop=1.2; muzzle=0');
replace('hp -= 1; invincible = 1.8;', 'hp -= 1; invincible = 1.8; hurt_timer=.25;');
s=s.replaceAll('maxf(checkpoint,camera_x+70)','checkpoint');
section('func start_boss() -> void:', 'func damage_boss(',`func start_boss() -> void:
\tvar health:=620.0 if stage==3 else 150.0+stage*55
\tvar home: float=STAGES[stage].length-330
\tboss={"p":Vector2(STAGES[stage].length+300,FLOOR),"home":home,"hp":health,"max":health,"active":true,"dead":false,"t":0.0,"phase":1,"flash":0.0,"warn":false,"pattern":0,"state":"enter","clock":2.2,"recoil":0.0,"track":0.0}
\ttoast("WARNING · "+["방송 방해 장갑차","꿀 공장 파괴자","과메기 상륙정","오리고기 · 초거대 과메기 전차"][stage]); shake=5

func update_boss(dt: float) -> void:
\tif boss.is_empty() or boss.dead: return
\tboss.t+=dt; boss.clock-=dt; boss.flash=maxf(0,boss.flash-dt); boss.recoil=maxf(0,boss.recoil-dt*3)
\tboss.track+=dt*(8 if boss.state=="enter" else 2); boss.warn=boss.state=="windup"
\tif boss.state=="enter":
\t\tboss.p.x=lerpf(boss.p.x,boss.home,1-exp(-dt*3))
\t\tif boss.clock<=0: boss.p.x=boss.home; boss.state="idle"; boss.clock=1.2
\t\treturn
\tif boss.hp<boss.max*.5 and boss.phase==1:
\t\tboss.phase=2; boss.state="break"; boss.clock=1.3; shake=12
\t\tfor i in range(12): particles.append({"p":boss.p+Vector2(randf_range(-200,170),-randf_range(60,210)),"v":Vector2(randf_range(-260,220),randf_range(-400,-120)),"life":1.8,"max":1.8,"color":Color("8c9b70"),"size":randf_range(14,26),"kind":"armor"})
\t\ttoast("장갑 파괴! · 과메기 본체 노출")
\tif boss.state=="idle":
\t\tboss.p.x=boss.home+sin(boss.t*1.2)*12
\t\tif boss.clock<=0: boss.state="windup"; boss.clock=.9 if boss.phase==1 else .65
\telif boss.state=="windup" and boss.clock<=0: boss.state="attack"; boss.clock=.48; boss_attack()
\telif boss.state=="attack" and boss.clock<=0: boss.state="recover"; boss.clock=.7
\telif boss.state in ["recover","break"] and boss.clock<=0:
\t\tboss.pattern=(boss.pattern+1)%3; boss.state="idle"; boss.clock=1.15 if boss.phase==1 else .55
\tif pos.x>boss.p.x-180 and pos.y>416: hurt()

func boss_attack() -> void:
\tvar origin: Vector2=boss.p+Vector2(-190,-145)
\tboss.recoil=1.0; shake=4
\tif boss.pattern==0:
\t\tfor i in range(5 if boss.phase==1 else 8): add_bullet(origin,Vector2.from_angle(PI-.46+i*.13)*305,false,1,"enemy")
\telif boss.pattern==1:
\t\tfor i in range(2 if boss.phase==1 else 3):
\t\t\tspawn_enemy(origin-Vector2(i*40,0),3); enemies[-1].launch=1.5; enemies[-1].launch_v=Vector2(-220-i*75,-260-i*80)
\t\tburst(origin,18,Color("fff1aa"),250)
\telse:
\t\tfor i in range(3): add_bullet(origin,Vector2(-220-i*115,-550-i*45),false,1,"honey")
\taudio.play("heavy",-11)

`);
replace('mode="clear"; save_best()', 'mode="celebrate"; celebration=3.0; save_best()');
fs.writeFileSync('scripts/game.gd',s);console.log('Upgraded Godot gameplay and animation state.');
