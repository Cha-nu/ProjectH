const fs=require('node:fs');let s=fs.readFileSync('scripts/presentation.gd','utf8');
function replace(a,b){if(!s.includes(a))throw Error(a.slice(0,70));s=s.replace(a,b);}
function section(a,b,v){let x=s.indexOf(a),y=s.indexOf(b,x);if(x<0||y<0)throw Error(a);s=s.slice(0,x)+v+s.slice(y);}
replace('Color("39272d")','Color("69444f")');replace('Color("fff4db")','Color("fff8f5")');replace('Color("ef91aa")','Color("FFD8D9")');replace('Color("ffc45e")','Color("f4a7b8")');
section('func hero(', 'func background()',`func world_transform() -> Transform2D:
\tvar shake:=Vector2(sin(g.time*83)*g.shake,cos(g.time*71)*g.shake*.6) if g.mode=="play" else Vector2.ZERO
\treturn Transform2D(0,Vector2(-g.camera_x,0)+shake)

func hero(p: Vector2, size: float, frame: int, facing := 1.0, tint: Color = Color.WHITE, modular := false) -> void:
\tvar texture: Texture2D=g.body_tex if modular else g.hero_tex
\tvar cell: Vector2=texture.get_size()/Vector2(4,2)
\tvar region:=Rect2(Vector2(frame%4,frame/4)*cell,cell)
\tvar base:=world_transform() if modular else Transform2D.IDENTITY
\tdraw_set_transform_matrix(base*Transform2D(0,Vector2(facing,1),0,p))
\tregion_texture(Rect2(-size/2,-size,size,size),texture,region,tint)
\tdraw_set_transform_matrix(base)

func weapon_icon(index: int, dest: Rect2, tint: Color = Color.WHITE) -> void:
\tif index==2:
\t\tvar size: Vector2=g.m4_tex.get_size()
\t\tregion_texture(dest,g.m4_tex,Rect2(size*Vector2(.025,.16),size*Vector2(.95,.74)),tint)
\t\treturn
\tvar regions := [Rect2(.01,.28,.343,.21),Rect2(.351,.319,.349,.14),Rect2(.709,.28,.287,.21),Rect2(.026,.59,.351,.17),Rect2(.438,.58,.229,.23),Rect2(.775,.61,.166,.18)]
\tvar r: Rect2=regions[index]
\tr.position*=g.weapons_tex.get_size(); r.size*=g.weapons_tex.get_size()
\tregion_texture(dest,g.weapons_tex,r,tint)

func gun(tint: Color) -> void:
\tvar p: Dictionary=g.weapon_pose()
\tdraw_set_transform_matrix(world_transform()*Transform2D(p.angle,Vector2(g.face,1),0,p.origin))
\tweapon_icon(g.weapon,Rect2(-p.width*p.grip,-p.height*.48,p.width,p.height),tint)
\tdraw_set_transform_matrix(world_transform())

func muzzle_flash() -> void:
\tif g.muzzle<=0: return
\tvar p: Dictionary=g.weapon_pose()
\tvar v: Dictionary=g.VISUALS[g.last_shot_weapon]
\tvar f: float=g.muzzle/.09
\tvar colors: Array[Color]=[Color("ffd079"),Color("fff1c0"),Color("beeaff"),Color("ffa662"),Color("ffc5e5"),Color("ffe3a7")]
\tdraw_set_transform_matrix(world_transform()*Transform2D(p.aim.angle(),p.muzzle))
\tvar col: Color=colors[g.last_shot_weapon]; col.a=f*.4
\tdraw_circle(Vector2(4,0),v.flash*.7,col)
\tvar length: float=v.flash*(1.1+f)
\tcol.a=f
\tdraw_colored_polygon(PackedVector2Array([Vector2(-3,-4),Vector2(length*.45,-v.flash*.4),Vector2(length*.36,-3),Vector2(length,0),Vector2(length*.36,3),Vector2(length*.45,v.flash*.4),Vector2(-3,4)]),col)
\tdraw_circle(Vector2(3,0),4,PAPER)
\tdraw_set_transform_matrix(world_transform())

func projectile(b: Dictionary) -> void:
\tvar dir: Vector2=b.v.normalized()
\tvar index: int=b.get("weapon",0)
\tvar color: Color=Color("9bf4ce") if b.kind=="support" else g.WEAPONS[index].color
\tif b.kind=="rocket":
\t\tdraw_set_transform_matrix(world_transform()*Transform2D(dir.angle(),b.p))
\t\tbox(Rect2(-17,-5,30,10),Color("636c54"),4,Color("493b3c"),2)
\t\tdraw_line(Vector2(-18,0),Vector2(-40,0),Color("ffab62"),7)
\t\tdraw_circle(Vector2(-34,0),4,Color("fff5be"))
\t\tdraw_set_transform_matrix(world_transform()); return
\tvar trail:=72.0 if b.kind=="sniper" else 12.0 if b.kind=="smg" else 9.0 if b.kind=="pistol" else 24.0
\tvar dim:=color; dim.a=.27
\tdraw_line(b.p-dir*trail,b.p,dim,8 if b.kind=="sniper" else 6)
\tdraw_line(b.p-dir*trail*.7,b.p,color,2.5 if b.kind=="sniper" else 3)
\tdraw_circle(b.p,3 if b.kind=="pistol" else 2.5,PAPER)

`);
section('\t\telif b.friendly:', '\t\telse:\n\t\t\tdraw_circle(p,10,INK)', '\t\telif b.friendly:\n\t\t\tprojectile(b)\n');
section('\tvar frame := 4','\tif g.support>0:',`\tvar frame: int=g.player_frame()
\tvar tint:=Color.WHITE
\tif g.invincible>0: tint.a=.45 if int(g.stage_time*16)%2==0 else 1.0
\tdraw_set_transform_matrix(world_transform())
\tellipse_shape(g.pos+Vector2(0,4),Vector2(43,8),Color(0.15,0.12,0.12,0.25))
\thero(g.pos,144,frame,g.face,tint,true)
\tgun(tint); muzzle_flash()
`);
replace('\t\tif p.kind=="fish": fish(p.p,p.size*2)\n\t\telse:', '\t\tif p.kind=="fish": fish(p.p,p.size*2)\n\t\telif p.kind in ["armor","casing"]:\n\t\t\tdraw_set_transform_matrix(world_transform()*Transform2D(p.life*8,p.p))\n\t\t\tbox(Rect2(-p.size/2,-p.size/3,p.size,p.size*.65),p.color,2)\n\t\t\tdraw_set_transform_matrix(world_transform())\n\t\telse:');
section('\tif g.boss.is_empty():\n\t\tbox(', 'func ellipse_shape(',`\tfor i in range(g.zones.size()):
\t\tvar z: Dictionary=g.zones[i]
\t\tvar guards:=0
\t\tfor e in g.enemies:
\t\t\tif e.zone==i and e.guard and e.hp>0: guards+=1
\t\tbox(Rect2(z.end-29,365,32,211),Color("afdbb8") if z.cleared else PINK,14,Color("946375"),2)
\t\tdraw_circle(Vector2(z.end-13,393),8,Color("568466") if z.cleared else Color("e77894"))
\t\tif not z.cleared:
\t\t\tfor y in range(430,560,27): draw_line(Vector2(z.end-65,y),Vector2(z.end+35,y-12),Color("ffb8c6aa"),7)
\t\tbox(Rect2(z.end-106,318,190,35),PAPER,17)
\t\tcenter("구역 확보 ✓" if z.cleared else "경비 %d · 통로 봉쇄"%guards,Vector2(z.end-11,341),13,INK)

`);
section('func draw_enemy(', 'func hud()',`func draw_enemy(e: Dictionary) -> void:
\tvar size:=105.0 if e.kind==2 else 92.0
\tvar frame:=6 if e.launch>0 or (e.kind==3 and e.p.y<550) else 7 if e.kick>0 else 5 if e.warn else int(e.t*9)%4 if e.walk else 4
\tvar cell: Vector2=g.fish_anim.get_size()/Vector2(4,2)
\tvar beat: float=sin(e.t*9)
\tvar amount:=.035 if e.walk else .015
\tvar sx:=1+amount*beat; var sy:=1-amount*beat
\tellipse_shape(e.p+Vector2(0,4),Vector2(size*.36,6),Color("261f1f2a"))
\tdraw_set_transform_matrix(world_transform()*Transform2D(.025*beat if e.walk else 0,Vector2(-sx if e.facing>0 else sx,sy),0,e.p))
\tregion_texture(Rect2(-size/2,-size,size,size),g.fish_anim,Rect2(Vector2(frame%4,frame/4)*cell,cell),Color(1.6,1.6,1.6) if e.flash>0 else Color.WHITE)
\tdraw_set_transform_matrix(world_transform())
\tif e.kind==1:
\t\tdraw_line(e.p+Vector2(-32,-85),e.p+Vector2(32,-85),INK,3)
\t\tdraw_line(e.p+Vector2(-40*sin(g.time*40),-92),e.p+Vector2(40*sin(g.time*40),-92),TEAL,4)
\tif e.kind==2: box(Rect2(e.p+Vector2(-45,-38),Vector2(12,37)),Color("829b89"),5,INK,2)
\tif e.guard: box(Rect2(e.p+Vector2(-17,-112),Vector2(34,20)),PINK,10); center("★",e.p+Vector2(0,-97),13,INK)
\tif e.warn: center("!",e.p+Vector2(0,-119),27,Color("d64c71"))

func boss_part(index: int, dest: Rect2) -> void:
\tvar regions: Array[Rect2]=[Rect2(.01,.015,.62,.61),Rect2(.63,.23,.365,.31),Rect2(.125,.645,.247,.34),Rect2(.45,.68,.545,.30)]
\tvar r:=regions[index]; r.position*=g.boss_parts.get_size(); r.size*=g.boss_parts.get_size()
\tregion_texture(dest,g.boss_parts,r)

func draw_boss() -> void:
\tvar b: Dictionary=g.boss
\tvar scale_amount:=1.0 if g.stage==3 else .68
\tvar base: Transform2D=world_transform()*Transform2D(0,Vector2.ONE*scale_amount,0,b.p)
\tdraw_set_transform_matrix(base)
\tellipse_shape(Vector2(0,6),Vector2(285,18),Color("291c2638"))
\tif b.dead:
\t\tboss_part(3,Rect2(-285,-130,570,130))
\t\tfor i in range(16): fish(Vector2(sin(i*2.1)*250,-absf(sin(g.time*2+i))*190),60)
\t\tdraw_set_transform_matrix(world_transform()); return
\tboss_part(3,Rect2(-285,-170,570,170))
\tfor i in range(21):
\t\tvar angle: float=fmod(i/21.0+b.track*.13,1)*TAU
\t\tvar p:=Vector2(cos(angle)*252,-77+sin(angle)*63)
\t\tdraw_set_transform_matrix(base*Transform2D(angle+PI/2,p))
\t\tbox(Rect2(-11,-4,22,8),Color("6d4b41"),3,Color("34262b"),1)
\tvar bob: float=sin(b.t*7)*2+(sin(b.t*16)*1.5 if b.state=="windup" else 0)
\tvar pitch: float=sin(b.t*2)*.009-b.recoil*.014
\tvar body: Transform2D=base*Transform2D(pitch,Vector2(0,bob))
\tdraw_set_transform_matrix(body)
\tboss_part(0,Rect2(-260,-445,520,355))
\tif b.phase==2:
\t\tfish(Vector2(-70,-120),360)
\t\tfor i in range(6): draw_circle(Vector2(80+i*18,-290-fmod(b.t*35+i*23,120)),14+(i%3)*5,Color("6f515655"))
\tvar commander: Transform2D=body*Transform2D(sin(b.t*2)*.035+(-.08 if b.state=="windup" else 0),Vector2(-105,-350-sin(b.t*3)*3-b.recoil*4))
\tdraw_set_transform_matrix(commander); boss_part(2,Rect2(-55,-120,110,120))
\tvar cannon: Transform2D=body*Transform2D(-.025*sin(b.t*1.5)+(-.035 if b.state=="windup" else 0),Vector2(-115+b.recoil*27,-212))
\tdraw_set_transform_matrix(cannon); boss_part(1,Rect2(-162,-83,260,167))
\tif b.recoil>.6: draw_circle(Vector2(-157,0),32*b.recoil,Color("ffdf9b99")); draw_circle(Vector2(-162,0),15*b.recoil,Color("fff6da"))
\tdraw_set_transform_matrix(base)
\tfor i in range(4):
\t\tvar a: float=fmod(b.t*.7+i*.25,1)
\t\tdraw_circle(Vector2(160+i*6,-345-a*95),7+a*16,Color("927c8130"))
\tif b.warn:
\t\tbox(Rect2(-220,-480,250,39),PINK,20)
\t\tcenter(["포격 준비!","과메기 발사!","꿀통 투척!"][b.pattern],Vector2(-95,-454),17,INK)
\tdraw_set_transform_matrix(world_transform())

func panel(rect: Rect2, color: Color = PAPER) -> void:
\tbox(Rect2(rect.position+Vector2(0,5),rect.size),Color("713e5020"),24)
\tbox(rect,color,24,Color("f0bcc7"),1)

`);
section('func hud() -> void:', 'func title_screen()',`func hud() -> void:
\tpanel(Rect2(18,16,300,78)); draw_circle(Vector2(60,55),28,PINK)
\tcenter("H",Vector2(60,66),29,INK); text_at("허니츄러스",Vector2(99,43),16,INK)
\tfor i in range(5): draw_circle(Vector2(105+i*25,67),8,Color("e98da5") if i<g.hp else Color("eedde1"))
\ttext_at("× %d"%g.lives,Vector2(251,67),17,INK)
\tpanel(Rect2(330,16,315,78),Color("ffe2e5") if g.weapon_pop>0 else PAPER)
\tweapon_icon(g.weapon,Rect2(347,39,83,33)); text_at(g.WEAPONS[g.weapon].name,Vector2(444,45),20,INK)
\ttext_at("∞" if g.ammo[g.weapon]<0 else "%03d"%g.ammo[g.weapon],Vector2(444,74),23,Color("bc637e")); text_at("Q 교체",Vector2(575,72),12,Color("ae7a89"))
\tpanel(Rect2(657,16,238,78)); text_at("SCORE",Vector2(675,39),11,Color("b18190")); text_at("%07d"%g.score,Vector2(675,66),22,INK)
\tbee(Vector2(847,62),37); text_at("%02d"%g.rescued,Vector2(865,67),17,INK); text_at("수류탄 %d"%g.grenades,Vector2(675,84),10,Color("a27884"))
\tpanel(Rect2(907,16,355,78)); text_at("MISSION 0%d / 04"%(g.stage+1),Vector2(927,39),11,Color("b18190")); text_at(g.STAGES[g.stage].name,Vector2(927,66),19,INK)
\tbox(Rect2(1197,33,48,40),PINK,17); center("Ⅱ",Vector2(1221,59),17,INK)
\tpanel(Rect2(22,110,268,51),Color("fff8f5ed")); text_at("AREA %d / %d"%[g.zone_index+1,g.zones.size()],Vector2(39,130),10,Color("b18190")); text_at(g.zones[g.zone_index].name,Vector2(39,150),15,INK)
\tfor i in range(g.zones.size()):
\t\tvar x:=925+i*62
\t\tbox(Rect2(x,109,53,26),Color("b5d9c5") if g.zones[i].cleared else PINK if i==g.zone_index else Color("fff8f5bb"),13)
\t\tcenter("✓" if g.zones[i].cleared else "0%d"%(i+1),Vector2(x+26,127),12,INK)
\tif g.combo>=2: text_at("%d COMBO!"%g.combo,Vector2(32,195),25,Color("bd5f7d"))
\tif g.banner_time>0:
\t\tvar width: float=g.font.get_string_size(g.banner,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+50
\t\tpanel(Rect2(640-width/2,108,width,45),PINK); center(g.banner,Vector2(640,137),17,INK)
\tif g.weapon_pop>0:
\t\tpanel(Rect2(510,181,260,61)); weapon_icon(g.weapon,Rect2(527,195,76,32))
\t\ttext_at(g.WEAPONS[g.weapon].name,Vector2(616,204),17,INK); text_at("WEAPON EQUIPPED",Vector2(616,225),10,Color("b18190"))
\tif not g.boss.is_empty() and not g.boss.dead:
\t\tpanel(Rect2(289,601,702,49)); box(Rect2(302,626,676,12),Color("f0dbe0"),6)
\t\tbox(Rect2(302,626,676*maxf(0,g.boss.hp/g.boss.max),12),Color("e98aa5"),6)
\t\tcenter("오리고기 · 초거대 과메기 전차" if g.stage==3 else "과메기단 기동부대",Vector2(640,620),13,INK)
\tpanel(Rect2(282,669,716,33),Color("fff8f5e8")); center("← → 이동   ↑ 조준   ↓ 앉기   Z 사격   X / Space 점프   C 수류탄   Q 무기   ESC 일시정지",Vector2(640,691),12,INK)
\tif g.boss.is_empty():
\t\tvar length: float=g.STAGES[g.stage].length
\t\tdraw_rect(Rect2(32,648,1216,4),Color("f7d4dc")); draw_rect(Rect2(32,648,1216*g.pos.x/length,4),Color("c66e8d"))
\t\tfor z in g.zones: draw_circle(Vector2(32+1216*z.end/length,650),5,Color("72a98c") if z.cleared else PINK)

`);
replace('Color(0.98,0.94,0.83,0.88)','Color("fff0f2ee")');replace('Color(1,0.97,0.9,0.4),24,INK,2','Color("fff8f580"),36,Color("edb9c7"),2');
replace('box(Rect2(67,399,295,67),INK,13)','box(Rect2(67,401,295,67),Color("d995aa"),28)');replace('box(Rect2(67,394,295,67),GOLD,13,INK,3)','box(Rect2(67,394,295,67),PINK,28,Color("f2b7c5"),2)');replace('Color("ead8b2")','PINK');
replace('box(r,Color("f6e8cb"),12,Color("bda98f"),1)','panel(r,PAPER)');
replace('box(Rect2(322,177,636,377),INK,24)','box(Rect2(322,177,636,377),Color("713e5030"),32)');replace('box(Rect2(315,168,636,377),PAPER,24,INK,3)','box(Rect2(315,168,636,377),PAPER,32,Color("efbac9"),2)');replace('box(Rect2(444,405,384,67),GOLD,12,INK,2)','box(Rect2(444,405,384,67),PINK,26,Color("eaa6bc"),2)');
fs.writeFileSync('scripts/presentation.gd',s);console.log('Godot pink UI and modular animation renderer updated.');
