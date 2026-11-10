const assert=require('node:assert/strict'),fs=require('node:fs');
const {Game}=require('../web/game.js'),V=require('../web/visuals.js');
for(const stage of [1,3]){
 const g=new Game();g.start(stage);g.begin();g.invincible=1e9;g.startBoss();const b=g.boss;
 let x=b.x,track=b.track;g.updateBoss(1/60);
 assert(b.track<track,'entrance rolls forward');assert(Math.abs(b.track-track-(b.x-x))<1e-8);
 b.state='attack';b.clock=10;b.pattern=2;b.charge=1;b.chargeDir=-1;b.x=b.home;
 x=b.x;track=b.track;g.updateBoss(1/60);assert(b.track<track);assert(Math.abs(b.track-track-(b.x-x))<1e-8);
 b.chargeDir=1;x=b.x;track=b.track;g.updateBoss(1/60);assert(b.track>track,'reverse rolls the opposite way');assert(Math.abs(b.track-track-(b.x-x))<1e-8);
 b.charge=0;b.state='windup';b.clock=10;track=b.track;g.updateBoss(.1);assert.equal(b.track,track,'parked belt stops');
 b.phase=2;b.state='attack';b.charge=1;b.chargeDir=-1;track=b.track;g.updateBoss(1/60);assert(b.track<track,'damaged vehicle still rolls');
 b.charge=0;b.air=true;b.y=200;b.vx=100;track=b.track;g.updateBoss(1/60);assert.equal(b.track,track,'airborne vehicle does not ground-drive');
 b.dead=true;g.updateBoss(.1);assert.equal(b.track,track,'wreck stops');
}
const length=180,radius=27,total=2*length+2*Math.PI*radius;
for(let d=-2000;d<2000;d+=7){
 const p=V.treadPoint(d,length,radius),q=V.treadPoint(d+total,length,radius);
 assert(Math.abs(p.x-q.x)<1e-8&&Math.abs(p.y-q.y)<1e-8,'belt wraps continuously in both directions');
 assert(p.x>=-radius&&p.x<=length+radius&&Math.abs(p.y)<=radius+1e-8);
}
for(const [name,atlas] of Object.entries(V.softBosses)){
 const png=fs.readFileSync('assets/generated/bosses/'+name+'_ink.png'),w=png.readUInt32BE(16),h=png.readUInt32BE(20);
 assert.equal(atlas.source.length,8);
 for(let i=0;i<8;i++){const {source:a,dest:d}=V.bossArt(name,i);assert(a[0]>=0&&a[1]>=0&&a[2]<=w&&a[3]<=h);assert(a[2]>a[0]&&a[3]>a[1]);assert(d.every(Number.isFinite));}
}
const native=fs.readFileSync('scripts/visual_motion.gd','utf8').match(/const SOFT_BOSSES := (\{.*\})/)[1];
assert.deepEqual(JSON.parse(native),V.softBosses,'both runtimes use identical art registration');
for(const [key,file,constant] of [['driveArt','bosses/drive_parts.png','DRIVE_ART'],['groundArt','ground_ink.png','GROUND_ART']]){
 const png=fs.readFileSync('assets/generated/'+file),w=png.readUInt32BE(16),h=png.readUInt32BE(20);
 for(const a of V[key])assert(a.length===4&&a.every(Number.isFinite)&&a[0]>=0&&a[1]>=0&&a[2]<=w&&a[3]<=h&&a[2]>a[0]&&a[3]>a[1]);
 const data=fs.readFileSync('scripts/visual_motion.gd','utf8').match(new RegExp('const '+constant+' := (\\[.*\\])'))[1];
 assert.deepEqual(JSON.parse(data),V[key],'painted drive/ground registration matches native');
}
// Observe the real draw helper: motion must reach the painted track parts.
const vm=require('node:vm'),source=fs.readFileSync('web/render.js','utf8');let commands=[];
const sandbox={HoneyVisuals:V,Math,clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),tex:{driveParts:'painted-drive'},c:new Proxy({}, {get:(_,k)=>(...a)=>commands.push([k,...a])})};
vm.createContext(sandbox);
for(const name of ['driveSprite','trackFace','trackSidePoint','drawBossTracks']){
 const start=source.indexOf('function '+name+'('),end=source.indexOf('\nfunction ',start+1);vm.runInContext(source.slice(start,end),sandbox);
}
for(const type of ['tank','cannon']){
 const r=require('../web/game.js').BOSS_RIG[type],b={type,x:900,y:576,flip:false,track:0};
 const draw=()=>{commands=[];sandbox.drawBossTracks(b,r);return JSON.stringify(commands);};
 const parked=draw();assert.equal(draw(),parked);b.track=21;assert.notEqual(draw(),parked,'travel visibly changes the painted wheels and shoes');
 const forward=draw();b.track=-21;assert.notEqual(draw(),forward,'reverse changes the painted track phase');
 assert(commands.some(c=>c[0]==='drawImage'&&c[1]==='painted-drive'));
}
console.log('PASS boss tracks: entrance, charge, reverse, stop, phase 2, air, wreck, continuous belt and 32 registered sprites.');
