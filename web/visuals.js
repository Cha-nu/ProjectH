/* Pure presentation selection shared by the browser renderer and its regression checks.
   GDScript counterpart: scripts/visual_motion.gd. No simulation state is changed. */
(function(root){'use strict';
const clamp=(x,a,b)=>Math.max(a,Math.min(b,x));
const DRIVE_ART=[[192,55,689,542],[835,210,1435,542],[104,673,906,915],[1016,542,1434,955]];
// Town strip wraps at x=1467 (that column repeats column 0), so the redrawn brick wall tiles without a seam.
const GROUND_ART=[[0,14,1467,260],[0,269,1536,505],[0,516,1536,736],[0,749,1536,1024]];
const SOFT_BOSSES={"walker":{"dest":[[44,113,470,462],[44,113,470,462],[84,223,413,398],[98,232,443,415],[159,122,342,382],[156,116,343,382],[64,40,449,452],[68,74,433,383]],"source":[[8,142,384,450],[392,143,768,451],[768,206,1114,390],[1157,198,1503,382],[91,582,333,927],[461,552,703,897],[822,620,1082,898],[1177,630,1498,902]]},"cannon":{"dest":[[39,110,486,473],[39,110,486,473],[37,105,457,456],[91,176,447,455],[70,101,469,356],[69,98,486,362],[26,45,419,399],[28,54,454,400]],"source":[[26,82,482,504],[486,82,947,504],[975,218,1362,497],[1386,251,1755,506],[73,575,437,823],[527,594,928,834],[994,571,1285,837],[1357,588,1728,852]]},"ship":{"dest":[[66,82,465,446],[66,82,465,446],[68,206,437,443],[69,198,427,428],[75,96,436,404],[134,168,381,378],[101,59,409,444],[73,100,442,430]],"source":[[12,102,384,441],[396,102,768,441],[830,161,1114,344],[1206,163,1490,346],[36,629,353,899],[433,571,750,841],[834,613,1072,911],[1186,620,1501,901]]},"tank":{"dest":[[102,105,441,463],[102,105,441,463],[85,213,408,409],[105,223,385,393],[95,175,398,382],[69,148,388,366],[49,76,411,449],[83,149,447,435]],"source":[[12,96,384,489],[396,95,768,488],[768,193,1137,418],[1157,189,1526,414],[80,680,342,859],[454,680,716,859],[838,625,1086,880],[1174,628,1494,880]]}};
// A capsule in local track coordinates. Arc length keeps links evenly spaced.
function treadPoint(distance,length,radius){
 const total=2*length+2*Math.PI*radius;let s=((distance%total)+total)%total;
 if(s<length)return {x:s,y:-radius,a:0};s-=length;
 if(s<Math.PI*radius){const a=s/radius-Math.PI/2;return {x:length+Math.cos(a)*radius,y:Math.sin(a)*radius,a:a+Math.PI/2};}s-=Math.PI*radius;
 if(s<length)return {x:length-s,y:radius,a:Math.PI};s-=length;
 const a=s/radius+Math.PI/2;return {x:Math.cos(a)*radius,y:Math.sin(a)*radius,a:a+Math.PI/2};}
function bossArt(sheet,frame){return {source:SOFT_BOSSES[sheet].source[frame],dest:SOFT_BOSSES[sheet].dest[frame]};}
const BOUNDS={"walker":[[36,68,411,402],[456,63,851,403],[910,91,1303,402],[1360,81,1739,401],[46,532,420,816],[449,465,865,820],[899,475,1292,813],[1319,560,1749,821]],"cannon":[[28,87,433,414],[464,88,875,417],[900,108,1323,417],[1356,87,1761,414],[29,508,436,820],[472,503,875,824],[907,502,1316,822],[1341,574,1758,825]],"ship":[[32,61,440,410],[453,65,876,410],[904,65,1322,410],[1325,65,1748,410],[32,472,440,821],[464,477,873,824],[902,465,1321,822],[1353,505,1751,825]],"tank":[[32,45,445,426],[468,45,887,428],[903,86,1324,428],[1349,55,1771,427],[27,486,449,845],[475,471,887,847],[911,471,1330,848],[1348,547,1753,853]],"portals":[[24,11,608,573],[664,13,1235,572],[13,620,617,1200],[642,609,1239,1200]]};
function scenery(zones,bossStart,focus){
 const starts=zones.map(z=>z.start);if(starts.length<6)starts.push(bossStart);
 for(let i=1;i<starts.length;i++)if(focus<starts[i]+400){
  const t=clamp((focus-starts[i]+400)/800,0,1);
  return {from:i-1,to:i,mix:t*t*(3-2*t)};}
 const last=Math.min(5,starts.length-1);return {from:last,to:last,mix:0};}
function bossFrame(b){
 // Hold a coherent painted pose. Time animates the rig, not armor/rivet texture.
 if(b.dead)return 7;
 if(b.phase===2||b.state==='break')return 6;
 if(b.air)return b.vy<0?4:5;
 if(b.state==='windup')return 2;
 if(b.state==='attack'&&b.pattern===2)return b.clock>.55?4:5;
 if(b.charge||b.state==='enter')return 1;
 if(b.state==='attack'||b.state==='recover'||b.recoil>.01)return 3;
 return 0;}
function bossPose(b){
 const t=b.t||0,k=b.sink||0,kick=clamp(b.recoil||0,0,1),moving=b.state==='enter'||b.charge;
 let u=b.state==='windup'?clamp(1-b.clock/(b.phase===2?.75:1),0,1):0;u=u*u*(3-2*u);
 const p={x:kick*5,y:0,rot:0,sx:1,sy:1};
 if(b.type==='boat'){p.y=Math.sin(t*1.6)*2;p.rot=Math.sin(t*1.6)*.012-kick*.01;}
 else {p.y=moving?Math.sin(t*6)*1.1:Math.sin(t*1.8)*.55;p.sy=1-u*.025;p.sx=1+u*.012;p.rot=kick*.008;}
 if(b.air){p.rot=b.vy<0?.025:-.025;p.sy=1.015;}
 if(b.dead){p.x+=k*20;p.y+=b.type==='boat'?200*k*k:12*k;p.rot+=(b.type==='boat'?.12:-.06)*k;p.sy=1-.12*k;}
 return p;}
function bossRect(sheet,frame,rig){
 const a=BOUNDS[sheet][frame],box=rig.box;
 const w=(box[2]-box[0])*rig.k,h=(box[3]-box[1])*rig.k*(frame===7?.68:1);
 return {source:a,x:((box[0]+box[2])/2-256)*rig.k-w/2,y:(box[3]-512*rig.base)*rig.k-h,w,h};}
function portals(zones,bossStart,camera,time=0){
 return zones.map((z,i)=>{const t=z.cleared?clamp((time-(z.clearedAt??(time-.7)))/.7,0,1):0;
  return {x:i+1<zones.length?zones[i+1].start:bossStart,open:!!z.cleared,reveal:t*t*(3-2*t),index:i+1};}).filter(p=>p.x>camera-320&&p.x<camera+1600);}
function entranceShade(portals,x){let shade=0;for(const p of portals)if(p.open){const t=clamp(1-Math.abs(x-p.x)/180,0,1);shade=Math.max(shade,t*t*(3-2*t)*.3);}return shade;}
const api={scenery,bossFrame,bossPose,bossRect,bossArt,treadPoint,portals,entranceShade,bounds:BOUNDS,softBosses:SOFT_BOSSES,driveArt:DRIVE_ART,groundArt:GROUND_ART};
if(typeof module!=='undefined')module.exports=api;else root.HoneyVisuals=api;
})(typeof globalThis!=='undefined'?globalThis:this);
