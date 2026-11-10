const fs=require('node:fs');const file='web/render.js';let s=fs.readFileSync(file,'utf8');
function replace(a,b){if(!s.includes(a))throw Error(a.slice(0,80));s=s.replace(a,b);}
function section(a,b,v){let x=s.indexOf(a),y=s.indexOf(b,x);if(x<0||y<0)throw Error(a);s=s.slice(0,x)+v+s.slice(y);}
replace('{Game,STAGES,WEAPONS,clamp}','{Game,STAGES,WEAPONS,VISUALS,weaponPose,playerFrame,clamp}');
replace("const INK='#39272d',PAPER='#fff4db',PINK='#ef91aa',GOLD='#ffc45e',TEAL='#35685e';", "const INK='#69444f',PAPER='#fff8f5',PINK='#FFD8D9',GOLD='#f4a7b8',TEAL='#416c61';");
replace("hero:'characters/hero_sheet.png',", "m4:'characters/m4_black.png',fishAnim:'characters/fish_sheet.png',bossParts:'characters/boss_parts.png',hero:'characters/hero_sheet.png',");
replace("switch(kind){case'shot':", "switch(kind){case'akm':tone(170,.1,'sawtooth',.16,45);break;case'm4':tone(260,.065,'square',.095,90);break;case'smg':tone(390,.045,'triangle',.12,130);break;case'pistol':tone(280,.11,'square',.17,65);break;case'sniper':tone(95,.27,'sawtooth',.3,24);tone(1800,.035,'triangle',.1);break;case'shot':");
section(' for(const e of g.enemies){',' drawBoss();',` for(const e of g.enemies)drawEnemy(e);
`);
section("else if(b.friendly){", "else{circle(b.x,b.y,10,INK)", 'else if(b.friendly){drawProjectile(b);}');
// Above substring begins immediately after the honey branch in the existing renderer.
section(' let frame=4;', ' if(g.support>0)',` const frame=playerFrame(g),alpha=g.invincible>0&&Math.floor(g.stageTime*16)%2===0?.45:1;
 ellipse(g.x,g.y+4,43,8,'#261f1f40');hero(g.x,g.y,144,frame,g.face,alpha,true);drawGun();drawMuzzle();
`);
replace("if(p.kind==='fish')fish(p.x,p.y,p.size*2);else{", "if(p.kind==='fish')fish(p.x,p.y,p.size*2);else if(p.kind==='armor'||p.kind==='casing'){c.save();c.translate(p.x,p.y);c.rotate(p.life*8);box(-p.size/2,-p.size/3,p.size,p.size*.65,p.color,2);c.restore();}else{");
section(' if(!g.boss){box(', 'c.restore();}', ` for(let i=0;i<g.zones.length;i++){const z=g.zones[i],guards=g.enemies.filter(e=>e.zone===i&&e.guard&&e.hp>0).length;box(z.end-29,365,32,211,z.cleared?'#afdbb8':PINK,14,'#946375',2);circle(z.end-13,393,8,z.cleared?'#568466':'#e77894');if(!z.cleared){for(let y=430;y<560;y+=27)line(z.end-65,y,z.end+35,y-12,'#ffb8c6aa',7);}box(z.end-106,318,190,35,PAPER,17);text(z.cleared?'구역 확보 ✓':'경비 '+guards+' · 통로 봉쇄',z.end-11,341,13,INK,'center');}
 `);
section('function drawGun(){','function hud(){',`
function weaponIcon(index,x,y,w,h){if(index===2){c.drawImage(tex.m4,.025*tex.m4.width,.16*tex.m4.height,.95*tex.m4.width,.74*tex.m4.height,x,y,w,h);return;}const r=[[.01,.28,.343,.21],[.351,.319,.349,.14],[.709,.28,.287,.21],[.026,.59,.351,.17],[.438,.58,.229,.23],[.775,.61,.166,.18]][index],im=tex.weapons;c.drawImage(im,r[0]*im.width,r[1]*im.height,r[2]*im.width,r[3]*im.height,x,y,w,h);}
function drawGun(){const p=weaponPose(g);c.save();c.translate(p.x,p.y);c.rotate(p.angle);c.scale(p.face,1);if(g.invincible>0&&Math.floor(g.stageTime*16)%2===0)c.globalAlpha=.45;weaponIcon(g.weapon,-p.width*p.grip,-p.height*.48,p.width,p.height);c.restore();}
function drawMuzzle(){if(g.muzzle<=0)return;const p=weaponPose(g),v=VISUALS[g.lastShotWeapon],f=g.muzzle/.09,colors=['#ffd079','#fff1c0','#beeaff','#ffa662','#ffc5e5','#ffe3a7'];c.save();c.translate(p.mx,p.my);c.rotate(Math.atan2(p.aim.y,p.aim.x));c.globalAlpha=f;circle(4,0,v.flash*.7,colors[g.lastShotWeapon]+'66');c.beginPath();const len=v.flash*(1.1+f);c.moveTo(-3,-4);c.lineTo(len*.45,-v.flash*.4);c.lineTo(len*.36,-3);c.lineTo(len,0);c.lineTo(len*.36,3);c.lineTo(len*.45,v.flash*.4);c.lineTo(-3,4);c.closePath();c.fillStyle=colors[g.lastShotWeapon];c.fill();circle(3,0,4,PAPER);c.restore();}
function drawProjectile(b){const len=Math.hypot(b.vx,b.vy),dx=b.vx/len,dy=b.vy/len,index=b.weapon??0,v=VISUALS[index],col=b.kind==='support'?'#9bf4ce':WEAPONS[index].color;
 if(b.kind==='rocket'){c.save();c.translate(b.x,b.y);c.rotate(Math.atan2(dy,dx));box(-17,-5,30,10,'#636c54',4,'#493b3c',2);line(-18,0,-36-Math.random()*10,0,'#ffab62',7);circle(-34,0,4,'#fff5be');c.restore();return;}
 const trail=b.kind==='sniper'?72:b.kind==='smg'?12:b.kind==='pistol'?9:24;line(b.x-dx*trail,b.y-dy*trail,b.x,b.y,col+'44',b.kind==='sniper'?8:6);line(b.x-dx*trail*.7,b.y-dy*trail*.7,b.x,b.y,col,b.kind==='sniper'?2.5:3);circle(b.x,b.y,b.kind==='pistol'?3:2.5,PAPER);}
function drawEnemy(e){const size=e.kind===2?105:92,frame=e.launch>0||e.kind===3&&e.y<550?6:e.kick>0?7:e.warn?5:e.walk?Math.floor(e.t*9)%4:4,im=tex.fishAnim,cw=im.width/4,ch=im.height/2,beat=Math.sin(e.t*9),sx=1+(e.walk?.035:.015)*beat,sy=1-(e.walk?.035:.015)*beat;
 ellipse(e.x,e.y+4,size*.36,6,'#261f1f2a');c.save();c.translate(e.x,e.y);c.scale(e.facing>0?-sx:sx,sy);c.rotate(e.walk?.025*beat:0);if(e.flash>0)c.filter='brightness(1.6)';c.drawImage(im,frame%4*cw,Math.floor(frame/4)*ch,cw,ch,-size/2,-size,size,size);c.restore();
 if(e.kind===1){line(e.x-32,e.y-85,e.x+32,e.y-85,INK,3);line(e.x-40*Math.sin(g.time*40),e.y-92,e.x+40*Math.sin(g.time*40),e.y-92,TEAL,4);}if(e.kind===2)box(e.x-45,e.y-38,12,37,'#829b89',5,INK,2);if(e.guard){box(e.x-17,e.y-112,34,20,PINK,10);text('★',e.x,e.y-97,13,INK,'center');}if(e.warn)text('!',e.x,e.y-119,27,'#d64c71','center',900);}
function bossPart(index,x,y,w,h){const regions=[[.01,.015,.62,.61],[.63,.23,.365,.31],[.125,.645,.247,.34],[.45,.68,.545,.30]],r=regions[index],im=tex.bossParts;c.drawImage(im,r[0]*im.width,r[1]*im.height,r[2]*im.width,r[3]*im.height,x,y,w,h);}
function drawBoss(){const b=g.boss;if(!b)return;const scale=g.stage===3?1:.68;c.save();c.translate(b.x,b.y);c.scale(scale,scale);ellipse(0,6,285,18,'#291c2638');
 if(b.dead){c.rotate(.035*Math.sin(g.time*3));bossPart(3,-285,-130,570,130);for(let i=0;i<16;i++)fish(Math.sin(i*2.1)*250,-Math.abs(Math.sin(g.time*2+i))*190,60);c.restore();return;}
 bossPart(3,-285,-170,570,170);
 for(let i=0;i<21;i++){const phase=(i/21+b.track*.13)%1,angle=phase*Math.PI*2,x=Math.cos(angle)*252,y=-77+Math.sin(angle)*63;c.save();c.translate(x,y);c.rotate(angle+Math.PI/2);box(-11,-4,22,8,'#6d4b41',3,'#34262b',1);c.restore();}
 const bob=Math.sin(b.t*7)*2+(b.state==='windup'?Math.sin(b.t*16)*1.5:0),pitch=Math.sin(b.t*2)*.009-b.recoil*.014;c.save();c.translate(0,bob);c.rotate(pitch);if(b.flash>0)c.filter='brightness(1.3)';bossPart(0,-260,-445,520,355);
 if(b.phase===2){c.globalAlpha=.94;fish(-70,-120,360);c.globalAlpha=1;for(let i=0;i<6;i++)circle(80+i*18,-290-(b.t*35+i*23)%120,14+(i%3)*5,'#6f515655');}
 c.save();c.translate(-105,-350-Math.sin(b.t*3)*3-b.recoil*4);c.rotate(Math.sin(b.t*2)*.035+(b.state==='windup'?-.08:0));bossPart(2,-55,-120,110,120);c.restore();
 c.save();c.translate(-115+b.recoil*27,-212);c.rotate(-.025*Math.sin(b.t*1.5)+(b.state==='windup'?-.035:0));bossPart(1,-162,-83,260,167);if(b.recoil>.6){circle(-157,0,32*b.recoil,'#ffdf9b99');circle(-162,0,15*b.recoil,'#fff6da');}c.restore();c.restore();
 for(let i=0;i<4;i++){const a=(b.t*.7+i*.25)%1;circle(160+i*6,-345-a*95,7+a*16,'#927c8130');}
 if(b.warn){box(-220,-480,250,39,PINK,20);text(['포격 준비!','과메기 발사!','꿀통 투척!'][b.pattern],-95,-454,17,INK,'center',700);}c.restore();}
function panel(x,y,w,h,color=PAPER){box(x,y+5,w,h,'#713e5020',24);box(x,y,w,h,color,24,'#f0bcc7',1.5);}
`);
section('function hud(){','function title(){',`function hud(){
 panel(18,16,300,78);circle(60,55,28,PINK);c.save();c.beginPath();c.arc(60,55,25,0,Math.PI*2);c.clip();hero(60,113,98,4);c.restore();text('허니츄러스',99,43,16,INK,'left',800);for(let i=0;i<5;i++)circle(105+i*25,67,8,i<g.hp?'#e98da5':'#eedde1');text('× '+g.lives,251,67,17,INK,'left',700);
 panel(330,16,315,78,g.weaponPop>0?'#ffe2e5':PAPER);weaponIcon(g.weapon,347,39,83,33);text(WEAPONS[g.weapon].name,444,45,20,INK,'left',800);text(g.ammo[g.weapon]<0?'∞':String(g.ammo[g.weapon]).padStart(3,'0'),444,74,23,'#bc637e','left',800);text('Q 교체',575,72,12,'#ae7a89');
 panel(657,16,238,78);text('SCORE',675,39,11,'#b18190','left',700);text(String(g.score).padStart(7,'0'),675,66,22,INK,'left',800);bee(847,62,37);text(String(g.rescued).padStart(2,'0'),865,67,17,INK);text('수류탄 '+g.grenades,675,84,10,'#a27884');
 panel(907,16,355,78);text('MISSION 0'+(g.stage+1)+' / 04',927,39,11,'#b18190','left',700);text(STAGES[g.stage].name,927,66,19,INK,'left',800);box(1197,33,48,40,PINK,17);text('Ⅱ',1221,59,17,INK,'center',800);
 const z=g.zones[g.zoneIndex];panel(22,110,268,51,'#fff8f5ed');text('AREA '+(g.zoneIndex+1)+' / '+g.zones.length,39,130,10,'#b18190','left',800);text(z.name,39,150,15,INK,'left',700);
 for(let i=0;i<g.zones.length;i++){const x=925+i*62;box(x,109,53,26,g.zones[i].cleared?'#b5d9c5':i===g.zoneIndex?PINK:'#fff8f5bb',13);text(g.zones[i].cleared?'✓':'0'+(i+1),x+26,127,12,INK,'center',700);}
 if(g.combo>=2)text(g.combo+' COMBO!',32,195,25,'#bd5f7d','left',900);
 if(g.bannerTime>0){c.font="600 17px 'Malgun Gothic',system-ui,sans-serif";const width=c.measureText(g.banner).width+50;panel(640-width/2,108,width,45,PINK);text(g.banner,640,137,17,INK,'center',700);}
 if(g.weaponPop>0){const a=Math.min(1,g.weaponPop*2);c.save();c.globalAlpha=a;panel(510,181,260,61);weaponIcon(g.weapon,527,195,76,32);text(WEAPONS[g.weapon].name,616,204,17,INK,'left',800);text('WEAPON EQUIPPED',616,225,10,'#b18190');c.restore();}
 if(g.boss&&!g.boss.dead){panel(289,601,702,49);box(302,626,676,12,'#f0dbe0',6);box(302,626,676*Math.max(0,g.boss.hp/g.boss.max),12,'#e98aa5',6);text(g.stage===3?'오리고기 · 초거대 과메기 전차':'과메기단 기동부대',640,620,13,INK,'center',800);}
 panel(282,669,716,33,'#fff8f5e8');text('← → 이동   ↑ 조준   ↓ 앉기   Z 사격   X / Space 점프   C 수류탄   Q 무기   ESC 일시정지',640,691,12,INK,'center');
 if(!g.boss){const len=STAGES[g.stage].length;c.fillStyle='#f7d4dc';c.fillRect(32,648,1216,4);c.fillStyle='#c66e8d';c.fillRect(32,648,1216*g.x/len,4);for(const zone of g.zones)circle(32+1216*zone.end/len,650,5,zone.cleared?'#72a98c':PINK);}}
`);
replace("c.fillStyle='#faf0d4e8'", "c.fillStyle='#fff0f2ee'");
replace("box(26,24,1228,672,'#fff7e666',24,INK,2)","box(26,24,1228,672,'#fff8f580',36,'#edb9c7',2)");
replace("box(67,399,295,67,INK,13);box(67,394,295,67,GOLD,13,INK,3)","box(67,401,295,67,'#d995aa',28);box(67,394,295,67,PINK,28,'#f2b7c5',2)");
replace("circle(951,290,208,'#ead8b2')", "circle(951,290,208,'#FFD8D9')");
replace("box(x,535,271,104,'#f6e8cb',12,'#bda98f',1)", "panel(x,535,271,104,'#fff8f5')");
replace("box(322,177,636,377,INK,24);box(315,168,636,377,PAPER,24,INK,3)","box(322,177,636,377,'#713e5030',32);box(315,168,636,377,PAPER,32,'#efbac9',2)");
replace("box(444,405,384,67,GOLD,12,INK,2)","box(444,405,384,67,PINK,26,'#eaa6bc',2)");
replace("if(g.mode!=='play')overlay();", "if(['briefing','pause','clear','gameover','victory'].includes(g.mode))overlay();");
fs.writeFileSync(file,s);console.log('Updated web animation, weapon effects and pink rounded UI.');
