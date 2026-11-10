// Exercise the browser renderer with a minimal Canvas API contract.
// This checks every screen for exceptions/invalid coordinates, not browser raster output.
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path'),assert=require('node:assert/strict');
let frameCallback,draws=0;const seenScenery=new Set();
const gradient={addColorStop(){}};
const context=new Proxy({measureText:s=>({width:s.length*12}),createLinearGradient:()=>gradient,createRadialGradient:()=>gradient,
 drawImage:(...a)=>{assert(a[0]?.width>0);for(const n of a.slice(1))assert(Number.isFinite(n),'Non-finite drawImage coordinate');draws++;
  if(a[0].asset?.includes('scene_')){const [im,sx,sy,sw,sh,x,y,w,h]=a;
   assert(sx===0&&sy===0&&sw===im.width&&sh===im.height,'use the whole standalone background');
   assert(sw>=w&&sh>=h,'background must not enlarge a low-resolution source');
   assert(x<=-24&&x+w>=1304&&y<=-24&&y+h>=600,'opaque scene overscans viewport and shake');
   seenScenery.add(im.asset);}
  if(a[0].asset?.includes('_stable.png')||a[0].asset?.includes('_ink.png')||a[0].asset?.includes('drive_parts.png')||a[0].asset?.includes('zone_portals.png')){const [im,sx,sy,sw,sh]=a;assert(sx>=0&&sy>=0&&sx+sw<=im.width&&sy+sh<=im.height,'sprite does not read outside atlas');}},
 fillRect:(...a)=>{a.forEach(n=>assert(Number.isFinite(n)));draws++;},roundRect:(...a)=>a.flat().forEach(n=>assert(Number.isFinite(n),'Non-finite roundRect')),
 arc:(...a)=>a.slice(0,3).forEach(n=>assert(Number.isFinite(n),'Non-finite arc')),fillText:(s,x,y)=>{assert(Number.isFinite(x)&&Number.isFinite(y),'Non-finite text');draws++;}},
 {get:(o,k)=>k in o?o[k]:(()=>{}),set:(o,k,v)=>(o[k]=v,true)});
const canvas={width:1280,height:720,getContext:()=>context,focus(){},addEventListener(){}};
const stub={remove(){},textContent:'',requestFullscreen:()=>Promise.resolve(),addEventListener(){}};
const sandbox={HoneyVisuals:require('../web/visuals.js'),HoneyGame:require('../web/game.js'),console,Math,Set,Map,JSON,Promise,Image:class{set src(src){this.asset=src;const file=path.resolve(__dirname,'../web',src);const b=fs.readFileSync(file);this.width=path.extname(file)==='.png'?b.readUInt32BE(16):512;this.height=path.extname(file)==='.png'?b.readUInt32BE(20):512;queueMicrotask(()=>this.onload());}},
 document:{querySelector:s=>s==='#game'?canvas:stub,addEventListener(){}},localStorage:{getItem:()=>null,setItem(){}},performance:{now:()=>0},requestAnimationFrame:f=>{frameCallback=f;},setTimeout,queueMicrotask};
sandbox.window={addEventListener(){},HoneyAudio:require('../web/audio.js')};sandbox.globalThis=sandbox;
vm.createContext(sandbox);vm.runInContext(fs.readFileSync(path.resolve(__dirname,'../web/render.js'),'utf8'),sandbox);
setTimeout(()=>{
 assert(frameCallback,'Renderer failed to initialize');
 const {game:g,ui}=sandbox.window.__honey;let t=0;const frame=(n=1)=>{for(let i=0;i<n;i++)frameCallback(t+=17);};
 frame();for(const s of ['stages','settings','howto','main']){ui.screen=s;frame();}
 { // settings: tapping ◀ lowers a volume, ▶ raises it, tapping the bar sets the level (mouse/touch, not only keys)
  const {settings,pointer}=sandbox.window.__honey;ui.screen='settings';ui.index=0;frame();
  const row=ui.hits.find(h=>h.dir===-1&&sandbox.window.__honey.settings&&true);const at=h=>({x:h.x+h.w/2,y:h.y+h.h/2});
  const key=['difficulty','master','music','sfx'];const before={...settings};
  const down=ui.hits.filter(h=>h.dir===-1),up=ui.hits.filter(h=>h.dir===1),bars=ui.hits.filter(h=>h.bar);
  assert(down.length>=3&&bars.length===3,'volume rows expose ◀/▶/bar targets');
  const masterBar=bars.find(h=>h.i===1);const masterDown=down.find(h=>h.i===1),masterUp=up.find(h=>h.i===1);
  pointer(at(masterDown),true);assert.equal(settings.master,before.master-1);frame();
  pointer(at(ui.hits.find(h=>h.dir===1&&h.i===1)),true);assert.equal(settings.master,before.master);frame();
  pointer({x:masterBar.x+masterBar.w*.25,y:masterBar.y+5},true);assert.equal(settings.master,3);frame();
  settings.master=before.master;ui.screen='main';ui.index=0;frame();}
 g.start(0,true);for(let st=0;st<25.5;st+=.7){g.storyTime=st;frame();}assert.equal(g.mode,'briefing');g.start(0,true);frame();g.confirm();assert.equal(g.mode,'briefing');g.mode='title';
 g.confirm();frame(3);g.confirm();frame(3);
 for(let w=0;w<6;w++)for(const face of [-1,1]){g.giveWeapon(w);g.face=face;g.fireTimer=0;g.shoot();frame();}
 g.knife=.2;frame();g.knife=0;
 for(let stage=0;stage<4;stage++){g.start(stage);g.begin();g.invincible=1e9;g.zones.forEach(z=>z.waves.forEach(w=>{w.done=false;}));g.x=g.zones[0].start+400;frame(5);
  const update=g.update;g.update=()=>{};
  for(const start of [...g.zones.map(z=>z.start),g.bossStart])for(const d of [-400,0,400]){g.camera=Math.max(0,start-640+d);g.x=g.camera+640;frame();}
  g.update=update;g.camera=0;g.x=400;
  for(const kind of Object.keys(sandbox.HoneyGame.ENEMIES)){const e=g.spawnEnemy(g.camera+700,576,kind);e.alert=1;}g.spawnWave('grunt',2,'P',0);
  g.dropItem(g.x+100,400,'weapon',3);g.dropItem(g.x+140,400,'food');g.dropItem(g.x+180,400,'medal');g.dropItem(g.x+220,400,'support');g.dropItem(g.x+260,400,'bomb');g.dropItem(g.x+300,400,'ammo');
  g.explode(g.x+200,500,150,30);frame(40);
  g.startBoss();frame(5);g.updateBoss(3);g.boss.hatch.clock=0;g.grenades=0;frame(80);assert(g.supplies.length>0||g.items.length>0);frame(8);g.addBullet(g.x,400,0,0,false,1,'crate');g.addBullet(g.x,400,0,0,false,1,'fire');g.addBullet(g.x,400,0,0,false,1,'spray');frame(30);for(let p=0;p<3;p++){g.boss.pattern=p;g.boss.state='windup';g.boss.warn=true;g.planBoss();assert(g.boss.zones.length>0);frame();g.bossAttack();frame(20);}
  g.damageBoss(g.boss.max*.6);frame(5);g.dying=1;frame(3);g.dying=0;g.mode='pause';frame();ui.screen='settings';frame();ui.screen='pause';g.mode='play';
  g.damageBoss(9999);frame(30);frame(400);assert.equal(g.mode,'result');frame(300);}
 for(const mode of ['continue','gameover','victory','briefing','title']){g.mode=mode;g.continueTime=5;frame(10);}
 assert(draws>1000);
 assert.equal(seenScenery.size,24,'every generated zone and boss-arena scene is rendered');
 console.log('PASS browser renderer: menus, intro cutscene, all screens, every enemy, item, weapon effect, four bosses and finite Canvas coordinates ('+draws+' draws).');},50);
