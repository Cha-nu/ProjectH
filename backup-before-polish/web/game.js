/* Honey Churros — fixed-step arcade game. No runtime dependencies or network services. */
(function(root){'use strict';
const STAGES=[
 {name:'방송국 습격',sub:'꽃과 꿀의 마을 · 끊어진 방송을 되찾아라',length:4580,zones:['꽃길 입구','방송 장비 거리','송신탑 광장'],color:'#85bf9e'},
 {name:'꿀 저장고 탈환',sub:'벌집 공장 · 컨베이어와 꿀 함정을 돌파하라',length:5680,zones:['꿀 운송장','컨베이어 홀','벌집 정제실','저장고 관제실'],color:'#d5a94d'},
 {name:'과메기 해안기지',sub:'해안과 항구 · 수륙양용 부대를 격파하라',length:4580,zones:['해변 초소','부두 창고','상륙정 선착장'],color:'#68afb6'},
 {name:'과메기단 본부',sub:'해산물 요새 · 오리고기의 초거대 전차',length:5680,zones:['요새 외벽','해산물 병영','중앙 보급로','오리고기 사령부'],color:'#8c829f'}];
const WEAPONS=[
 {name:'AKM',rate:.14,damage:2,speed:1050,ammo:150,color:'#ffc45c'},
 {name:'Kar98k',rate:.65,damage:10,speed:1600,ammo:24,color:'#e6f7dd'},
 {name:'M4',rate:.10,damage:2,speed:1250,ammo:180,color:'#b5e3cf'},
 {name:'RPG-26',rate:.8,damage:18,speed:650,ammo:9,color:'#ff966f'},
 {name:'FMG-9',rate:.065,damage:1,speed:950,ammo:220,color:'#f4a9c8'},
 {name:'Glock 19',rate:.24,damage:2,speed:1000,ammo:-1,color:'#fbdfa5'}];
const VISUALS=[
 {width:88,ratio:.40,grip:.36,recoil:4,flash:18,kind:'akm',sound:'akm'},
 {width:108,ratio:.26,grip:.44,recoil:9,flash:31,kind:'sniper',sound:'sniper'},
 {width:90,ratio:.40,grip:.35,recoil:3,flash:15,kind:'m4',sound:'m4'},
 {width:104,ratio:.37,grip:.47,recoil:12,flash:34,kind:'rocket',sound:'rocket'},
 {width:62,ratio:.66,grip:.43,recoil:2,flash:11,kind:'smg',sound:'smg'},
 {width:43,ratio:.68,grip:.28,recoil:5,flash:13,kind:'pistol',sound:'pistol'}];
function playerFrame(g){if(g.hurtTimer>0)return 7;if(g.crouch)return 5;if(!g.grounded)return 6;if(Math.abs(g.vx)>30)return Math.floor(g.stageTime*12)%4;return 4;}
function weaponPose(g){const frame=playerFrame(g),v=VISUALS[g.weapon],anchors=[[.52,.55],[.53,.55],[.54,.54],[.51,.55],[.52,.54],[.55,.67],[.55,.49],[.55,.53]],a=g.aim(),recoil=Math.max(0,g.muzzle)/.09*v.recoil;
 const x=g.x+(anchors[frame][0]-.5)*108*g.face-a.x*recoil,y=g.y+(anchors[frame][1]-1)*108-a.y*recoil,reach=v.width*.75*(1-v.grip),normal=-v.width*.75*v.ratio*.13*g.face;
 return {frame,x,y,angle:Math.atan2(a.y*g.face,a.x*g.face),face:g.face,width:v.width*.75,height:v.width*.75*v.ratio,grip:v.grip,mx:x+a.x*reach-a.y*normal,my:y+a.y*reach+a.x*normal,aim:a};}
const clamp=(v,a,b)=>Math.min(b,Math.max(a,v)),rand=(a,b)=>a+Math.random()*(b-a),dist=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
function intersects(a,b,r){let t0=0,t1=1,dx=b.x-a.x,dy=b.y-a.y;for(const [p,q] of [[-dx,a.x-r.x],[dx,r.x+r.w-a.x],[-dy,a.y-r.y],[dy,r.y+r.h-a.y]]){if(!p){if(q<0)return false;}else{const t=q/p;if(p<0)t0=Math.max(t0,t);else t1=Math.min(t1,t);if(t0>t1)return false;}}return true;}
class Game{
 constructor(){this.mode='title';this.stage=0;this.time=0;this.best=0;this.sound=()=>{};this.onSave=()=>{};this.ammo=WEAPONS.map(w=>w.ammo);this.unlocked=[0,5];this.weapon=0;this.hp=5;this.lives=3;this.grenades=6;this.score=0;this.rescued=0;this.input={};this.loadStage();this.mode='title';}
 start(){this.stage=0;this.score=0;this.rescued=0;this.lives=3;this.hp=5;this.grenades=6;this.weapon=0;this.unlocked=[0,5];this.ammo=WEAPONS.map(w=>w.ammo);this.loadStage();this.mode='briefing';}
 confirm(){if(['title','gameover','victory'].includes(this.mode))this.start();else if(['pause','briefing'].includes(this.mode))this.mode='play';else if(this.mode==='clear'){if(++this.stage>3){this.stage=3;this.mode='victory';this.save();}else{this.hp=5;this.grenades=Math.min(9,this.grenades+3);this.ammo=WEAPONS.map(w=>w.ammo);this.loadStage();this.mode='briefing';}}}
 pause(){if(this.mode==='play')this.mode='pause';else if(this.mode==='pause')this.mode='play';}
 retry(){if(!['pause','gameover'].includes(this.mode))return;this.hp=5;this.lives=Math.max(3,this.lives);this.ammo=WEAPONS.map(w=>w.ammo);this.grenades=6;this.loadStage();this.mode='play';}
 save(){this.best=Math.max(this.best,this.score);this.onSave(this.best);}
 loadStage(){this.x=180;this.y=576;this.vx=this.vy=0;this.face=1;this.grounded=true;this.crouch=false;this.invincible=2;this.fireTimer=0;this.grenadeTimer=0;this.muzzle=0;this.coyote=0;this.jumpBuffer=0;this.camera=0;this.checkpoint=180;this.shake=0;this.combo=0;this.comboTimer=0;this.stageTime=0;this.stageRescued=0;this.support=0;this.supportTimer=0;this.enemies=[];this.bullets=[];this.particles=[];this.cages=[];this.pickups=[];this.platforms=[];this.hazards=[];this.props=[];this.boss=null;this.nextId=1;this.hurtTimer=0;this.lastShotWeapon=0;this.weaponPop=0;this.gateToast=0;this.zoneIndex=0;this.celebrate=0;this.zones=STAGES[this.stage].zones.map((name,i)=>({name,start:i*1100,end:(i+1)*1100,cleared:false,entered:i===0}));
 for(let z=0;z<this.zones.length;z++){
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
 this.toast(`MISSION ${String(this.stage+1).padStart(2,'0')} · ${STAGES[this.stage].name}`,3.8);}
 toast(s,t=2.5){this.banner=s;this.bannerTime=t;}
 spawnEnemy(x,y,kind){this.enemies.push({id:this.nextId++,x,y,hp:5+this.stage*2+(kind===2?5:0),kind,t:rand(0,2),shot:rand(1.2,2.5),flash:0,warn:0,facing:-1,walk:0,kick:0,zone:-1,guard:false,launch:0,vx:0,vy:0});}
 update(dt,input={}){this.time+=dt;this.input=input;
 if(this.mode!=='play'){if(this.mode==='celebrate'){this.celebrate-=dt;if(this.celebrate<=0)this.mode='clear';}if(this.mode==='clear'||this.mode==='celebrate'){this.particles.forEach(p=>{p.life-=dt;p.x+=p.vx*dt;p.y+=p.vy*dt;p.vy+=400*dt;});this.particles=this.particles.filter(p=>p.life>0);}return;}
 this.stageTime+=dt;this.hurtTimer=Math.max(0,this.hurtTimer-dt);this.weaponPop=Math.max(0,this.weaponPop-dt);this.gateToast-=dt;this.invincible=Math.max(0,this.invincible-dt);this.fireTimer-=dt;this.grenadeTimer-=dt;this.muzzle-=dt;this.comboTimer-=dt;this.bannerTime-=dt;this.shake=Math.max(0,this.shake-22*dt);if(this.comboTimer<=0)this.combo=0;
 const axis=(input.right?1:0)-(input.left?1:0);this.crouch=this.grounded&&input.down;if(axis)this.face=Math.sign(axis);
 if(input.jumpPressed)this.jumpBuffer=.12;this.jumpBuffer-=dt;this.coyote=this.grounded?.1:this.coyote-dt;
 if(this.jumpBuffer>0&&this.coyote>0){this.vy=-660;this.grounded=false;this.jumpBuffer=0;this.coyote=0;this.sound('jump');this.burst(this.x,this.y,6,'#fff0cd',120);}
 if(input.jumpReleased&&this.vy< -260)this.vy=-260;
 let target=axis*(this.crouch?95:300);
 this.vx+=clamp(target-this.vx,-2400*dt,2400*dt);const oldY=this.y;
 this.vy+=1650*dt;this.x+=this.vx*dt;this.y+=this.vy*dt;this.grounded=false;
 for(const p of this.platforms){if(p.type==='boat')p.x=p.base+Math.sin(this.time*1.3)*52;if(this.x>p.x-12&&this.x<p.x+p.w+12&&oldY<=p.y+3&&this.y>=p.y&&this.vy>=0){this.y=p.y;this.vy=0;this.grounded=true;if(p.type==='belt')this.x+=95*dt;if(p.type==='boat')this.x+=Math.cos(this.time*1.3)*67.6*dt;}}
 let water=false;for(const h of this.hazards)if(this.x>h.x&&this.x<h.x+h.w&&this.y>=564){if(h.kind==='water')water=true;else if(h.kind==='honey')this.vx*=.75;else if(this.time%3<1.2)this.hurt();}
 if(this.y>=576&&!water){this.y=576;this.vy=0;this.grounded=true;}if(this.y>800)this.hurt(true);
 this.x=clamp(this.x,this.boss?.active?this.zones.at(-1).end+25:30,STAGES[this.stage].length-70);
 if(input.fire&&this.fireTimer<=0)this.shoot();
 if(input.grenadePressed&&this.grenades>0&&this.grenadeTimer<=0){this.grenades--;this.grenadeTimer=.45;this.bullets.push({x:this.x+this.face*25,y:this.y-65,vx:this.face*430,vy:-580,friendly:true,damage:22,life:1.45,kind:'grenade',pierce:0,hit:[]});this.sound('rocket');}
 if(input.swapPressed){this.weapon=this.unlocked[(this.unlocked.indexOf(this.weapon)+1)%this.unlocked.length];this.weaponPop=1;this.sound('click');this.toast(WEAPONS[this.weapon].name);}
 this.updateEnemies(dt);this.updateBoss(dt);this.updateBullets(dt);this.collectCages();this.updateZones();
 for(const p of this.pickups){p.t+=dt;if(Math.hypot(this.x-p.x,this.y-p.y-35)<72){if(p.kind==='weapon'){this.giveWeapon(p.weapon);this.toast(WEAPONS[p.weapon].name+' 획득!');}else{if(this.ammo[this.weapon]>=0)this.ammo[this.weapon]=Math.min(WEAPONS[this.weapon].ammo,this.ammo[this.weapon]+50);this.score+=100;}p.t=-99;this.sound('pickup');}}
 this.pickups=this.pickups.filter(p=>p.t>=0);
 for(const p of this.particles){p.life-=dt;p.x+=p.vx*dt;p.y+=p.vy*dt;p.vy+=400*dt;}this.particles=this.particles.filter(p=>p.life>0).slice(-260);
 if(this.support>0){this.support-=dt;this.supportTimer-=dt;if(this.supportTimer<0){this.supportTimer=.32;const origin={x:this.x-this.face*55,y:this.y-95},target=this.enemies.find(e=>(e.x-this.x)*this.face>0&&Math.hypot(e.x-this.x,e.y-this.y)<600),angle=target?Math.atan2(target.y-30-origin.y,target.x-origin.x):Math.atan2(.15,this.face);this.addBullet(origin.x,origin.y,Math.cos(angle)*900,Math.sin(angle)*900,true,3,'support');}}
 if(!this.boss&&this.zones.every(z=>z.cleared)&&this.x>this.zones.at(-1).end+110)this.startBoss();
 const cam=this.boss?.active?STAGES[this.stage].length-1280:clamp(this.x-370,0,STAGES[this.stage].length-1280);this.camera+=(cam-this.camera)*(1-Math.exp(-dt*5.5));
 }
 aim(){const i=this.input;let x=this.face,y=0;if(i.up){x=(i.left||i.right)?this.face:0;y=-1;}else if(i.down&&!this.grounded){x=(i.left||i.right)?this.face:0;y=1;}const len=Math.hypot(x,y);return{x:x/len,y:y/len};}
 shoot(){if(this.ammo[this.weapon]===0){this.weapon=5;this.weaponPop=1;this.toast('탄약 소진 · Glock 19');}const w=WEAPONS[this.weapon],v=VISUALS[this.weapon];if(this.ammo[this.weapon]>0)this.ammo[this.weapon]--;const pose=weaponPose(this),a=pose.aim;this.addBullet(pose.mx,pose.my,a.x*w.speed,a.y*w.speed,true,w.damage,v.kind);const bullet=this.bullets.at(-1);bullet.weapon=this.weapon;bullet.color=w.color;this.fireTimer=w.rate;this.muzzle=.09;this.lastShotWeapon=this.weapon;this.sound(v.sound);this.burst(pose.mx,pose.my,this.weapon===3?12:3,w.color,this.weapon===3?180:100);
 if(this.weapon!==3)this.particles.push({x:pose.x,y:pose.y-9,vx:-this.face*100+rand(-30,30),vy:-rand(100,180),life:.6,max:.6,color:'#efc17c',size:3,kind:'casing'});
 for(const e of this.enemies)if(Math.hypot(e.x-this.x,e.y-this.y)<90){e.hp-=4;e.flash=.12;this.burst(e.x,e.y-30,5,'#fff4be',180);}}
 updateZones(){if(this.boss)return;for(let i=0;i<this.zones.length;i++){const z=this.zones[i];if(!z.entered&&this.x>=z.start+20){z.entered=true;this.zoneIndex=i;this.checkpoint=z.start+100;for(let j=0;j<2;j++){this.spawnEnemy(z.start+580+j*100,120-j*80,0);const e=this.enemies.at(-1);e.zone=i;e.launch=2;e.vx=-40;e.vy=50;}this.toast('AREA '+(i+1)+' / '+this.zones.length+' · '+z.name);}
 const guards=this.enemies.filter(e=>e.zone===i&&e.guard&&e.hp>0).length;
 if(!z.cleared&&guards===0&&this.x>=z.end-280){z.cleared=true;this.score+=300;this.sound('rescue');this.toast(i===this.zones.length-1?'전 구역 확보! · 보스 구역으로 진입':'구역 확보! · 다음 구역으로 이동');}
 if(!z.cleared&&this.x>z.end-70){this.x=z.end-70;this.vx=0;if(this.gateToast<=0){this.toast('통로 봉쇄 · 경비 '+guards+'마리 남음');this.gateToast=2.5;}break;}}}
 addBullet(x,y,vx,vy,friendly,damage,kind){this.bullets.push({x,y,vx,vy,friendly,damage,life:2.5,kind,pierce:kind==='sniper'?3:0,hit:[]});}
 updateEnemies(dt){for(const e of this.enemies){e.t+=dt;e.flash=Math.max(0,e.flash-dt);e.kick=Math.max(0,e.kick-dt);if(e.hp<=0||e.x>this.camera+1380||e.x<this.camera-250)continue;const dx=this.x-e.x,d=Math.sign(dx);e.facing=d||e.facing;e.walk=Math.abs(dx)>300?1:0;e.shot-=dt;if(e.launch>0){e.launch-=dt;e.vy+=1250*dt;e.x+=e.vx*dt;e.y+=e.vy*dt;if(e.y>=576){e.y=576;e.launch=0;e.kick=.25;}}else if(e.kind===1){e.y=426+Math.sin(e.t*2.5)*65;e.x+=d*45*dt;}else if(e.kind===3){e.x+=d*125*dt;e.y=576-Math.abs(Math.sin(e.t*3))*55;}else if(Math.abs(dx)>300)e.x+=d*(45+this.stage*9)*dt;e.warn=e.shot<.45;if(e.shot<=0){e.shot=rand(1.9,3)-this.stage*.16;e.warn=false;e.kick=.22;const x=e.x+d*24,y=e.y-30,a=Math.atan2(this.y-45-y,this.x-x);for(const off of e.kind===2?[-.18,0,.18]:[0])this.addBullet(x,y,Math.cos(a+off)*(250+this.stage*22),Math.sin(a+off)*(250+this.stage*22),false,1,'enemy');}if(Math.abs(dx)<35&&Math.abs(e.y-this.y)<65)this.hurt();}
 for(const e of this.enemies)if(e.hp<=0){this.combo++;this.comboTimer=2.8;this.score+=100*Math.min(this.combo,5);this.burst(e.x,e.y-30,16,'#ffc86a',230);this.sound('hit');if(Math.random()<.17)this.pickups.push({x:e.x,y:e.y-30,kind:'ammo',weapon:0,t:0});}this.enemies=this.enemies.filter(e=>e.hp>0);}
 updateBullets(dt){const explosions=[];for(const b of this.bullets){b.life-=dt;const old={x:b.x,y:b.y};if(['grenade','honey'].includes(b.kind))b.vy+=950*dt;b.x+=b.vx*dt;b.y+=b.vy*dt;if(b.kind==='rocket'&&Math.random()<.6)this.particles.push({x:b.x,y:b.y,vx:-b.vx*.08,vy:rand(-15,15),life:.35,max:.35,color:'#d8c5c0',size:rand(5,10),kind:'smoke'});
 if(b.kind==='grenade'&&b.y>=568){b.y=568;b.vy*=-.48;b.vx*=.75;}
 if(b.kind==='honey'&&b.y>=568){b.life=0;this.burst(b.x,b.y,14,'#ffbf49',220);if(Math.hypot(b.x-this.x,b.y-this.y)<95)this.hurt();}
 if(b.kind==='grenade'&&b.life<=0)explosions.push(b);
 if(b.friendly&&b.kind!=='grenade'){
 for(const e of this.enemies){if(e.hp<=0||b.hit.includes(e.id))continue;if(intersects(old,b,{x:e.x-38,y:e.y-68,w:76,h:68})){e.hp-=b.damage;e.flash=.12;b.hit.push(e.id);this.burst(b.x,b.y,5,'#fff1b7',140);if(b.kind==='rocket')explosions.push(b);if(b.pierce<=0){b.life=0;break;}b.pierce--;}}
 if(b.life>0)for(const c of this.cages)if(!c.open&&intersects(old,b,{x:c.x-43,y:c.y-95,w:86,h:95})){this.damageCage(c,b.damage);b.life=0;break;}
 if(b.life>0)for(const p of this.props)if(p.hp>0&&intersects(old,b,{x:p.x-26,y:p.y-54,w:52,h:54})){p.hp-=b.damage;b.life=0;if(p.hp<=0){explosions.push({x:p.x,y:p.y-20});this.score+=50;}break;}
 if(b.life>0&&this.boss&&!this.boss.dead){const w=this.stage===3?540:350,h=this.stage===3?440:300;if(intersects(old,b,{x:this.boss.x-w/2,y:this.boss.y-h,w,h})){this.damageBoss(b.damage);b.life=0;if(b.kind==='rocket')explosions.push(b);}}
 }else if(!b.friendly){const h=this.crouch?35:69;if(intersects(old,b,{x:this.x-14,y:this.y-h,w:28,h})){this.hurt();b.life=0;}}
 if(b.x<this.camera-300||b.x>this.camera+1780||b.y< -100)b.life=0;}
 this.bullets=this.bullets.filter(b=>b.life>0);for(const p of explosions)this.explode(p.x,p.y);}
 explode(x,y){this.burst(x,y,35,'#ffad51',340);this.shake=Math.max(this.shake,7);this.sound('explode');for(const e of this.enemies)if(Math.hypot(e.x-x,e.y-y)<165){e.hp-=22;e.flash=.2;}for(const c of this.cages)if(Math.hypot(c.x-x,c.y-y)<150)this.damageCage(c,9);if(this.boss&&!this.boss.dead&&Math.hypot(this.boss.x-x,this.boss.y-y)<330)this.damageBoss(25);}
 damageCage(c,n){if(c.open)return;c.hp-=n;if(c.hp<=0){c.open=true;this.burst(c.x,c.y-40,14,'#bee9d0',180);}}
 collectCages(){for(const c of this.cages)if(c.open&&!c.taken&&Math.hypot(this.x-c.x,this.y-c.y)<85){c.taken=true;this.rescued++;this.stageRescued++;this.score+=500;this.sound('rescue');if(c.special){this.support=22;this.toast('특수 허니비 구출! · 22초 지원 사격');}else{this.hp=Math.min(5,this.hp+1);this.grenades=Math.min(9,this.grenades+1);const w=(this.rescued+this.stage)%5;this.giveWeapon(w);this.toast('허니비 구출! +500 · '+WEAPONS[w].name);}}}
 giveWeapon(w){if(!this.unlocked.includes(w))this.unlocked.push(w);this.ammo[w]=WEAPONS[w].ammo;this.weapon=w;this.weaponPop=1.2;this.muzzle=0;}
 hurt(fall=false){if(this.invincible>0&&!fall)return;this.hp--;this.invincible=1.8;this.hurtTimer=.25;this.shake=7;this.combo=0;this.sound('hit');this.burst(this.x,this.y-40,12,'#ffafc3',200);if(fall){this.x=this.checkpoint;this.camera=clamp(this.x-370,0,STAGES[this.stage].length-1280);this.y=426;this.vx=this.vy=0;}if(this.hp<=0){this.lives--;if(this.lives<=0){this.mode='gameover';this.save();}else{this.hp=5;this.x=this.checkpoint;this.camera=clamp(this.x-370,0,STAGES[this.stage].length-1280);this.y=476;this.vx=this.vy=0;this.invincible=3;this.grenades=Math.max(this.grenades,3);this.toast(`다시 출동! · 남은 목숨 ${this.lives}`);}}}
 startBoss(){const hp=this.stage===3?620:150+this.stage*55,home=STAGES[this.stage].length-330;this.boss={x:STAGES[this.stage].length+300,home,y:576,hp,max:hp,active:true,dead:false,t:0,attack:2.5,phase:1,flash:0,warn:0,pattern:0,state:'enter',clock:2.2,recoil:0,track:0,burst:0};this.toast('WARNING · '+['방송 방해 장갑차','꿀 공장 파괴자','과메기 상륙정','오리고기 · 초거대 과메기 전차'][this.stage]);this.shake=5;}
 updateBoss(dt){const b=this.boss;if(!b||b.dead)return;b.t+=dt;b.clock-=dt;b.flash=Math.max(0,b.flash-dt);b.recoil=Math.max(0,b.recoil-dt*3);b.track+=dt*(b.state==='enter'?8:2);b.warn=b.state==='windup';
 if(b.state==='enter'){b.x+=(b.home-b.x)*(1-Math.exp(-dt*3));if(b.clock<=0){b.x=b.home;b.state='idle';b.clock=1.2;}return;}
 if(b.hp<b.max*.5&&b.phase===1){b.phase=2;b.state='break';b.clock=1.3;this.shake=12;for(let i=0;i<12;i++)this.particles.push({x:b.x+rand(-200,170),y:b.y-rand(60,210),vx:rand(-260,220),vy:rand(-400,-120),life:1.8,max:1.8,color:'#8c9b70',size:rand(14,26),kind:'armor'});this.toast('장갑 파괴! · 과메기 본체 노출');}
 if(b.state==='idle'){b.x=b.home+Math.sin(b.t*1.2)*12;if(b.clock<=0){b.state='windup';b.clock=b.phase===1?.9:.65;}}
 else if(b.state==='windup'&&b.clock<=0){b.state='attack';b.clock=.48;this.bossAttack();}
 else if(b.state==='attack'&&b.clock<=0){b.state='recover';b.clock=.7;}
 else if((b.state==='recover'||b.state==='break')&&b.clock<=0){b.pattern=(b.pattern+1)%3;b.state='idle';b.clock=b.phase===1?1.15:.55;}
 if(this.x>b.x-180&&this.y>416)this.hurt();}
 bossAttack(){const b=this.boss,scale=this.stage===3?1:.68,x=b.x-277*scale,y=b.y-212*scale;b.recoil=1;this.shake=4;if(b.pattern===0){for(let i=0;i<(b.phase===1?5:8);i++){const a=Math.PI-.46+i*.13;this.addBullet(x,y,Math.cos(a)*305,Math.sin(a)*305,false,1,'enemy');}}
 else if(b.pattern===1){for(let i=0;i<(b.phase===1?2:3);i++){this.spawnEnemy(x-i*40,y,3);const e=this.enemies.at(-1);e.launch=1.5;e.vx=-220-i*75;e.vy=-260-i*80;}this.burst(x,y,18,'#fff1aa',250);}
 else for(let i=0;i<3;i++)this.addBullet(x,y,-220-i*115,-550-i*45,false,1,'honey');this.sound('heavy');}
 damageBoss(n){const b=this.boss;if(!b||b.dead)return;b.hp-=n;b.flash=.08;this.score+=5;if(b.hp<=0){b.dead=true;b.active=false;this.score+=5000+this.stageRescued*500;this.bullets.forEach(x=>x.life=0);this.enemies=[];for(let i=0;i<55;i++)this.particles.push({x:b.x+rand(-180,120),y:b.y+rand(-200,-70),vx:rand(-400,300),vy:rand(-600,-150),life:4,max:4,color:'#fff',size:rand(20,38),kind:'fish'});this.shake=14;this.sound('rescue');this.mode='celebrate';this.celebrate=3;this.save();}}
 burst(x,y,count,color,speed){for(let i=0;i<count;i++){const a=rand(0,Math.PI*2),s=rand(speed*.3,speed),life=rand(.2,.65);this.particles.push({x,y,vx:Math.cos(a)*s,vy:Math.sin(a)*s,life,max:life,color,size:rand(2,7),kind:'spark'});}}
}
root.HoneyGame={Game,STAGES,WEAPONS,VISUALS,playerFrame,weaponPose,intersects,clamp};if(typeof module!=='undefined')module.exports=root.HoneyGame;
})(typeof window!=='undefined'?window:globalThis);
