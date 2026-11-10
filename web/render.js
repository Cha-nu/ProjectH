/* Honey Churros — browser front end: loading, input (keyboard / touch / gamepad), menus, HUD and Canvas rendering. */
(async()=>{'use strict';
const {Game,WEAPON_UNLOCK,THROW_TIME,CELEBRATE_BURST,STAGES,LEVELS,WEAPONS,VISUALS,ENEMIES,BOSSES,BOSS_RIG,DIFFICULTY,PISTOL,FLOOR,weaponPose,playerFrame,clamp}=HoneyGame;
const canvas=document.querySelector('#game'),c=canvas.getContext('2d'),g=new Game();
const audio=window.HoneyAudio?window.HoneyAudio.create():{ready(){},set(){},opts:{},sfx(){},music(){},stopMusic(){},voice(){}};
const INK='#5b3440',PAPER='#fff8f5',PINK='#ffd8d9',HOT='#ef7f9e',GOLD='#ffc94d',TEAL='#3f7468',SHADOW='#3a1f2a';
const DISPLAY="'Black Han Sans','Malgun Gothic',sans-serif",BODY="'Jua','Malgun Gothic',sans-serif";
const THEME={town:{sky:['#9fdcf4','#e4f6ef'],ground:'#a9cf8e',top:'#d6ecb4',edge:'#6f9a5b',deep:'#7d6650'},
 factory:{sky:['#f6d27d','#fff1cf'],ground:'#c9a067',top:'#e8c58a',edge:'#8a6235',deep:'#6b4a2e'},
 harbor:{sky:['#8fd2ef','#e2f5f6'],ground:'#b88f68',top:'#d9b48a',edge:'#7b5638',deep:'#5c4436'},
 fortress:{sky:['#9c90c6','#e5ddf0'],ground:'#8d8696',top:'#b4adbd',edge:'#5c5566',deep:'#4a4352'}};

// ---------- loading ----------
const tex={},loadEl=document.querySelector('#loading'),bar=document.querySelector('#bar');
const files={aim:'characters/hero_aim_sheet.png',menuFriends:'characters/menu_friends_v2.png',bossCrew:'generated/boss_crew.png',profile:'characters/profile.jpg',profileRound:'generated/profile_round.png',m4:'characters/m4_black.png',fishAnim:'characters/fish_sheet.png',bossParts:'characters/boss_parts.png',hero:'characters/hero_sheet.png',body:'characters/hero_body_sheet.png',bodyP:'characters/hero_body_pistol.png',runP:'generated/hero_run_pistol.png',weapons:'characters/weapons_clean.png',bee:'characters/honeybee.webp',tank:'characters/tank.png',bg:'backgrounds.png',bgWrap:'generated/backgrounds_wrap.png',roster:'generated/enemies.png',upRun:'generated/hero_up_run.png',menuBg:'generated/menu_bg_meadow.png',menuGirl:'generated/menu_churros_sit.png',menuFish:'generated/menu_gwamegi_peek.png',menuBush:'generated/menu_bush_front.png',menuTree:'generated/menu_tree_whole.png',victory:'generated/hero_victory.png',punch:'generated/hero_punch.png',run:'generated/hero_run.png',story:'generated/story_churros.png',bodyHands:'generated/hero_body_hands.png',runHands:'generated/hero_run_hands.png',briefing:'generated/story_briefing.png',pow:'generated/pow_tied.png',cage:'generated/pow_cage.png',items:'generated/items.png',boom:'generated/explosion.png',bossKing:'generated/boss_king.png',bossCannon:'generated/boss_cannon.png',bossBoat:'generated/boss_boat.png',boss_walker:'generated/bosses/walker_ink.png',boss_cannon:'generated/bosses/cannon_ink.png',boss_ship:'generated/bosses/ship_ink.png',boss_tank:'generated/bosses/tank_ink.png',
 e_grunt:'generated/enemies/grunt.png',e_hopper:'generated/enemies/hopper.png',e_flyer:'generated/enemies/flyer.png',e_shield:'generated/enemies/shield.png',e_bomber:'generated/enemies/bomber.png',e_heavy:'generated/enemies/heavy.png',e_turret:'generated/enemies/turret.png',chute:'generated/enemies/parachute.png',
 g_town:'generated/ground/town.png',g_factory:'generated/ground/factory.png',g_harbor:'generated/ground/harbor.png',g_fortress:'generated/ground/fortress.png'};

files.driveParts='generated/bosses/drive_parts.png';files.groundInk='generated/ground_ink.png';
for(const name of ['town','factory','harbor','fortress'])for(let i=0;i<6;i++)files['scene_'+name+'_'+i]='generated/scene_'+name+'_'+i+'.png';
let loaded=0;const total=Object.keys(files).length;
try{await Promise.all([...Object.entries(files).map(([key,path])=>new Promise((resolve,reject)=>{const im=new Image();im.onload=()=>{tex[key]=im;loaded++;if(bar?.style)bar.style.width=Math.round(loaded/total*100)+'%';resolve();};im.onerror=()=>reject(new Error(path));im.src='../assets/'+path;})),
 Promise.race([Promise.all([document.fonts?.load?.("40px 'Black Han Sans'"),document.fonts?.load?.("20px 'Jua'")]),new Promise(r=>setTimeout(r,2500))]).catch(()=>{})]);}
catch(e){if(loadEl)loadEl.textContent='이미지를 불러오지 못했어요. 실행 도우미(Play-Web)로 다시 열어 주세요. '+e.message;return;}
loadEl?.remove?.();canvas.focus?.();

// ---------- persistence ----------
const store={get(k,d){try{const v=localStorage.getItem(k);return v==null?d:JSON.parse(v);}catch{return d;}},set(k,v){try{localStorage.setItem(k,JSON.stringify(v));}catch{}}};
const settings=Object.assign({difficulty:'normal',master:8,music:6,sfx:8,voice:true,shake:true,touch:'auto'},store.get('honey-settings',{})||{});if(!DIFFICULTY[settings.difficulty])settings.difficulty='normal';
let records=store.get('honey-records',[]),progress=Number(store.get('honey-progress',0))||0;if(!Array.isArray(records))records=[];
g.best=Math.max(Number(store.get('honey-best',0))||0,...records.map(r=>r.score),0);
g.onSave=v=>store.set('honey-best',v);
g.sound=n=>audio.sfx(n);g.voice=t=>audio.voice(t);
function applySettings(){g.difficulty=settings.difficulty;g.shakeScale=settings.shake?1:0;audio.set({master:settings.master/10,music:settings.music/10,sfx:settings.sfx/10,voice:settings.voice});store.set('honey-settings',settings);}
applySettings();
function addRecord(){if(!g.score)return;records.push({score:g.score,stage:g.stage+1,clear:g.mode==='victory',dif:g.difficulty,date:new Date().toISOString().slice(0,10)});records.sort((a,b)=>b.score-a.score);records=records.slice(0,5);store.set('honey-records',records);}

// ---------- input ----------
const kb=new Set(),pressedEv=new Set(),releasedEv=new Set(),touchHeld=new Map();let padHeld=new Set(),prevHeld=new Set(),touchMode=settings.touch==='on';
const KEYMAP={ArrowLeft:'left',KeyA:'left',ArrowRight:'right',KeyD:'right',ArrowUp:'up',KeyW:'up',ArrowDown:'down',KeyS:'down',KeyZ:'fire',KeyJ:'fire',KeyX:'jump',Space:'jump',KeyC:'grenade',KeyK:'grenade',KeyQ:'swap',ShiftLeft:'swap'};
function menuKey(code){return {ArrowUp:'up',KeyW:'up',ArrowDown:'down',KeyS:'down',ArrowLeft:'left',KeyA:'left',ArrowRight:'right',KeyD:'right',Enter:'ok',NumpadEnter:'ok',Space:'ok',KeyZ:'ok',Escape:'back',Backspace:'back',KeyX:'back'}[code];}
document.addEventListener('keydown',e=>{
 if(KEYMAP[e.code]||['Enter','Escape','Space','KeyP','KeyM','KeyR','Tab'].includes(e.code))e.preventDefault();
 audio.ready();
 if(e.code==='KeyM'&&!e.repeat){audio.set({muted:!audio.opts.muted});toastUI(audio.opts.muted?'소리 끔':'소리 켬');return;}
 if(g.mode==='play'){
  if((e.code==='Escape'||e.code==='KeyP')&&!e.repeat){openPause();return;}
  if(e.repeat)return;
  const a=KEYMAP[e.code];if(a){kb.add(a);pressedEv.add(a);}
  return;}
 const m=menuKey(e.code);if(m)uiInput(m,e.repeat);
 if(e.code==='KeyR'&&!e.repeat&&['pause','continue'].includes(g.mode)){g.retry();closeMenus();}});
document.addEventListener('keyup',e=>{const a=KEYMAP[e.code];if(a){kb.delete(a);releasedEv.add(a);}});
function clearHeld(){kb.clear();touchHeld.clear();}
window.addEventListener('blur',()=>{clearHeld();if(g.mode==='play')openPause();});
document.addEventListener('visibilitychange',()=>{if(document.hidden){clearHeld();if(g.mode==='play')openPause();}});

function pos(e){const r=canvas.getBoundingClientRect();return{x:(e.clientX-r.left)*1280/r.width,y:(e.clientY-r.top)*720/r.height};}
const PAD={x:118,y:612,r:72},BTN=[{a:'fire',x:1182,y:618,r:54,label:'사격',key:'Z'},{a:'jump',x:1068,y:656,r:40,label:'점프',key:'X'},{a:'grenade',x:1072,y:548,r:34,label:'폭탄',key:'C'},{a:'swap',x:1190,y:500,r:30,label:'교체',key:'Q'}];
function touchActions(p){
 const dx=p.x-PAD.x,dy=p.y-PAD.y;
 if(Math.hypot(dx,dy)<PAD.r*1.5&&p.x<300&&p.y>480){if(Math.hypot(dx,dy)<12)return [];const a=Math.atan2(dy,dx),out=[];
  if(Math.cos(a)>.38)out.push('right');if(Math.cos(a)<-.38)out.push('left');if(Math.sin(a)<-.38)out.push('up');if(Math.sin(a)>.55)out.push('down');return out;}
 for(const b of BTN)if(Math.hypot(p.x-b.x,p.y-b.y)<b.r+10)return [b.a];
 return [];}
function setTouch(id,actions){const old=touchHeld.get(id)||[];for(const a of actions)if(!old.includes(a))pressedEv.add(a);
 for(const a of old)if(!actions.includes(a)&&![...touchHeld.entries()].some(([k,v])=>k!==id&&v.includes(a)))releasedEv.add(a);
 if(actions.length)touchHeld.set(id,actions);else touchHeld.delete(id);}
const pauseHit=p=>Math.hypot(p.x-1229,p.y-51)<30;
canvas.addEventListener('pointerdown',e=>{
 audio.ready();canvas.focus?.();const p=pos(e);
 if(e.pointerType==='touch'&&settings.touch==='auto')touchMode=true;
 if(g.mode==='play'){
  if(pauseHit(p)){openPause();return;}
  const acts=touchActions(p);if(acts.length){e.preventDefault?.();canvas.setPointerCapture?.(e.pointerId);setTouch(e.pointerId,acts);}
  return;}
 uiPointer(p,true);});
canvas.addEventListener('pointermove',e=>{const p=pos(e);
 if(touchHeld.has(e.pointerId)){setTouch(e.pointerId,touchActions(p));return;}
 if(g.mode!=='play')uiPointer(p,false);
 if(canvas.style)canvas.style.cursor=g.mode==='play'?(pauseHit(p)?'pointer':'default'):ui.hover>=0?'pointer':'default';});
const touchEnd=e=>{if(touchHeld.has(e.pointerId))setTouch(e.pointerId,[]);};
canvas.addEventListener('pointerup',touchEnd);canvas.addEventListener('pointercancel',touchEnd);
document.querySelector('#full')?.addEventListener?.('click',toggleFull);
function toggleFull(){const el=document.querySelector('#shell');if(document.fullscreenElement)document.exitFullscreen?.();else el?.requestFullscreen?.().catch(()=>{});canvas.focus?.();}

// Gamepad (standard mapping): A jump, X fire, B grenade, Y swap, Start pause.
let padPrev={};
function pollPad(){
 padHeld=new Set();const pads=globalThis.navigator?.getGamepads?.()||[];const p=[...pads].find(Boolean);if(!p)return;
 const b=i=>!!p.buttons[i]?.pressed,ax=p.axes[0]||0,ay=p.axes[1]||0,now={};
 now.left=b(14)||ax<-.4;now.right=b(15)||ax>.4;now.up=b(12)||ay<-.5;now.down=b(13)||ay>.5;now.jump=b(0);now.fire=b(2)||b(7);now.grenade=b(1)||b(6);now.swap=b(3)||b(5);now.start=b(9);
 const edge=k=>now[k]&&!padPrev[k];
 if(g.mode==='play'){for(const k of ['left','right','up','down','jump','fire','grenade','swap'])if(now[k])padHeld.add(k);if(edge('start'))openPause();}
 else{for(const k of ['up','down','left','right'])if(edge(k))uiInput(k);if(edge('jump')||edge('start'))uiInput('ok');if(edge('grenade'))uiInput('back');}
 padPrev=now;}

// ---------- UI / menus ----------
const ui={screen:'main',titleAt:0,index:0,hover:-1,hits:[],fade:1,toast:'',toastT:0,lastMode:'',goT:0,cleared:0,from:'main',tickNum:-1,shownRow:-1};
function toastUI(s){ui.toast=s;ui.toastT=1.6;}
function closeMenus(){ui.screen='main';ui.index=0;audio.set({duck:false});}
function openPause(){if(g.mode!=='play')return;g.pause();ui.screen='pause';ui.index=0;audio.set({duck:true});audio.sfx('click');clearHeld();}
const onOff=v=>v?'켜기':'끄기';
function menu(){
 const S=settings,vol=(k)=>({label:{master:'전체 볼륨',music:'음악',sfx:'효과음'}[k],value:'■'.repeat(S[k])+'□'.repeat(10-S[k]),adjust:d=>{S[k]=clamp(S[k]+d,0,10);applySettings();audio.sfx('move');},setTo:v=>{S[k]=clamp(v,0,10);applySettings();audio.sfx('move');}});
 const dif=()=>({label:'난이도',value:DIFFICULTY[S.difficulty].label,adjust:d=>{const k=Object.keys(DIFFICULTY);S.difficulty=k[(k.indexOf(S.difficulty)+d+k.length)%k.length];applySettings();audio.sfx('move');}});
 switch(ui.screen){
  case'main':return [{label:'게임 시작',go:()=>{g.difficulty=S.difficulty;g.start(0,true);}},{label:'스테이지 선택',go:()=>open('stages')},dif(),{label:'조작 방법',go:()=>open('howto')},{label:'설정',go:()=>open('settings')}];
  case'stages':return [...STAGES.map((s,i)=>({label:`MISSION ${i+1}  ${s.name}`,locked:i>progress,go:()=>{if(i>progress){audio.sfx('back');toastUI('이전 미션을 먼저 클리어하세요');return false;}g.difficulty=S.difficulty;g.start(i);}})),{label:'돌아가기',go:()=>back()}];
  case'settings':return [...(ui.from==='main'?[dif()]:[]),vol('master'),vol('music'),vol('sfx'),
   {label:'아나운서 음성',value:onOff(S.voice),adjust:()=>{S.voice=!S.voice;applySettings();audio.sfx('move');if(S.voice)audio.voice('Mission start!');}},
   {label:'화면 흔들림',value:onOff(S.shake),adjust:()=>{S.shake=!S.shake;applySettings();audio.sfx('move');}},
   {label:'터치 버튼',value:{auto:'자동',on:'항상 표시',off:'숨김'}[S.touch],adjust:d=>{const k=['auto','on','off'];S.touch=k[(k.indexOf(S.touch)+d+3)%3];touchMode=S.touch==='on';applySettings();audio.sfx('move');}},
   {label:'전체 화면',value:document.fullscreenElement?'켜짐':'꺼짐',go:()=>{toggleFull();return false;}},
   {label:'돌아가기',go:()=>back()}];
  case'pause':return [{label:'계속하기',go:()=>{g.pause();closeMenus();}},{label:'미션 처음부터',go:()=>{g.retry();closeMenus();}},{label:'설정',go:()=>open('settings','pause')},{label:'타이틀로 나가기',go:()=>{g.quit();closeMenus();}}];
  case'howto':case'records':return [{label:'돌아가기',go:()=>back()}];}
 return [];}
function open(screen,from){ui.from=from||ui.screen;ui.screen=screen;ui.index=0;audio.sfx('select');}
function back(){const to=ui.screen==='settings'&&ui.from==='pause'?'pause':'main';ui.screen=to;ui.index=to==='pause'?2:0;audio.sfx('back');}
function activate(item,dir=1){if(!item)return;if(item.go){if(item.go()!==false&&!item.locked)audio.sfx('select');}else if(item.adjust)item.adjust(dir);}
function menuActive(){return g.mode==='title'||g.mode==='pause';}
function uiInput(a,repeat=false){
 if(menuActive()){
  const items=menu();if(!items.length)return;
  if(a==='up'||a==='down'){ui.index=(ui.index+(a==='up'?-1:1)+items.length)%items.length;audio.sfx('move');}
  else if((a==='left'||a==='right')&&items[ui.index]?.adjust)items[ui.index].adjust(a==='left'?-1:1);
  else if(a==='ok'&&!repeat)activate(items[ui.index]);
  else if(a==='back'&&!repeat){if(g.mode==='pause'&&ui.screen==='pause'){g.pause();closeMenus();}else if(ui.screen!=='main'&&ui.screen!=='pause')back();}
  return;}
 if(repeat)return;
 if(a==='ok')advance();
 else if(a==='back'&&g.mode==='continue')g.continueTime=0;}
function advance(){
 if(g.mode==='result'){if(g.result.t<tallyEnd()){g.result.t=tallyEnd();return;}g.confirm();return;}
 if(g.mode==='victory'&&victoryT()<3)return;
 if(['story','briefing','continue','gameover','victory'].includes(g.mode)){g.confirm();audio.sfx('select');}}
function uiPointer(p,click){
 const hit=ui.hits.find(h=>p.x>=h.x&&p.x<=h.x+h.w&&p.y>=h.y&&p.y<=h.y+h.h);
 ui.hover=hit?hit.i:-1;
 if(hit&&!click&&menuActive()&&ui.index!==hit.i){ui.index=hit.i;}
 if(!click)return;
 if(hit){if(menuActive()){ui.index=hit.i;const item=menu()[hit.i];if(hit.bar&&item?.setTo)item.setTo(Math.ceil((p.x-hit.bar[0])/(hit.bar[1]-hit.bar[0])*10));else activate(item,hit.dir||1);}else hit.go?.();return;}
 if(g.mode==='title'){if(ui.screen==='howto'||ui.screen==='records')back();return;}
 if(!menuActive())advance();}

// ---------- drawing helpers ----------
function box(x,y,w,h,color,r=10,border=null,line=2){if(w<=0||h<=0)return;c.beginPath();c.roundRect(x,y,w,h,r);c.fillStyle=color;c.fill();if(border){c.strokeStyle=border;c.lineWidth=line;c.stroke();}}
function text(s,x,y,size=18,color=INK,align='left',font=BODY){c.fillStyle=color;c.font=`${size}px ${font}`;c.textAlign=align;c.textBaseline='alphabetic';c.fillText(s,x,y);}
function outlined(s,x,y,size,fill=PAPER,stroke=SHADOW,align='center',lw=0,font=DISPLAY){c.font=`${size}px ${font}`;c.textAlign=align;c.textBaseline='alphabetic';c.lineJoin='round';c.lineWidth=lw||Math.max(3,size*.16);
 c.strokeStyle=stroke;c.strokeText(s,x,y+size*.07);c.strokeText(s,x,y);c.fillStyle=fill;c.fillText(s,x,y);}
function line(x,y,xx,yy,color,width=2){c.beginPath();c.moveTo(x,y);c.lineTo(xx,yy);c.strokeStyle=color;c.lineWidth=width;c.lineCap='round';c.stroke();}
function circle(x,y,r,color){c.beginPath();c.arc(x,y,Math.max(0,r),0,Math.PI*2);c.fillStyle=color;c.fill();}
function ring(x,y,r,color,w=2){c.beginPath();c.arc(x,y,Math.max(0,r),0,Math.PI*2);c.strokeStyle=color;c.lineWidth=w;c.stroke();}
function ellipse(x,y,rx,ry,color){c.beginPath();c.ellipse(x,y,Math.max(0,rx),Math.max(0,ry),0,0,Math.PI*2);c.fillStyle=color;c.fill();}
function poly(points,color,border=null,w=2){c.beginPath();points.forEach(([x,y],i)=>i?c.lineTo(x,y):c.moveTo(x,y));c.closePath();c.fillStyle=color;c.fill();if(border){c.strokeStyle=border;c.lineWidth=w;c.lineJoin='round';c.stroke();}}
function heart(x,y,s,color,border=SHADOW){c.beginPath();c.moveTo(x,y+s*.35);c.bezierCurveTo(x,y-s*.1,x-s*.6,y-s*.1,x-s*.6,y+s*.3);c.bezierCurveTo(x-s*.6,y+s*.65,x,y+s*.85,x,y+s);c.bezierCurveTo(x,y+s*.85,x+s*.6,y+s*.65,x+s*.6,y+s*.3);c.bezierCurveTo(x+s*.6,y-s*.1,x,y-s*.1,x,y+s*.35);c.fillStyle=color;c.fill();c.strokeStyle=border;c.lineWidth=2;c.stroke();}
const ease=t=>1-Math.pow(1-clamp(t,0,1),3),back3=t=>{t=clamp(t,0,1);const s=1.7;return 1+(s+1)*Math.pow(t-1,3)+s*Math.pow(t-1,2);};
const pad7=n=>String(Math.max(0,Math.floor(n))).padStart(7,'0');

// ---------- sprites ----------
function bee(x,y,size,alpha=1,flip=1){c.save();c.globalAlpha*=alpha;c.translate(x,y);c.scale(flip,1);c.drawImage(tex.bee,50,130,370,320,-size/2,-size*.8,size,size*.8);c.restore();}
function hero(x,y,size,frame=4,face=1,alpha=1,modular=false,sheet=null){const t=sheet||(modular?(g.weapon===PISTOL?tex.bodyP:tex.body):tex.hero),w=t.width/4,h=t.height/2;c.save();c.translate(x,y);c.scale(face,1);c.globalAlpha*=alpha;c.drawImage(t,(frame%4)*w,Math.floor(frame/4)*h,w,h,-size/2,-size,size,size);c.restore();}
function fishSprite(x,y,size,frame=4,facing=-1,opts={}){const im=tex.fishAnim,cw=im.width/4,ch=im.height/2;c.save();c.translate(x,y);if(opts.rot)c.rotate(opts.rot);c.scale((facing>0?-1:1)*(opts.sx||1),opts.sy||1);if(opts.alpha!=null)c.globalAlpha*=opts.alpha;if(opts.filter)c.filter=opts.filter;
 c.drawImage(im,(frame%4)*cw,Math.floor(frame/4)*ch,cw,ch,-size/2,-size*(opts.anchor??1),size,size);c.restore();}
// Source crop size of each weapon in the atlas, so icons can be fitted without squashing.
function weaponSize(i){if(i===2)return[.95*tex.m4.width,.74*tex.m4.height];const r=[[.343,.21],[.349,.14],[.287,.21],[.351,.17],[.229,.23],[.166,.18]][i];return[r[0]*tex.weapons.width,r[1]*tex.weapons.height];}
function weaponFit(i,x,y,w,h){const [sw,sh]=weaponSize(i),k=Math.min(w/sw,h/sh),dw=sw*k,dh=sh*k;weaponIcon(i,x+(w-dw)/2,y+(h-dh)/2,dw,dh);}
function weaponIcon(i,x,y,w,h){if(i===2){const m=tex.m4;c.drawImage(m,.025*m.width,.16*m.height,.95*m.width,.74*m.height,x,y,w,h);return;}const r=[[.01,.28,.343,.21],[.351,.319,.349,.14],[.709,.28,.287,.21],[.026,.59,.351,.17],[.438,.58,.229,.23],[.775,.61,.166,.18]][i],im=tex.weapons;c.drawImage(im,r[0]*im.width,r[1]*im.height,r[2]*im.width,r[3]*im.height,x,y,w,h);}
function bossPart(i,x,y,w,h){const r=[[.01,.015,.62,.61],[.63,.23,.365,.31],[.125,.645,.247,.34],[.45,.68,.545,.30]][i],im=tex.bossParts;c.drawImage(im,r[0]*im.width,r[1]*im.height,r[2]*im.width,r[3]*im.height,x,y,w,h);}
// 4x2 sheets generated with Codex. src = crop in cell units (may extend past the cell), base = feet line in cell units.
// Enemy sheets (generated/enemies/*.png): 4x2 frames facing left — 0-3 walk, 4 idle, 5 windup, 6 attack, 7 hurt. base = feet line in cell units.
const EBASE={grunt:.80,hopper:.88,flyer:.88,shield:.87,bomber:.88,heavy:.88,turret:.87},ESCALE=1.6;
const ITEM={weapon:0,bomb:1,food:2,medal:3,ammo:4,barrel:5,crate:6,tied:7};
function cell(im,i,x,y,size,o={}){const cw=im.width/4,ch=im.height/2,[a,b,c2,d]=o.src||[0,0,1,1],base=o.base??.5,cx=o.cx??.5;
 c.save();c.translate(x,y);if(o.rot)c.rotate(o.rot);c.scale((o.flip?-1:1)*(o.sx||1),o.sy||1);if(o.alpha!=null)c.globalAlpha*=o.alpha;if(o.filter)c.filter=o.filter;
 c.drawImage(im,(i%4+a)*cw,(Math.floor(i/4)+b)*ch,(c2-a)*cw,(d-b)*ch,(a-cx)*size,(b-base)*size,(c2-a)*size,(d-b)*size);c.restore();}
// Captured honeybee: same character as honeybee.webp, tied with rope.
function powTied(x,y,size,rot=0){c.save();c.translate(x,y);c.rotate(rot);c.drawImage(tex.pow,-size/2,-size*.9,size,size);c.restore();}
function enemySprite(kind,x,y,S,o={}){
 if(kind==='para'){parachute(x,y,S,o);kind=o.body||'grunt';o={...o,frame:4};}
 cell(tex['e_'+kind],o.frame??4,x,y,S*ESCALE,{...o,base:EBASE[kind]});}
function parachute(x,y,S,o={}){const s=S*1.7;c.save();c.translate(x,y);if(o.rot)c.rotate(o.rot);if(o.alpha!=null)c.globalAlpha*=o.alpha;c.drawImage(tex.chute,-s/2,-S*.62-s*.95,s,s);c.restore();}
function enemyFrame(e){
 if(e.flash>0)return 7;
 if(e.warn&&e.kind!=='hopper')return 5;
 if(e.kick>0||e.stab>0||e.launch>0)return 6;
 if(e.air)return 2;
 if(e.kind==='flyer')return Math.floor(e.t*12)%4;
 if(e.kind==='turret')return Math.floor(e.t*2.5)%4;
 if(e.walk||e.state==='enter')return Math.floor(e.t*(e.kind==='hopper'?12:8))%4;
 return 4;}
function bgPanel(stage,x,y,w,h,crop=.66){const cw=tex.bg.width/2,ch=tex.bg.height/2;c.drawImage(tex.bg,(stage%2)*cw,Math.floor(stage/2)*ch,cw,ch*crop,x,y,w,h);}

// ---------- world ----------
const theme=()=>THEME[STAGES[g.stage].theme];
// Camera x for the parallax layers: while the harbor ship sails, the scenery keeps streaming past.
const viewCam=()=>g.camera+(g.ship?.sail||0);
function background(){
 const T=theme(),grad=c.createLinearGradient(0,0,0,576);grad.addColorStop(0,T.sky[0]);grad.addColorStop(1,T.sky[1]);c.fillStyle=grad;c.fillRect(-40,-40,1360,800);
 const blend=HoneyVisuals.scenery(g.zones,g.bossStart,g.x);
 // An opaque full-viewport base plus the next scene: never two translucent tiles over an empty gap.
 zoneBackdrop(blend.from,1);if(blend.mix>0)zoneBackdrop(blend.to,blend.mix);
 ambient(false);}
function zoneBackdrop(index,alpha){
 const im=tex['scene_'+STAGES[g.stage].theme+'_'+index];
 const z=g.zones[index],start=z?.start??g.bossStart,end=z?.end??(start+1600);
 const pan=clamp((viewCam()-start+640)/(end-start+1280),0,1);
 // Standalone full-resolution plates avoid atlas bleed and 2x enlargement. Keep smooth subpixel parallax.
 c.save();c.globalAlpha*=alpha;
 c.drawImage(im,0,0,im.width,im.height,-40-pan*200,-32,1560,640);c.restore();}
// Painted near-ground lip, registered to the gameplay floor in every stage.
function ground(){
 const im=tex.groundInk,a=HoneyVisuals.groundArt[g.stage],x0=g.camera-40,w=1360,tw=920;
 for(let i=Math.floor(x0/tw);i*tw<x0+w;i++)c.drawImage(im,a[0],a[1],a[2]-a[0],a[3]-a[1],i*tw-.5,FLOOR-6,tw+1,156);}
function ambient(front){
 const th=STAGES[g.stage].theme,t=g.time;c.save();
 for(let i=0;i<(front?6:14);i++){const s=i*977%1000/1000;
  let x=(i*173+t*(front?60:24)*(th==='harbor'?-1:1))%1400,y;if(x<0)x+=1400;x-=60;
  if(th==='town'){y=(i*91+t*(30+s*30))%760-40;c.globalAlpha=front?.85:.6;c.save();c.translate(x,y);c.rotate(t*2+i);ellipse(0,0,front?7:5,front?4:3,'#ffc1d6');c.restore();}
  else if(th==='factory'){y=(i*67+t*(50+s*40))%760-40;c.globalAlpha=.5;ellipse(x,y,3,5,'#ffbf49');}
  else if(th==='harbor'){if(front)continue;y=90+i*13%120+Math.sin(t*2+i)*8;c.globalAlpha=.65;line(x-9,y,x,y+5,'#4c5a68',2);line(x,y+5,x+9,y,'#4c5a68',2);}
  else{y=720-((i*83+t*(40+s*30))%760);c.globalAlpha=.7;circle(x,y,front?3:2,'#ffb07a');}}
 c.restore();}

function world(){
 const sh=g.shake*g.shake*24*g.shakeScale,sx=Math.sin(g.time*34)*sh,sy=Math.cos(g.time*27)*sh*.7;  // slow enough to read as a rumble, not per-frame jitter
 c.save();c.translate(sx,sy);background();c.translate(-g.camera,0);ground();
 for(const h of g.hazards)drawHazard(h);
 if(g.ship)drawShip(g.ship);
 for(const p of g.platforms)if(p.x>g.camera-350&&p.x<g.camera+1400)drawPlatform(p);
 for(const p of g.props)if(p.hp>0)drawProp(p);
 for(const p of g.pows)drawPow(p);
 for(const it of g.items)drawItem(it);
 drawSupplies();
 drawBossZones();
 if(g.boss?.started)drawBoss();
 for(const e of g.enemies)drawEnemy(e);
 for(const k of g.corpses)drawCorpse(k);
 for(const b of g.bullets)drawBullet(b);
 drawPlayer();
 drawParticles();
 for(const b of g.blasts)drawBlast(b);
 for(const p of g.popups){const a=1-p.t/(p.big?1.4:.9),y=p.y-p.t*(p.big?50:70);c.save();c.globalAlpha=clamp(a*2,0,1);outlined(p.text,p.x,y,p.big?30:20,p.big?PINK:GOLD,SHADOW);c.restore();}
 c.restore();
 c.save();c.translate(sx,sy);ambient(true);c.restore();
 const v=c.createRadialGradient(640,360,380,640,360,820);v.addColorStop(0,'#00000000');v.addColorStop(1,'#3a1f2a40');c.fillStyle=v;c.fillRect(0,0,1280,720);}
// Harbor boss arena: the big ship the player fights from. Deck at floor level from ship.x to the stage end; the stern
// (left end) faces the boss. Hull, deckhouse, bridge, funnel and mast are drawn behind the actors.
function drawShip(s){
 const x0=s.x,x1=STAGES[g.stage].length+80,t=g.time,sailing=!!g.boss?.started,cx=x1-520;
 // mast and flag
 line(cx+260,FLOOR-440,cx+260,FLOOR-340,'#5b3440',6);line(cx+214,FLOOR-400,cx+306,FLOOR-400,'#5b3440',4);
 const flap=Math.sin(t*7)*7;poly([[cx+260,FLOOR-440],[cx+322,FLOOR-428+flap],[cx+314,FLOOR-418+flap*.6],[cx+260,FLOOR-410]],'#ef7f9e',SHADOW,3);
 // funnel with smoke
 if(sailing)for(let i=0;i<6;i++){const a=(t*.8+i/6)%1;circle(cx+395-a*260,FLOOR-400-a*110,18+a*30,`rgba(90,74,74,${.42*(1-a)})`);}
 box(cx+360,FLOOR-400,74,136,'#ef7f9e',10,SHADOW,3);box(cx+360,FLOOR-400,74,24,'#3a1f2a',8);
 circle(cx+397,FLOOR-318,17,GOLD);ring(cx+397,FLOOR-318,17,SHADOW,3);text('♥',cx+397,FLOOR-311,18,'#ef7f9e','center');
 // bridge: window band, roof, radar
 box(cx+30,FLOOR-340,240,96,'#fff8f5',14,SHADOW,3);
 box(cx+44,FLOOR-322,212,36,'#3f6f8f',9,SHADOW,2);
 for(let i=1;i<5;i++)line(cx+44+i*42.4,FLOOR-322,cx+44+i*42.4,FLOOR-286,SHADOW,2);
 for(let i=0;i<5;i++)line(cx+54+i*42.4,FLOOR-316,cx+66+i*42.4,FLOOR-298,'#bfeaf2',3);
 box(cx+18,FLOOR-352,264,18,'#e2574c',7,SHADOW,3);
 line(cx+90,FLOOR-352,cx+90,FLOOR-384,'#5b3440',4);
 const spin=Math.sin(t*3)*22;box(cx+90-Math.abs(spin),FLOOR-394,Math.abs(spin)*2+4,10,'#d9c6b8',4,SHADOW,2);
 // deckhouse: portholes, door, lifebuoy
 box(cx-20,FLOOR-250,380,246,'#f1e6dc',16,SHADOW,3);box(cx-20,FLOOR-250,380,16,'#d9c6b8',8);
 for(let i=0;i<5;i++){const px=cx+26+i*72;circle(px,FLOOR-186,15,'#5fa9c2');ring(px,FLOOR-186,15,SHADOW,3);ring(px,FLOOR-186,11,'#fff8f5',2);line(px-6,FLOOR-192,px+2,FLOOR-184,'#bfeaf2',3);}
 box(cx+150,FLOOR-128,60,124,'#d9c6b8',10,SHADOW,3);circle(cx+198,FLOOR-66,4,SHADOW);box(cx+162,FLOOR-116,36,26,'#5fa9c2',6,SHADOW,2);
 const lb=cx+60;ring(lb,FLOOR-104,22,'#e2574c',11);ring(lb,FLOOR-104,28,SHADOW,2);ring(lb,FLOOR-104,16,SHADOW,2);
 for(let k=0;k<4;k++){const a=k*Math.PI/2+Math.PI/4;box(lb+Math.cos(a)*22-5,FLOOR-104+Math.sin(a)*22-5,10,10,'#fff8f5',3);}
 // cargo crates by the deckhouse
 cell(tex.items,ITEM.crate,cx-80,FLOOR+58,84,{base:.88});cell(tex.items,ITEM.crate,cx-160,FLOOR+58,84,{base:.88});cell(tex.items,ITEM.crate,cx-120,FLOOR+2,84,{base:.88});
 // railing
 for(let rx=x0+4;rx<x1;rx+=48)box(rx,FLOOR-40,6,34,'#fff8f5',2,SHADOW,1);
 line(x0+4,FLOOR-40,x1,FLOOR-40,'#fff8f5',6);line(x0+4,FLOOR-22,x1,FLOOR-22,'#fff8f5',4);
 // hull: rounded stern, white stripe, portholes, red waterline band, name
 poly([[x0-52,FLOOR-8],[x1,FLOOR-8],[x1,720],[x0+46,720],[x0+14,694],[x0-18,656],[x0-40,612]],'#2f4a6b',SHADOW,3);
 poly([[x0-38,604],[x1,604],[x1,616],[x0-32,616]],'#fff8f5');
 poly([[x0+20,682],[x1,682],[x1,720],[x0+46,720]],'#e2574c');
 for(let hx=x0+210;hx<x1;hx+=96){circle(hx,646,10,'#bfeaf2');ring(hx,646,10,SHADOW,3);}
 text('HONEY-1',x0+300,654,22,'#fff8f5','left',DISPLAY);
 box(x0-52,FLOOR-10,x1-x0+52,14,'#c79a6a',4,SHADOW,2);
 for(let pk=x0-20;pk<x1;pk+=44)line(pk,FLOOR-8,pk,FLOOR+2,'#a77d5a',2);
 // wake churning off the stern while under way
 if(sailing)for(let i=0;i<10;i++){const a=(t*1.3+i*.1)%1;circle(x0-30-a*260,604+Math.sin(i*1.7)*26+a*10,12+a*22,`rgba(233,251,255,${.85*(1-a)})`);}}
// Wavy lit band along a water surface with a few glints drifting at `flow` px/s (the open sea streams past the ship).
const waveY=(x,y0)=>y0+Math.sin(g.time*2.4+x*.045)*3+Math.sin(g.time*1.3+x*.017)*2;
function waterSurface(x0,w,y0,flow){if(w<=0)return;const top=[],bot=[];
 for(let x=x0;x<=x0+w+15;x+=15){const xx=Math.min(x,x0+w);top.push([xx,waveY(xx,y0)]);bot.unshift([xx,waveY(xx,y0)+12]);}
 poly([...top,...bot],'#9fe3ec');for(let i=0;i<top.length-1;i++)line(top[i][0],top[i][1],top[i+1][0],top[i+1][1],'#e9fbff',3);
 for(let i=0;i<Math.floor(w/70);i++){const gx=x0+((i*70+37*i*i-g.time*flow)%w+w)%w,gy=y0+22+(i%3)*24;line(gx,gy,gx+18+(i%2)*10,gy,'#d4f3f7',3);}}
function drawHazard(h){
 if(h.kind==='water'){const grad=c.createLinearGradient(0,h.y,0,720);grad.addColorStop(0,'#5fc0cf');grad.addColorStop(1,'#2f7f9c');c.fillStyle=grad;c.fillRect(h.x,h.y,h.w,h.h);
  waterSurface(h.x,h.w,h.y,h.sea?160:24);
  if(h.sea)for(let i=0;i<Math.floor(h.w/90);i++){const sx=h.x+h.w-(g.time*220+i*90)%h.w;line(sx,h.y+46+(i%3)*30,sx+34,h.y+46+(i%3)*30,'#bfeaf2',3);}}
 else if(h.kind==='honey'||h.kind==='puddle')honeyPuddle(h);
 else if(h.kind==='fire')firePatch(h);
 else{box(h.x,h.y-2,h.w,16,'#5c5566',4,SHADOW,2);for(let j=0;j<4;j++)box(h.x+8+j*23,h.y+2,12,6,'#3d3744',2);
  const on=g.time%3<1.2,warn=g.time%3>2.5;
  if(warn)for(let j=0;j<4;j++)circle(h.x+14+j*23,h.y-6-Math.random()*6,4,'#ffffffaa');
  if(on)for(let j=0;j<6;j++){const yy=h.y-20-((g.time*160+j*30)%120);circle(h.x+h.w/2+Math.sin(g.time*9+j)*24,yy,16+j*2,`rgba(255,235,220,${.75-j*.1})`);}}}
function firePatch(h){const a=clamp(h.life??1,0,1);c.save();c.globalAlpha=a;ellipse(h.x+h.w/2,h.y+8,h.w/2,7,'#5a2a1a88');
 for(let j=0;j<5;j++){const x=h.x+12+j*(h.w-24)/4,f=Math.sin(g.time*14+j*1.7),hh=26+f*8;poly([[x-12,h.y+8],[x,h.y+8-hh],[x+12,h.y+8]],'#ff8a3d',SHADOW,2);poly([[x-6,h.y+8],[x,h.y+8-hh*.55],[x+6,h.y+8]],'#ffe08a');}
 c.restore();}
// Walker stomps shake platforms; crane crates are temporary platforms that blink before vanishing.
function drawPlatform(p){
 if(p.life!=null&&p.life<1.5&&Math.floor(p.life*10)%2)return;
 const sy=p.shake?Math.sin(g.time*70)*5*p.shake:0;c.save();c.translate(0,sy);drawPlatformBody(p);c.restore();}
function drawPlatformBody(p){
 if(p.type==='crate'){cell(tex.items,ITEM.crate,p.x+p.w/2,p.y+58,84,{base:.88});return;}
 const th=STAGES[g.stage].theme;
 if(p.type==='belt'){box(p.x,p.y,p.w,20,'#4d4450',8,SHADOW,3);for(let j=0;j<p.w/26;j++){const xx=p.x+((j*26+g.time*95)%p.w);line(xx,p.y+5,xx+10,p.y+15,'#ffc94d',3);}circle(p.x+10,p.y+10,7,'#8a8090');circle(p.x+p.w-10,p.y+10,7,'#8a8090');return;}
 if(p.type==='boat'){poly([[p.x-14,p.y+10],[p.x+p.w+14,p.y+10],[p.x+p.w-18,p.y+58],[p.x+18,p.y+58]],'#c4573f',SHADOW,3);box(p.x-8,p.y,p.w+16,14,'#e8d3b0',5,SHADOW,3);line(p.x+5,p.y+28,p.x+p.w-5,p.y+28,'#fff3',4);
  // the waterline: water laps over the lower hull, with foam at bow and stern
  const top=[];for(let x=p.x-20;x<=p.x+p.w+20;x+=12)top.push([x,waveY(x,571)]);c.save();c.globalAlpha=.85;poly([...top,[p.x+p.w+20,p.y+64],[p.x-20,p.y+64]],'#5fc0cf');c.restore();
  for(let i=0;i<top.length-1;i++)line(top[i][0],top[i][1],top[i+1][0],top[i+1][1],'#e9fbff',3);
  for(const s of [-1,1]){const fx=s<0?p.x-14:p.x+p.w+14;for(let i=0;i<3;i++)circle(fx+s*(i*9-4),572+Math.sin(g.time*5+i)*2,7-i*1.5,'#f4fdff');}
  return;}
 const col={town:'#79b38d',factory:'#c98b4b',harbor:'#9b6b47',fortress:'#7d7690'}[th];
 box(p.x+4,p.y+8,p.w,p.h,'#3a1f2a33',8);
 if(th==='harbor'||th==='factory'){for(const lx of [p.x+20,p.x+p.w-28])box(lx,p.y+10,10,FLOOR-p.y-10,th==='harbor'?'#7a5236':'#8b8494',3,SHADOW,2);}
 else{line(p.x+24,p.y+18,p.x+24,p.y+60,'#5f7863',8);line(p.x+p.w-24,p.y+18,p.x+p.w-24,p.y+60,'#5f7863',8);}
 box(p.x,p.y,p.w,p.h,col,7,SHADOW,3);line(p.x+8,p.y+5,p.x+p.w-8,p.y+5,'#ffffff66',3);}
function drawProp(p){
 ellipse(p.x,p.y+3,32,6,'#3a1f2a33');
 const shake=p.flash>0?Math.sin(g.time*90)*3:0;
 cell(tex.items,ITEM[p.kind],p.x+shake,p.y,p.kind==='barrel'?84:78,{base:.88,filter:p.flash>0?'brightness(1.8)':undefined});}
function drawPow(p){
 const bob=Math.sin(p.t*5)*3;
 if(p.state==='leave'){c.save();c.globalAlpha=clamp(1-p.t/2.5,0,1);bee(p.x,p.y-30+Math.sin(p.t*14)*4,64,1,-1);c.restore();return;}
 if(p.state==='thanks'){const j=Math.abs(Math.sin(p.t*10))*14;bee(p.x,p.y-j,70);bubble(p.x,p.y-104,'고마워요!',TEAL);return;}
 ellipse(p.x,p.y+3,30,6,'#3a1f2a33');
 // A honeybee freed from a broken cage is no longer tied up: it just waits, bobbing, for the hero to come over.
 if(p.state==='tied'&&p.kind==='cage'){bee(p.x,p.y+2-Math.abs(Math.sin(p.t*4))*6,84);return;}
 if(p.state==='tied'){powTied(p.x,p.y+4,92,Math.sin(p.t*3)*.05);bubble(p.x,p.y-96+bob,'HELP!',HOT);return;}
 // Caged honeybee: one illustrated cage sprite (pow_cage.png, feet line at 403/420 of the image).
 c.save();if(p.flash>0)c.filter='brightness(1.6)';c.translate(p.x,p.y+4);c.rotate(Math.sin(p.t*3)*.015);c.drawImage(tex.cage,-56,-112*403/420,112,112);c.restore();bubble(p.x,p.y-122+bob,'HELP!',HOT);}
// Flat sticker-style honey puddle: wobbly mounded top, thick outline, glossy dabs and slow bubbles.
function honeyPuddle(h){
 const a=h.life!=null?clamp(h.life,0,1):1,x0=h.x,x1=h.x+h.w,top=h.y+9,base=h.y+15,n=Math.max(2,Math.round(h.w/34)),seg=(h.w-12)/n;
 c.save();c.globalAlpha=a;ellipse((x0+x1)/2,base+2,h.w/2+8,5,'#3a1f2a22');
 for(const [dx,r] of [[-9,4],[h.w+8,3.5],[h.w+17,2.4]]){ellipse(x0+dx,base-1,r*1.5,r,'#ffc23d');c.beginPath();c.ellipse(x0+dx,base-1,r*1.5,r,0,0,Math.PI*2);c.strokeStyle='#7a3b22';c.lineWidth=2.5;c.stroke();}
 c.beginPath();c.moveTo(x0+2,base);c.quadraticCurveTo(x0-5,top+5,x0+6,top);
 for(let j=0;j<n;j++){const bump=2.2+(j%3)*.9+Math.sin(g.time*2.2+j*1.7)*.7;c.quadraticCurveTo(x0+6+(j+.5)*seg,top-bump*2,x0+6+(j+1)*seg,top);}
 c.quadraticCurveTo(x1+5,top+5,x1-2,base);c.quadraticCurveTo((x0+x1)/2,base+5,x0+2,base);c.closePath();
 c.fillStyle='#ffc23d';c.fill();c.strokeStyle='#7a3b22';c.lineWidth=3;c.lineJoin='round';c.stroke();
 ellipse((x0+x1)/2,base-1,h.w/2-12,1.8,'#f59a1e');
 for(let j=0;j<n;j++){const cx=x0+6+(j+.5)*seg;ellipse(cx-4,top+1,Math.min(8,seg*.24),1.8,'#fff4c8');
  const p=(g.time*.7+j*.43)%1;if(p<.45){const r=1.5+p*7;c.save();c.globalAlpha*=1-p/.45;circle(cx+seg*.22,top+3-p*6,r,'#ffe08a');ring(cx+seg*.22,top+3-p*6,r,'#7a3b22',1.5);c.restore();}}
 c.restore();}
function bubble(x,y,s,color){c.font=`15px ${DISPLAY}`;const w=c.measureText(s).width+18;box(x-w/2,y-18,w,26,PAPER,13,color,2);poly([[x-6,y+7],[x+6,y+7],[x,y+14]],PAPER);text(s,x,y,15,color,'center',DISPLAY);}
function drawItem(it){
 if(it.life<3&&Math.floor(it.t*10)%2)return;
 const y=it.y-(it.grounded?Math.abs(Math.sin(it.t*4))*4:0);
 ellipse(it.x,it.y+2,22,5,'#3a1f2a33');
 if(it.kind==='support'){c.save();c.shadowColor='#bff8e0';c.shadowBlur=20;bee(it.x,y-4,58);c.restore();return;}
 const size=it.kind==='weapon'?76:62;
 if(it.kind==='weapon'){c.save();c.globalCompositeOperation='lighter';circle(it.x,y-30,34+Math.sin(it.t*6)*4,'#fff3a033');c.restore();}
 cell(tex.items,ITEM[it.kind],it.x,y,size,{base:.88});
 if(it.kind==='weapon')outlined(WEAPONS[it.weapon].letter,it.x+.04*size,y-.26*size+11,30,HOT,SHADOW,'center',5);}
function drawEnemy(e){
 const S=ENEMIES[e.kind].size,t=e.t,walk=e.walk||e.state==='enter',para=e.state==='para';
 if(e.kind!=='flyer'&&!para&&!e.air)ellipse(e.x,e.y+3,S*.4,7,'#3a1f2a2e');
 // The sheet frames carry the walk cycle; keep only a light squash so poses still breathe.
 const bob=walk?Math.abs(Math.sin(t*10))*2:Math.sin(t*3)*1,beat=Math.sin(t*(walk?10:3));
 let sx=1+beat*(walk?.015:.012),sy=1-beat*(walk?.015:.012),rot=walk?beat*.02:0,dx=0;
 if(e.kick>0){sx*=1.08;sy*=.92;dx=e.facing*-6;}
 if(e.warn&&e.kind!=='hopper'){sx*=.96;sy*=1.04;rot+=Math.sin(g.time*40)*.03;}
 if(e.air||e.launch>0){sy*=1.08;sx*=.94;rot=-e.facing*.2;}
 if(e.kind==='shield'&&e.peek>0)rot+=e.facing*.12;
 const filter=e.flash>0?'brightness(1.8)':undefined,flip=e.facing>0,frame=enemyFrame(e);
 if(para)enemySprite('para',e.x,e.y,S,{flip,filter,rot:Math.sin(t*2)*.08,body:e.kind});
 else if(e.kind==='turret'){enemySprite('turret',e.x,e.y,S,{flip,filter,frame,sx:e.kick>0?1.05:1});box(e.x-36,e.y-128,72,8,'#3a1f2a66',4);box(e.x-36,e.y-128,72*e.hp/e.max,8,HOT,4);}
 else enemySprite(e.kind,e.x+dx,e.y-(e.kind==='flyer'?Math.sin(t*6)*4:bob),S,{flip,filter,sx,sy,rot,frame});
 const top=e.y-S*(e.kind==='turret'?1.1:.85);
 if(e.warn&&e.kind!=='hopper')outlined('!',e.x,top-8+Math.sin(g.time*30)*2,28,HOT,SHADOW);
 if(e.startle>0)outlined('!?',e.x,top-12-(.4-e.startle)*30,24,GOLD,SHADOW);}
function drawTurret(e){drawEnemy(e);}
function drawCorpse(k){
 if(k.life<.5&&Math.floor(k.life*20)%2)return;
 const blast=k.style==='explosion',grounded=k.vy===0,s=blast?0:k.settle||0;
 enemySprite(k.kind,k.x,k.y,k.size,{frame:7,flip:k.facing>0,rot:k.rot+k.facing*.25*s,sx:1+.06*s,sy:1-.14*s,filter:blast?'brightness(.5) saturate(.6)':'brightness(1.05) saturate(.85)',alpha:clamp(k.life*2,0,1)});
 if(!blast&&grounded)for(let i=0;i<3;i++){const a=g.time*6+i*2.1;text('★',k.x+Math.cos(a)*22,k.y-k.size*.6+Math.sin(a)*7,12,GOLD,'center');}}
function drawBullet(b){
 if(b.kind==='spray'){c.save();c.globalAlpha=Math.min(1,b.life*2);circle(b.x,b.y,9,'#ffbf49');ring(b.x,b.y,9,'#c47a17',2);circle(b.x-3,b.y-3,3,'#fff4c8');c.restore();return;}
 if(b.kind==='fire'){c.save();c.translate(b.x,b.y);c.rotate(g.time*10);circle(0,0,16,'#ff8a3d');ring(0,0,16,SHADOW,3);circle(-4,-4,7,'#ffe08a');c.restore();c.save();c.globalCompositeOperation='lighter';circle(b.x,b.y,26,'#ff6a2a44');c.restore();return;}
 if(b.kind==='crate'){line(b.x,b.y-200,b.x,b.y,'#7a5a3a',3);cell(tex.items,ITEM.crate,b.x,b.y+56,80,{base:.88});return;}
 if(b.kind==='grenade'){c.save();c.translate(b.x,b.y);c.rotate(b.spin||0);ellipse(0,0,9,11,'#5d7a52');ring(0,0,10,SHADOW,2.5);box(-4,-15,8,6,'#3d3540',2);c.restore();return;}
 if(b.kind==='lob'||b.kind==='honey'){c.save();c.translate(b.x,b.y);c.rotate(g.time*8);box(-12,-14,24,28,'#f3a531',7,SHADOW,3);box(-8,-18,16,6,'#c47a17',3);c.restore();return;}
 if(b.kind==='bomb'){circle(b.x,b.y,10,'#3d3540');ring(b.x,b.y,10,SHADOW,2);line(b.x,b.y-10,b.x+4,b.y-16,GOLD,3);circle(b.x+5,b.y-17,3+Math.random()*2,'#ffdf7a');return;}
 if(b.kind==='shell2'){circle(b.x,b.y,13,'#3d3540');ring(b.x,b.y,13,SHADOW,3);circle(b.x-4,b.y-4,4,'#ffffff55');return;}
 if(b.kind==='wave'){c.save();c.globalAlpha=.85;for(let i=0;i<3;i++){ellipse(b.x-Math.sign(b.vx)*i*16,FLOOR-10-i*4,22-i*5,18-i*4,i?'#efe2cfaa':'#fff8e8');}c.restore();return;}
 if(!b.friendly){const big=b.kind==='shell',r=big?11:8;c.save();c.globalCompositeOperation='lighter';circle(b.x,b.y,r+7,'#ff6f9140');c.restore();circle(b.x,b.y,r,'#ff6f91');ring(b.x,b.y,r,SHADOW,2.5);circle(b.x-2,b.y-2,r*.4,PAPER);return;}
 const len=Math.hypot(b.vx,b.vy)||1,dx=b.vx/len,dy=b.vy/len,col=b.kind==='support'?'#9bf4ce':WEAPONS[b.weapon??0].color;
 if(b.kind==='rocket'){c.save();c.translate(b.x,b.y);c.rotate(Math.atan2(dy,dx));box(-18,-6,32,12,'#7a8a5a',5,SHADOW,2);poly([[14,-6],[24,0],[14,6]],'#d9573f',SHADOW,2);c.globalCompositeOperation='lighter';circle(-24,0,9+Math.random()*4,'#ffab62aa');circle(-22,0,5,'#fff5be');c.restore();return;}
 const trail=b.kind==='sniper'?90:b.kind==='smg'?14:b.kind==='pistol'?12:28;
 c.save();c.globalCompositeOperation='lighter';line(b.x-dx*trail,b.y-dy*trail,b.x,b.y,col+'66',b.kind==='sniper'?9:7);c.restore();
 line(b.x-dx*trail*.6,b.y-dy*trail*.6,b.x,b.y,col,b.kind==='sniper'?3:3.5);circle(b.x,b.y,b.kind==='pistol'?3.5:3,PAPER);}
// Metal Slug style victory loop: jump + fist pump, V-sign, wave (8 frames, top row baseline 1.0, bottom .958).
// Frames 0-3 are a hop: lift follows one smooth arc over them instead of stepping per frame.
function victoryPose(x,y,size,face=1,speed=7){const ff=(g.time*speed)%8,f=Math.floor(ff),lift=ff<3.5?Math.max(0,Math.sin(Math.PI*(ff-.5)/3))*.3*size:0;cell(tex.victory,f,x,y-lift,size,{base:f<4?1:.958,flip:face<0});}
function drawPlayer(){
 if(g.y<-150)return;
 if(g.mode==='celebrate'&&g.dying<=0&&g.grounded){ellipse(g.x,Math.min(FLOOR,g.y)+4,30,6,'#3a1f2a40');victoryPose(g.x,Math.min(FLOOR,g.y),108,g.face);return;}
 const frame=playerFrame(g),blink=g.invincible>0&&g.dying<=0&&Math.floor(g.stageTime*18)%2===0,alpha=blink?.35:1;
 ellipse(g.x,Math.min(FLOOR,g.y)+4,30*(g.grounded?1:.7),6,'#3a1f2a40');
 if(g.dying>0){c.save();c.translate(g.x,g.y-50);c.rotate(-g.face*(1.4-g.dying)*1.2);c.globalAlpha=Math.floor(g.dying*12)%2?.5:1;hero(0,50,108,7,g.face,1,true);c.restore();return;}
 const squash=g.landed>0?1-g.landed*1.2:1;
 c.save();c.translate(g.x,g.y);c.scale(1/Math.max(.85,squash)*(g.landed>0?1.05:1),squash);c.translate(-g.x,-g.y);
 const pose=weaponPose(g);leanShift.x=leanShift.y=0;let handsLayer=null;
 if(g.knife>0)punchPose(alpha);
 else if(g.throwT>0)throwPose(alpha);
 else if(pose.up){const run=pose.sheet==='upRun',im=run?tex.upRun:tex.aim,f=run?pose.sheetFrame:pose.aimFrame,w=im.width/4,h=im.height/(run?3:2);c.save();c.translate(g.x+pose.bx,g.y+pose.by);c.scale(g.face,1);c.globalAlpha=alpha;c.drawImage(im,(f%4)*w,Math.floor(f/4)*h,w,h,-54,-108,108,108);c.restore();}
 else{
  // Front-facing aim on the way up: lean the body back so head and gun rise together; the gun follows the hands.
  const lean=pose.aim.y<0?g.face*pose.aim.y*.18:0,px=g.x+pose.bx,py=g.y+pose.by-38;
  leanShift.x=(pose.x-px)*(Math.cos(lean)-1)-(pose.y-py)*Math.sin(lean);leanShift.y=(pose.x-px)*Math.sin(lean)+(pose.y-py)*(Math.cos(lean)-1);
  // Body now; after the gun, the same frame again from the hands sheet so her fists close over the grip and handguard.
  // Only while the gun is near level: steep aims rotate the gun away from where the drawn fists are.
  const body=hands=>{c.save();c.translate(px,py);c.rotate(lean);c.translate(-px,-py);
   if(frame<4&&g.grounded&&!g.crouch){const rf=Math.floor(g.stageTime*15)%8,im=hands?tex.runHands:g.weapon===PISTOL?tex.runP:tex.run,w=im.width/4,h=im.height/2;c.save();c.translate(g.x+pose.bx,g.y+pose.by);c.scale(g.face,1);c.globalAlpha=alpha;c.drawImage(im,(rf%4)*w,Math.floor(rf/4)*h,w,h,-54,-108,108,108);c.restore();}
   else hero(g.x+pose.bx,g.y+pose.by,108,frame,g.face,alpha,true,hands?tex.bodyHands:null);
   c.restore();};
  body(false);if(g.weapon!==PISTOL&&Math.abs(pose.aim.y)<.35)handsLayer=()=>body(true);}
 if(g.knife>0){const t=1-g.knife/.22;if(t>.2&&t<.8){const k=(t-.2)/.6,fx=g.x+g.face*48,fy=g.y-60;c.save();c.globalAlpha=alpha*(1-k);c.translate(fx,fy);c.rotate(k*.6);
  for(let i=0;i<8;i++){const a=i*Math.PI/4,r0=10+k*14,r1=r0+12+(i%2)*8;line(Math.cos(a)*r0,Math.sin(a)*r0,Math.cos(a)*r1,Math.sin(a)*r1,i%2?GOLD:PAPER,4);}c.restore();}}
 else if(g.throwT<=0){drawGun(alpha,!!handsLayer);handsLayer?.();drawMuzzle();}
 c.restore();
 if(g.y<0)for(let i=0;i<5;i++)circle(g.x+Math.sin(g.time*20+i)*20,Math.max(10,g.y)-i*24,4,'#fff6c8aa');
 if(g.support>0){const bx=g.x-g.face*75,by=g.y-100+Math.sin(g.time*7)*7;c.save();c.shadowColor='#bff8e0';c.shadowBlur=16;bee(bx,by,56,1,-g.face);c.restore();box(bx-26,by-60,52,6,'#3a1f2a55',3);box(bx-26,by-60,52*g.support/22,6,'#7fe0b3',3);}}
const leanShift={x:0,y:0};
// Melee punch (generated/hero_punch.png, 4 frames in a row facing right: wind-up, punch, impact, recover; feet at 88%, body centre at 45%).
function punchPose(alpha){const t=1-g.knife/.22,f=t<.18?0:t<.5?1:t<.78?2:3,im=tex.punch,w=im.width/4,S=126;
 c.save();c.translate(g.x,g.y);c.scale(g.face,1);c.globalAlpha=alpha;c.drawImage(im,f*w,0,w,im.height,-S*.45,-S*.88,S,S);c.restore();}
// Grenade throw on the punch sheet: wind-up with the grenade cocked in the back hand, the arm snaps forward at release, recover.
function throwPose(alpha){const t=1-g.throwT/THROW_TIME,f=t<.32?0:t<.66?1:3,im=tex.punch,w=im.width/4,S=126;
 c.save();c.translate(g.x,g.y);c.scale(g.face,1);c.globalAlpha=alpha;c.drawImage(im,f*w,0,w,im.height,-S*.45,-S*.88,S,S);
 if(f===0){circle(-22,-44,8,'#5d6b3c');ring(-22,-44,8,SHADOW,2.5);box(-25,-56,6,6,GOLD,1);}c.restore();}
function drawGun(alpha,held=false){const p=weaponPose(g);c.save();c.translate(p.x+leanShift.x,p.y+leanShift.y);c.rotate(p.angle);c.scale(p.face,1);c.globalAlpha=alpha;weaponIcon(g.weapon,-p.width*p.grip,-p.height*.48,p.width,p.height);
 // Without the hands layer, small hands sit in front of the receiver/foregrip so the weapon is held rather than pasted over arms.
 if(!held){ellipse(0,p.height*.18,3.2,3.8,'#ffe9df');if(g.weapon!==5)ellipse(Math.min(p.width*.28,19),p.height*.12,3.4,3.5,'#ffe9df');}c.restore();}
function drawMuzzle(){if(g.muzzle<=0)return;const p=weaponPose(g),v=VISUALS[g.lastShotWeapon],f=g.muzzle/.09,cols=['#ffd079','#fff1c0','#beeaff','#ffa662','#ffc5e5','#ffe3a7'],col=cols[g.lastShotWeapon];
 c.save();c.translate(p.mx+leanShift.x,p.my+leanShift.y);c.rotate(Math.atan2(p.aim.y,p.aim.x));c.globalCompositeOperation='lighter';c.globalAlpha=f;circle(4,0,v.flash*.9,col+'55');
 const len=v.flash*(1.2+f);poly([[-3,-4],[len*.45,-v.flash*.45],[len*.36,-3],[len,0],[len*.36,3],[len*.45,v.flash*.45],[-3,4]],col);circle(3,0,5,PAPER);c.restore();}
function drawParticles(){
 for(const p of g.particles){const a=clamp(p.life/p.max,0,1);
  if(p.kind==='bossdebris'){bossDebrisDraw(p,a);continue;}
  if(p.kind==='fish'){fishSprite(p.x,p.y,p.size*2,Math.floor(g.time*8+p.size)%4,p.vx>0?1:-1,{rot:p.rot||0,anchor:.5});continue;}
  if(p.kind==='armor'||p.kind==='casing'||p.kind==='debris'){c.save();c.translate(p.x,p.y);c.rotate(p.rot||p.life*8);c.globalAlpha=Math.min(1,a*2);box(-p.size/2,-p.size/3,p.size,p.size*.62,p.color,p.kind==='casing'?1:3,p.kind==='casing'?null:SHADOW,1.5);c.restore();continue;}
  if(p.kind==='smoke'){c.save();c.globalAlpha=a*.55;circle(p.x,p.y,p.size,p.color);c.restore();continue;}
  if(p.kind==='flash'){c.save();c.globalCompositeOperation='lighter';c.globalAlpha=a;circle(p.x,p.y,p.size*(1.2-a*.4),'#fff6d0');c.restore();continue;}
  c.save();c.globalAlpha=a;circle(p.x,p.y,p.size*(.4+a*.6),p.color);c.restore();}}
function drawBlast(b){
 const t=b.t/b.max,f=Math.min(7,Math.floor(t*8)),size=b.r*2.3;
 c.save();
 if(t<.15){c.globalAlpha=1-t/.15;c.globalCompositeOperation='lighter';circle(b.x,b.y,b.r*.8,'#fff6d0');c.globalCompositeOperation='source-over';}
 c.globalAlpha=1;ring(b.x,b.y,b.r*(.3+t*1.1),`rgba(255,240,200,${.7*(1-t)})`,8*(1-t)+1);
 c.restore();
 cell(tex.boom,f,b.x,b.y,size,{base:.56,rot:(b.x%7)*.1,alpha:t>.85?(1-t)/.15:1});}
// Telegraph: where the locked-in boss attack will hit, shown for the whole windup.
function drawBossZones(){
 const b=g.boss;if(!b?.started||b.dead||b.state!=='windup'||!b.zones)return;
 const p=.5+.5*Math.sin(g.time*18),fill=a=>`rgba(255,60,95,${a})`;
 c.save();
 for(const z of b.zones){
  if(z.kind==='cone'){const r=z.r||1500;c.beginPath();c.moveTo(z.x,z.y);c.arc(z.x,z.y,r,z.angle-z.spread/2,z.angle+z.spread/2);c.closePath();
   const gr=c.createRadialGradient(z.x,z.y,20,z.x,z.y,r);gr.addColorStop(0,fill(.32+.12*p));gr.addColorStop(1,fill(0));c.fillStyle=gr;c.fill();
   for(const e of [-1,1]){const a=z.angle+e*z.spread/2;line(z.x,z.y,z.x+Math.cos(a)*Math.min(r,900),z.y+Math.sin(a)*Math.min(r,900),fill(.55+.3*p),3);}}
  else if(z.kind==='spot'){ellipse(z.x,FLOOR+2,z.r,z.r*.3,fill(.22+.18*p));c.beginPath();c.ellipse(z.x,FLOOR+2,z.r,z.r*.3,0,0,Math.PI*2);c.strokeStyle=fill(.8);c.lineWidth=3;c.setLineDash([10,8]);c.stroke();c.setLineDash([]);
   c.fillStyle=fill(.07+.05*p);c.fillRect(z.x-z.r*.6,0,z.r*1.2,FLOOR);outlined('!',z.x,FLOOR-z.r*.3-14-p*6,26,'#ff5f7e',SHADOW,'center',5);}
  else if(z.kind==='lane'){const x0=z.dir>0?z.x:g.camera-40,x1=z.dir>0?g.camera+1320:z.x;c.fillStyle=fill(.2+.15*p);c.fillRect(x0,FLOOR-28,x1-x0,28);
   for(let x=z.x;z.dir>0?x<x1:x>x0;x+=z.dir*70)outlined(z.dir>0?'▶':'◀',x+z.dir*20,FLOOR-6,20,'#ff5f7e',SHADOW,'center',4);}
  else if(z.kind==='drop'){ellipse(z.x,FLOOR+2,46,12,fill(.25+.15*p));outlined('▼',z.x,FLOOR-70-p*12,30,'#ff5f7e',SHADOW,'center',5);}}
 c.restore();}
function bossSprite(sheet,i,x,y,size,o={}){
 const q=HoneyVisuals.bossArt(sheet,i),a=q.source,d=q.dest,k=size/512;
 c.save();c.translate(x,y);c.rotate(o.rot||0);c.scale(o.sx||1,o.sy||1);if(o.filter)c.filter=o.filter;
 c.drawImage(tex['boss_'+sheet],a[0],a[1],a[2]-a[0],a[3]-a[1],(d[0]-512*(o.cx??.5))*k,(d[1]-512*(o.base??.5))*k,(d[2]-d[0])*k,(d[3]-d[1])*k);c.restore();}
function driveSprite(i,x,y,w,h,rot=0){
 const a=HoneyVisuals.driveArt[i];c.save();c.translate(x,y);c.rotate(rot);
 c.drawImage(tex.driveParts,a[0],a[1],a[2]-a[0],a[3]-a[1],-w/2,-h/2,w,h);c.restore();}
function trackFace(x,y,w,r,distance){
 for(let i=0;i<Math.ceil(r*2/13);i++){
  const v=-r+((-distance%13)+13)%13+i*13;if(v>=r)continue;
  const edge=Math.sqrt(Math.max(0,1-v*v/(r*r)));
  driveSprite(2,x+4*(1-edge),y+v,w*(.55+.45*edge),9);}}
function trackSidePoint(distance){
 const p=HoneyVisuals.treadPoint(distance,200,40),t=clamp(p.x/200,0,1);
 return {x:p.x*.72,y:p.y*(1-.24*t)-p.x*.09,visible:p.y>0||p.x>200};}
function drawBossTracks(b,r){
 // The choco tank sheet paints its own treads and fish wheels; only the cannon still gets the animated overlay.
 if(b.type!=='cannon')return;
 const d=HoneyVisuals.bossArt(r.sheet,0).dest,w=d[2]-d[0],h=d[3]-d[1];
 const distance=(b.track||0)*(b.flip?-1:1)/r.k*400/w;
 c.save();c.translate(b.x+(d[0]-256)*r.k,b.y+(d[1]-512*r.base)*r.k);c.scale(w*r.k/400,h*r.k/360);
 const cy=b.type==='cannon'?310:306,total=400+80*Math.PI;
 // Painted shoes follow the visible lower/rear belt; upper belt remains behind the armor.
 for(let i=0;i<40;i++){
  const t=i*total/40+distance/.72,p=trackSidePoint(t);if(!p.visible)continue;
  const q=trackSidePoint(t+.2);driveSprite(1,224+p.x,cy+p.y,14,8,Math.atan2(q.y-p.y,q.x-p.x));}
 trackFace(36,cy-12,40,34,distance);trackFace(164,cy,58,43,distance);
 const wheels=[[0,0,29,40],[56,-6,25,36],[102,-12,23,33],[145,-18,20,30]];
 for(const [x,y,rx,ry] of wheels){c.save();c.translate(224+x,cy+y);c.scale(rx,ry);c.rotate(distance/ry);driveSprite(0,0,0,2,2);c.restore();}
 c.restore();}
function drawBossBody(b,r,flash){
 c.save();if(b.dead){c.translate(b.x,b.y);c.scale(1,1-.32*clamp((b.sink||0)/.35,0,1));c.translate(-b.x,-b.y);}
 bossSprite(r.sheet,b.phase===2||b.dead?1:0,b.x,b.y,512*r.k,{base:r.base,filter:flash});
 c.save();if(flash)c.filter=flash;drawBossTracks(b,r);c.restore();c.restore();}
function drawStoryTank(x,y,travel){
 const r={...BOSS_RIG.tank,k:.94},S=512*r.k,b={type:'tank',x,y,track:travel,flip:false,phase:1,dead:false};
 drawBossBody(b,r);
 for(const name of ['B','A']){const P=r[name];bossSprite('tank',name==='A'?2:4,x+(P.u-.5)*S,y+(P.v-r.base)*S,S*P.ps,{cx:P.pu,base:P.pv,rot:P.rot||0});}}
function drawBoss(){
 const b=g.boss,r=BOSS_RIG[b.type],S=512*r.k,im=tex['boss_'+r.sheet],k=b.sink||0,flash=b.flash>0?'brightness(1.18)':undefined;
 const pose=HoneyVisuals.bossPose(b),{x:ox,y:oy,rot,sx,sy}=pose;let alpha=1;
 if(b.dead&&b.burst)alpha=Math.max(0,1-(CELEBRATE_BURST-g.celebrate)/1.2);
 if(alpha<=0)return;
 const h=g.bossBox();if(b.type!=='boat'&&!b.air)ellipse(b.x,FLOOR+4,h.w*.48,14,'#3a1f2a40');else if(b.air)ellipse(b.x,FLOOR+4,h.w*.3,9,'#3a1f2a30');
 const mir=b.flip?-1:1;  // left-side bosses are drawn mirrored; rig points inside are raw
 c.save();c.globalAlpha*=alpha;c.translate(b.x+ox*mir,b.y+oy);c.rotate(rot*mir);c.scale(sx*mir,sy);c.translate(-b.x,-b.y);
 // hatch pops out of the body while open
 const hc=b.hatch;if(hc&&hc.open>0&&!b.dead){const P=r.H,o=g.bossBodyPt(P.u,P.v,true),pop=clamp(Math.min((1.6-hc.open)/.25,hc.open/.25),0,1);bossSprite(r.sheet,6,o.x,o.y+(1-pop)*40,S*P.ps,{cx:P.pu,base:P.pv,sy:.4+.6*pop});}
 drawBossBody(b,r,flash);
 if(b.phase===2&&!b.dead){const o=g.bossBodyPt(r.core[0],r.core[1],true),pulse=.5+.5*Math.sin(g.time*8);c.save();c.globalCompositeOperation='lighter';circle(o.x,o.y,34+pulse*14,`rgba(255,190,70,${.25+.25*pulse})`);circle(o.x,o.y,16+pulse*6,'#fff2b099');c.restore();
  for(let i=0;i<4;i++){const a=(b.t*.8+i*.25)%1;circle(o.x+30+i*14,o.y-60-a*110,10+a*18,`rgba(90,74,74,${.45*(1-a)})`);}}
 for(const name of ['B','A']){if(b.dead&&k>.35)continue;const P=r[name],p=b.parts[name],pv=g.bossBodyPt(P.u,P.v,true);
  let pr=(p.ang||0)+(P.rot||0);const px=pv.x+p.recoil*6,py=pv.y;
  if(!p.dead){if(b.type==='boat'&&name==='B')pr+=Math.sin(b.t*1.5)*.08+(b.state==='attack'&&b.pattern===1?-.2:0);
   if(b.type==='cannon'&&name==='A')pr+=(b.state==='windup'&&b.pattern===0?-.12:0)+Math.sin(b.t*2)*.02;
   if(b.type==='king'&&name==='B')pr+=b.state==='windup'&&b.pattern===1?-.15:0;}
  bossSprite(r.sheet,name==='A'?(p.dead?3:2):(p.dead?5:4),px,py,S*P.ps,{cx:P.pu,base:P.pv,rot:pr,filter:p.flash>0?'brightness(1.25)':flash});
  if(!p.dead&&p.recoil>.6){const m=g.bossMuzzle(name,true);c.save();c.globalCompositeOperation='lighter';circle(m.x,m.y,26*p.recoil,'#ffdf9b99');circle(m.x,m.y,12*p.recoil,'#fff6da');c.restore();}
  if(p.dead&&!b.dead){const m=g.bossPartBox(name,true);for(let i=0;i<2;i++){const a=(b.t*.9+i*.5)%1;circle(m.x+m.w*.5+i*12,m.y+m.h*.3-a*90,8+a*14,`rgba(80,64,64,${.5*(1-a)})`);}}}
 c.restore();
 if(b.type==='boat'){c.save();c.globalAlpha=.9;for(let i=0;i<12;i++)line(b.x-300+i*52,FLOOR+6+Math.sin(g.time*3+i)*4,b.x-266+i*52,FLOOR+6+Math.sin(g.time*3+i+1)*4,'#e9fbff',4);c.restore();}
 if(b.warn&&!b.dead){const m=g.bossMouth(),lbl={king:['기관포 연사!','미사일 폭격!','점프 압살!'],cannon:['꿀 박격포!','꿀 화염방사!','돌진!'],boat:['함포 사격!','크레인 투하!','상륙 부대!'],tank:['주포 발사!','개틀링 난사!','전진 압박!']}[b.type][b.pattern];
  bubble(clamp(m.x,g.camera+120,g.camera+1160),Math.max(150,h.y-30),lbl,HOT);
  c.save();c.globalCompositeOperation='lighter';circle(m.x,m.y,18+Math.sin(g.time*6)*4,'#ff6f9188');c.restore();}}
// Supply bees from the boss hatch: a honeybee carrying a crate that drops an item near the player.
function drawSupplies(){for(const s of g.supplies||[]){const flip=s.state==='leave'?1:(s.tx<s.x?1:-1),bob=Math.sin(s.t*10)*3;
 if(!s.dropped){line(s.x,s.y+bob+4,s.x,s.y+bob+22,'#b0814f',3);cell(tex.items,ITEM[s.item]??ITEM.crate,s.x,s.y+bob+56,46,{base:.88});}
 bee(s.x,s.y+bob,62,1,flip);}}
function bossDebrisDraw(p,a){const im=tex['boss_'+p.sheet];if(!im)return;const cw=im.width/4,ch=im.height/2,q=p.chunk%4;
 c.save();c.translate(p.x,p.y);c.rotate(p.rot||0);c.globalAlpha=Math.min(1,a*2);c.drawImage(im,3*cw+(q%2)*cw/2,ch+Math.floor(q/2)*ch/2,cw/2,ch/2,-p.size,-p.size,p.size*2,p.size*2);c.restore();}

// ---------- HUD ----------
function hud(){
 // Player card: bottom-left (lifted above the arms card when the touch pad owns that corner)
 const touchUI=touchMode&&settings.touch!=='off';c.save();if(touchUI)c.translate(470-14,538-12);else c.translate(0,608-12);
 box(14,12,340,100,'#fff8f5ee',22,'#f2c4cf',2);
 circle(62,62,38,PINK);ring(62,62,38,SHADOW,3);c.drawImage(tex.profileRound,28,28,68,68); // pre-cut round badge (Godot's canvas shim can only clip rectangles)
 box(108,22,40,22,HOT,11);text('1P',128,39,15,PAPER,'center',DISPLAY);
 text(pad7(g.score),158,42,26,INK,'left',DISPLAY);
 const maxHp=g.dif.hp;for(let i=0;i<maxHp;i++)heart(118+i*26,56,18,i<g.hp?HOT:'#f3dfe3');
 box(270,58,72,26,'#5b3440dd',13);text('LIFE',284,76,12,PINK,'left',DISPLAY);text('×'+Math.max(0,g.lives),335,77,16,PAPER,'right',DISPLAY);
 box(108,88,234,6,'#f3dfe3',3);if(g.combo>1)box(108,88,234*clamp(g.comboTimer/2.8,0,1),6,GOLD,3);
 c.restore();
 // Arms card: bottom centre
 const pop=g.weaponPop>0?1+Math.sin(g.weaponPop*20)*.04*g.weaponPop:1;
 c.save();c.translate(640,677);c.scale(pop,pop);c.translate(-170,-31);box(0,0,340,62,'#fff8f5ee',20,'#f2c4cf',2);
 box(10,8,104,46,PINK,14);weaponFit(g.weapon,16,12,92,38);
 text('ARMS',126,24,12,'#a8707f','left',DISPLAY);text(g.ammo[g.weapon]<0?'∞':String(g.ammo[g.weapon]),126,50,24,g.ammo[g.weapon]>0&&g.ammo[g.weapon]<20?HOT:INK,'left',DISPLAY);
 text('BOMB',214,24,12,'#a8707f','left',DISPLAY);text(String(g.grenades),214,50,24,g.grenades?INK:HOT,'left',DISPLAY);
 if(g.unlocked.length>1){box(282,14,48,34,'#5b3440dd',12);text('Q',306,37,16,PAPER,'center',DISPLAY);text('교체',306,58,10,'#a8707f','center');}
 c.restore();
 // Hi-score and pause
 box(970,12,212,58,'#fff8f5ee',20,'#f2c4cf',2);text('HI-SCORE',990,34,12,'#a8707f','left',DISPLAY);text(pad7(Math.max(g.best,g.score)),1166,58,22,INK,'right',DISPLAY);
 circle(1229,51,26,'#fff8f5ee');ring(1229,51,26,'#f2c4cf',2);box(1219,40,7,22,INK,2);box(1232,40,7,22,INK,2);
 // Rescued tally: bottom-right (top-left when the touch buttons own that corner)
 if(g.stageRescued>0){const tw=46+g.stageRescued*36,tx=touchUI?14:1266-tw,ty=touchUI?12:668;
  box(tx,ty,tw,40,'#fff8f5dd',20);text('POW',tx+12,ty+26,12,'#a8707f','left',DISPLAY);for(let i=0;i<g.stageRescued;i++)bee(tx+62+i*36,ty+32,32);}
 // Combo
 if(g.combo>=2){const s=1+Math.max(0,g.comboTimer-2.4)*.8;c.save();c.translate(1250,210);c.scale(s,s);outlined(String(g.combo),0,0,46,GOLD,SHADOW,'right');outlined('COMBO',0,26,18,PAPER,SHADOW,'right');c.restore();}
 if(g.lock&&g.lock.zone!=null&&Math.floor(g.time*2)%2===0){outlined('◀',30,380,30,'#ffffffaa',SHADOW);outlined('▶',1250,380,30,'#ffffffaa',SHADOW);}
 if(ui.goT>0&&Math.floor(ui.goT*4)%2===0)outlined('GO! ▶',1150,330+Math.sin(g.time*8)*6,48,GOLD,SHADOW);
 if(touchUI)touchControls();}
function touchControls(){
 c.save();c.globalAlpha=.85;circle(PAD.x,PAD.y,PAD.r,'#fff8f544');ring(PAD.x,PAD.y,PAD.r,'#ffffff99',3);
 const held=heldSet();const dir={left:[-1,0],right:[1,0],up:[0,-1],down:[0,1]};
 for(const [k,[dx,dy]] of Object.entries(dir))outlined({left:'◀',right:'▶',up:'▲',down:'▼'}[k],PAD.x+dx*46,PAD.y+dy*46+8,22,held.has(k)?HOT:PAPER,SHADOW);
 circle(PAD.x,PAD.y,22,'#ffd8d9cc');
 for(const b of BTN){circle(b.x,b.y+4,b.r,'#3a1f2a33');circle(b.x,b.y,b.r,held.has(b.a)?HOT:'#fff8f5dd');ring(b.x,b.y,b.r,'#f2c4cf',3);text(b.label,b.x,b.y+5,b.r>45?18:13,INK,'center',DISPLAY);}
 text('×'+g.grenades,1072,505,13,PAPER,'center',DISPLAY);c.restore();}

// ---------- cinematics ----------
function cinematics(){
 if(g.mode==='play'&&g.intro>0){const t=2.6-g.intro,o=g.intro<.4?g.intro/.4:1;c.save();c.globalAlpha=o;
  const s1=back3(t/.35),s2=back3((t-.35)/.35);
  box(0,250,1280,150,'#3a1f2acc',0);for(let i=0;i<26;i++)box(((i*64+g.time*120)%1400)-80,250,32,6,PINK,0);for(let i=0;i<26;i++)box(((i*64-g.time*120)%1400+1400)%1400-80,394,32,6,PINK,0);
  outlined(`MISSION ${g.stage+1}`,-400+1040*s1,335,74,PINK,SHADOW,'center',10);
  if(t>.35)outlined('START!',1680-680*s2,372,46,GOLD,SHADOW,'center',8);
  c.restore();}
 const b=g.boss;
 if(b?.started&&b.state==='enter'&&!b.dead){const on=Math.floor(g.time*5)%2===0;c.save();c.fillStyle='#ff4d6d22';c.fillRect(0,0,1280,720);
  box(0,240,1280,130,'#3a1f2add',0);for(let i=0;i<20;i++)poly([[((i*90+g.time*200)%1500)-120,240],[((i*90+g.time*200)%1500)-80,240],[((i*90+g.time*200)%1500)-120,280],[((i*90+g.time*200)%1500)-160,280]],'#ffc94d');
  if(on)outlined('WARNING!!',640,340,76,'#ff6f91',SHADOW,'center',10);outlined(BOSSES[b.type].title+' 접근 중',640,362,18,PAPER,SHADOW,'center',4);c.restore();}
 if(g.callout&&(g.mode==='play'||g.mode==='celebrate')&&!(b?.state==='enter')){const t=g.callout.t,s=back3(t/.25),o=t>1.3?Math.max(0,1-(t-1.3)/.3):1;
  c.save();c.globalAlpha=o;c.translate(640,g.mode==='celebrate'?320:236);c.scale(s,s);c.rotate(-.03);
  const big=g.callout.text.length>14?50:62;outlined(g.callout.text,0,0,big,g.mode==='celebrate'?PINK:GOLD,SHADOW,'center',9);
  if(g.callout.sub)outlined(g.callout.sub,0,34,20,PAPER,SHADOW,'center',5);c.restore();}
 // Big outlined banner, no panel: headline pops in, the part after " · " sits under it; enemy alerts in red-pink.
 if(g.mode==='play'&&g.bannerTime>0&&!g.intro){const [head,sub]=g.banner.split(' · '),alarm=/적|부대/.test(head),s=back3((g.bannerMax-g.bannerTime)/.3);
  c.save();c.globalAlpha=Math.min(1,g.bannerTime*3);c.translate(640,176);c.scale(s,s);
  outlined(head,0,0,40,alarm?'#ff6f91':GOLD,SHADOW,'center',9);if(sub)outlined(sub,0,32,20,PAPER,SHADOW,'center',5);c.restore();}
 if(g.mode==='celebrate'){if(g.celebrate<.8){c.save();c.globalAlpha=Math.min(1,(.8-g.celebrate)*2);c.fillStyle='#fff8f5';c.fillRect(0,0,1280,720);c.restore();}}}

// ---------- screens ----------
function panelCard(x,y,w,h){box(x+6,y+10,w,h,'#3a1f2a33',30);box(x,y,w,h,PAPER,30,'#f2c4cf',3);}
function menuList(items,x,y,w,gap=58,size=24){
 ui.hits=[];
 items.forEach((it,i)=>{const sel=i===ui.index,yy=y+i*gap,bob=sel?Math.sin(g.time*8)*2:0;
  ui.hits.push({x,y:yy-gap*.4,w,h:gap*.82,i});
  if(sel){box(x+4,yy-gap*.38+6,w,gap*.78,'#e7a7b866',gap*.39);box(x,yy-gap*.38,w,gap*.78,PINK,gap*.39,HOT,3);outlined('▶',x+26+bob,yy+size*.36,size*.8,HOT,PAPER,'center',4);}
  const color=it.locked?'#c9b1b7':INK;
  text(it.label+(it.locked?'  🔒':''),x+52,yy+size*.36,size,color,'left',DISPLAY);
  if(it.value!=null){const font=it.value.includes('■')?BODY:DISPLAY,vs=size*.9,right=x+w-26,base=yy+size*.36;c.font=`${vs}px ${font}`;
   // Value sits in a chip so it reads clearly against the paper panel; adjustable rows always show their ◀ ▶ arrows.
   const vw=c.measureText(it.value).width,aw=it.adjust?c.measureText('◀  ').width:0,cx=right-aw-vw-12;
   box(cx,yy-vs*.72,vw+24,vs*1.44,sel?HOT:'#f9cdd8',vs*.72,sel?SHADOW:'#e89bb0',2);
   text(it.value,right-aw,base,vs,sel?PAPER:INK,'right',font);
   if(it.adjust){text('◀',cx-6,base,vs*.8,sel?HOT:'#c27088','right',DISPLAY);text('▶',right,base,vs*.8,sel?HOT:'#c27088','right',DISPLAY);}
   // Pointer targets for adjustable rows (registered even when not selected, so a single tap works on touch):
   // ◀ lowers, ▶ raises, and tapping a volume bar sets that level directly. They go first so they win over the row.
   if(it.adjust){c.font=`${vs}px ${font}`;const full=c.measureText('◀  '+it.value+'  ▶').width,arrow=c.measureText('◀  ').width,bar=c.measureText(it.value).width,h=gap*.82,top=yy-gap*.4;
    ui.hits.unshift({x:right-full-10,y:top,w:arrow+10,h,i,dir:-1},{x:right-arrow,y:top,w:arrow+16,h,i,dir:1});
    if(it.setTo)ui.hits.unshift({x:right-arrow-bar,y:top,w:bar,h,i,bar:[right-arrow-bar,right-arrow]});}}});}
// Logo intro (plays once each time the title is entered, then holds still): the rounded (Jua) letters of
// "허니츄러스와" drop in one by one and settle upright on one baseline, then the "과메기단의 습격" warning plate slams down
// with a shake (the plate only, the title stays put) and a debris burst, and finally the honeybee flies in.
function logoLetters(s,x,y,size,depth,gap,start,t){c.font=`${size}px ${BODY}`;const out=[];let cx=x;
 for(const ch of s){const w=c.measureText(ch).width,i=out.length,p=clamp((t-start-i*.09)/.42,0,1),side=i%2?1:-1;
  out.push({ch,w,size,depth,a:clamp(p*5,0,1),x:cx+w/2,y:y-(1-back3(p))*120,r:(1-ease(p))*side*.12});cx+=w+gap;}
 return out;}
function drawLetters(L,fill,rim){L=L.filter(l=>l.a>0);
 const each=f=>{for(const l of L){c.save();c.globalAlpha*=l.a;c.translate(l.x,l.y);c.rotate(l.r);c.font=`${l.size}px ${BODY}`;f(l);c.restore();}};
 c.textAlign='center';c.textBaseline='alphabetic';c.lineJoin='round';
 // Passes run across all letters so a neighbour's rim never covers another letter's face.
 each(l=>{c.strokeStyle=PAPER;c.lineWidth=l.size*.34;for(let d=l.depth;d>=0;d-=3)c.strokeText(l.ch,0,d);});
 each(l=>{c.strokeStyle=SHADOW;c.lineWidth=l.size*.16;c.fillStyle=SHADOW;for(let d=l.depth;d>0;d-=3){c.strokeText(l.ch,0,d);c.fillText(l.ch,0,d);}c.strokeText(l.ch,0,0);});
 each(l=>{c.fillStyle=rim;c.fillText(l.ch,0,0);c.fillStyle=fill;c.fillText(l.ch,0,l.size*.05);});}
function sparkle(x,y,r,color){poly([[x,y-r],[x+r*.28,y-r*.28],[x+r,y],[x+r*.28,y+r*.28],[x,y+r],[x-r*.28,y+r*.28],[x-r,y],[x-r*.28,y-r*.28]],color);}
// Yellow/black caution tape; stripe corners are clamped to the tape so nothing pokes out of its ends.
function hazardTape(x,y,w,h){box(x,y,w,h,GOLD,4);
 for(let sx=x;sx<x+w+h;sx+=28)poly([[sx,y],[sx+14,y],[sx+14-h,y+h],[sx-h,y+h]].map(([px,py])=>[clamp(px,x,x+w),py]),SHADOW);
 box(x,y,w,h,'#ffffff00',4,SHADOW,3);}
// "과메기단의 습격" as a red warning plate with torn ends over crossed caution tape; h = seconds since it started to fall;
// its right end lines up with the end of "와".
function raidBadge(h,right){if(h<=0)return;
 const s1='과메기단의 ',s2='습격';c.font=`36px ${BODY}`;const t1=c.measureText(s1).width;c.font=`46px ${BODY}`;const t2=c.measureText(s2).width;
 const W=100+t1+t2,x0=right-W,y0=44,y1=110,x1=right,cx=x0+W/2,cy=(y0+y1)/2,p=clamp(h/.18,0,1),sc=2.4-1.4*p*p,imp=h-.18;
 c.save();c.translate(cx,cy);c.rotate(.06);
 if(imp>0&&imp<.45){const k=imp/.45;c.save();c.globalAlpha*=1-k;
  for(let i=0;i<14;i++){const a=i/14*Math.PI*2,r0=W*.42+k*70,r1=r0+12+46*(1-k);
   poly([[Math.cos(a-.05)*r0,Math.sin(a-.05)*r0*.45],[Math.cos(a)*r1,Math.sin(a)*r1*.45],[Math.cos(a+.05)*r0,Math.sin(a+.05)*r0*.45]],i%2?GOLD:PAPER);}
  c.restore();}
 c.globalAlpha*=p;c.scale(sc,sc);c.translate(-cx,-cy);
 c.save();c.translate(cx,cy+6);c.rotate(-.1);hazardTape(-W/2-46,-12,W+92,24);c.restore();
 const L=[[x0,y0],[x0+12,y0+16],[x0-2,y0+33],[x0+12,y0+50],[x0,y1]],pts=[...L,...[...L].reverse().map(([x,y])=>[x0+x1-x,y])];
 poly(pts.map(([x,y])=>[x+6,y+8]),'#3a1f2a55');poly(pts,'#d8344c',SHADOW,5);box(x0+18,y0+7,W-36,6,'#ff6b80',3);
 const tx=x0+42,ty=cy+2;poly([[tx,ty-20],[tx+21,ty+15],[tx-21,ty+15]],GOLD,SHADOW,4);text('!',tx,ty+12,24,SHADOW,'center',DISPLAY);
 outlined(s1,x0+74,cy+13,36,PAPER,SHADOW,'left',8,BODY);outlined(s2,x0+74+t1,cy+16,46,GOLD,SHADOW,'left',9,BODY);
 c.restore();}
function titleLogo(s){const imp=s-1.13,shake=imp>0&&imp<.35?1-imp/.35:0;
 c.save();
 const big=logoLetters('허니츄러스',0,8,112,14,0,0,s),last=big[big.length-1],wa=logoLetters('와',last.x+last.w/2+2,8,80,10,0,.45,s);
 drawLetters([...big,...wa],HOT,'#ffd0dc');
 const w1=wa[0].x+wa[0].w/2;
 c.save();c.translate(Math.sin(s*95)*6*shake,Math.cos(s*80)*4*shake);raidBadge(s-.95,w1);c.restore();
 for(let i=0;i<3;i++){const k=back3((s-1.2-i*.12)/.3);if(k>0)sparkle([w1+28,w1-30,-16][i],[-8,-96,-72][i],[12,9,10][i]*k,i===1?PAPER:GOLD);}
 const bp=ease((s-1.4)/.6);if(bp>0)bee(w1+30+(1-bp)*560,-58+Math.sin(s*3)*4*bp,76);
 c.restore();}
function title(){
 const t=g.time;
 // Layered menu scene: clean background, one jealous gwamegi sneaking a look from behind the tree trunk, Honey Churros hugging a honeybee.
 const zoom=1.02+Math.sin(t*.24)*.006;c.save();c.translate(640,360);c.scale(zoom,zoom);c.translate(-640,-360);
 c.drawImage(tex.menuBg,0,0,1280,720);
 // It slides out to glare, then ducks back; the complete opaque tree is drawn over the character against a tree-free meadow.
 const out=clamp(Math.sin(t*.8)*1.8+.4,0,1),s=200;c.drawImage(tex.menuFish,1028+142*(1-out),488-.81*s+Math.sin(t*3)*1.5,s,s);
 c.drawImage(tex.menuTree,0,0,1280,720);
 const breathe=Math.sin(t*2)*.012;c.save();c.translate(850,724);c.scale(1-breathe*.4,1+breathe);c.drawImage(tex.menuGirl,-250,-476,500,500);c.restore();
 bee(860,308-breathe*470+Math.sin(t*3)*2,96);
 c.restore();
 for(let i=0;i<8;i++){const x=(i*211+t*12)%1400-60,y=(i*97+t*18)%780-40;c.save();c.globalAlpha=.4;c.translate(x,y);c.rotate(t*.5+i);ellipse(0,0,7,4,'#ffc1d6');c.restore();}
 const small=!['main','stages'].includes(ui.screen);c.save();c.translate(62,small?120:180);c.scale(small?.62:1,small?.62:1);
 titleLogo(t-ui.titleAt);c.restore();
 if(ui.screen==='main'){panelCard(48,300,440,324);menuList(menu(),68,346,400,56,24);}
 else if(ui.screen==='stages'){panelCard(48,280,520,410);text('스테이지 선택',78,322,20,'#a8707f','left',DISPLAY);menuList(menu(),68,370,480,58,22);}
 else if(ui.screen==='settings'){panelCard(48,226,640,474);text('설정',78,266,22,'#a8707f','left',DISPLAY);menuList(menu(),68,312,600,42,20);}
 else if(ui.screen==='howto')howto();
 else if(ui.screen==='records')recordsScreen();
 text('v1.0',1250,24,13,'#c9a2ad','right',DISPLAY);}
function keycap(k,x,y,w=40){box(x,y-24,w,32,PAPER,8,'#c9a2ad',2);box(x,y+4,w,4,'#c9a2ad',2);text(k,x+w/2,y-1,15,INK,'center',DISPLAY);}
function howto(){
 panelCard(48,230,1184,460);outlined('조작 방법',90,288,30,INK,PAPER,'left',6);
 const rows=[[['←','→'],'이동'],[['↑','↓'],'조준 (위 · 공중에서 아래)'],[['Z'],'사격 · 적에게 붙으면 나이프'],[['X','Space'],'점프 (길게 누르면 높이)'],[['C'],'수류탄'],[['Q'],'무기 교체'],[['Esc'],'일시정지'],[['M'],'소리 켜기/끄기']];
 rows.forEach(([keys,label],i)=>{const x=90+(i>=4?560:0),y=350+(i%4)*62;let kx=x;for(const k of keys){const w=k.length>2?78:42;keycap(k,kx,y,w);kx+=w+8;}text(label,x+150,y,19,INK);});
 box(90,600,1100,62,PINK,18);text('TIP  철창을 쏴서 부수고 허니비에게 다가가면 무기와 보급품을 줘요. 무기를 다 쓰면 권총으로 돌아가요.',112,638,17,INK);
 text('게임패드 지원: A 점프 · X 사격 · B 수류탄 · Y 교체 · START 일시정지',90,684,14,'#a8707f');
 ui.hits=[];}
function recordsScreen(){
 panelCard(48,230,700,460);outlined('명예의 전당',90,288,30,INK,PAPER,'left',6);
 if(!records.length)text('아직 기록이 없어요. 첫 기록을 세워 보세요!',90,360,20,'#a8707f');
 records.forEach((r,i)=>{const y=350+i*60;box(80,y-34,640,50,i===0?PINK:'#fff1f3',16);outlined(String(i+1),112,y,28,i===0?HOT:INK,PAPER,'center',5);text(pad7(r.score),150,y,26,INK,'left',DISPLAY);
  text((r.clear?'ALL CLEAR':'MISSION '+r.stage)+' · '+(DIFFICULTY[r.dif]?.label||''),390,y-2,16,'#a8707f');text(r.date||'',700,y-2,14,'#c9a2ad','right');});
 ui.hits=[];}
function overlayDim(a=.55){c.fillStyle=`rgba(58,31,42,${a})`;c.fillRect(0,0,1280,720);}
function pauseScreen(){
 overlayDim(.6);
 if(ui.screen==='settings'){panelCard(300,110,680,520);outlined('설정',640,170,34,INK,PAPER,'center',6);menuList(menu(),330,230,620,48,20);return;}
 panelCard(390,150,500,420);outlined('PAUSE',640,222,52,HOT,SHADOW,'center',8);text(`MISSION ${g.stage+1} · ${STAGES[g.stage].name}`,640,256,16,'#a8707f','center');
 menuList(menu(),420,312,440,62,24);
 text('R 미션 재시작 · M 소리',640,548,14,'#a8707f','center');}
function briefing(){
 const t=g.briefTime||0,S=STAGES[g.stage],L=LEVELS[g.stage];
 c.fillStyle='#3a1f2a';c.fillRect(0,0,1280,720);
 c.save();c.globalAlpha=.85;bgPanel(g.stage,-((t*12)%60),0,1400,720,.7);c.restore();
 overlayDim(.45);
 const s=ease(t/.5);
 c.save();c.translate(-300*(1-s),0);box(0,160,760,400,'#fff8f5f2',0);box(0,160,16,400,HOT,0);
 outlined(`MISSION ${g.stage+1}`,60,250,80,HOT,SHADOW,'left',12);outlined(S.name,64,316,40,INK,PAPER,'left',6);text(S.sub,66,356,19,'#7b5a63');
 S.zones.forEach((z,i)=>{const y=400+i*26;circle(76,y-6,9,PINK);text(String(i+1),76,y,12,INK,'center',DISPLAY);text(z,96,y,17,INK);});
 text('TARGET',440,410,13,'#a8707f','left',DISPLAY);text(BOSSES[L.boss].name,440,438,22,INK,'left',DISPLAY);text(BOSSES[L.boss].title,440,462,15,'#a8707f');
 text('난이도 '+g.dif.label,440,500,15,'#a8707f');
 text('NEW ARMS · '+WEAPON_UNLOCK[g.stage].map(i=>WEAPONS[i].name).join(' · '),440,530,15,HOT,'left',DISPLAY);c.restore();
 cell(tex.briefing,4+g.stage,1010,650+Math.sin(t*2)*4,440,{base:.93});
 if(t>.8&&Math.floor(t*2.5)%2===0)outlined('ENTER로 출격!',1050,690,26,PAPER,SHADOW,'center',6);
 box(0,700,1280*clamp(t/6,0,1),20,'#ffd8d944',0);}
function tallyEnd(){return .6+g.result.rows.length*.7+1.2;}
function resultScreen(){
 const R=g.result,t=R.t;
 c.fillStyle='#fff3f5';c.fillRect(0,0,1280,720);c.save();c.globalAlpha=.3;bgPanel(g.stage,0,0,1280,720,.7);c.restore();
 for(let i=0;i<14;i++){const x=(i*211+g.time*30)%1400-60,y=(i*97+g.time*40)%780-40;c.save();c.globalAlpha=.5;c.translate(x,y);c.rotate(g.time+i);ellipse(0,0,8,5,'#ffc1d6');c.restore();}
 outlined(`MISSION ${g.stage+1} COMPLETE!`,640,110,58,HOT,SHADOW,'center',10);text(STAGES[g.stage].name,640,146,20,'#a8707f','center');
 panelCard(250,180,780,420);
 let shown=0;
 R.rows.forEach((r,i)=>{const start=.6+i*.7;if(t<start)return;const k=clamp((t-start)/.5,0,1),v=Math.floor(r.value*k),y=240+i*70;shown+=v;
  text(r.label,290,y,22,INK,'left',DISPLAY);text(r.detail,560,y,18,'#a8707f');text(pad7(v).replace(/^0+(?=\d)/,''),990,y,26,v?INK:'#c9b1b7','right',DISPLAY);line(290,y+18,990,y+18,'#f2c4cf',2);
  if(i>ui.shownRow){ui.shownRow=i;}
  if(k<1&&Math.floor(t*30)!==ui.tickNum){ui.tickNum=Math.floor(t*30);audio.sfx('tick');}});
 const done=t>=.6+R.rows.length*.7;
 text('BONUS',290,560,22,HOT,'left',DISPLAY);text(String(done?R.bonus:shown),990,562,32,HOT,'right',DISPLAY);
 if(t>tallyEnd()-1.0){const k=clamp((t-(tallyEnd()-1))/.25,0,1),s=3-2*ease(k);if(!ui.stamped){ui.stamped=true;audio.sfx('stamp');}
  c.save();c.translate(1090,250);c.rotate(-.2);c.scale(s,s);c.globalAlpha=k;circle(0,0,78,'#ffffffcc');ring(0,0,78,HOT,8);ring(0,0,64,HOT,3);outlined(R.rank,0,40,110,HOT,PAPER,'center',8);text('RANK',0,-48,16,HOT,'center',DISPLAY);c.restore();}
 victoryPose(150,700,260,1,6);
 text('SCORE '+pad7(g.score),640,650,26,INK,'center',DISPLAY);
 if(t>=tallyEnd()&&Math.floor(g.time*2.5)%2===0)outlined(g.stage>=3?'ENTER · 엔딩 보기':'ENTER · 다음 미션',640,696,24,PAPER,SHADOW,'center',6);}
function continueScreen(){
 overlayDim(.75);const n=Math.max(0,Math.ceil(g.continueTime));
 if(n!==ui.tickNum){ui.tickNum=n;audio.sfx('tick');}
 outlined('CONTINUE?',640,230,84,PINK,SHADOW,'center',12);
 const frac=g.continueTime-Math.floor(g.continueTime),s=1+frac*.25;c.save();c.translate(640,420);c.scale(s,s);outlined(String(n),0,0,180,GOLD,SHADOW,'center',14);c.restore();
 text('ENTER · 이어서 하기 (점수 유지)',640,520,24,PAPER,'center',DISPLAY);text('R · 이 미션 처음부터   ·   Esc · 포기',640,560,17,'#ffd8d9','center');
 hero(1010,700,230,7,-1,.95,false);
 text(`SCORE ${pad7(g.score)}   ·   CREDIT ${g.credits}`,640,620,18,'#ffd8d9','center',DISPLAY);}
function gameoverScreen(){
 c.fillStyle='#2b1720';c.fillRect(0,0,1280,720);
 const s=back3((g.time-ui.modeT)/.6);c.save();c.translate(640,240);c.scale(s,s);outlined('GAME OVER',0,0,110,HOT,PAPER,'center',12);c.restore();
 text('방송 재연결이 필요해!',640,300,22,PINK,'center');
 text('FINAL SCORE',640,380,18,'#ffd8d9','center',DISPLAY);outlined(pad7(g.score),640,440,56,GOLD,SHADOW,'center',8);
 if(ui.newRecord)outlined('NEW RECORD!',640,494,28,PINK,SHADOW,'center',6);
 text(`허니비 ${g.rescued}마리 구출 · 과메기 ${g.kills}마리 처치 · MISSION ${g.stage+1}`,640,548,18,PAPER,'center');
 if(Math.floor(g.time*2)%2===0)text('ENTER · 타이틀로',640,640,22,PAPER,'center',DISPLAY);}
function victoryT(){return g.time-ui.modeT;}
// Ending in three acts (seconds since the mode began): peace returns to the meadow (0-9.5), the final tally (9.5-16),
// then the staff roll over a dusk sky ending on THE END. Enter skips back to the title at any point.
const ENDING_LINES=[[.6,3.6,'과메기단은 바다 저 멀리 도망쳤고…'],[3.6,6.6,'구출된 허니비들은 모두 꽃밭으로 돌아왔어요.'],[6.6,9.6,'허니츄러스 마을에 다시 평화가 찾아왔습니다!']];
const ENDING_CREDITS=[['STAFF',''],['주인공','허니츄러스'],['구출 대상','허니비 여러분'],['악당','과메기단'],['최종 보스','오리고기 사령관'],['기획 · 개발','project-h'],['아트','Codex 이미지 생성'],['음악','Suno BGM'],['엔진','Godot 4 · HTML5 Canvas'],['특별 감사','플레이해 준 바로 당신!']];
const ENDING_TALLY=9.5,ENDING_ROLL=16,ROLL_SPEED=70,ROLL_GAP=66;
function victory(){
 const t=victoryT();
 // the meadow from the title, with the villain gone
 c.drawImage(tex.menuBg,0,0,1280,720);c.drawImage(tex.menuTree,0,0,1280,720);
 for(let i=0;i<10;i++){const x=(i*211+t*14)%1400-60,y=(i*97+t*20)%780-40;c.save();c.globalAlpha=.55;c.translate(x,y);c.rotate(t*.6+i);ellipse(0,0,8,4,'#ffc1d6');c.restore();}
 const dusk=clamp((t-ENDING_ROLL)/2,0,1);
 if(dusk>0){c.save();c.globalAlpha=dusk*.62;const gr=c.createLinearGradient(0,0,0,720);gr.addColorStop(0,'#2b1d3f');gr.addColorStop(1,'#7a3b56');c.fillStyle=gr;c.fillRect(0,0,1280,720);c.restore();
  for(let i=0;i<40;i++){const tw=.5+.5*Math.sin(t*2+i*1.7);c.save();c.globalAlpha=dusk*tw*.9;circle((i*317)%1280,(i*137)%330,1.5+(i%3),'#fff6da');c.restore();}}
 // the hero dances in the middle, the honeybees circle her and hearts drift up
 const hx=dusk>0?lerp(640,300,ease(dusk)):640,hs=dusk>0?lerp(300,230,ease(dusk)):300;
 ellipse(hx,700,hs*.24,10,'#3a1f2a33');victoryPose(hx,700,hs,1,8);
 for(let i=0;i<9;i++){const a=t*1.1+i*Math.PI*2/9,r=lerp(150,120,dusk)+Math.sin(t*2+i)*16;bee(hx+Math.cos(a)*r*1.6,560-hs*.55+Math.sin(a)*r*.7,44+(i%3)*10,1,Math.sin(a)>0?-1:1);}
 for(let i=0;i<6;i++){const k=(t*.35+i/6)%1;c.save();c.globalAlpha=(1-k)*.9;heart(hx-120+i*48+Math.sin(t*2+i)*12,620-k*420,18+(i%2)*6,i%2?'#ffd8d9':HOT);c.restore();}
 // act 1: title and story captions
 if(t<ENDING_TALLY){const s=back3(t/.6),o=clamp((ENDING_TALLY-t)/.5,0,1);c.save();c.globalAlpha=o;c.translate(640,104);c.scale(s,s);outlined('ALL MISSION COMPLETE!',0,0,62,HOT,SHADOW,'center',10);c.restore();
  for(const [a,b,line] of ENDING_LINES)if(t>=a&&t<b){const k=Math.min(1,(t-a)/.4,(b-t)/.4);c.save();c.globalAlpha=k;outlined(line,640,186+(1-k)*10,30,PAPER,SHADOW,'center',7);c.restore();}}
 // act 2: the final tally
 else if(t<ENDING_ROLL){const k=back3((t-ENDING_TALLY)/.5),o=clamp((ENDING_ROLL-t)/.5,0,1);overlayDim(.35*o);
  c.save();c.globalAlpha=o;c.translate(640,360);c.scale(k,k);c.translate(-640,-360);panelCard(340,130,600,430);
  outlined('FINAL SCORE',640,196,30,HOT,PAPER,'center',6);outlined(pad7(g.score),640,262,56,GOLD,SHADOW,'center',8);
  const rows=[['구출한 허니비',g.rescued+'마리'],['처치한 과메기',g.kills+'마리'],['사용한 크레딧',String(g.credits)],['난이도',g.dif.label]];
  rows.forEach(([a,b],i)=>{if(t<ENDING_TALLY+.7+i*.35)return;const y=330+i*50;text(a,390,y,21,'#a8707f','left',DISPLAY);text(b,890,y,26,INK,'right',DISPLAY);line(390,y+15,890,y+15,'#f2c4cf',2);});
  if(ui.newRecord&&t>ENDING_TALLY+2.4){const s2=back3((t-ENDING_TALLY-2.4)/.4);c.save();c.translate(820,540);c.rotate(-.12);c.scale(s2,s2);outlined('NEW RECORD!',0,0,34,HOT,PAPER,'center',7);c.restore();}
  c.restore();}
 // act 3: staff roll, then THE END
 else{const r=t-ENDING_ROLL,x=820;
  ENDING_CREDITS.forEach(([a,b],i)=>{const y=780+i*ROLL_GAP-r*ROLL_SPEED;if(y<-40||y>760)return;c.save();c.globalAlpha=clamp((y-40)/80,0,1)*clamp((720-y)/60,0,1);
   if(i===0)outlined(a,x,y,34,GOLD,SHADOW,'center',7);else{text(a,x,y-6,16,'#ffd8d9','center',DISPLAY);outlined(b,x,y+22,26,PAPER,SHADOW,'center',6);}c.restore();});
  const endAt=(780+(ENDING_CREDITS.length-1)*ROLL_GAP+60)/ROLL_SPEED;
  if(r>endAt){const k=back3((r-endAt)/.8);c.save();c.translate(x,330);c.scale(k,k);outlined('THE END',0,0,84,HOT,PAPER,'center',12);c.restore();
   if(r>endAt+1)outlined('THANK YOU FOR PLAYING',x,400,26,PAPER,SHADOW,'center',6);
   if(r>endAt+1.6)text(`SCORE ${pad7(g.score)}`,x,444,20,'#ffd8d9','center',DISPLAY);}}
 if(t>2&&Math.floor(g.time*2)%2===0)text('ENTER · 타이틀로',1240,700,18,dusk>0?'#ffd8d9':'#a8707f','right',DISPLAY);}
// ---------- intro cutscene ----------
// Timeline in seconds: peace (0-6) → alarm (6-8.5) → raid (8.5-15) → retreat (15-19) → resolve (19-25).
const STORY_LINES=[[.6,3.2,'','꽃과 꿀이 넘치는 허니츄러스 마을.'],[3.2,6,'','허니비들은 오늘도 평화롭게 꿀을 모으고 있었어요…'],[6.2,8.6,'','그런데 그때——!'],
 [10.6,14.6,'commander','꿀도, 허니비도 전부 우리 과메기단 거다~! 몽땅 실어라!'],[14.9,18.6,'bee','살려줘요~! 허니츄러스~!'],[19.2,23,'hero','…내 친구들을 돌려놔. 한 마리도 빠짐없이 구해낼 거야!']];
STORY_LINES.splice(3,0,[9.3,10.5,'hero','앗…! 내 허니비!!']);
const STORY_CUES=[[6,'alarm'],[6,'music:boss'],[8.7,'warning'],[9.3,'hurt'],[10,'explode'],[19.2,'click'],[21.4,'pistol'],[11,'slam'],[15,'charge'],[19,'music:title'],[22.6,'stamp']];
const lerp=(a,b,k)=>a+(b-a)*clamp(k,0,1);
function storyBee(i,t){
 const home={x:180+i*150+Math.sin(t*1.3+i)*30,y:300+Math.sin(t*2+i*1.7)*36+(i%2)*60},grab=9+i*.55;
 if(t<grab)return{...home,x:home.x+(t>6?Math.sin(t*30+i)*4:0),state:t>6?'panic':'happy'};
 const k=(t-grab)/2.6;if(k>=1)return null;
 return{x:lerp(home.x,1080,ease(k)),y:lerp(home.y,330,ease(k))-Math.sin(k*Math.PI)*120,state:'carried'};}
function story(){
 const t=g.storyTime||0;
 for(const [at,cue] of STORY_CUES)if(t>=at&&!(ui.storyDone||(ui.storyDone=new Set())).has(at+cue)){ui.storyDone.add(at+cue);if(cue.startsWith('music:'))audio.music(cue.slice(6));else audio.sfx(cue);}
 const quake=(t>6&&t<8.5?Math.sin(t*60)*3:0)+(t>10&&t<10.7?Math.sin(t*90)*14*(10.7-t):0)+(t>9&&t<11?Math.sin(t*40)*2:0);
 const zoom=t<19?1:1+ease((t-19)/1.5)*.55,heroX=t<10?330:t<10.6?lerp(330,210,(t-10)/.6):210;
 c.save();c.translate(quake,quake*.5);
 if(zoom>1){const k=ease((t-19)/1.5);c.translate(Math.min(heroX+(420-heroX)*k,heroX*zoom),600);c.scale(zoom,zoom);c.translate(-heroX,-600);}
 g.camera=0;background();c.save();ground();c.restore();
 if(t>6){const k=clamp((t-6)/1.5,0,1)*(t<19?1:clamp(1-(t-19)/2,0,1));c.fillStyle=`rgba(70,20,45,${.28*k})`;c.fillRect(-200,0,1700,720);if(t<8.5&&Math.floor(t*6)%2===0){c.fillStyle='rgba(255,60,90,.12)';c.fillRect(-200,0,1700,720);}}
 // tank arrives, then backs away with its cargo
 const tankX=t<9?1700:t<11?lerp(1700,1030,ease((t-9)/2)):t<15?1030+Math.sin(t*3)*3:lerp(1030,1800,Math.pow(clamp((t-15)/4,0,1),2));
 if(tankX<1700){ellipse(tankX,592,230,14,'#3a1f2a40');drawStoryTank(tankX,592,(t>=11&&t<15?1030:tankX)-1700);for(let i=0;i<3;i++){const a=(t*1.2+i*.33)%1;circle(tankX+160+i*8,260-a*80,10+a*16,`rgba(120,100,100,${.4*(1-a)})`);}}
 // paratroopers drop in and stand guard
 for(let i=0;i<3;i++){const x=640+i*130,land=10.2+i*.4,y=t<land?lerp(-80,576,(t-8.6-i*.3)/(land-8.6-i*.3)):576;if(t<8.6+i*.3||t>15.2)continue;
  if(t<land)enemySprite('para',x+Math.sin(t*2+i)*14,y,92,{rot:Math.sin(t*2+i)*.08});else enemySprite('grunt',x,576,92,{sx:1+Math.sin(t*10+i)*.03});
  if(t>land&&t<land+.6)outlined('!',x,470,26,HOT,SHADOW);}
 // flyers swoop down and carry the honeybees off to the tank
 for(let i=0;i<6;i++){const b=storyBee(i,t);if(!b)continue;const grab=9+i*.55;
  if(b.state==='carried'||t>grab-1.1&&t<grab){const fx=b.state==='carried'?b.x:lerp(1400,b.x,(t-(grab-1.1))/1.1),fy=b.state==='carried'?b.y-70:lerp(60,b.y-70,(t-(grab-1.1))/1.1);enemySprite('flyer',fx,fy+40,80,{});c.save();c.globalAlpha=.5;const w=30*Math.sin(g.time*50);line(fx-w,fy-38,fx+w,fy-38,'#fff',4);c.restore();}
  if(b.state==='carried'){line(b.x,b.y-60,b.x,b.y-30,'#b0814f',3);powTied(b.x,b.y+34,74,Math.sin(t*8+i)*.15);}
  else{bee(b.x,b.y,64,1,Math.sin(t*3+i)>0?1:-1);if(b.state==='panic'){text('💦',b.x+26,b.y-50,16,'#7fc8f8','center');if(i%2===0)outlined('!',b.x,b.y-64,22,HOT,SHADOW);}else if(i%3===0){box(b.x-10,b.y-6,20,16,GOLD,5,SHADOW,2);}}}
 // our hero (story pose sheet): bee on head → bee snatched → knocked down → gets up → draws the Glock
 const D=240,pose=(f,x,y,o={})=>cell(tex.story,f,x,y,D,{base:f<4?.98:.93,...o});
 let f=Math.floor(t*.8)%4===1?1:0,hy=576,rot=0;
 if(t>=6&&t<9.3){f=2;hy=576-(t<6.6?Math.abs(Math.sin((t-6)*6))*24:0);}
 else if(t>=9.3&&t<10)f=3;
 else if(t>=10&&t<10.6){f=4;hy=576-Math.sin((t-10)/.6*Math.PI)*70;rot=-(t-10)*1.2;}
 else if(t>=10.6&&t<17)f=4;
 else if(t>=17&&t<18.4){f=5;hy=576-Math.abs(Math.sin((t-17)*5))*(t<17.6?18:0);}
 else if(t>=18.4&&t<20)f=6;
 else if(t>=20)f=7;
 // Story sheet frames 0-5 face left; mirror them (except 3, reaching right toward the stolen bee) so she faces the threat on the right.
 const mirror=f<6&&f!==3;
 ellipse(heroX,580,48,8,'#3a1f2a40');pose(f,heroX,hy,{rot,flip:mirror});
 if(t>6.1&&t<7.6)outlined('!',heroX,hy-D*.98-10,40,HOT,SHADOW);
 if(t>10.6&&t<17)for(let i=0;i<3;i++){const a=g.time*5+i*2.1;text('★',heroX+Math.cos(a)*30,hy-D*.78+Math.sin(a)*8,16,GOLD,'center');}
 if(t>10&&t<10.9){const k=(t-10)/.9;cell(tex.boom,Math.min(7,Math.floor(k*8)),heroX+80,520,260,{base:.56});}
 // a propeller trooper swoops in and snatches the bee off her head
 const head={x:heroX+(mirror?-1:1)*D*.05,y:hy-D*.86};
 if(t>8.6&&t<11.6){const k1=clamp((t-8.6)/.7,0,1),k2=clamp((t-9.3)/2.3,0,1),fx=t<9.3?lerp(1350,head.x,ease(k1)):lerp(head.x,1060,ease(k2)),fy=(t<9.3?lerp(40,head.y-60,ease(k1)):lerp(head.y-60,300,ease(k2))-Math.sin(k2*Math.PI)*90);
  enemySprite('flyer',fx,fy+40,84,{});c.save();c.globalAlpha=.5;const w=30*Math.sin(g.time*50);line(fx-w,fy-40,fx+w,fy-40,'#fff',4);c.restore();
  if(t>=9.3){line(fx,fy+20,fx,fy+44,'#b0814f',3);powTied(fx,fy+108,70,Math.sin(t*8)*.15);}}
 if(t>=19.9&&t<20.1)ellipse(heroX+D*.45,hy-D*.57,26,12,'#fff6c8');
 if(t>=21.4&&t<21.6){c.save();c.globalCompositeOperation='lighter';circle(heroX+D*.43,hy-D*.57,26,'#ffd079aa');circle(heroX+D*.43,hy-D*.57,12,'#fff6d0');c.restore();}
 if(t>14.9&&t<18.6&&tankX<1500)for(let i=0;i<2;i++)bubble(tankX-40+i*110,300+i*16+Math.sin(t*6+i)*4,'살려줘~!',HOT);
 c.restore();
 // letterbox, dialogue, skip hint
 const bar=60*ease(t/.6);c.fillStyle='#1d1016';c.fillRect(0,0,1280,bar);c.fillRect(0,720-bar,1280,bar);
 const cur=STORY_LINES.find(([a,b])=>t>=a&&t<b);
 if(cur){const [a,,who,line]=cur,shown=line.slice(0,Math.floor((t-a)*22)),y=74;
  box(160,y,960,92,'#fff8f5f2',22,'#f2c4cf',3);
  if(who){circle(210,y+46,36,PINK);ring(210,y+46,36,SHADOW,3);c.save();c.beginPath();c.arc(210,y+46,32,0,Math.PI*2);c.clip();
   if(who==='hero')c.drawImage(tex.profile,220,65,440,440,178,y+14,64,64);else if(who==='commander')bossPart(2,174,y+8,72,78);else bee(210,y+74,70);c.restore();
   text({hero:'허니츄러스',commander:'오리고기 사령관',bee:'허니비들'}[who],262,y+32,15,HOT,'left',DISPLAY);text(shown,262,y+66,22,INK);}
  else text(shown,640,y+56,24,INK,'center');}
 if(t>22.4){const k=back3((t-22.4)/.4);c.save();c.translate(760,250);c.scale(k,k);c.rotate(-.04);outlined('허니비 구출 작전',0,0,84,PINK,SHADOW,'center',12);outlined('OPERATION HONEY RESCUE',0,46,24,GOLD,SHADOW,'center',6);c.restore();}
 if(t>24.2){c.fillStyle=`rgba(255,248,245,${clamp((t-24.2)/.8,0,1)})`;c.fillRect(0,0,1280,720);}
 if(Math.floor(g.time*2)%2===0)text('ENTER · 클릭  건너뛰기 ▶▶',1250,40,15,'#ffffffcc','right',DISPLAY);}

// ---------- frame loop ----------
function heldSet(){const s=new Set([...kb,...padHeld]);for(const v of touchHeld.values())for(const a of v)s.add(a);return s;}
function musicFor(){switch(g.mode){case'title':return'title';case'story':return'title';case'briefing':return'title';case'play':case'pause':return g.boss?.started&&!g.boss.dead?'boss':STAGES[g.stage].theme;case'celebrate':return'clear';case'result':return'result';case'gameover':return'gameover';case'victory':return'victory';}return null;}
function onModeChange(from,to){
 ui.modeT=g.time;ui.tickNum=-1;ui.stamped=false;ui.shownRow=-1;ui.hits=[];ui.hover=-1;
 if(!(from==='play'&&to==='pause'||from==='pause'&&to==='play')&&to!=='celebrate')ui.fade=1;
 if(to==='play'||to==='title')audio.set({duck:false});
 if(to==='pause'&&ui.screen!=='settings'){ui.screen='pause';ui.index=0;}
 if(to==='title'&&from!=='title'){ui.screen='main';ui.index=0;ui.titleAt=g.time;}
 if(to==='story')ui.storyDone=new Set();
 if(to==='briefing'&&(from==='title'||from==='story'))ui.bestAtStart=g.best;
 if(to==='briefing'){progress=Math.max(progress,g.stage);store.set('honey-progress',progress);}
 if(to==='gameover'||to==='victory'){ui.newRecord=g.score>(ui.bestAtStart??g.best)&&g.score>(records[0]?.score||0);addRecord();if(to==='victory'){progress=3;store.set('honey-progress',3);}}
 const m=musicFor();if(m)audio.music(m);else audio.stopMusic();
 const live=document.querySelector('#access');if(live)live.textContent={play:STAGES[g.stage].name+' 플레이 중',pause:'일시정지',briefing:`미션 ${g.stage+1} 브리핑. Enter로 출격`,result:'미션 완료. Enter로 계속',continue:'컨티뉴? Enter로 이어하기',gameover:'게임 오버. Enter로 타이틀',victory:'모든 미션 완료!',title:'타이틀. Enter로 시작'}[to]||'';}
let previous=performance.now(),acc=0,lastBoss=false;
function frame(now){
 const elapsed=Math.min(.1,(now-previous)/1000);previous=now;acc+=elapsed;
 pollPad();
 let first=true;
 while(acc>=1/60){
  const held=heldSet(),input=Object.fromEntries([...held].map(k=>[k,true]));
  if(first){for(const k of ['jump','grenade','swap','fire'])input[k+'Pressed']=pressedEv.has(k)||held.has(k)&&!prevHeld.has(k);input.jumpReleased=releasedEv.has('jump')||!held.has('jump')&&prevHeld.has('jump');
   if(pressedEv.has('fire'))input.fire=true;if(pressedEv.has('jump')&&!held.has('jump'))input.jumpReleased=false;
   pressedEv.clear();releasedEv.clear();prevHeld=held;first=false;}
  g.update(1/60,input);acc-=1/60;
  if(g.mode==='briefing'&&g.briefTime>6)g.confirm();}
 ui.fade=Math.max(0,ui.fade-elapsed*2.5);ui.toastT-=elapsed;ui.goT=Math.max(0,ui.goT-elapsed);
 const cleared=g.zones.filter(z=>z.cleared).length;if(cleared>ui.cleared&&g.mode==='play'&&cleared<g.zones.length)ui.goT=2.5;ui.cleared=cleared;
 if(ui.lastMode!==g.mode){onModeChange(ui.lastMode,g.mode);ui.lastMode=g.mode;}
 const bossNow=!!(g.boss?.started&&!g.boss.dead);if(bossNow!==lastBoss){lastBoss=bossNow;const m=musicFor();if(m)audio.music(m);}
 const dpr=Math.min(2,window.devicePixelRatio||1),pw=Math.round((canvas.clientWidth||1280)*dpr),ph=Math.round(pw*720/1280);
 if(canvas.width!==pw||canvas.height!==ph){canvas.width=pw;canvas.height=ph;}
 c.setTransform?.(pw/1280,0,0,ph/720,0,0);c.imageSmoothingEnabled=true;c.imageSmoothingQuality='high';
 switch(g.mode){
  case'title':title();break;
  case'story':story();break;
  case'briefing':briefing();break;
  case'result':resultScreen();break;
  case'gameover':gameoverScreen();break;
  case'victory':victory();break;
  default:world();hud();cinematics();if(g.mode==='pause')pauseScreen();if(g.mode==='continue')continueScreen();}
 if(ui.toastT>0){c.save();c.globalAlpha=Math.min(1,ui.toastT*3);c.font=`16px ${BODY}`;const w=c.measureText(ui.toast).width+40;box(640-w/2,660,w,36,'#3a1f2add',18);text(ui.toast,640,684,16,PAPER,'center');c.restore();}
 if(ui.fade>0){c.fillStyle=`rgba(255,240,243,${ui.fade})`;c.fillRect(0,0,1280,720);}
 requestAnimationFrame(frame);}
requestAnimationFrame(frame);
window.__honey={game:g,assets:tex,ui,audio,settings,pointer:uiPointer,visuals:HoneyVisuals};
})();
