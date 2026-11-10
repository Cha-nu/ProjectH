const fs=require('node:fs');function edit(p,f){fs.writeFileSync(p,f(fs.readFileSync(p,'utf8')));}
edit('web/render.js',s=>{
 s=s.replace(/function background\(\)\{[\s\S]*?\nfunction world\(\)/,`function background(){c.imageSmoothingEnabled=true;c.imageSmoothingQuality='high';c.fillStyle='#e8eee0';c.fillRect(0,0,1280,720);const off=Math.round(g.camera*.12)%1280;panelBG(g.stage,-off,0,1280,576);panelBG(g.stage,1280-off,0,1280,576);}\nfunction world()`);
 const a=s.indexOf(' for(let i=Math.floor(g.camera/70)'),b=s.indexOf(' for(const h of g.hazards)',a);s=s.slice(0,a)+s.slice(b);
 const start=s.indexOf('function hud(){'),end=s.indexOf('function title(){',start);
 s=s.slice(0,start)+`function hud(){
 // A compact combat HUD, with a thumb-zone action cluster rather than dashboard cards.
 circle(57,55,33,'#fff8f5');circle(57,55,30,PINK);c.save();c.beginPath();c.arc(57,55,27,0,Math.PI*2);c.clip();c.drawImage(tex.profile,220,65,440,440,30,28,54,54);c.restore();
 box(96,25,192,24,'#69444fbb',12);text('허니츄러스',109,42,13,PAPER,'left',800);text('× '+g.lives,272,42,12,PAPER,'right');
 box(96,56,192,16,'#fff8f5',8);box(99,59,186*g.hp/5,10,'#ed96ae',5);text(g.hp+' / 5',192,68,9,INK,'center',800);
 box(25,96,263,42,'#fff8f5e8',21);weaponIcon(g.weapon,38,105,65,25);text(WEAPONS[g.weapon].name,114,112,12,INK,'left',800);text(g.ammo[g.weapon]<0?'∞':String(g.ammo[g.weapon]),114,130,17,'#b65c7d','left',800);box(244,104,28,26,PINK,13);text('Q',258,122,12,INK,'center',800);
 box(480,22,320,32,'#69444fbb',16);text('0'+(g.stage+1)+'  '+STAGES[g.stage].name,640,44,15,PAPER,'center',800);
 const z=g.zones[g.zoneIndex];text(z.name+'  ·  '+(g.zoneIndex+1)+' / '+g.zones.length,640,74,12,INK,'center',700);
 text(String(g.score).padStart(7,'0'),1168,45,23,INK,'right',800);text('SCORE',1168,63,9,INK,'right');bee(1083,96,30);text('× '+g.rescued,1104,90,14,INK);
 circle(1229,51,25,'#fff8f5e8');line(1225,43,1225,59,INK,3);line(1233,43,1233,59,INK,3);
 circle(110,619,67,'#fff8f550');circle(110,619,51,'#fff8f560');circle(110,619,26,'#FFD8D9bb');text('←',64,625,21,INK,'center');text('→',156,625,21,INK,'center');text('↑',110,579,19,INK,'center');text('↓',110,667,19,INK,'center');
 for(const [x,y,r,label,key] of [[1180,620,49,'사격','Z'],[1078,650,35,'점프','X'],[1085,553,30,'수류탄','C']]){circle(x,y+4,r,'#69444f22');circle(x,y,r,'#fff8f5d9');circle(x,y,r-5,'#FFD8D9cc');text(label,x,y+4,r===49?16:12,INK,'center',800);text(key,x,y+22,10,'#a76f85','center');}text('× '+g.grenades,1085,521,13,INK,'center',800);
 if(g.combo>=2)text(g.combo+' COMBO!',32,176,23,'#b65c7d','left',900);
 if(g.weaponPop>0){box(430,550,420,40,PINK,20);text('WEAPON GET!  '+WEAPONS[g.weapon].name,640,577,20,INK,'center',800);}
 if(g.boss&&!g.boss.dead){box(350,98,580,30,'#69444fcc',15);text('BOSS',367,118,11,PAPER);box(420,108,490,9,'#f0dbe0',5);box(420,108,490*Math.max(0,g.boss.hp/g.boss.max),9,'#ed96ae',5);}
 cinematic();
}
function cinematic(){
 const intro=g.stageTime<2.5&&!g.boss,warning=g.boss&&!g.boss.dead&&g.boss.state==='enter',win=g.mode==='celebrate';
 if(intro||warning||win){const col=warning?'#f1a0b6':'#FFD8D9';box(0,207,1280,105,'#69444fe6',0);for(let i=0;i<24;i++)box((i*70+g.time*70)%1400-70,207,40,5,col,0);text(warning?'WARNING':win?'MISSION COMPLETE!':'MISSION '+(g.stage+1)+'  START!',640,267,42,col,'center',900);text(warning?'거대 장갑차 접근 · 전투 준비':win?'허니비 구출 성공!':'허니비를 구출하고 전진하세요!',640,296,15,PAPER,'center');}
 else if(g.bannerTime>0){box(440,150,400,36,'#fff8f5e8',18);text(g.banner,640,174,14,INK,'center',700);}
 if(!g.boss&&g.zones[g.zoneIndex].cleared){text('GO!  →',1180,300+Math.sin(g.time*6)*6,30,'#b65c7d','center',900);}
}
`+s.slice(end);
 // Pointer controls support multiple simultaneous fingers and release safely.
 const point=`const touches=new Map();function touchAction(e){const r=canvas.getBoundingClientRect(),x=(e.clientX-r.left)*1280/r.width,y=(e.clientY-r.top)*720/r.height;if(x<195&&y>530){const dx=x-110,dy=y-619;return Math.abs(dx)>Math.abs(dy)?dx<0?'left':'right':dy<0?'up':'down';}if(Math.hypot(x-1180,y-620)<53)return 'fire';if(Math.hypot(x-1078,y-650)<39)return 'jump';if(Math.hypot(x-1085,y-553)<34)return 'grenade';if(x>244&&x<280&&y>96&&y<140)return 'swap';return null;}function touchEnd(e){const old=touches.get(e.pointerId);touches.delete(e.pointerId);if(old&&![...touches.values()].includes(old)){keys.delete(old);released.add(old);}}canvas.addEventListener('pointerdown',e=>{if(g.mode!=='play')return;const action=touchAction(e);if(action){e.preventDefault();canvas.setPointerCapture(e.pointerId);touches.set(e.pointerId,action);keys.add(action);pressed.add(action);}});canvas.addEventListener('pointermove',e=>{if(!touches.has(e.pointerId))return;const next=touchAction(e),old=touches.get(e.pointerId);if(next!==old){touchEnd(e);if(next){touches.set(e.pointerId,next);keys.add(next);pressed.add(next);}}});canvas.addEventListener('pointerup',touchEnd);canvas.addEventListener('pointercancel',touchEnd);\n`;
 s=s.replace("document.querySelector('#full').onclick",point+"document.querySelector('#full').onclick");return s;
});
edit('web/index.html',s=>s.replace('canvas{display:block;','canvas{touch-action:none;display:block;'));
edit('scripts/presentation.gd',s=>{
 const a=s.indexOf('\tfor i in range(18):',s.indexOf('func background()')),b=s.indexOf('\nfunc world()',a);s=s.slice(0,a)+s.slice(b);
 const d=s.indexOf('\tfor i in range(int(g.camera_x/70)'),e=s.indexOf('\tfor hazard in g.hazards:',d);s=s.slice(0,d)+s.slice(e);
 s=s.replace('fmod(g.camera_x*0.18,1280)','fmod(round(g.camera_x*0.12),1280)').replaceAll('-offset,40,1280,570','-offset,0,1280,576').replaceAll('1280-offset,40,1280,570','1280-offset,0,1280,576');
 // Native HUD keeps keyboard input; same compact silhouette and combat priorities.
 const h=s.indexOf('func hud()'),t=s.indexOf('func title_screen()',h);
 s=s.slice(0,h)+`func hud() -> void:
\tdraw_circle(Vector2(57,55),33,PAPER)
\tvar points:=PackedVector2Array(); var uvs:=PackedVector2Array()
\tfor i in range(64):
\t\tvar unit:=Vector2(cos(i*TAU/64),sin(i*TAU/64)); points.append(Vector2(57,55)+unit*27); uvs.append((Vector2(440,285)+unit*220)/g.profile_tex.get_size())
\tdraw_polygon(points,PackedColorArray([Color.WHITE]),uvs,g.profile_tex)
\tbox(Rect2(96,25,192,24),Color("69444fbb"),12); text_at("허니츄러스     × %d"%g.lives,Vector2(109,42),13,PAPER)
\tbox(Rect2(96,56,192,16),PAPER,8); box(Rect2(99,59,186*g.hp/5.0,10),Color("ed96ae"),5)
\tbox(Rect2(25,96,263,42),Color("fff8f5e8"),21); weapon_icon(g.weapon,Rect2(38,105,65,25)); text_at(g.WEAPONS[g.weapon].name,Vector2(114,112),12,INK)
\ttext_at("∞" if g.ammo[g.weapon]<0 else str(g.ammo[g.weapon]),Vector2(114,130),17,Color("b65c7d")); box(Rect2(244,104,28,26),PINK,13); center("Q",Vector2(258,122),12,INK)
\tbox(Rect2(480,22,320,32),Color("69444fbb"),16); center("0%d  %s"%[g.stage+1,g.STAGES[g.stage].name],Vector2(640,44),15,PAPER)
\tcenter("%s  ·  %d / %d"%[g.zones[g.zone_index].name,g.zone_index+1,g.zones.size()],Vector2(640,74),12,INK)
\ttext_at("%07d"%g.score,Vector2(1030,45),23,INK); bee(Vector2(1083,96),30); text_at("× %d"%g.rescued,Vector2(1104,90),14,INK)
\tdraw_circle(Vector2(1229,51),25,PAPER); center("Ⅱ",Vector2(1229,58),19,INK)
\tdraw_circle(Vector2(110,619),67,Color("fff8f550")); draw_circle(Vector2(110,619),51,Color("fff8f560")); draw_circle(Vector2(110,619),26,Color("FFD8D9bb"))
\tcenter("←",Vector2(64,625),21,INK); center("→",Vector2(156,625),21,INK); center("↑",Vector2(110,579),19,INK); center("↓",Vector2(110,667),19,INK)
\tfor action in [[1180,620,49,"사격","Z"],[1078,650,35,"점프","X"],[1085,553,30,"수류탄","C"]]:
\t\tvar p:=Vector2(action[0],action[1]); draw_circle(p+Vector2(0,4),action[2],Color("69444f22")); draw_circle(p,action[2],Color("fff8f5d9")); draw_circle(p,action[2]-5,Color("FFD8D9cc")); center(action[3],p+Vector2(0,4),14,INK); center(action[4],p+Vector2(0,22),10,Color("a76f85"))
\tcenter("× %d"%g.grenades,Vector2(1085,521),13,INK)
\tif g.combo>=2: text_at("%d COMBO!"%g.combo,Vector2(32,176),23,Color("b65c7d"))
\tif g.weapon_pop>0:
\t\tbox(Rect2(430,550,420,40),PINK,20); center("WEAPON GET!  "+g.WEAPONS[g.weapon].name,Vector2(640,577),20,INK)
\tif not g.boss.is_empty() and not g.boss.dead:
\t\tbox(Rect2(350,98,580,30),Color("69444fcc"),15); text_at("BOSS",Vector2(367,118),11,PAPER); box(Rect2(420,108,490,9),Color("f0dbe0"),5); box(Rect2(420,108,490*maxf(0,g.boss.hp/g.boss.max),9),Color("ed96ae"),5)
\tvar intro: bool=g.stage_time<2.5 and g.boss.is_empty()
\tvar warning: bool=not g.boss.is_empty() and not g.boss.dead and g.boss.state=="enter"
\tvar win: bool=g.mode=="celebrate"
\tif intro or warning or win:
\t\tbox(Rect2(0,207,1280,105),Color("69444fe6"),0)
\t\tfor i in range(24): box(Rect2(fmod(i*70+g.time*70,1400)-70,207,40,5),PINK,0)
\t\tcenter("WARNING" if warning else "MISSION COMPLETE!" if win else "MISSION %d  START!"%(g.stage+1),Vector2(640,267),42,PINK)
\t\tcenter("거대 장갑차 접근 · 전투 준비" if warning else "허니비 구출 성공!" if win else "허니비를 구출하고 전진하세요!",Vector2(640,296),15,PAPER)
\telif g.banner_time>0:
\t\tbox(Rect2(440,150,400,36),Color("fff8f5e8"),18); center(g.banner,Vector2(640,174),14,INK)
\tif g.boss.is_empty() and g.zones[g.zone_index].cleared: center("GO! →",Vector2(1180,300+sin(g.time*6)*6),30,Color("b65c7d"))

`+s.slice(t);return s;
});
