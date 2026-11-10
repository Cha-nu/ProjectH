const fs=require('node:fs');function edit(p,f){fs.writeFileSync(p,f(fs.readFileSync(p,'utf8')));}
edit('web/game.js',s=>{
 const start=s.indexOf('function weaponPose(g)'),end=s.indexOf('\nclass Game',start);
 return s.slice(0,start)+`function weaponPose(g){
 const frame=playerFrame(g),v=VISUALS[g.weapon],a=g.aim(),up=a.y<-.4&&!(g.dying>0)&&!(g.hurtTimer>0)&&!(g.knife>0),diagonal=Math.abs(a.x)>.2;
 const aimFrame=diagonal?(g.muzzle>.045?5:4):!g.grounded?6:g.crouch?7:Math.abs(g.vx)>30?2+Math.floor(g.stageTime*9)%2:g.muzzle>.045?1:0;
 const anchors=[[.52,.55],[.53,.55],[.54,.54],[.51,.55],[.52,.54],[.55,.67],[.55,.49],[.55,.53]],rear=[[.69,.30],[.70,.34],[.72,.29],[.77,.30],[.74,.35],[.78,.36],[.70,.28],[.77,.42]],anchor=up?rear[aimFrame]:anchors[frame];
 const recoil=Math.max(0,g.muzzle)/.09*v.recoil*.35,bob=g.grounded&&Math.abs(g.vx)<30?Math.sin(g.stageTime*3)*.65:0,bx=-a.x*recoil,by=-a.y*recoil+bob;
 const x=g.x+(anchor[0]-.5)*108*g.face+bx,y=g.y+(anchor[1]-1)*108+by,reach=v.width*.75*(1-v.grip),normal=-v.width*.75*v.ratio*.13*g.face;
 return {frame,up,aimFrame,bx,by,x,y,angle:Math.atan2(a.y*g.face,a.x*g.face),face:g.face,width:v.width*.75,height:v.width*.75*v.ratio,grip:v.grip,mx:x+a.x*reach-a.y*normal,my:y+a.y*reach+a.x*normal,aim:a};}
`+s.slice(end);
});
edit('web/render.js',s=>{
 s=s.replace("const files={profile:","const files={aim:'characters/hero_aim_sheet.png',menuFriends:'characters/menu_friends.png',bossCrew:'generated/boss_crew.png',profile:");
 s=s.replace('hero(g.x,g.y,108,frame,g.face,alpha,true);',`const pose=weaponPose(g);
 if(pose.up){const im=tex.aim,w=im.width/4,h=im.height/2;c.save();c.translate(g.x+pose.bx,g.y+pose.by);c.scale(g.face,1);c.globalAlpha=alpha;c.drawImage(im,(pose.aimFrame%4)*w,Math.floor(pose.aimFrame/4)*h,w,h,-54,-108,108,108);c.restore();}
 else hero(g.x+pose.bx,g.y+pose.by,108,frame,g.face,alpha,true);`);
 s=s.replace('weaponIcon(g.weapon,-p.width*p.grip,-p.height*.48,p.width,p.height);c.restore();}',`weaponIcon(g.weapon,-p.width*p.grip,-p.height*.48,p.width,p.height);
 // Hands sit in front of the receiver/foregrip, so the weapon is held rather than pasted over arms.
 ellipse(0,p.height*.18,3.2,3.8,'#ffe9df');if(g.weapon!==5)ellipse(Math.min(p.width*.28,19),p.height*.12,3.4,3.5,'#ffe9df');c.restore();}`);
 const a=s.indexOf(' const grad=c.createLinearGradient',s.indexOf('function title(){')),b=s.indexOf(' const pop=back3',a);
 s=s.slice(0,a)+` const zoom=1.025+Math.sin(t*.24)*.006;c.save();c.translate(640,360);c.scale(zoom,zoom);c.drawImage(tex.menuFriends,-640,-360,1280,720);c.restore();
 for(let i=0;i<8;i++){const x=(i*211+t*12)%1400-60,y=(i*97+t*18)%780-40;c.save();c.globalAlpha=.4;c.translate(x,y);c.rotate(t*.5+i);ellipse(0,0,7,4,'#ffc1d6');c.restore();}
`+s.slice(b);
 s=s.replace('c.drawImage(tex.bossKing,-W/2,-.902*W,W,W)','crewBoss(0,-W/2,-.92*W,W,W)').replace('H=W*tex.bossCannon.height/tex.bossCannon.width','H=W').replace('c.drawImage(tex.bossCannon,-W/2,-.949*H,W,H)','crewBoss(1,-W/2,-.92*H,W,H)').replace('H=W*tex.bossBoat.height/tex.bossBoat.width','H=W').replace('c.drawImage(tex.bossBoat,-W/2,-.904*H,W,H)','crewBoss(2,-W/2,-.92*H,W,H)');
 s=s.replace('function drawBoss(){',`function crewBoss(i,x,y,w,h){const im=tex.bossCrew,cw=im.width/3;c.drawImage(im,i*cw,0,cw,im.height,x,y,w,h);}
function drawBoss(){`);
 return s;
});
edit('scripts/game.gd',s=>{
 s=s.replace('var profile_tex: Texture2D','var aim_tex: Texture2D\nvar menu_tex: Texture2D\nvar profile_tex: Texture2D').replace('profile_tex = load(', 'aim_tex = load("res://assets/characters/hero_aim_sheet.png")\n\tmenu_tex = load("res://assets/characters/menu_friends.png")\n\tprofile_tex = load(');
 s=s.replace('var recoil: float=maxf(0,muzzle)/.09*visual.recoil',"RECOIL_PLACEHOLDER");
 s=s.replace("RECOIL_PLACEHOLDER",`var up: bool=aim.y<-.4 and hurt_timer<=0
\tvar aim_frame: int=(5 if muzzle>.045 else 4) if absf(aim.x)>.2 else 6 if not grounded else 7 if crouch else 2+int(stage_time*9)%2 if absf(vel.x)>30 else 1 if muzzle>.045 else 0
\tvar rear: Array=[Vector2(.69,.30),Vector2(.70,.34),Vector2(.72,.29),Vector2(.77,.30),Vector2(.74,.35),Vector2(.78,.36),Vector2(.70,.28),Vector2(.77,.42)]
\tif up: anchors[frame]=rear[aim_frame]
\tvar recoil: float=maxf(0,muzzle)/.09*visual.recoil*.35
\tvar offset: Vector2=-aim*recoil+Vector2(0,sin(stage_time*3)*.65 if grounded and absf(vel.x)<30 else 0)`);
 s=s.replace(')-aim*recoil',')+offset').replace('return {"origin":origin,','return {"up":up,"aim_frame":aim_frame,"offset":offset,"origin":origin,');
 return s;
});
edit('scripts/presentation.gd',s=>{
 s=s.replace('hero(g.pos,108,frame,g.face,tint,true)',`var pose: Dictionary=g.weapon_pose()
\tif pose.up:
\t\tvar cell: Vector2=g.aim_tex.get_size()/Vector2(4,2)
\t\tdraw_set_transform_matrix(world_transform()*Transform2D(0,Vector2(g.face,1),0,g.pos+pose.offset))
\t\tregion_texture(Rect2(-54,-108,108,108),g.aim_tex,Rect2(Vector2(pose.aim_frame%4,pose.aim_frame/4)*cell,cell),tint)
\t\tdraw_set_transform_matrix(world_transform())
\telse: hero(g.pos+pose.offset,108,frame,g.face,tint,true)`);
 s=s.replace('weapon_icon(g.weapon,Rect2(-p.width*p.grip,-p.height*.48,p.width,p.height),tint)',`weapon_icon(g.weapon,Rect2(-p.width*p.grip,-p.height*.48,p.width,p.height),tint)
\tdraw_circle(Vector2(0,p.height*.18),3.3,Color("ffe9df"))
\tif g.weapon!=5: draw_circle(Vector2(minf(p.width*.28,19),p.height*.12),3.4,Color("ffe9df"))`);
 const a=s.indexOf('\tdraw_circle(Vector2(951,290),208,PINK)',s.indexOf('func title_screen()')),b=s.indexOf('\tvar names:',a);if(a>=0)s=s.slice(0,a)+s.slice(b);
 s=s.replace('func title_screen() -> void:\n','func title_screen() -> void:\n\timage(g.menu_tex,Rect2(0,0,1280,720))\n').replace('draw_rect(Rect2(0,0,1280,720),Color("fff0f2ee"))','draw_rect(Rect2(0,0,570,720),Color("fff0f244"))').replace('box(Rect2(26,24,1228,672),Color("fff8f580"),36,Color("edb9c7"),2)','box(Rect2(26,24,560,490),Color("fff8f570"),36)');return s;
});
edit('tools/package-web.cjs',s=>s.replace("['profile.jpg'","['hero_aim_sheet.png','menu_friends.png','profile.jpg'"));
