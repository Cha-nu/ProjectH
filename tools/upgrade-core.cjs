const fs=require('node:fs');
const file='web/game.js';let s=fs.readFileSync(file,'utf8');
function replace(a,b){if(!s.includes(a))throw Error('Missing '+a.slice(0,70));s=s.replace(a,b);}
function section(a,b,v){const x=s.indexOf(a),y=s.indexOf(b,x);if(x<0||y<0)throw Error(a);s=s.slice(0,x)+v+s.slice(y);}
replace("length:4400,color", "length:4580,zones:['꽃길 입구','방송 장비 거리','송신탑 광장'],color");
replace("length:4800,color", "length:5680,zones:['꿀 운송장','컨베이어 홀','벌집 정제실','저장고 관제실'],color");
replace("length:5000,color", "length:4580,zones:['해변 초소','부두 창고','상륙정 선착장'],color");
replace("length:5200,color", "length:5680,zones:['요새 외벽','해산물 병영','중앙 보급로','오리고기 사령부'],color");
replace("const clamp=",`const VISUALS=[
 {width:88,ratio:.40,grip:.36,recoil:4,flash:18,kind:'akm',sound:'akm'},
 {width:108,ratio:.26,grip:.44,recoil:9,flash:31,kind:'sniper',sound:'sniper'},
 {width:90,ratio:.40,grip:.35,recoil:3,flash:15,kind:'m4',sound:'m4'},
 {width:104,ratio:.37,grip:.47,recoil:12,flash:34,kind:'rocket',sound:'rocket'},
 {width:62,ratio:.66,grip:.43,recoil:2,flash:11,kind:'smg',sound:'smg'},
 {width:43,ratio:.68,grip:.28,recoil:5,flash:13,kind:'pistol',sound:'pistol'}];
function playerFrame(g){if(g.hurtTimer>0)return 7;if(g.crouch)return 5;if(!g.grounded)return 6;if(Math.abs(g.vx)>30)return Math.floor(g.stageTime*12)%4;return 4;}
function weaponPose(g){const frame=playerFrame(g),v=VISUALS[g.weapon],anchors=[[.52,.55],[.53,.55],[.54,.54],[.51,.55],[.52,.54],[.55,.67],[.55,.49],[.55,.53]],a=g.aim(),recoil=Math.max(0,g.muzzle)/.09*v.recoil;
 const x=g.x+(anchors[frame][0]-.5)*144*g.face-a.x*recoil,y=g.y+(anchors[frame][1]-1)*144-a.y*recoil,reach=v.width*(1-v.grip),normal=-v.width*v.ratio*.13*g.face;
 return {frame,x,y,angle:Math.atan2(a.y*g.face,a.x*g.face),face:g.face,width:v.width,height:v.width*v.ratio,grip:v.grip,mx:x+a.x*reach-a.y*normal,my:y+a.y*reach+a.x*normal,aim:a};}
const clamp=`);
replace("this.boss=null;this.nextId=1;","this.boss=null;this.nextId=1;this.hurtTimer=0;this.lastShotWeapon=0;this.weaponPop=0;this.gateToast=0;this.zoneIndex=0;this.celebrate=0;this.zones=STAGES[this.stage].zones.map((name,i)=>({name,start:i*1100,end:(i+1)*1100,cleared:false,entered:i===0}));");
section(' const len=STAGES[this.stage].length;', ' this.toast(`MISSION',` for(let z=0;z<this.zones.length;z++){
 const start=z*1100;
 for(let i=0;i<5;i++){this.spawnEnemy(start+440+i*125,576,(i+z+this.stage)%4);const e=this.enemies.at(-1);e.zone=z;e.guard=i>=3;}
 this.cages.push({x:start+460,y:576,hp:4,open:false,taken:false,special:z===2});
 this.platforms.push({x:start+260,y:441,w:190,h:20,type:'normal',base:start+260},{x:start+600,y:396,w:190,h:20,type:'normal',base:start+600});
 this.props.push({x:start+580,y:576,hp:4},{x:start+820,y:576,hp:4});
 this.pickups.push({x:start+680,y:365,kind:'weapon',weapon:(z+this.stage+1)%5,t:0});
 if(this.stage===1){this.platforms.push({x:start+640,y:564,w:310,h:20,type:'belt'});this.hazards.push({x:start+330,y:568,w:100,h:12,kind:'honey'});}
 if(this.stage===2){this.hazards.push({x:start+560,y:571,w:185,h:150,kind:'water'});this.platforms.push({x:start+590,base:start+590,y:531,w:160,h:20,type:'boat'});}
 if(this.stage===3)this.hazards.push({x:start+570,y:568,w:100,h:12,kind:'steam'});
 }
 if(this.cages.length<4)this.cages.push({x:3020,y:576,hp:4,open:false,taken:false,special:false});
`);
replace("flash:0,warn:0});}","flash:0,warn:0,facing:-1,walk:0,kick:0,zone:-1,guard:false,launch:0,vx:0,vy:0});}");
replace("if(this.mode!=='play'){if(this.mode==='clear'){", "if(this.mode!=='play'){if(this.mode==='celebrate'){this.celebrate-=dt;if(this.celebrate<=0)this.mode='clear';}if(this.mode==='clear'||this.mode==='celebrate'){");
replace('this.stageTime+=dt;', 'this.stageTime+=dt;this.hurtTimer=Math.max(0,this.hurtTimer-dt);this.weaponPop=Math.max(0,this.weaponPop-dt);this.gateToast-=dt;');
replace('this.x=clamp(this.x,Math.max(30,this.camera-80),STAGES[this.stage].length-70);','this.x=clamp(this.x,this.boss?.active?this.zones.at(-1).end+25:30,STAGES[this.stage].length-70);');
section(' if(this.x>this.checkpoint+1000', ' if(input.fire', '');
replace("this.weapon=this.unlocked[(this.unlocked.indexOf(this.weapon)+1)%this.unlocked.length];this.sound('click');", "this.weapon=this.unlocked[(this.unlocked.indexOf(this.weapon)+1)%this.unlocked.length];this.weaponPop=1;this.sound('click');");
replace('this.updateEnemies(dt);this.updateBoss(dt);this.updateBullets(dt);this.collectCages();','this.updateEnemies(dt);this.updateBoss(dt);this.updateBullets(dt);this.collectCages();this.updateZones();');
replace(' if(!this.boss&&this.x>STAGES[this.stage].length-1050)this.startBoss();',' if(!this.boss&&this.zones.every(z=>z.cleared)&&this.x>this.zones.at(-1).end+110)this.startBoss();');
section(' shoot(){',' addBullet(',` shoot(){if(this.ammo[this.weapon]===0){this.weapon=5;this.weaponPop=1;this.toast('탄약 소진 · Glock 19');}const w=WEAPONS[this.weapon],v=VISUALS[this.weapon];if(this.ammo[this.weapon]>0)this.ammo[this.weapon]--;const pose=weaponPose(this),a=pose.aim;this.addBullet(pose.mx,pose.my,a.x*w.speed,a.y*w.speed,true,w.damage,v.kind);const bullet=this.bullets.at(-1);bullet.weapon=this.weapon;bullet.color=w.color;this.fireTimer=w.rate;this.muzzle=.09;this.lastShotWeapon=this.weapon;this.sound(v.sound);this.burst(pose.mx,pose.my,this.weapon===3?12:3,w.color,this.weapon===3?180:100);
 if(this.weapon!==3)this.particles.push({x:pose.x,y:pose.y-9,vx:-this.face*100+rand(-30,30),vy:-rand(100,180),life:.6,max:.6,color:'#efc17c',size:3,kind:'casing'});
 for(const e of this.enemies)if(Math.hypot(e.x-this.x,e.y-this.y)<90){e.hp-=4;e.flash=.12;this.burst(e.x,e.y-30,5,'#fff4be',180);}}
 updateZones(){if(this.boss)return;for(let i=0;i<this.zones.length;i++){const z=this.zones[i];if(!z.entered&&this.x>=z.start+20){z.entered=true;this.zoneIndex=i;this.checkpoint=z.start+100;this.toast('AREA '+(i+1)+' / '+this.zones.length+' · '+z.name);}
 const guards=this.enemies.filter(e=>e.zone===i&&e.guard&&e.hp>0).length;
 if(!z.cleared&&guards===0&&this.x>=z.end-280){z.cleared=true;this.score+=300;this.sound('rescue');this.toast(i===this.zones.length-1?'전 구역 확보! · 보스 구역으로 진입':'구역 확보! · 다음 구역으로 이동');}
 if(!z.cleared&&this.x>z.end-70){this.x=z.end-70;this.vx=0;if(this.gateToast<=0){this.toast('통로 봉쇄 · 경비 '+guards+'마리 남음');this.gateToast=2.5;}break;}}}
`);
replace('e.t+=dt;e.flash=Math.max(0,e.flash-dt);','e.t+=dt;e.flash=Math.max(0,e.flash-dt);e.kick=Math.max(0,e.kick-dt);');
replace('const dx=this.x-e.x,d=Math.sign(dx);e.shot-=dt;if(e.kind===1)', 'const dx=this.x-e.x,d=Math.sign(dx);e.facing=d||e.facing;e.walk=Math.abs(dx)>300?1:0;e.shot-=dt;if(e.launch>0){e.launch-=dt;e.vy+=1250*dt;e.x+=e.vx*dt;e.y+=e.vy*dt;if(e.y>=576){e.y=576;e.launch=0;e.kick=.25;}}else if(e.kind===1)');
replace('e.shot=rand(1.9,3)-this.stage*.16;e.warn=false;', 'e.shot=rand(1.9,3)-this.stage*.16;e.warn=false;e.kick=.22;');
replace('b.x+=b.vx*dt;b.y+=b.vy*dt;', "b.x+=b.vx*dt;b.y+=b.vy*dt;if(b.kind==='rocket'&&Math.random()<.6)this.particles.push({x:b.x,y:b.y,vx:-b.vx*.08,vy:rand(-15,15),life:.35,max:.35,color:'#d8c5c0',size:rand(5,10),kind:'smoke'});");
replace('this.weapon=w;}','this.weapon=w;this.weaponPop=1.2;}');
replace('this.hp--;this.invincible=1.8;', 'this.hp--;this.invincible=1.8;this.hurtTimer=.25;');
replace('this.x=Math.max(this.checkpoint,this.camera+70);','this.x=this.checkpoint;this.camera=clamp(this.x-370,0,STAGES[this.stage].length-1280);');
replace('this.x=Math.max(this.checkpoint,this.camera+70);','this.x=this.checkpoint;this.camera=clamp(this.x-370,0,STAGES[this.stage].length-1280);');
section(' startBoss(){',' damageBoss(',` startBoss(){const hp=this.stage===3?620:150+this.stage*55,home=STAGES[this.stage].length-330;this.boss={x:STAGES[this.stage].length+300,home,y:576,hp,max:hp,active:true,dead:false,t:0,attack:2.5,phase:1,flash:0,warn:0,pattern:0,state:'enter',clock:2.2,recoil:0,track:0,burst:0};this.toast('WARNING · '+['방송 방해 장갑차','꿀 공장 파괴자','과메기 상륙정','오리고기 · 초거대 과메기 전차'][this.stage]);this.shake=5;}
 updateBoss(dt){const b=this.boss;if(!b||b.dead)return;b.t+=dt;b.clock-=dt;b.flash=Math.max(0,b.flash-dt);b.recoil=Math.max(0,b.recoil-dt*3);b.track+=dt*(b.state==='enter'?8:2);b.warn=b.state==='windup';
 if(b.state==='enter'){b.x+=(b.home-b.x)*(1-Math.exp(-dt*3));if(b.clock<=0){b.x=b.home;b.state='idle';b.clock=1.2;}return;}
 if(b.hp<b.max*.5&&b.phase===1){b.phase=2;b.state='break';b.clock=1.3;this.shake=12;for(let i=0;i<12;i++)this.particles.push({x:b.x+rand(-200,170),y:b.y-rand(60,210),vx:rand(-260,220),vy:rand(-400,-120),life:1.8,max:1.8,color:'#8c9b70',size:rand(14,26),kind:'armor'});this.toast('장갑 파괴! · 과메기 본체 노출');}
 if(b.state==='idle'){b.x=b.home+Math.sin(b.t*1.2)*12;if(b.clock<=0){b.state='windup';b.clock=b.phase===1?.9:.65;}}
 else if(b.state==='windup'&&b.clock<=0){b.state='attack';b.clock=.48;this.bossAttack();}
 else if(b.state==='attack'&&b.clock<=0){b.state='recover';b.clock=.7;}
 else if((b.state==='recover'||b.state==='break')&&b.clock<=0){b.pattern=(b.pattern+1)%3;b.state='idle';b.clock=b.phase===1?1.15:.55;}
 if(this.x>b.x-180&&this.y>416)this.hurt();}
 bossAttack(){const b=this.boss,x=b.x-190,y=b.y-145;b.recoil=1;this.shake=4;if(b.pattern===0){for(let i=0;i<(b.phase===1?5:8);i++){const a=Math.PI-.46+i*.13;this.addBullet(x,y,Math.cos(a)*305,Math.sin(a)*305,false,1,'enemy');}}
 else if(b.pattern===1){for(let i=0;i<(b.phase===1?2:3);i++){this.spawnEnemy(x-i*40,y,3);const e=this.enemies.at(-1);e.launch=1.5;e.vx=-220-i*75;e.vy=-260-i*80;}this.burst(x,y,18,'#fff1aa',250);}
 else for(let i=0;i<3;i++)this.addBullet(x,y,-220-i*115,-550-i*45,false,1,'honey');this.sound('heavy');}
`);
replace("this.mode='clear';this.save();}}", "this.mode='celebrate';this.celebrate=3;this.save();}}");
replace('root.HoneyGame={Game,STAGES,WEAPONS,intersects,clamp};','root.HoneyGame={Game,STAGES,WEAPONS,VISUALS,playerFrame,weaponPose,intersects,clamp};');
fs.writeFileSync(file,s);console.log('Upgraded gameplay, rig, zones and boss state machine.');
