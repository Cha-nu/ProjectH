// Offline review of the actual browser draw helpers when no graphics window is available.
const fs=require('fs'),vm=require('vm'),{Game,BOSS_RIG,FLOOR,CELEBRATE_BURST,STAGES}=require('../web/game.js');
const source=fs.readFileSync('web/render.js','utf8'),ops=[],tex={};
for(const name of ['walker','cannon','ship','tank'])tex['boss_'+name]='assets/generated/bosses/'+name+'_ink.png';
tex.driveParts='assets/generated/bosses/drive_parts.png';tex.groundInk='assets/generated/ground_ink.png';
for(const name of ['town','factory','harbor','fortress'])for(let i=0;i<6;i++)tex['scene_'+name+'_'+i]='assets/generated/scene_'+name+'_'+i+'.png';
tex.hero='assets/characters/hero_sheet.png';
tex.items='assets/generated/items.png';
for(const key in tex){const path=tex[key],png=fs.readFileSync(path);tex[key]={path,width:png.readUInt32BE(16),height:png.readUInt32BE(20)};}
const c=new Proxy({globalAlpha:1}, {get:(o,k)=>k in o?o[k]:(...a)=>ops.push({op:k,a:k==='drawImage'?[a[0].path||a[0],...a.slice(1)]:a}),set:(o,k,v)=>{ops.push({op:'set',a:[k,v]});o[k]=v;return true;}});
const sandbox={c,tex,BOSS_RIG,FLOOR,STAGES,CELEBRATE_BURST,HoneyVisuals:require('../web/visuals.js'),Math,clamp:(v,a,b)=>Math.max(a,Math.min(b,v))};
sandbox.viewCam=()=>sandbox.g.camera;
vm.createContext(sandbox);
for(const prefix of ['const INK=','const DISPLAY=','const ITEM='])vm.runInContext(source.slice(source.indexOf(prefix),source.indexOf('\n',source.indexOf(prefix))),sandbox);
for(const name of ['box','line','circle','ellipse','poly','ring','text','cell','hero','drawShip','zoneBackdrop','ground','bossSprite','drawBossBody','drawBoss']){
 const start=source.indexOf('function '+name+'('),next=source.indexOf('\nfunction ',start+1);
 vm.runInContext(source.slice(start,next<0?source.length:next),sandbox);
}
for(let stage=0;stage<4;stage++){
 const g=new Game();g.start(stage);g.begin();g.startBoss();sandbox.g=g;
 g.camera=STAGES[stage].length-1280;
 const b=g.boss;b.x=g.camera+(stage===2?350:950);b.y=FLOOR;b.air=false;b.state='idle';b.warn=false;b.track=stage*17+Number(process.argv[2]||0);
 c.save();c.translate((stage%2)*640,Math.floor(stage/2)*360);c.scale(.5,.5);
 c.beginPath();c.rect(0,0,1280,720);c.clip();
 sandbox.zoneBackdrop(5,1);c.translate(-g.camera,0);
 if(stage!==2)sandbox.ground();
 else sandbox.drawShip(g.ship);
 sandbox.hero(g.camera+(stage===2?1000:210),FLOOR,108,4,stage===2?-1:1);
 sandbox.drawBoss();c.restore();
}
fs.writeFileSync('build/boss-preview-commands.json',JSON.stringify(ops));
console.log('Recorded actual browser boss draw commands for four art-review panels.');
