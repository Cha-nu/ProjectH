const assert=require('node:assert/strict'),fs=require('node:fs');
const {Game,BOSS_RIG}=require('../web/game.js'),V=require('../web/visuals.js');
let boundaries=0;
for(let stage=0;stage<4;stage++){
 const g=new Game();g.start(stage);
 for(let i=0;i<g.zones.length;i++){
  const z=g.zones[i],v=V.scenery(g.zones,g.bossStart,(z.start+z.end)/2);
  assert.equal(v.mix===1?v.to:v.from,i,'each zone gets its own scenery');}
 const starts=g.zones.slice(1).map(z=>z.start);if(g.zones.length<6)starts.push(g.bossStart);
 for(const x of starts){
  const a=V.scenery(g.zones,g.bossStart,x-400),m=V.scenery(g.zones,g.bossStart,x),b=V.scenery(g.zones,g.bossStart,x+400);
  assert.equal(a.mix,0);assert.equal(m.mix,.5);assert.equal(m.to,m.from+1);
  assert.equal(b.mix===1?b.to:b.from,m.to);
  let previous=0;
  for(let p=x-400;p<x+400;p+=.5){const blend=V.scenery(g.zones,g.bossStart,p);assert(blend.mix>=previous&&blend.mix-previous<.002);previous=blend.mix;}
  boundaries++;}
 // All finite positions, including backwards travel, spawn, and sailing beyond the level.
 for(const focus of [-100,0,640,4000,100000]){const v=V.scenery(g.zones,g.bossStart,focus);assert(v.from>=0&&v.to<6&&v.mix>=0&&v.mix<=1);}
}
const boss={dead:false,state:'idle',t:0,clock:1,phase:1,pattern:0,air:false,vy:0,charge:0,recoil:0,sink:0};
for(let t=0;t<30;t+=1/60){
 assert.equal(V.bossFrame({...boss,t}),0,'idle surface must not flicker between paintings');
 assert.equal(V.bossFrame({...boss,t,phase:2}),6,'exposed armor stays damaged during attacks');
 for(const type of ['king','cannon','boat','tank']){
  const p=V.bossPose({...boss,type,t}),next=V.bossPose({...boss,type,t:t+1/60});
  assert(Math.abs(p.y-next.y)<.1&&Math.abs(p.rot-next.rot)<.001,'no high frequency chassis jitter');}}
for(const [state,f] of [['idle',0],['enter',1],['windup',2],['attack',3],['recover',3],['break',6]])assert.equal(V.bossFrame({...boss,state}),f);
assert.equal(V.bossFrame({...boss,air:true,vy:-100}),4);assert.equal(V.bossFrame({...boss,air:true,vy:100}),5);assert.equal(V.bossFrame({...boss,dead:true}),7);
let entryCount=0;
for(let stage=0;stage<4;stage++){
 const g=new Game();g.start(stage);
 for(const z of g.zones){z.cleared=true;const entries=V.portals(g.zones,g.bossStart,z.end-640),entry=entries.find(p=>p.x===z.end);assert(entry&&entry.open);entryCount++;
  assert.equal(V.entranceShade([entry],entry.x-181),0);assert.equal(V.entranceShade([entry],entry.x),.3);assert.equal(V.entranceShade([{...entry,open:false}],entry.x),0);}}
assert.equal(entryCount,22);
{const zones=[{start:0,end:1400,cleared:true,clearedAt:10}];assert.equal(V.portals(zones,1400,1000,10)[0].reveal,0);assert(Math.abs(V.portals(zones,1400,1000,10.35)[0].reveal-.5)<1e-9);assert.equal(V.portals(zones,1400,1000,11)[0].reveal,1);}
for(const rig of Object.values(BOSS_RIG)){
 const png=fs.readFileSync('assets/generated/bosses/'+rig.sheet+'_stable.png'),width=png.readUInt32BE(16),height=png.readUInt32BE(20);
 let bottom=null;
 for(let f=0;f<8;f++){
  const q=V.bossRect(rig.sheet,f,rig),a=q.source;
  assert(a[0]>=0&&a[1]>=0&&a[2]<=width&&a[3]<=height&&a[2]>a[0]&&a[3]>a[1]);
  assert([q.x,q.y,q.w,q.h].every(Number.isFinite)&&q.w>0&&q.h>0);
  if(bottom!==null)assert(Math.abs(q.y+q.h-bottom)<1e-8,'feet/hull stay anchored across frames');bottom=q.y+q.h;
 }
}
// The shared port must use exactly the same measured source rectangles.
const native=fs.readFileSync('scripts/visual_motion.gd','utf8').match(/const BOUNDS := (\{.*\})/)[1];
assert.deepEqual(JSON.parse(native),V.bounds);
assert(fs.readFileSync('project.godot','utf8').includes('default_texture_filter=2'),'use linear mipmap filtering');
console.log(`PASS visuals: stable idle/damaged textures, smooth rigs, 32 source crops, 22 entrances, ${boundaries} background boundaries and matching native metadata.`);
