// Record the actual browser backdrop helper for comparison with the native renderer.
const fs=require('node:fs'),vm=require('node:vm'),{Game,STAGES}=require('../web/game.js');
const source=fs.readFileSync('web/render.js','utf8'),ops=[],tex={};
for(const theme of ['town','factory','harbor','fortress'])for(let i=0;i<6;i++){
 const path=`assets/generated/scene_${theme}_${i}.png`,png=fs.readFileSync(path);
 tex[`scene_${theme}_${i}`]={path,width:png.readUInt32BE(16),height:png.readUInt32BE(20)};
}
const c={globalAlpha:1,save(){this.previous=this.globalAlpha;},restore(){this.globalAlpha=this.previous;},drawImage(im,...a){ops.push({path:im.path,source:a.slice(0,4),dest:a.slice(4),alpha:this.globalAlpha});}};
const sandbox={c,tex,STAGES,clamp:(v,a,b)=>Math.max(a,Math.min(b,v))};sandbox.viewCam=()=>sandbox.g.camera+(sandbox.g.ship?.sail||0);
vm.createContext(sandbox);
const start=source.indexOf('function zoneBackdrop('),end=source.indexOf('\nfunction ground(',start);
vm.runInContext(source.slice(start,end),sandbox);
for(let stage=0;stage<4;stage++){
 const g=new Game();g.start(stage);sandbox.g=g;
 for(let i=0;i<6;i++){g.camera=(g.zones[i]?.start??g.bossStart)+200.5;sandbox.zoneBackdrop(i,1);}
}
fs.writeFileSync('build/background-browser-commands.json',JSON.stringify(ops));
console.log('Recorded 24 real browser background placements.');
