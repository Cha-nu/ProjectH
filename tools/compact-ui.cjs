const fs=require('node:fs');
function edit(p,f){fs.writeFileSync(p,f(fs.readFileSync(p,'utf8')));}
edit('web/game.js',s=>s.replaceAll('*144','*108').replace('reach=v.width*(1-v.grip),normal=-v.width*v.ratio*.13*g.face','reach=v.width*.75*(1-v.grip),normal=-v.width*.75*v.ratio*.13*g.face').replace('width:v.width,height:v.width*v.ratio','width:v.width*.75,height:v.width*.75*v.ratio').replace('this.crouch?46:92','this.crouch?35:69').replace('x:this.x-19,y:this.y-h,w:38,h','x:this.x-14,y:this.y-h,w:28,h'));
edit('scripts/game.gd',s=>s.replace('var body_tex: Texture2D','var profile_tex: Texture2D\nvar body_tex: Texture2D').replace('body_tex = load(', 'profile_tex = load("res://assets/characters/profile.jpg")\n\tbody_tex = load(').replaceAll('*144','*108').replace('visual.width*(1-visual.grip)','visual.width*.75*(1-visual.grip)').replace('-visual.width*visual.ratio','-visual.width*.75*visual.ratio').replace('"width":visual.width,"height":visual.width*visual.ratio','"width":visual.width*.75,"height":visual.width*.75*visual.ratio').replace('Vector2(-19,-46 if crouch else -92),Vector2(38,46 if crouch else 92)','Vector2(-14,-35 if crouch else -69),Vector2(28,35 if crouch else 69)'));
edit('web/render.js',s=>{
 s=s.replace("{m4:'characters/m4_black.png'","{profile:'characters/profile.jpg',m4:'characters/m4_black.png'").replace('hero(g.x,g.y,144','hero(g.x,g.y,108').replace('ellipse(g.x,g.y+4,43,8','ellipse(g.x,g.y+4,31,6');
 s=s.replace('hero(65,119,98,4);','c.drawImage(tex.profile,220,65,440,440,41,38,48,48);');
 s=s.replace('panel(24,24,278,76)','panel(24,24,278,76,\'#fff8f5ed\')');
 s=s.replace("panel(432,24,416,87);box(447,39,57,24,PINK,12);text('0'+(g.stage+1),476,56,13,INK,'center',800);text(STAGES[g.stage].name,517,56,18,INK,'left',800);","panel(470,24,340,50,'#fff8f5ed');box(480,34,40,30,PINK,15);text('0'+(g.stage+1),500,54,13,INK,'center',800);text(STAGES[g.stage].name,535,55,16,INK,'left',800);");
 s=s.replace("text(z.name,450,91,12,'#967481');","box(493,83,294,29,'#fff8f5e8',14);text(z.name,507,102,11,'#967481');").replace('const x=705+i*30;circle(x,86,10','const x=690+i*25;circle(x,97,9').replace('x,90,10,INK','x,101,9,INK');
 s=s.replace("panel(376,660,528,36,'#fff8f5ed');const hints=","panel(376,660,528,36,'#fff8f5c9');const hints=");
 s=s.replace("panel(25,554,247,55)","panel(25,548,247,55)");
 return s;
});
edit('scripts/presentation.gd',s=>{
 s=s.replaceAll('hero(g.pos,144','hero(g.pos,108');
 s=s.replace('region_texture(Rect2(42,38,46,44),g.body_tex,Rect2(100,485,240,220))',`var points:=PackedVector2Array(); var uvs:=PackedVector2Array()
\tfor i in range(64):
\t\tvar unit:=Vector2(cos(i*TAU/64),sin(i*TAU/64))
\t\tpoints.append(Vector2(65,62)+unit*24)
\t\tuvs.append((Vector2(440,285)+unit*220)/g.profile_tex.get_size())
\tdraw_polygon(points,PackedColorArray([Color.WHITE]),uvs,g.profile_tex)`);
 s=s.replace('panel(Rect2(432,24,416,87)); box(Rect2(447,39,57,24),PINK,12); center("0%d"%(g.stage+1),Vector2(476,56),13,INK)','panel(Rect2(470,24,340,50),Color("fff8f5ed")); box(Rect2(480,34,40,30),PINK,15); center("0%d"%(g.stage+1),Vector2(500,54),13,INK)');
 s=s.replace('text_at(g.STAGES[g.stage].name,Vector2(517,56),18,INK); text_at(g.zones[g.zone_index].name,Vector2(450,91),12,Color("967481"))','text_at(g.STAGES[g.stage].name,Vector2(535,55),16,INK); box(Rect2(493,83,294,29),Color("fff8f5e8"),14); text_at(g.zones[g.zone_index].name,Vector2(507,102),11,Color("967481"))');
 s=s.replace('var x:=705+i*30','var x:=690+i*25').replace('Vector2(x,86),10','Vector2(x,97),9').replace('Vector2(x,90),10','Vector2(x,101),9');
 return s;
});
edit('tools/package-web.cjs',s=>s.replace("['hero_sheet.png'","['profile.jpg','hero_sheet.png'"));
