const assert=require('node:assert/strict');
const {Game,WEAPONS,STAGES,LEVELS,VISUALS,ENEMIES,PISTOL,FLOOR,W,SHIP_SEA,weaponPose,intersects}=require('../web/game.js');
let count=0;
function test(name,run){run();count++;console.log('PASS',name);}
function game(stage=0){const g=new Game();g.start(stage);g.begin();g.entering=false;g.x=180;g.enemies=[];for(const z of g.zones)z.waves.forEach(w=>w.done=true);return g;}
function steps(g,n,input={}){for(let i=0;i<n;i++)g.update(1/60,input);}

test('stage opens with the hero running in from the left, no blink, controls locked until the mark',()=>{const g=new Game();g.start(0);g.begin();assert(g.entering);assert(g.x<g.camera);assert.equal(g.invincible,0);steps(g,10,{left:true,fire:true});assert(g.x>g.camera-70);assert.equal(g.bullets.length,0);steps(g,90);assert(!g.entering);assert(g.x>=170&&g.x<230);const x=g.x;steps(g,30,{right:true});assert(g.x>x);});
test('winning in mid-air lands before the victory dance',()=>{const g=game(0);g.invincible=1e9;g.startBoss();for(let i=0;i<900&&g.boss.state==='enter';i++)g.update(1/60,{});g.y=300;g.vy=-200;g.grounded=false;g.damageBoss(1e9);assert.equal(g.mode,'celebrate');assert(!g.grounded);steps(g,60);assert(g.grounded);assert.equal(g.y,FLOOR);});
test('squads arrive staggered and spread out instead of piling up',()=>{const g=game(0);g.invincible=1e9;g.spawnWave('grunt',3,'R',0);assert.equal(g.enemies.length,1);g.spawnWave('shield',1,'R',0,false,.3);g.spawnWave('heavy',1,'R',0,false,.6);g.spawnWave('bomber',1,'R',0,false,.9);g.spawnWave('grunt',2,'P',0);steps(g,900);const live=g.enemies.filter(e=>e.hp>0&&e.kind!=='flyer'&&!e.air&&e.state!=='para'&&e.state!=='enter');assert(live.length>=6);for(const a of live)for(const b of live)if(a!==b&&Math.abs(a.y-b.y)<30)assert(Math.abs(a.x-b.x)>=40,a.kind+' '+b.kind+' '+Math.abs(a.x-b.x));});
test('T-entry snipers drop onto a platform and stay on it',()=>{const g=game(0);g.invincible=1e9;g.spawnWave('grunt',2,'T',0);steps(g,300);const up=g.enemies.filter(e=>e.hp>0&&e.y<FLOOR-50);assert(up.length>=1);for(const e of up){assert.equal(e.y,e.floor);assert(e.x>=e.perchL&&e.x<=e.perchR);}});
test('every platform can be reached by jumping (from the floor or another platform)',()=>{
 const g=game(0);g.platforms=[];let apex=FLOOR,y0=FLOOR;g.update(1/60,{jumpPressed:true,jump:true});for(let i=0;i<90;i++){g.update(1/60,{jump:true});apex=Math.min(apex,g.y);}const reach=y0-apex-8;
 for(const [si,L] of LEVELS.entries())for(const z of L.zones){const ps=z.plat.filter(p=>!p[3]||p[3]==='normal').map(([x,y,w])=>({x,y,w,ok:FLOOR-y<=reach}));
  for(let k=0;k<4;k++)for(const p of ps)if(!p.ok)p.ok=ps.some(q=>q.ok&&q.y-p.y<=reach&&Math.max(q.x,p.x)-Math.min(q.x+q.w,p.x+p.w)<=220);
  for(const p of ps)assert(p.ok,'stage '+si+' '+z.name+' platform y='+p.y+' unreachable (jump '+reach.toFixed(0)+'px)');}});
test('jumping straight up under a high platform lands on it',()=>{const g=game(0);g.platforms=[{x:g.x-60,base:g.x-60,y:396,w:120,h:20,type:'normal'}];g.update(1/60,{jumpPressed:true,jump:true});steps(g,90,{jump:true});assert(g.grounded);assert.equal(g.y,396);});
test('down + jump drops through a platform; coyote jump works just after walking off',()=>{const plat=g=>[{x:g.x-60,base:g.x-60,y:396,w:120,h:20,type:'normal'}];
 const g=game(0);g.platforms=plat(g);g.y=396;g.grounded=true;steps(g,5);assert.equal(g.y,396);
 g.update(1/60,{down:true,jumpPressed:true,jump:true});steps(g,60);assert.equal(g.y,FLOOR);assert(g.grounded);
 const c=game(0);c.platforms=plat(c);c.y=396;c.grounded=true;steps(c,2);c.x=c.platforms[0].x+150;steps(c,7);assert(!c.grounded);
 c.update(1/60,{jumpPressed:true,jump:true});assert(c.vy<0);});
test('harbor water is too wide to jump; the boat ferries close to both banks',()=>{const g=game(2);
 const boats=g.platforms.filter(p=>p.type==='boat'&&p.amp>52);assert.equal(boats.length,4);
 for(const b of boats){const w=g.hazards.find(h=>h.kind==='water'&&b.base>=h.x&&b.base<=h.x+h.w);assert(w&&w.w>=500,'wide water');
  const minL=b.base-b.amp,maxR=b.base+b.amp+b.w;assert(minL-w.x<=60&&w.x+w.w-maxR<=60,'boat reaches both banks');
  assert(w.w-b.w>300,'cannot clear the water in one jump');}
 for(const p of g.props)assert(!g.hazards.some(h=>h.kind==='water'&&p.x>h.x&&p.x<h.x+h.w),'no props in the water');
 for(const p of g.pows)assert(!g.hazards.some(h=>h.kind==='water'&&p.x>h.x&&p.x<h.x+h.w),'no cages in the water');});
test('continuous bullet collision cannot tunnel through thin targets',()=>{assert(intersects({x:0,y:10},{x:200,y:10},{x:100,y:0,w:3,h:20}));assert(!intersects({x:0,y:30},{x:200,y:30},{x:100,y:0,w:3,h:20}));});
test('flow: title → briefing → play → pause → play',()=>{const g=new Game();assert.equal(g.mode,'title');g.confirm();assert.equal(g.mode,'briefing');g.confirm();assert.equal(g.mode,'play');g.pause();const x=g.x;steps(g,30,{right:true});assert.equal(g.x,x);g.pause();assert.equal(g.mode,'play');});
test('movement, variable jump and landing',()=>{const a=game(),b=game();a.platforms=[];b.platforms=[];steps(a,40,{right:true});assert(a.x>300);a.update(1/60,{jumpPressed:true});b.update(1/60,{jumpPressed:true});b.update(1/60,{jumpReleased:true});steps(a,12);steps(b,11);assert(a.y<b.y);steps(a,100);assert.equal(a.y,FLOOR);assert(a.grounded);});
test('camera only scrolls forward outside scroll locks',()=>{const g=game();steps(g,70,{right:true});assert(!g.lock);const cam=g.camera;assert(cam>0);steps(g,120,{left:true});assert(g.camera>=cam-1e-6);assert(g.x>=g.camera+29);});
test('aim sweeps toward up and diagonal-down instead of snapping',()=>{const g=game();g.update(1/60,{up:true});const mid=g.aim();assert(mid.y<0&&mid.y>-1);steps(g,20,{up:true});assert(g.aim().y<-.99);g.grounded=false;g.y=300;steps(g,30,{down:true,right:true});const a=g.aim();assert(a.x>0&&a.y>0);});
test('pistol is infinite; heavy weapons run dry and fall back to pistol',()=>{const g=game();assert.equal(g.weapon,PISTOL);g.shoot();assert.equal(g.ammo[PISTOL],-1);g.giveWeapon(2);assert.equal(g.weapon,2);g.ammo[2]=1;g.shoot();assert.equal(g.weapon,PISTOL);assert(!g.unlocked.includes(2));});
test('picking the same weapon stacks ammo',()=>{const g=game();g.giveWeapon(3);g.ammo[3]=5;g.giveWeapon(3);assert.equal(g.ammo[3],5+WEAPONS[3].ammo);});
test('each weapon fires its own projectile, sound and muzzle position',()=>{const g=game(),heard=[];g.sound=k=>heard.push(k);for(let w=0;w<5;w++){g.giveWeapon(w);g.fireTimer=0;g.muzzle=0;const pose=weaponPose(g);g.shoot();const b=g.bullets.at(-1);assert.equal(b.weapon,w);assert.equal(b.kind,VISUALS[w].kind);assert(heard.includes(VISUALS[w].sound));assert.equal(b.x,pose.mx);assert.equal(b.y,pose.my);}});
test('weapon grip and muzzle mirror for every weapon and pose',()=>{const g=game();g.x=700;g.y=FLOOR;for(let w=0;w<6;w++)for(const pose of ['idle','walk','crouch','jump','hurt']){g.weapon=w;g.crouch=pose==='crouch';g.grounded=pose!=='jump';g.vx=pose==='walk'?300:0;g.hurtTimer=pose==='hurt'?.2:0;g.muzzle=.06;g.aimLocal=0;g.face=1;const r=weaponPose(g);g.face=-1;const l=weaponPose(g);assert(Math.abs(r.x+l.x-1400)<1e-8);assert(Math.abs(r.mx+l.mx-1400)<1e-8);assert.equal(r.y,l.y);}});
test('knife replaces shooting at point blank',()=>{const g=game();const e=g.spawnEnemy(g.x+40,FLOOR,'grunt');e.alert=1;const hp=e.hp;g.shoot();assert(e.hp<hp);assert(g.knife>0);assert.equal(g.bullets.length,0);});
test('shield blocks frontal shots but not explosions',()=>{const g=game();const e=g.spawnEnemy(g.x+400,FLOOR,'shield');e.facing=-1;e.peek=0;const hp=e.hp;assert.equal(g.damageEnemy(e,5,'shot',{vx:1000,vy:0}),'block');assert.equal(e.hp,hp);g.damageEnemy(e,5,'explosion');assert(e.hp<hp);});
test('kills create corpses, combo score and popups',()=>{const g=game();for(let i=0;i<3;i++){const e=g.spawnEnemy(g.x+300+i*30,FLOOR,'grunt');g.damageEnemy(e,99,'shot',{vx:1,vy:0});}assert.equal(g.corpses.length,3);assert.equal(g.combo,3);assert(g.score>=600);assert(g.popups.length>=3);});
test('every enemy archetype acts without errors and stays finite',()=>{for(const kind of Object.keys(ENEMIES)){const g=game(1);g.invincible=999;const e=g.spawnEnemy(g.x+380,FLOOR,kind);e.alert=1;steps(g,400);assert(Number.isFinite(e.x)&&Number.isFinite(e.y),kind);}});
test('caged POW needs breaking, then touch rescues and drops a reward once',()=>{const g=game(0);const p=g.pows.find(q=>q.kind==='cage')||g.pows[0];p.kind='cage';p.state='caged';p.reward='bomb';g.x=p.x;g.collectPows();assert.equal(g.rescued,0);g.damageCage(p,99);assert.equal(p.state,'tied');g.x=p.x;g.collectPows();assert.equal(g.rescued,1);g.collectPows();assert.equal(g.rescued,1);steps(g,60);assert(g.items.some(i=>i.kind==='bomb')||g.grenades>10);});
test('items apply their effects',()=>{const g=game();g.hp=1;g.takeItem({kind:'food'});assert.equal(g.hp,3);const b=g.grenades;g.takeItem({kind:'bomb'});assert.equal(g.grenades,b+10);g.takeItem({kind:'support'});assert.equal(g.support,22);g.takeItem({kind:'weapon',weapon:1});assert.equal(g.weapon,1);});
test('special support bee fires at enemies ahead',()=>{const g=game();g.support=22;const e=g.spawnEnemy(g.x+300,FLOOR,'grunt');e.alert=1;g.update(1/60,{});const b=g.bullets.find(b=>b.kind==='support');assert(b&&b.vx>0);});
test('grenades bounce then explode with area damage',()=>{const g=game();g.update(1/60,{grenadePressed:true});assert.equal(g.grenades,9);assert(g.throwT>0&&!g.bullets.some(b=>b.kind==='grenade'),'wind-up first');steps(g,8);assert(g.bullets.some(b=>b.kind==='grenade'));steps(g,150);assert(!g.bullets.some(b=>b.kind==='grenade'));assert(g.blasts.length>=0);const e=g.spawnEnemy(g.x+200,FLOOR,'heavy');g.explode(e.x,e.y-40,150,99);assert.equal(g.enemies.filter(x=>x.hp>0).length,0);});
test('explosive barrels detonate',()=>{const g=game();const p=g.props.find(q=>q.kind==='barrel');const e=g.spawnEnemy(p.x+40,FLOOR,'grunt');g.damageProp(p,99);assert(p.hp<=0);assert(e.hp<=0);});
test('arena stragglers left off-screen walk back in instead of stalling the lock',()=>{const g=game();const z=g.zones[0];g.x=z.end-700;g.updateZones(0);assert(g.lock);g.camera=g.lock.cam;g.enemies=[];
 const e=g.spawnEnemy(g.camera+1280+400,FLOOR-120,'grunt');e.arena=true;e.zone=g.lock.zone;e.air=true;for(let i=0;i<400;i++)g.updateEnemies(1/60);assert(e.x<g.camera+1280-40);assert.equal(e.y,e.floor);});
test('scroll-lock arena spawns waves and releases when cleared',()=>{const g=game();const z=g.zones[0];g.x=z.end-700;g.camera=g.x-470;g.updateZones(0);assert(g.lock);let guard=0;while(!z.cleared&&guard++<600){g.updateZones(.5);for(const e of g.enemies)e.hp=0;g.enemies=[];}assert(z.cleared);assert(!g.lock);assert(z.arenaWave===z.arena.length-1);});
test('damage, death animation, respawn and continue',()=>{const g=game();g.invincible=0;g.hurt();assert.equal(g.hp,g.dif.hp-1);g.hurt();assert.equal(g.hp,g.dif.hp-1);g.hp=1;g.invincible=0;g.giveWeapon(3);g.hurt();assert(g.dying>0);assert.equal(g.weapon,PISTOL);steps(g,100);assert(g.dying<=0&&g.hp===g.dif.hp);g.lives=1;g.hp=1;g.invincible=0;g.hurt();steps(g,100);assert.equal(g.mode,'continue');const score=g.score;g.confirm();assert.equal(g.mode,'play');assert.equal(g.credits,1);assert.equal(g.score,score);g.lives=1;g.hp=1;g.invincible=0;g.hurt();steps(g,100);steps(g,700);assert.equal(g.mode,'gameover');g.confirm();assert.equal(g.mode,'title');});
test('difficulty changes health and lives',()=>{const g=new Game();g.difficulty='easy';g.start();assert.equal(g.hp,7);assert.equal(g.lives,5);g.difficulty='hard';g.start();assert.equal(g.hp,3);});
test('four stages with hazards: conveyors, honey, water, boats and steam',()=>{assert.equal(STAGES.length,4);const f=game(1),s=game(2),k=game(3);assert(f.platforms.some(p=>p.type==='belt'));assert(f.hazards.some(h=>h.kind==='honey'));assert(s.hazards.some(h=>h.kind==='water'));const boat=s.platforms.find(p=>p.type==='boat'),x=boat.x;steps(s,30);assert.notEqual(boat.x,x);assert(k.hazards.some(h=>h.kind==='steam'));for(let i=0;i<4;i++)assert([5,6].includes(LEVELS[i].zones.length));});
test('every boss enters, cycles all attacks, breaks armor and ends in a tally',()=>{for(let stage=0;stage<4;stage++){const g=game(stage);g.invincible=1e9;g.startBoss();const b=g.boss,states=new Set(),patterns=new Set();for(let i=0;i<1500;i++){g.invincible=1e9;g.update(1/60,{});states.add(b.state);patterns.add(b.pattern);}for(const s of ['enter','idle','windup','attack','recover'])assert(states.has(s),stage+' '+s);assert.equal(patterns.size,3);g.damageBoss(b.max*.6);steps(g,2);assert.equal(b.phase,2);g.damageBoss(9999);assert(b.dead);assert.equal(g.mode,'celebrate');steps(g,420);assert.equal(g.mode,'result');assert(g.result.rows.length===4&&'SABC'.includes(g.result.rank));}});
const bossReady=stage=>{const g=game(stage);g.invincible=1e9;g.startBoss();for(let i=0;i<600&&g.boss.state==='enter';i++)g.update(1/60,{});assert.equal(g.boss.state,'idle');return g;};
test('boss weapons are destructible parts; a destroyed weapon stops its attack',()=>{for(let stage=0;stage<4;stage++){const g=bossReady(stage),b=g.boss,hp=b.hp;
 const pb=g.bossPartBox('A');g.addBullet(pb.x+pb.w-4,pb.y+pb.h/2,-900,0,true,1e4,'pistol');steps(g,10);assert(b.parts.A.dead,'stage '+stage+' part A shot off');assert(b.hp<hp,'core chipped');
 const seen=new Set();for(let i=0;i<1400;i++){g.invincible=1e9;g.update(1/60,{});if(b.state==='attack')seen.add(b.pattern);}assert(!seen.has(0),'stage '+stage+' weapon A no longer attacks');assert(seen.size>=1);}});
test('boss phase 2: destroying both weapons exposes the core and armor no longer reduces damage',()=>{for(let stage=0;stage<4;stage++){const g=bossReady(stage),b=g.boss;
 const before=b.hp;g.hitBossBody(10);assert(Math.abs(before-b.hp-3)<1e-6,'armored body takes 30%');g.damageBossPart('A',1e6);g.damageBossPart('B',1e6);steps(g,12);assert.equal(b.phase,2);
 const h=b.hp;g.hitBossBody(10);assert(Math.abs(h-b.hp-10)<1e-6,'exposed core takes full damage');}});
test('MISSION COMPLETE only shows after the wreck finishes exploding',()=>{const g=bossReady(0);g.damageBoss(1e9);assert.equal(g.mode,'celebrate');assert.equal(g.callout,null);
 let burstAt=-1,callAt=-1;for(let i=0;i<400;i++){g.update(1/60,{});if(burstAt<0&&g.boss.burst)burstAt=i;if(callAt<0&&g.callout?.text==='MISSION COMPLETE!')callAt=i;}
 assert(burstAt>=0&&callAt>burstAt+60,`callout ${callAt} after burst ${burstAt}`);});
test('the melee swing grants brief invincibility',()=>{const g=game();g.invincible=0;g.knife=.2;const hp=g.hp;g.hurt();assert.equal(g.hp,hp);g.knife=0;g.hurt();assert.equal(g.hp,hp-1);});
test('a grenade explodes on contact with an enemy',()=>{const g=game();const e=g.spawnEnemy(g.x+60,FLOOR,'heavy');e.state='idle';const hp=e.hp;
 g.bullets.push({x:e.x-30,y:e.y-40,vx:400,vy:0,friendly:true,damage:22,life:1.6,kind:'grenade',pierce:0,hit:[],bounces:0,spin:0});steps(g,6);
 assert(!g.bullets.some(b=>b.kind==='grenade'),'detonated before bouncing');assert(e.hp<hp);});
test('harbor boss surfaces on the left behind the sailing ship and attacks toward the deck',()=>{const g=game(2),len=STAGES[2].length;assert(g.ship);
 g.zones.forEach(z=>z.cleared=true);g.boss={started:false};g.x=g.ship.x-200;steps(g,2);assert(!g.boss.started,'still on the dock');
 g.x=g.ship.x+100;steps(g,2);assert(g.boss.started,'boarding the ship starts the fight');
 for(let i=0;i<600&&g.boss.state==='enter';i++){g.invincible=1e9;g.update(1/60,{});}
 const b=g.boss;assert(b.flip);assert(b.x<g.ship.x&&b.x>len-W);assert.equal(g.ship.sea.w,SHIP_SEA,'sea opened behind the ship');
 const h=g.bossBox();assert(h.x+h.w<g.ship.x+40,'boss stays off the deck');
 steps(g,30,{left:true});assert(g.x>=g.ship.x+19,'player cannot walk off the stern');
 assert(g.bossMuzzle('A').x>b.x,'deck gun faces right');
 b.pattern=2;b.state='windup';b.clock=0;g.planBoss();steps(g,1);for(const z of b.zones)assert(z.x>b.x,'landing party drops in front of the boss');
 steps(g,120);for(const e of g.enemies)assert(e.x>g.ship.x-30,'troops end up on the deck');});
test('harbor troops ride the ferry across a wide channel to reach the player',()=>{const g=game(2),hz=g.hazards.find(h=>h.kind==='water'&&h.w>240);
 g.camera=hz.x-400;g.x=hz.x-100;g.invincible=1e9;const e=g.spawnEnemy(hz.x+hz.w+60,FLOOR,'grunt');e.alert=1;let rode=false;
 for(let i=0;i<1500&&!(e.x<hz.x&&!e.air);i++){g.invincible=1e9;g.x=hz.x-100;g.update(1/60,{});if(e.boat&&!e.air)rode=true;}
 assert(rode,'boarded the boat');assert(e.x<hz.x&&e.hp>0,'crossed to the player bank (x='+e.x+')');});
test('boss hatch releases soldiers and a supply bee whose item drops',()=>{for(let stage=0;stage<4;stage++){const g=bossReady(stage),b=g.boss;g.enemies=[];g.grenades=0;b.hatch.clock=0;
 let released=0,drops=false;for(let i=0;i<400;i++){g.invincible=1e9;const n=g.items.length;g.update(1/60,{});released=Math.max(released,g.enemies.length);if(g.supplies.some(s=>s.dropped))drops=true;}
 assert(b.hatch.count>=1);assert(released>=1,'soldiers released');assert(drops,'supply bee dropped its item');}});
test('every boss can be shot down to the tally',()=>{for(let stage=0;stage<4;stage++){const g=bossReady(stage),b=g.boss;
 for(let i=0;i<4000&&!b.dead;i++){g.invincible=1e9;g.giveWeapon(3);g.ammo[3]=99;const h=g.bossBox();g.addBullet(h.x-20,h.y+h.h*.5,900,0,true,25,'rocket');g.update(1/60,{});}
 assert(b.dead,'stage '+stage+' boss defeated');assert.equal(g.mode,'celebrate');steps(g,420);assert.equal(g.mode,'result');}});
test('full campaign reaches the ending',()=>{const g=new Game();g.start();for(let i=0;i<4;i++){assert.equal(g.stage,i);g.begin();g.startBoss();g.boss.state='idle';g.damageBoss(9999);steps(g,420);assert.equal(g.mode,'result');g.confirm();if(i<3)assert.equal(g.mode,'briefing');}assert.equal(g.mode,'victory');assert(g.best>=g.score&&g.score>0);g.confirm();assert.equal(g.mode,'title');});
test('long simulation stays finite and bounds transient objects',()=>{const g=game(2);g.zones.forEach(z=>z.waves.forEach(w=>w.done=false));for(let i=0;i<3600;i++){if(g.mode==='continue')g.confirm();g.update(1/60,{right:i%300<240,left:i%300>=240,fire:true,jumpPressed:i%55===0,grenadePressed:i%200===0,up:i%120<20});assert(Number.isFinite(g.x)&&Number.isFinite(g.y)&&Number.isFinite(g.camera));assert(g.particles.length<=320);}});
console.log(`\n${count} gameplay tests passed.`);
