/* Honey Churros — fixed-step run-and-gun simulation.
   Pure game logic: no DOM, drawing or audio. The renderer reads state and the
   game reports sounds/voice lines through the `sound` and `voice` callbacks. */
(function(root){'use strict';
const W=1280,H=720,FLOOR=576,ENTRY_X=180;

const DIFFICULTY={
 easy:{label:'쉬움',hp:7,lives:5,enemyHp:.75,fire:1.4,bullet:.82,score:.8},
 normal:{label:'보통',hp:5,lives:3,enemyHp:1,fire:1,bullet:1,score:1},
 hard:{label:'어려움',hp:3,lives:3,enemyHp:1.3,fire:.72,bullet:1.18,score:1.5}};

const WEAPONS=[
 {name:'AKM',letter:'A',call:'A K M!',label:'돌격소총',rate:.13,damage:2.2,speed:1050,ammo:150,spread:.035,color:'#ffc45c'},
 {name:'Kar98k',letter:'K',call:'Kar ninety-eight K!',label:'저격소총',rate:.6,damage:12,speed:1700,ammo:30,spread:0,color:'#e6f7dd'},
 {name:'M4',letter:'M',call:'M four!',label:'카빈 소총',rate:.075,damage:2,speed:1250,ammo:200,spread:.045,color:'#b5e3cf'},
 {name:'RPG-26',letter:'R',call:'R P G twenty-six!',label:'로켓 런처',rate:.55,damage:14,speed:700,ammo:20,spread:0,color:'#ff966f'},
 {name:'FMG-9',letter:'S',call:'F M G nine!',label:'기관단총',rate:.055,damage:1.2,speed:950,ammo:250,spread:.09,color:'#f4a9c8'},
 {name:'Glock 19',letter:'P',call:'',label:'권총',rate:.2,damage:2,speed:1000,ammo:-1,spread:0,color:'#fbdfa5'}];
const PISTOL=5;
// Weapons unlock as the campaign goes on: each mission adds its guns to the drop pool (AKM+FMG-9, then M4, Kar98k, RPG-26).
const WEAPON_UNLOCK=[[0,4],[2],[1],[3]];

const VISUALS=[
 {width:88,ratio:.40,grip:.36,recoil:4,flash:18,kind:'akm',sound:'akm'},
 {width:108,ratio:.26,grip:.33,recoil:9,flash:31,kind:'sniper',sound:'sniper'},
 {width:90,ratio:.40,grip:.35,recoil:3,flash:15,kind:'m4',sound:'m4'},
 {width:104,ratio:.37,grip:.47,recoil:12,flash:34,kind:'rocket',sound:'rocket'},
 {width:62,ratio:.66,grip:.43,recoil:2,flash:11,kind:'smg',sound:'smg'},
 {width:43,ratio:.68,grip:.28,recoil:5,flash:13,kind:'pistol',sound:'pistol'}];

// Enemy archetypes. All use the gwamegi sheet; the renderer adds gear per kind.
const ENEMIES={
 grunt:{name:'소총병',hp:5,size:92,speed:70,score:100},
 hopper:{name:'돌격병',hp:4,size:82,speed:170,score:100},
 flyer:{name:'프로펠러병',hp:4,size:84,speed:95,score:200},
 shield:{name:'방패병',hp:10,size:100,speed:42,score:300},
 bomber:{name:'꿀단지 투척병',hp:5,size:92,speed:60,score:200},
 heavy:{name:'중화기병',hp:14,size:112,speed:34,score:400},
 turret:{name:'꿀 포대',hp:34,size:120,speed:0,score:800}};

/* Hand-placed level data. x positions are relative to the zone start.
   waves: [at, kind, count, entry]  entry R=right edge, L=left edge (ambush), P=parachute
   arena: list of waves fought with the camera locked at the end of the zone. */
const LEVELS=[
 {theme:'town',boss:'king',par:400,zones:[
  {name:'꽃길 입구',len:1400,plat:[[320,446,190],[660,400,170]],props:[['crate',560],['barrel',985]],pows:[['cage',780,'weapon',0]],
   waves:[[150,'grunt',2,'R'],[430,'grunt',1,'T'],[650,'hopper',2,'R'],[900,'flyer',2,'R']],
   arena:[[['grunt',2,'R'],['bomber',1,'R']],[['hopper',2,'L'],['grunt',2,'P']]]},
  {name:'방송 장비 거리',len:1500,plat:[[260,446,200],[560,396,180],[900,446,200]],props:[['barrel',420],['crate',760],['barrel',1110]],pows:[['cage',640,'ammo'],['cage',1010,'food']],
   waves:[[100,'grunt',2,'R'],[300,'shield',1,'R'],[350,'grunt',1,'T'],[600,'bomber',1,'R'],[800,'flyer',2,'R'],[1000,'hopper',2,'L']],
   arena:[[['shield',1,'R'],['grunt',2,'R']],[['bomber',1,'T'],['grunt',2,'P']]]},
  {name:'꽃시장 골목',len:1400,plat:[[240,446,180],[520,400,160],[820,446,200],[1080,396,160]],props:[['crate',380],['barrel',700],['crate',1000]],pows:[['cage',900,'weapon',4]],
   waves:[[120,'grunt',2,'R'],[260,'hopper',2,'R'],[400,'grunt',1,'T'],[600,'flyer',2,'R'],[850,'shield',1,'R'],[1000,'grunt',2,'P']],
   arena:[[['grunt',2,'R'],['hopper',2,'L']],[['shield',1,'R'],['bomber',1,'T']]]},
  {name:'양봉장 언덕',len:1300,plat:[[300,430,200],[620,380,180],[940,430,180]],props:[['barrel',480],['crate',800]],pows:[['cage',560,'food'],['cage',1080,'ammo']],
   waves:[[100,'flyer',2,'R'],[300,'grunt',2,'R'],[450,'bomber',1,'T'],[700,'heavy',1,'R'],[900,'hopper',2,'L']],
   arena:[[['heavy',1,'R'],['grunt',1,'T']],[['flyer',2,'R'],['grunt',2,'P']]]},
  {name:'송신탑 광장',len:1400,plat:[[300,420,220],[700,380,200]],props:[['crate',500],['barrel',860]],pows:[['cage',820,'support']],
   waves:[[150,'grunt',2,'R'],[300,'grunt',1,'T'],[450,'flyer',2,'R'],[650,'heavy',1,'R'],[700,'grunt',1,'R'],[900,'grunt',2,'P']],
   arena:[[['heavy',1,'R'],['grunt',2,'L']],[['hopper',2,'R'],['flyer',2,'R']]]}]},
 {theme:'factory',boss:'cannon',par:450,zones:[
  {name:'꿀 운송장',len:1300,plat:[[280,446,180],[600,564,310,'belt']],hazards:[['honey',470,100]],props:[['crate',380],['barrel',980]],pows:[['cage',720,'weapon',2]],
   waves:[[120,'grunt',2,'R'],[300,'grunt',1,'T'],[450,'bomber',1,'R'],[650,'hopper',2,'R'],[900,'grunt',2,'P']],
   arena:[[['grunt',2,'R'],['hopper',2,'L']],[['bomber',1,'R'],['grunt',1,'T']]]},
  {name:'컨베이어 홀',len:1400,plat:[[200,564,360,'belt'],[640,420,180],[900,564,300,'belt']],hazards:[['honey',580,90]],props:[['barrel',860],['crate',1180]],pows:[['cage',700,'weapon',0],['cage',1150,'ammo']],
   waves:[[100,'flyer',2,'R'],[350,'shield',1,'R'],[400,'grunt',1,'R'],[550,'grunt',1,'T'],[650,'grunt',2,'L'],[850,'bomber',1,'R']],turrets:[1240],
   arena:[[['shield',1,'R'],['grunt',2,'P']],[['flyer',2,'R'],['hopper',2,'L']]]},
  {name:'꿀단지 창고',len:1400,plat:[[220,446,180],[520,564,280,'belt'],[880,420,200]],hazards:[['honey',820,90]],props:[['crate',300],['barrel',440],['crate',1150]],pows:[['cage',1000,'weapon',2]],
   waves:[[120,'grunt',2,'R'],[300,'bomber',1,'R'],[450,'grunt',1,'T'],[700,'shield',1,'R'],[900,'hopper',2,'L'],[1050,'flyer',2,'R']],
   arena:[[['bomber',1,'R'],['grunt',2,'R']],[['shield',1,'R'],['hopper',2,'L'],['grunt',1,'T']]]},
  {name:'벌집 정제실',len:1300,plat:[[260,430,200],[560,380,180],[860,430,200]],hazards:[['honey',420,110],['honey',740,90]],props:[['barrel',330],['crate',950]],pows:[['cage',600,'support']],
   waves:[[150,'heavy',1,'R'],[200,'grunt',1,'T'],[400,'flyer',2,'R'],[700,'grunt',2,'P'],[750,'bomber',1,'T']],
   arena:[[['heavy',1,'R'],['bomber',1,'R']],[['grunt',2,'L'],['hopper',2,'R'],['grunt',1,'T']]]},
  {name:'로열젤리 실험실',len:1300,plat:[[260,430,180],[560,380,200],[880,430,180]],hazards:[['honey',450,100],['honey',780,90]],props:[['barrel',360],['crate',1000]],pows:[['cage',680,'ammo']],
   waves:[[100,'heavy',1,'R'],[250,'grunt',1,'T'],[500,'flyer',2,'R'],[750,'grunt',2,'P'],[900,'bomber',1,'R']],turrets:[1180],
   arena:[[['heavy',1,'R'],['grunt',2,'L']],[['bomber',1,'T'],['flyer',2,'R']]]},
  {name:'저장고 관제실',len:1300,plat:[[300,446,200],[700,396,200]],props:[['crate',500],['barrel',640],['barrel',1000]],pows:[['cage',850,'food']],
   waves:[[100,'grunt',2,'R'],[350,'shield',1,'R'],[400,'grunt',1,'T'],[700,'flyer',2,'R'],[750,'bomber',1,'R']],turrets:[1100],
   arena:[[['shield',1,'R'],['bomber',1,'R'],['grunt',1,'T']],[['heavy',1,'R'],['grunt',2,'P']]]}]},
 {theme:'harbor',boss:'boat',par:430,zones:[
  {name:'해변 초소',len:1400,plat:[[300,446,190],[840,531,160,'boat',180]],hazards:[['water',640,560]],props:[['crate',520],['barrel',1260]],pows:[['cage',600,'weapon',4]],
   waves:[[150,'grunt',2,'R'],[300,'grunt',1,'T'],[450,'flyer',2,'R'],[850,'hopper',2,'R'],[1050,'grunt',2,'P']],
   arena:[[['grunt',2,'R'],['bomber',1,'R']],[['hopper',2,'L'],['flyer',1,'R']]]},
  {name:'수산물 시장',len:1400,plat:[[260,446,180],[560,400,160],[880,446,200]],props:[['crate',400],['barrel',740],['crate',1180]],pows:[['cage',980,'weapon',0]],
   waves:[[120,'grunt',2,'R'],[280,'shield',1,'R'],[420,'grunt',1,'T'],[650,'flyer',2,'R'],[850,'bomber',1,'R'],[1050,'hopper',2,'L']],turrets:[1250],
   arena:[[['shield',1,'R'],['grunt',2,'P']],[['bomber',1,'R'],['hopper',2,'L']]]},
  {name:'부두 창고',len:1500,plat:[[220,420,200],[660,531,160,'boat',170],[1030,400,200]],hazards:[['water',470,540]],props:[['crate',300],['crate',1060],['barrel',1300]],pows:[['cage',1120,'weapon',1],['cage',1380,'ammo']],
   waves:[[100,'shield',1,'R'],[150,'grunt',1,'R'],[400,'flyer',3,'R'],[700,'bomber',1,'R'],[750,'grunt',1,'T'],[1000,'grunt',2,'L']],turrets:[1300],
   arena:[[['shield',1,'R'],['grunt',2,'P']],[['heavy',1,'R'],['hopper',2,'L']]]},
  {name:'방파제 수로',len:1500,plat:[[220,446,180],[790,531,160,'boat',170],[1280,420,160]],hazards:[['water',600,540]],props:[['crate',300],['barrel',1360]],pows:[['cage',1250,'food']],
   waves:[[100,'grunt',2,'R'],[300,'flyer',2,'R'],[500,'grunt',1,'T'],[800,'bomber',1,'R'],[1100,'grunt',2,'R'],[1200,'hopper',2,'L']],
   arena:[[['grunt',2,'R'],['flyer',1,'R']],[['heavy',1,'R'],['grunt',1,'T']]]},
  {name:'상륙정 선착장',len:1400,plat:[[260,446,200],[720,531,160,'boat',160],[1080,420,200]],hazards:[['water',540,520]],props:[['barrel',420],['crate',1100]],pows:[['cage',1200,'support']],
   waves:[[150,'heavy',1,'R'],[200,'grunt',1,'R'],[400,'grunt',2,'P'],[850,'flyer',2,'R'],[1050,'bomber',1,'T'],[1100,'grunt',1,'R']],
   arena:[[['grunt',2,'R'],['flyer',1,'R'],['grunt',1,'T']],[['heavy',1,'R'],['shield',1,'L']]]}]},
 {theme:'fortress',boss:'tank',par:480,zones:[
  {name:'요새 외벽',len:1300,plat:[[300,446,200],[650,396,180]],hazards:[['steam',520,100]],props:[['barrel',420],['crate',900]],pows:[['cage',760,'weapon',2]],
   waves:[[100,'grunt',2,'R'],[200,'grunt',1,'T'],[350,'shield',1,'R'],[650,'flyer',2,'R'],[900,'hopper',2,'L'],[950,'bomber',1,'R']],turrets:[1150],
   arena:[[['shield',2,'R'],['grunt',1,'T']],[['heavy',1,'R'],['grunt',2,'P']]]},
  {name:'해산물 병영',len:1400,plat:[[260,430,200],[600,380,180],[950,430,200]],hazards:[['steam',470,100],['steam',820,100]],props:[['crate',380],['barrel',700],['barrel',1150]],pows:[['cage',650,'weapon',3],['cage',1050,'food']],
   waves:[[120,'bomber',1,'R'],[150,'grunt',1,'T'],[400,'grunt',2,'P'],[700,'heavy',1,'R'],[750,'bomber',1,'T'],[1000,'flyer',3,'R']],
   arena:[[['heavy',1,'R'],['bomber',1,'R']],[['shield',1,'R'],['hopper',2,'L'],['grunt',1,'T']]]},
  {name:'탄약고',len:1400,plat:[[280,446,200],[620,396,180],[960,446,200]],hazards:[['steam',500,100],['steam',840,100]],props:[['barrel',400],['barrel',760],['crate',1100]],pows:[['cage',700,'weapon',1]],
   waves:[[100,'heavy',1,'R'],[200,'grunt',1,'T'],[450,'shield',1,'R'],[650,'bomber',1,'R'],[850,'grunt',2,'P'],[1050,'flyer',2,'R']],turrets:[1250],
   arena:[[['heavy',1,'R'],['shield',1,'R']],[['grunt',2,'L'],['bomber',1,'T']]]},
  {name:'중앙 보급로',len:1300,plat:[[300,446,200],[700,400,200]],hazards:[['steam',560,100]],props:[['barrel',250],['crate',880],['barrel',1000]],pows:[['cage',780,'support']],
   waves:[[100,'shield',1,'R'],[150,'grunt',1,'R'],[400,'flyer',2,'R'],[450,'grunt',1,'T'],[700,'grunt',2,'L']],turrets:[1150],
   arena:[[['heavy',2,'R'],['grunt',1,'T']],[['grunt',2,'P'],['hopper',2,'L']]]},
  {name:'감시탑 회랑',len:1300,plat:[[240,420,180],[560,370,180],[880,420,180]],hazards:[['steam',420,100],['steam',740,100]],props:[['crate',320],['barrel',1000]],pows:[['cage',640,'food'],['cage',1100,'ammo']],
   waves:[[120,'flyer',2,'R'],[250,'grunt',2,'R'],[400,'grunt',1,'T'],[600,'heavy',1,'R'],[850,'hopper',2,'L'],[1000,'bomber',1,'R']],
   arena:[[['shield',1,'R'],['grunt',2,'P']],[['heavy',1,'R'],['flyer',2,'R'],['grunt',1,'T']]]},
  {name:'오리고기 사령부',len:1300,plat:[[260,420,200],[640,370,200]],hazards:[['steam',480,100]],props:[['crate',360],['barrel',900]],pows:[['cage',820,'ammo']],
   waves:[[100,'grunt',2,'R'],[250,'grunt',1,'T'],[350,'bomber',1,'R'],[650,'shield',1,'R'],[700,'bomber',1,'T'],[900,'flyer',2,'R']],
   arena:[[['heavy',1,'R'],['shield',1,'R']],[['bomber',1,'R'],['grunt',2,'P'],['grunt',1,'T']],[['hopper',3,'L'],['flyer',1,'R']]]}]}];
// STORY_SPEED slows the whole intro cutscene timeline (25 story-seconds play over ~36 real seconds).
const BOSS_ARENA=1400,
// Boss death timeline (celebrate counts down): chain explosions, final burst at CELEBRATE_BURST, the wreck fades over 1.2s,
// then MISSION COMPLETE at CELEBRATE_CALLOUT, and the screen whites out before the tally.
 CELEBRATE_TIME=6.4,
// Grenades: GRENADE_START on a new game, topped back up to GRENADE_FLOOR on respawn/continue/next mission.
 // Grenade throw: THROW_TIME of animation; the grenade leaves the hand THROW_RELEASE into it (after the wind-up).
 THROW_TIME=.32,THROW_RELEASE=.1,GRENADE_START=10,GRENADE_FLOOR=10,CELEBRATE_BURST=4.2,CELEBRATE_CALLOUT=2.8,
// Harbor boss: open sea between the arena start and the ship's stern; the deck runs from there to the stage end.
 SHIP_SEA=680,SHIP_SPEED=320,STORY_LEN=25,STORY_SPEED=.7;

const BOSSES={
 king:{name:'오리고기 보행전차',title:'과메기 선발대 지휘관',hp:170,w:340,h:330,score:8000},
 cannon:{name:'오리고기 꿀 공성포',title:'과메기 포병대 지휘관',hp:260,w:400,h:420,score:10000},
 boat:{name:'오리고기 상륙 지휘함',title:'과메기 상륙대 지휘관',hp:330,w:480,h:440,score:12000},
 tank:{name:'초거대 과메기 전차',title:'오리고기 사령관',hp:620,w:540,h:440,score:20000}};

// Boss rigs (generated/bosses/<sheet>.png: 4x2 cells of 512px, all facing left — 0 body, 1 body damaged, 2/3 weapon A ok/broken,
// 4/5 weapon B ok/broken, 6 open hatch, 7 debris). k = body draw scale (cell px -> screen); base = feet line of the body cell.
// Parts: pivot (pu,pv) in its own cell sits on body point (u,v); ps = part scale relative to the body; mu/mv = muzzle; box = opaque bounds (cell px).
const BOSS_RIG={
 king:{sheet:'walker',k:1.35,base:.9,box:[44,82,470,462],home:300,core:[.58,.38],nameA:'턱 기관포 파괴',nameB:'미사일 포드 파괴',
  A:{u:.36,v:.64,pu:.74,pv:.6,ps:.5,mu:.18,mv:.6,box:[84,202,413,420],hp:.22,aim:.5},
  B:{u:.86,v:.2,pu:.83,pv:.5,ps:.4,mu:.15,mv:.4,box:[43,122,458,383],hp:.18,rot:-.3},
  H:{u:.6,v:.22,pu:.5,pv:.86,ps:.38}},
 cannon:{sheet:'cannon',k:1.15,base:.924,box:[39,110,486,473],home:330,core:[.53,.5],nameA:'꿀 박격포 파괴',nameB:'꿀 화염방사기 파괴',
  A:{u:.7,v:.4,pu:.5,pv:.86,ps:.38,mu:.17,mv:.33,box:[37,105,458,456],hp:.22},
  B:{u:.22,v:.64,pu:.82,pv:.55,ps:.45,mu:.15,mv:.45,box:[70,100,469,357],hp:.18},
  H:{u:.84,v:.3,pu:.45,pv:.74,ps:.38}},
 boat:{sheet:'ship',k:1.4,base:.87,box:[54,82,476,446],home:260,core:[.54,.5],nameA:'갑판 포탑 파괴',nameB:'크레인 파괴',left:true,
  A:{u:.4,v:.36,pu:.6,pv:.86,ps:.36,mu:.17,mv:.43,box:[68,189,437,460],hp:.22,aim:.6},
  B:{u:.74,v:.5,pu:.72,pv:.72,ps:.45,mu:.18,mv:.5,box:[49,95,462,404],hp:.18},
  H:{u:.62,v:.38,pu:.5,pv:.88,ps:.35}},
 tank:{sheet:'tank',k:1.5,base:.905,box:[76,104,467,463],home:330,core:[.47,.49],nameA:'주포 파괴',nameB:'측면 개틀링 파괴',
  A:{u:.36,v:.64,pu:.6,pv:.8,ps:.45,mu:.2,mv:.5,box:[85,200,408,422],hp:.2,aim:.2},
  B:{u:.66,v:.62,pu:.55,pv:.7,ps:.45,mu:.2,mv:.47,box:[80,175,413,382],hp:.16},
  H:{u:.6,v:.36,pu:.45,pv:.84,ps:.38}}};

const STAGES=[
 {name:'방송국 습격',sub:'꽃과 꿀의 마을 · 끊어진 방송을 되찾아라',color:'#85bf9e'},
 {name:'꿀 저장고 탈환',sub:'벌집 공장 · 컨베이어와 꿀 함정을 돌파하라',color:'#d5a94d'},
 {name:'과메기 해안기지',sub:'해안과 항구 · 수륙양용 부대를 격파하라',color:'#68afb6'},
 {name:'과메기단 본부',sub:'해산물 요새 · 오리고기의 초거대 전차',color:'#8c829f'}];
LEVELS.forEach((level,i)=>{const s=STAGES[i];s.zones=level.zones.map(z=>z.name);s.length=level.zones.reduce((n,z)=>n+z.len,0)+BOSS_ARENA;s.theme=level.theme;s.boss=BOSSES[level.boss];});

const clamp=(v,a,b)=>Math.min(b,Math.max(a,v)),rand=(a,b)=>a+Math.random()*(b-a),pick=a=>a[Math.floor(Math.random()*a.length)];
function intersects(a,b,r){let t0=0,t1=1;const dx=b.x-a.x,dy=b.y-a.y;for(const [p,q] of [[-dx,a.x-r.x],[dx,r.x+r.w-a.x],[-dy,a.y-r.y],[dy,r.y+r.h-a.y]]){if(!p){if(q<0)return false;}else{const t=q/p;if(p<0)t0=Math.max(t0,t);else t1=Math.min(t1,t);if(t0>t1)return false;}}return true;}
const overlap=(a,b)=>a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y;

function playerFrame(g){if(g.dying>0||g.hurtTimer>0)return 7;if(g.crouch)return 5;if(!g.grounded)return 6;if(Math.abs(g.vx)>30)return Math.floor(g.stageTime*12)%4;return 4;}
function weaponPose(g){
 const frame=playerFrame(g),v=VISUALS[g.weapon],a=g.aim(),up=a.y<-.92&&!(g.dying>0)&&!(g.hurtTimer>0)&&!(g.knife>0),diagonal=Math.abs(a.x)>.2;
 const aimFrame=diagonal?(g.muzzle>.045?5:4):!g.grounded?6:g.crouch?7:Math.abs(g.vx)>30?2+Math.floor(g.stageTime*9)%2:g.muzzle>.045?1:0;
 const anchors=[[.52,.55],[.53,.55],[.54,.54],[.51,.55],[.52,.54],[.55,.67],[.55,.49],[.55,.53]],rear=[[.69,.30],[.70,.34],[.72,.29],[.77,.30],[.74,.35],[.78,.36],[.70,.28],[.77,.42]];
 // Running or landing while aiming straight up uses the rear run sheet (8 run + land) with its own grip points. Its
 // rise/apex/fall frames (8-10) have the head cut off at the cell top, so jumps keep the aim sheet's rear jump pose.
 let sheet='aim',sheetFrame=aimFrame;
 if(up&&!g.crouch&&!diagonal&&g.grounded){if(Math.abs(g.vx)>30){sheet='upRun';sheetFrame=Math.floor(g.stageTime*15)%8;}else if(g.landed>0){sheet='upRun';sheetFrame=11;}}
 const upRun=[[.72,.30],[.72,.30],[.72,.30],[.72,.30],[.72,.28],[.72,.28],[.72,.28],[.72,.28],[.745,.13],[.745,.13],[.745,.13],[.745,.30]];
 // The pistol uses its own two-handed sheets (hero_body_pistol / hero_run_pistol): the grip sits in the clasped hands.
 const pistolBody=[[.677,.549],[.691,.56],[.699,.56],[.699,.558],[.674,.518],[.689,.611],[.691,.488],[.701,.539]],pistolRun=[[.698,.508],[.705,.51],[.703,.513],[.724,.504],[.712,.492],[.746,.504],[.739,.503],[.766,.504]];
 const pistolAnchor=frame<4&&g.grounded&&!g.crouch?pistolRun[Math.floor(g.stageTime*15)%8]:pistolBody[frame];
 const anchor=up?(sheet==='upRun'?upRun[sheetFrame]:rear[aimFrame]):g.weapon===PISTOL?pistolAnchor:anchors[frame];
 const recoil=Math.max(0,g.muzzle)/.09*v.recoil*.35,bob=g.grounded&&Math.abs(g.vx)<30?Math.sin(g.stageTime*3)*.65:0,bx=-a.x*recoil,by=-a.y*recoil+bob;
 const x=g.x+(anchor[0]-.5)*108*g.face+bx,y=g.y+(anchor[1]-1)*108+by,reach=v.width*.75*(1-v.grip),normal=-v.width*.75*v.ratio*.13*g.face;
 return {frame,up,aimFrame,sheet,sheetFrame,bx,by,x,y,angle:Math.atan2(a.y*g.face,a.x*g.face),face:g.face,width:v.width*.75,height:v.width*.75*v.ratio,grip:v.grip,mx:x+a.x*reach-a.y*normal,my:y+a.y*reach+a.x*normal,aim:a};}

class Game{
 constructor(){
  this.mode='title';this.stage=0;this.time=0;this.best=0;this.difficulty='normal';this.shakeScale=1;
  this.sound=()=>{};this.voice=()=>{};this.onSave=()=>{};
  this.score=0;this.rescued=0;this.credits=0;this.kills=0;this.input={};
  this.resetLoadout();this.loadStage();this.mode='title';}
 get dif(){return DIFFICULTY[this.difficulty]||DIFFICULTY.normal;}
 get level(){return LEVELS[this.stage];}
 resetLoadout(){this.hp=this.dif.hp;this.lives=this.dif.lives;this.grenades=GRENADE_START;this.weapon=PISTOL;this.unlocked=[PISTOL];this.ammo=WEAPONS.map(w=>w.ammo<0?-1:0);}

 // ---- flow ----
 start(stage=0,story=false){this.stage=stage;this.score=0;this.rescued=0;this.credits=0;this.kills=0;this.resetLoadout();this.loadStage();this.mode=story?'story':'briefing';this.briefTime=0;this.storyTime=0;}
 confirm(){
  switch(this.mode){
   case'title':this.start();break;
   case'gameover':case'victory':this.mode='title';break;
   case'story':this.mode='briefing';this.briefTime=0;break;
   case'briefing':this.begin();break;
   case'pause':this.mode='play';break;
   case'result':this.nextStage();break;
   case'continue':this.continueGame();break;}}
 begin(){this.enterStage();this.voice('Mission '+['one','two','three','final'][this.stage]+'. Start!');this.sound('start');}
 nextStage(){if(this.stage>=LEVELS.length-1){this.mode='victory';this.save();this.sound('victory');this.voice('Mission complete! Congratulations!');return;}
  this.stage++;this.hp=this.dif.hp;this.grenades=Math.max(this.grenades,GRENADE_FLOOR);this.loadStage();this.mode='briefing';this.briefTime=0;}
 pause(){if(this.mode==='play')this.mode='pause';else if(this.mode==='pause')this.mode='play';}
 retry(){if(!['pause','gameover','continue'].includes(this.mode))return;this.resetLoadout();this.loadStage();this.enterStage();}
 // Metal Slug-style opening: the hero runs in from off-screen left and control starts once they reach the start mark.
 enterStage(){this.mode='play';this.intro=2.6;this.entering=true;this.x=this.camera-70;this.vx=0;this.face=1;}
 quit(){this.save();this.mode='title';}
 continueGame(){if(this.mode!=='continue')return;this.credits++;this.lives=this.dif.lives;this.hp=this.dif.hp;this.grenades=Math.max(this.grenades,GRENADE_FLOOR);this.mode='play';this.respawn();this.voice("Let's go!");}
 save(){this.best=Math.max(this.best,this.score);this.onSave(this.best);}

 loadStage(){
  const L=this.level;
  Object.assign(this,{x:180,y:FLOOR,vx:0,vy:0,face:1,grounded:true,crouch:false,invincible:0,entering:false,fireTimer:0,grenadeTimer:0,muzzle:0,coyote:0,jumpBuffer:0,dropTimer:0,standOn:'',
   camera:0,lock:null,shake:0,hitstop:0,combo:0,comboTimer:0,stageTime:0,stageRescued:0,stageKills:0,stageHits:0,support:0,supportTimer:0,
   hurtTimer:0,dying:0,knife:0,throwT:0,throwPending:false,aimLocal:0,lastShotWeapon:PISTOL,weaponPop:0,zoneIndex:0,celebrate:0,intro:0,banner:'',bannerTime:0,callout:null,result:null,continueTime:0,landed:0,
   enemies:[],bullets:[],particles:[],corpses:[],blasts:[],popups:[],pows:[],items:[],platforms:[],hazards:[],props:[],boss:null,ship:null,nextId:1,spawnQueue:[],supplies:[]});
  this.zones=[];let start=0;
  for(const [zi,z] of L.zones.entries()){
   this.zones.push({name:z.name,start,end:start+z.len,cleared:false,entered:zi===0,waves:z.waves.map(w=>({at:start+w[0],kind:w[1],n:w[2],entry:w[3],done:false})),arena:z.arena,arenaWave:-1,arenaDelay:0});
   // boats: 5th value = ferry swing (px) — wide water can only be crossed by riding the boat
   for(const [px,py,pw,type,amp] of z.plat)this.platforms.push({x:start+px,base:start+px,y:py,w:pw,h:20,type:type||'normal',amp:amp||52});
   for(const [kind,hx,hw] of z.hazards||[])this.hazards.push(kind==='water'?{x:start+hx,y:571,w:hw,h:150,kind}:{x:start+hx,y:568,w:hw,h:12,kind});
   for(const [kind,px] of z.props)this.props.push({x:start+px,y:FLOOR,kind,hp:kind==='barrel'?4:7,flash:0});
   for(const [kind,px,reward,weapon] of z.pows)this.pows.push({x:start+px,y:FLOOR,kind,state:kind==='cage'?'caged':'tied',hp:6,reward,weapon,t:rand(0,3),vy:0});
   for(const tx of z.turrets||[]){this.spawnEnemy(start+tx,FLOOR,'turret');this.enemies.at(-1).zone=zi;}
   start+=z.len;}
  this.bossStart=start;
  // Boss arena gimmicks: walker — a ledge to dodge stomp waves from; factory — floor conveyors pushing toward the boss;
  // harbor — water with a bobbing crate raft (the crane adds temporary crate platforms); fortress — open ground for fire patches.
  if(L.boss==='king')this.platforms.push({x:start+380,base:start+380,y:446,w:200,h:20,type:'normal'});
  if(L.boss==='cannon')for(const [px,pw] of [[260,240],[600,180]])this.platforms.push({x:start+px,base:start+px,y:564,w:pw,h:20,type:'belt'});
  // harbor: the player boards a big ship that casts off when the fight starts
  if(L.boss==='boat')this.ship={x:start+SHIP_SEA};
  this.banner='';this.bannerTime=0;}
 toast(s,t=2.4){this.banner=s;this.bannerTime=this.bannerMax=t;}
 call(text,sub='',voice=''){this.callout={text,sub,t:0};if(voice)this.voice(voice);}

 // ---- entities ----
 spawnEnemy(x,y,kind='grunt',entry=''){
  if(typeof kind==='number')kind=['grunt','flyer','heavy','hopper'][kind]||'grunt';
  // ground troops never appear standing on open water: move them to the far bank
  if(kind!=='flyer')for(const h of this.hazards)if(h.kind==='water'&&x>h.x-20&&x<h.x+h.w+20)x=h.x+h.w+40;
  const base=ENEMIES[kind],hp=Math.round((base.hp+this.stage*1.5)*this.dif.enemyHp);
  const e={id:this.nextId++,kind,x,y,vx:0,vy:0,hp,max:hp,t:rand(0,2),shot:rand(1.4,2.6)*this.dif.fire,flash:0,warn:0,facing:-1,walk:0,kick:0,zone:-1,
   state:entry==='P'?'para':entry?'enter':'idle',alert:kind==='turret'?1:0,startle:0,range:rand(240,420),launch:0,peek:0,stab:0,hopT:rand(.2,.8),air:false,arena:false,
   floor:FLOOR,perchL:-1e9,perchR:1e9,hold:{shield:300,heavy:380,bomber:360}[kind]||0,ofs:0,cover:0,coverIdx:-1};
  if(kind==='flyer'){e.y=Math.min(y,rand(170,250));e.state=entry?'enter':'idle';}
  if(entry==='P')e.vy=150;
  this.enemies.push(e);return e;}
 // Squads trickle in one by one (Metal Slug style) instead of popping in as a pile; members get distinct roles/slots.
 spawnWave(kind,n,entry,zone,arena=false,delay=0){
  const gap=entry==='P'?.45:kind==='hopper'?.3:kind==='flyer'?.4:.55;
  for(let i=0;i<n;i++)this.spawnQueue.push({t:delay+i*gap,kind,entry:entry||'R',zone,i,n,arena});
  this.updateSpawns(0);}
 updateSpawns(dt){
  for(const q of this.spawnQueue){q.t-=dt;if(q.t<=0)this.spawnMember(q);}
  this.spawnQueue=this.spawnQueue.filter(q=>q.t>0);}
 spawnMember(q){
  const {kind,zone,i,n}=q;let entry=q.entry,x,y=FLOOR,perch=null;
  if(entry==='T'){perch=['grunt','bomber','heavy','shield'].includes(kind)?this.perchFor(i):null;if(!perch)entry='R';}
  if(perch){x=perch.x+perch.w*(.3+.4*(Math.floor(i/2)%2));y=perch.y-180;}
  else if(entry==='L')x=this.camera-50;
  else if(entry==='P'){const span=770/n;x=this.camera+380+span*(i+.5)+rand(-span*.2,span*.2);y=-70-rand(0,50);}
  else x=this.camera+1330;
  if(kind==='flyer'&&entry!=='P')y=175+(i%3)*38;
  const e=this.spawnEnemy(x,y,kind,perch?'':entry);e.zone=zone;e.facing=entry==='L'?1:-1;e.arena=q.arena;
  if(perch){e.floor=perch.y;e.perchL=perch.x+16;e.perchR=perch.x+perch.w-16;e.air=true;e.vy=0;}
  // Roles: shields hold the front, heavies behind them, riflemen and pot throwers further back, each in its own slot.
  if(kind==='grunt')e.range=280+i*80+rand(0,40);
  else if(kind==='shield')e.hold=230+i*70;
  else if(kind==='heavy')e.hold=340+i*80;
  else if(kind==='bomber')e.hold=400+i*70;
  else if(kind==='flyer')e.ofs=(i-(n-1)/2)*120;
  return e;}
 // A plain platform ahead of the player (on screen or just beyond it) for snipers that drop in from above.
 perchFor(i){
  const c=this.platforms.filter(p=>p.type==='normal'&&p.x+p.w>this.camera+460&&p.x<this.camera+1500).sort((a,b)=>a.x-b.x);
  return c.length?c[i%c.length]:null;}
 takeCover(e){
  if(!['grunt','bomber','heavy'].includes(e.kind)||e.perchL>-1e8)return;
  let best=-1,bd=1e9;
  this.props.forEach((p,i)=>{
   if(p.kind!=='crate'||p.hp<=0||Math.abs(p.x-this.x)<220||p.x<this.camera+80||p.x>this.camera+W-80)return;
   if(Math.sign(p.x-this.x)!==Math.sign(e.x-this.x)||this.enemies.some(o=>o!==e&&o.hp>0&&o.coverIdx===i))return;
   const dd=Math.abs(p.x-e.x);if(dd<bd){bd=dd;best=i;}});
  if(best>=0){const p=this.props[best];e.coverIdx=best;e.cover=p.x+Math.sign(p.x-this.x)*46;}}
 // Crouch behind a claimed crate until it breaks or the hero gets around/close to it.
 holdCover(e,speed,dt){
  if(e.coverIdx<0)return false;const p=this.props[e.coverIdx];
  if(!p||p.hp<=0||Math.sign(p.x-this.x)!==Math.sign(e.x-this.x)||Math.abs(p.x-this.x)<150){e.coverIdx=-1;return false;}
  if(Math.abs(e.cover-e.x)>6)this.walkEnemy(e,Math.sign(e.cover-e.x),speed,dt);
  return true;}
 // Living ground troops keep a little elbow room so squads read as individuals, not a pile.
 separateEnemies(dt){
  const SEP=72,k=Math.min(1,dt*10);
  const g=this.enemies.filter(e=>e.hp>0&&e.kind!=='flyer'&&e.kind!=='turret'&&e.state!=='para'&&e.state!=='enter'&&!e.air&&!(e.launch>0)).sort((a,b)=>a.x-b.x);
  for(let j=1;j<g.length;j++){const a=g[j-1],b=g[j];if(Math.abs(a.y-b.y)>30)continue;const gap=b.x-a.x;
   if(gap<SEP){const push=(SEP-gap)*.5*k;a.x=clamp(a.x-push,a.perchL,a.perchR);b.x=clamp(b.x+push,b.perchL,b.perchR);}}
  // landed ground troops that end up over open water (pushed or hopped in) step back onto the nearer bank
  for(const e of g)if(e.y>=FLOOR-2)for(const h of this.hazards)if(h.kind==='water'&&e.x>h.x-20&&e.x<h.x+h.w+20){e.x=e.x-h.x<h.x+h.w-e.x&&!h.sea?h.x-20:h.x+h.w+20;break;}}

 // ---- main update ----
 update(dt,input={}){
  this.time+=dt;this.input=input;
  if(this.mode==='story'){this.storyTime+=dt*STORY_SPEED;if(this.storyTime>=STORY_LEN){this.mode='briefing';this.briefTime=0;}return;}
  if(this.mode==='briefing'){this.briefTime=(this.briefTime||0)+dt;return;}
  if(this.mode==='continue'){this.continueTime-=dt;if(this.continueTime<=0){this.mode='gameover';this.save();this.sound('gameover');this.voice('Game over');}return;}
  if(this.mode==='celebrate'){this.updateCelebrate(dt);return;}
  if(this.mode==='result'){this.result.t+=dt;this.updateFx(dt);return;}
  if(this.mode!=='play')return;
  if(this.hitstop>0){this.hitstop-=dt;return;}
  this.stageTime+=dt;this.intro=Math.max(0,this.intro-dt);
  for(const k of ['hurtTimer','weaponPop','invincible','knife','throwT','landed'])this[k]=Math.max(0,this[k]-dt);
  if(this.throwPending&&this.throwT<=THROW_TIME-THROW_RELEASE)this.launchGrenade();
  this.fireTimer-=dt;this.grenadeTimer-=dt;this.muzzle-=dt;this.comboTimer-=dt;this.bannerTime-=dt;this.shake=Math.max(0,this.shake-dt*1.8);
  if(this.callout){this.callout.t+=dt;if(this.callout.t>1.6)this.callout=null;}
  if(this.comboTimer<=0)this.combo=0;
  this.updatePlayer(dt,input);
  this.updateEnemies(dt);this.updateBoss(dt);this.updateSupplies(dt);this.updateBullets(dt);this.updatePows(dt);this.updateItems(dt);this.updateZones(dt);this.updateFx(dt);
  this.updateSupport(dt);this.updateCamera(dt);}

 updatePlayer(dt,input){
  if(this.dying>0){
   this.dying-=dt;this.vy+=1650*dt;this.x+=this.vx*dt;this.y=Math.min(FLOOR,this.y+this.vy*dt);
   if(this.dying<=0){if(this.lives<=0){this.mode='continue';this.continueTime=10;this.voice('Continue?');this.sound('continue');}else this.respawn();}
   return;}
  if(this.entering){input={right:this.x<ENTRY_X};if(!input.right)this.entering=false;}
  const axis=(input.right?1:0)-(input.left?1:0);
  this.crouch=this.grounded&&!!input.down;
  if(axis)this.face=Math.sign(axis);
  // Down + jump on a thin platform drops through it instead of jumping; belts and boats stay solid.
  if(input.jumpPressed){if(this.grounded&&input.down&&this.standOn&&this.standOn!=='belt'&&this.standOn!=='boat')this.dropTimer=.2;else this.jumpBuffer=.12;}
  this.dropTimer-=dt;this.jumpBuffer-=dt;this.coyote=this.grounded?.15:this.coyote-dt;
  if(this.jumpBuffer>0&&this.coyote>0){this.vy=-810;this.grounded=false;this.jumpBuffer=0;this.coyote=0;this.sound('jump');this.dust(this.x,this.y,6);}
  if(input.jumpReleased&&this.vy< -260)this.vy=-260;
  const target=axis*(this.crouch?95:300);
  this.vx+=clamp(target-this.vx,-2400*dt,2400*dt);
  const oldY=this.y,wasGrounded=this.grounded,fallSpeed=this.vy;
  this.vy=Math.min(1100,this.vy+1650*dt);this.x+=this.vx*dt;this.y+=this.vy*dt;this.grounded=false;this.standOn='';
  for(const p of this.platforms){
   if(p.type==='boat')p.x=p.base+Math.sin(this.time*1.3)*(p.amp||52);
   if(this.x>p.x-12&&this.x<p.x+p.w+12&&oldY<=p.y+3&&this.y>=p.y&&this.vy>=0&&!(this.dropTimer>0&&p.type!=='belt'&&p.type!=='boat')){
    this.y=p.y;this.vy=0;this.grounded=true;this.standOn=p.type;
    if(p.type==='belt')this.x+=95*dt;
    if(p.type==='boat')this.x+=Math.cos(this.time*1.3)*1.3*(p.amp||52)*dt;}}
  let water=false;
  for(const h of this.hazards)if(this.x>h.x&&this.x<h.x+h.w&&this.y>=564){
   if(h.kind==='water')water=true;
   else if(h.kind==='honey'||h.kind==='puddle'){this.vx*=.75;if(Math.random()<.1)this.particles.push({x:this.x,y:FLOOR-4,vx:rand(-30,30),vy:-rand(40,90),life:.4,max:.4,color:'#ffbf49',size:4,kind:'spark'});}
   else if(h.kind==='fire')this.hurt();
   else if(this.time%3<1.2)this.hurt();}
  if(this.y>=FLOOR&&!water){this.y=FLOOR;this.vy=0;this.grounded=true;}
  if(this.grounded&&!wasGrounded&&fallSpeed>420){this.dust(this.x,this.y,8);this.landed=.12;this.sound('land');}
  if(this.grounded&&Math.abs(this.vx)>200&&Math.floor(this.stageTime*6)!==Math.floor((this.stageTime-dt)*6))this.dust(this.x-this.face*12,this.y,2);
  if(this.y>800){this.hurt(true);return;}
  const left=Math.max(this.entering?this.camera-100:this.camera+30,this.lock?.left!=null?this.lock.left+30:-1e9),right=this.lock?this.lock.right-30:STAGES[this.stage].length-70;
  this.x=clamp(this.x,left,right);
  // Aim sweeps toward the requested direction, like a heavy machine gun spray.
  const up=!!input.up,down=!!input.down&&!this.grounded,diag=!!(input.left||input.right);
  const want=up?-Math.PI/2:down?(diag?Math.PI/4:Math.PI/2):0;
  const turn=(this.weapon===2||this.weapon===4?7:8.5)*dt;
  this.aimLocal+=clamp(want-this.aimLocal,-turn,turn);
  if(input.firePressed&&this.weapon===PISTOL&&this.fireTimer>.08)this.fireTimer=0;
  if(input.fire&&this.fireTimer<=0)this.shoot();
  if(input.grenadePressed&&this.grenades>0&&this.grenadeTimer<=0)this.throwGrenade();
  if(input.swapPressed&&this.unlocked.length>1){this.weapon=this.unlocked[(this.unlocked.indexOf(this.weapon)+1)%this.unlocked.length];this.weaponPop=1;this.sound('click');}
  this.collectPows();}
 aim(){const a=this.aimLocal||0;return{x:Math.cos(a)*this.face,y:Math.sin(a)};}

 shoot(){
  if(this.ammo[this.weapon]===0){this.dropWeapon();}
  const target=this.knifeTarget();
  if(target){this.knife=.22;this.fireTimer=.28;this.sound('knife');this.damageEnemy(target,8,'knife');this.burst(target.x-this.face*10,target.y-40,8,'#fff4be',200);return;}
  const w=WEAPONS[this.weapon],v=VISUALS[this.weapon];
  if(this.ammo[this.weapon]>0)this.ammo[this.weapon]--;
  const pose=weaponPose(this),a=pose.aim,spread=rand(-w.spread,w.spread),ang=Math.atan2(a.y,a.x)+spread;
  this.addBullet(pose.mx,pose.my,Math.cos(ang)*w.speed,Math.sin(ang)*w.speed,true,w.damage,v.kind);
  const b=this.bullets.at(-1);b.weapon=this.weapon;b.color=w.color;
  this.fireTimer=w.rate;this.muzzle=.09;this.lastShotWeapon=this.weapon;this.sound(v.sound);
  this.burst(pose.mx,pose.my,this.weapon===3?10:2,w.color,this.weapon===3?180:90);
  if(this.weapon===3){this.shake=Math.max(this.shake,.25);this.particles.push({x:pose.x-a.x*40,y:pose.y-a.y*40,vx:-a.x*160,vy:-a.y*160-40,life:.5,max:.5,color:'#d8c5c0',size:12,kind:'smoke'});}
  else this.particles.push({x:pose.x,y:pose.y-9,vx:-this.face*rand(70,130),vy:-rand(110,190),life:1.2,max:1.2,color:'#efc17c',size:3,kind:'casing',spin:rand(-12,12)});
  if(this.ammo[this.weapon]===0&&this.weapon!==PISTOL)this.dropWeapon();}
 knifeTarget(){return this.enemies.find(e=>e.hp>0&&e.kind!=='turret'&&e.kind!=='flyer'&&e.state!=='para'&&(e.x-this.x)*this.face>-34&&Math.abs(e.x-this.x)<80&&Math.abs(e.y-this.y)<60);}
 dropWeapon(){const old=this.weapon;if(old===PISTOL)return;this.unlocked=this.unlocked.filter(w=>w!==old);this.ammo[old]=0;this.weapon=PISTOL;this.weaponPop=1;this.toast('탄약 소진 · Glock 19');}
 throwGrenade(){this.grenades--;this.grenadeTimer=.4;this.throwT=THROW_TIME;this.throwPending=true;}
 launchGrenade(){this.throwPending=false;
  this.bullets.push({x:this.x+this.face*20,y:this.y-70,vx:this.face*430+this.vx*.4,vy:-560,friendly:true,damage:22,life:1.6,kind:'grenade',pierce:0,hit:[],bounces:0,spin:0});this.sound('throw');}
 addBullet(x,y,vx,vy,friendly,damage,kind){this.bullets.push({x,y,vx,vy,friendly,damage,life:kind==='wave'?3:2.5,kind,pierce:kind==='sniper'?3:0,hit:[]});return this.bullets.at(-1);}

 // ---- zones, waves, scroll locks ----
 updateZones(dt){
  this.updateSpawns(dt);
  if(this.boss){if(!this.boss.started&&this.x>=(this.ship?this.ship.x+60:this.bossStart+260))this.startBoss();return;}
  for(let i=0;i<this.zones.length;i++){
   const z=this.zones[i];
   if(!z.entered&&this.x>=z.start+20){z.entered=true;this.zoneIndex=i;this.toast(`AREA ${i+1} / ${this.zones.length} · ${z.name}`);}
   if(z.entered&&i>this.zoneIndex)this.zoneIndex=i;
   for(const w of z.waves)if(!w.done&&this.x>=w.at){w.done=true;this.spawnWave(w.kind,w.n,w.entry,i);}
   if(!z.cleared&&!this.lock&&this.x>=z.end-760&&this.zones.slice(0,i).every(p=>p.cleared)){
    this.lock={zone:i,cam:z.end-1280,right:z.end};z.arenaWave=-1;z.arenaDelay=.9;this.toast('적 부대 출현! · 전멸시켜라');this.sound('alarm');}}
  if(this.lock&&this.lock.zone!=null){
   const z=this.zones[this.lock.zone];
   const alive=this.enemies.filter(e=>e.zone===this.lock.zone&&e.arena&&e.hp>0).length+this.spawnQueue.filter(q=>q.zone===this.lock.zone&&q.arena).length;
   z.arenaDelay-=dt;
   if(alive<=1&&z.arenaDelay<=0&&z.arenaWave<z.arena.length-1){
    z.arenaWave++;z.arenaDelay=1.4;
    if(z.arenaWave>0)this.toast(z.arenaWave===z.arena.length-1?'최후의 부대 접근! · 버텨라':'적 증원 접근!',1.6);
    z.arena[z.arenaWave].forEach(([kind,n,entry],k)=>this.spawnWave(kind,n,entry,this.lock.zone,true,k*.4));}
   else if(alive===0&&z.arenaWave>=z.arena.length-1&&z.arenaDelay<=0){
    z.cleared=true;z.clearedAt=this.stageTime;this.score+=1000;this.lock=null;this.sound('clear');
    const last=this.lock===null&&this.zones.every(q=>q.cleared);
    this.toast(last?'전 구역 확보! · 보스 구역으로 진입':'구역 확보! +1000 · GO!');
    if(last)this.boss={started:false};}}}

 updateCamera(dt){
  const len=STAGES[this.stage].length;
  let target=clamp(this.x-470,0,len-W);
  if(this.lock)target=this.lock.cam;
  if(this.boss?.started)target=len-W;
  const next=this.camera+(target-this.camera)*(1-Math.exp(-dt*(this.lock?3.5:6)));
  this.camera=this.lock?next:Math.max(this.camera,next);}

 // ---- enemies ----
 updateEnemies(dt){
  const dif=this.dif;
  for(const e of this.enemies){
   e.t+=dt;e.flash=Math.max(0,e.flash-dt);e.kick=Math.max(0,e.kick-dt);e.startle=Math.max(0,e.startle-dt);e.peek=Math.max(0,e.peek-dt);
   if(e.hp<=0)continue;
   if(e.boat)this.rideBoat(e);
   const onScreen=e.x<this.camera+W+60&&e.x>this.camera-60;
   if(e.state==='para'){e.y+=e.vy*dt;e.x+=Math.sin(e.t*2)*20*dt;if(e.y>=e.floor){e.y=e.floor;e.state='idle';e.kick=.25;}continue;}
   if(e.launch>0){e.launch-=dt;e.vy+=1250*dt;e.x+=e.vx*dt;e.y+=e.vy*dt;if(e.y>=e.floor){e.y=e.floor;e.launch=0;e.kick=.25;e.vx=0;e.state='idle';}continue;}
   const dx=this.x-e.x,d=Math.sign(dx)||1,adx=Math.abs(dx);
   if(e.state==='enter'){
    const inside=e.x>this.camera+40&&e.x<this.camera+W-40;
    if(e.kind==='flyer')e.x+=Math.sign(this.camera+W/2-e.x)*150*dt;else{e.x+=Math.sign(this.camera+W/2-e.x)*140*dt;e.walk=1;}
    e.facing=Math.sign(this.camera+W/2-e.x)||-1;
    if(inside){e.state='idle';this.takeCover(e);}
    continue;}
   // Off-screen troops sleep, but the scroll lock waits on its arena squad: march stragglers (knocked out, landed or
   // moved past water) back in, or the area can never clear.
   if(!onScreen&&e.kind!=='turret'){if(this.lock&&e.arena){e.state='enter';e.air=false;e.vy=0;e.vx=0;if(e.kind!=='flyer')e.y=e.floor;}continue;}
   if(e.kind==='turret'&&(e.x>this.camera+W-20||e.x<this.camera-60))continue;
   if(!e.alert&&adx<560){e.alert=1;e.startle=.4;if(e.kind!=='flyer'){e.vy=-200;e.air=true;}this.sound('alert');}
   if(e.air){e.vy+=1400*dt;e.y+=e.vy*dt;e.x=clamp(e.x+(e.vx||0)*dt,e.perchL,e.perchR);if(e.y>=e.floor&&e.vy>0){e.y=e.floor;e.air=false;e.vy=0;e.vx=0;}}
   if(e.startle>0)continue;
   if(this.considerFerry(e))continue;
   e.facing=e.kind==='shield'&&e.peek<=0&&adx<40?e.facing:d;
   e.shot-=dt;e.walk=0;
   const fire=(rate)=>{e.shot=rand(rate*.8,rate*1.2)*dif.fire-this.stage*.12;e.kick=.22;e.warn=0;};
   switch(e.kind){
    case'grunt':{
     if(this.holdCover(e,ENEMIES.grunt.speed+this.stage*8,dt)){}
     else if(adx>e.range+40)this.walkEnemy(e,d,ENEMIES.grunt.speed+this.stage*8,dt);
     else if(adx<e.range-140&&adx>90)this.walkEnemy(e,-d,40,dt);
     if(adx<70&&Math.abs(this.y-e.y)<50){e.stab+=dt;e.warn=1;if(e.stab>.45){e.stab=0;e.kick=.3;if(Math.abs(this.x-e.x)<80)this.hurt();}}
     else{e.stab=0;e.warn=e.shot<.45?1:0;if(e.shot<=0){fire(2.4);this.enemyShot(e,0);}}
     break;}
    case'hopper':{
     e.hopT-=dt;
     if(!e.air&&e.hopT<=0){e.air=true;e.vy=-rand(330,480);e.vx=d*ENEMIES.hopper.speed*rand(.9,1.3);e.hopT=rand(.35,.7);}
     e.walk=1;e.warn=adx<180?1:0;
     break;}
    case'flyer':{
     const ty=190+Math.sin(e.t*1.7)*40;e.y+=(ty-e.y)*Math.min(1,dt*2);
     const tx=this.x+e.ofs+Math.sin(e.t*.9)*90;e.x+=clamp(tx-e.x,-ENEMIES.flyer.speed*dt,ENEMIES.flyer.speed*dt);
     e.warn=e.shot<.4&&adx<120?1:0;
     if(e.shot<=0&&adx<140){fire(1.9);const b=this.addBullet(e.x,e.y+10,0,60,false,1,'bomb');b.vy=80;}
     else if(e.shot<=0)e.shot=.3;
     break;}
    case'shield':{
     if(adx>e.hold)this.walkEnemy(e,d,ENEMIES.shield.speed,dt);
     e.warn=e.shot<.5?1:0;if(e.shot<.5)e.peek=Math.max(e.peek,.5);
     if(e.shot<=0){fire(2.8);e.peek=.7;this.enemyShot(e,0);}
     break;}
    case'bomber':{
     if(this.holdCover(e,ENEMIES.bomber.speed,dt)){}
     else if(adx>e.hold+100)this.walkEnemy(e,d,ENEMIES.bomber.speed,dt);else if(adx<e.hold-100)this.walkEnemy(e,-d,55,dt);
     e.warn=e.shot<.5?1:0;
     if(e.shot<=0){fire(2.9);const t=1.05,x=e.x+d*20,y=e.y-70,tx=this.x+rand(-40,40);const b=this.addBullet(x,y,(tx-x)/t,(FLOOR-8-y-.5*950*t*t)/t,false,1,'lob');b.life=3;}
     break;}
    case'heavy':{
     if(this.holdCover(e,ENEMIES.heavy.speed,dt)){}
     else if(adx>e.hold)this.walkEnemy(e,d,ENEMIES.heavy.speed,dt);
     e.warn=e.shot<.6?1:0;
     if(e.shot<=0){fire(3);for(const off of [-.2,-.07,.07,.2])this.enemyShot(e,off);}
     break;}
    case'turret':{
     e.facing=d;e.warn=e.shot<.6?1:0;
     if(e.shot<=0){fire(2.6);e.burst=3;e.burstT=0;}
     if(e.burst>0){e.burstT-=dt;if(e.burstT<=0){e.burst--;e.burstT=.14;this.enemyShot(e,rand(-.05,.05),true);}}
     break;}}
   if(e.kind!=='turret'&&e.kind!=='flyer'&&Math.abs(dx)<34&&Math.abs(e.y-this.y)<60&&(e.kind==='hopper'||e.air))this.hurt();
   }
  this.separateEnemies(dt);
  this.enemies=this.enemies.filter(e=>e.hp>0&&(e.state==='enter'||e.x>this.camera-220));}
 // Harbor ferries: ground troops treat a boat as a bridge. Held up at a wide channel while the player is across (or on
 // the boat), they hop aboard when it docks at their bank, ride it, and jump off once it docks at the player's bank.
 dockedBoat(h,side){return this.platforms.find(p=>p.type==='boat'&&p.x+p.w>=h.x&&p.x<=h.x+h.w&&(side<0?p.x-h.x<50:h.x+h.w-(p.x+p.w)<50))||null;}
 considerFerry(e){
  if(e.air||e.perchL>-1e8||e.boat||!['grunt','shield','bomber','heavy'].includes(e.kind))return false;
  for(const h of this.hazards){if(h.kind!=='water'||h.w<=240||h.sea)continue;
   const side=e.x>=h.x+h.w&&e.x<h.x+h.w+110&&this.x<h.x+h.w?1:e.x<=h.x&&e.x>h.x-110&&this.x>h.x?-1:0;if(!side)continue;
   const p=this.dockedBoat(h,side);if(!p||this.enemies.filter(o=>o.hp>0&&o.boat===p).length>=3)continue;
   const tx=p.x+p.w*(side>0?.75:.25);Object.assign(e,{boat:p,boatX:p.x,floor:p.y,air:true,vy:-520,vx:(tx-e.x)/.64,facing:-side});return true;}
  return false;}
 rideBoat(e){const p=e.boat;if(e.air){e.boatX=p.x;return;}
  e.x+=p.x-e.boatX;e.boatX=p.x;e.perchL=p.x+16;e.perchR=p.x+p.w-16;e.x=clamp(e.x,e.perchL,e.perchR);
  const side=Math.sign(this.x-e.x)||1,h=this.hazards.find(h=>h.kind==='water'&&p.x+p.w>=h.x&&p.x<=h.x+h.w);if(!h)return;
  if(((side<0&&this.x<h.x)||(side>0&&this.x>h.x+h.w))&&this.dockedBoat(h,side)===p){const bank=side<0?h.x-50:h.x+h.w+50;
   Object.assign(e,{boat:null,floor:FLOOR,perchL:-1e9,perchR:1e9,air:true,vy:-420,vx:(bank-e.x)/.69,facing:side});}}
 walkEnemy(e,dir,speed,dt){if(e.air)return;const nx=e.x+dir*speed*dt;if(nx<e.perchL||nx>e.perchR){e.facing=Math.sign(this.x-e.x)||e.facing;return;}const w=e.perchL<-1e8&&this.hazards.find(h=>h.kind==='water'&&nx>h.x-20&&nx<h.x+h.w+20);
  // narrow water is hopped over; wide water (harbor ferry) stops them at the bank, where they hold and fire
  if(w){if(w.w<=240){e.air=true;e.vy=-640;e.vx=dir*330;}else e.facing=Math.sign(this.x-e.x)||e.facing;return;}e.x=nx;e.walk=1;e.facing=Math.sign(this.x-e.x)||e.facing;}
 enemyShot(e,offset,big=false){
  const dir=Math.sign(this.x-e.x)||1,size=ENEMIES[e.kind].size,x=e.x+dir*size*.3,y=e.y-size*(e.kind==='turret'?.55:.35);
  const a=Math.atan2(this.y-40-y,this.x-x)+offset,s=(big?320:250+this.stage*18)*this.dif.bullet;
  this.addBullet(x,y,Math.cos(a)*s,Math.sin(a)*s,false,1,big?'shell':'enemy');this.sound('enemyShot');}
 damageEnemy(e,n,src='shot',bullet=null){
  if(e.hp<=0)return false;
  if(e.kind==='shield'&&e.peek<=0&&bullet&&src==='shot'&&Math.sign(bullet.vx)===-e.facing&&Math.abs(bullet.vy)<Math.abs(bullet.vx)*.7){
   this.sound('ting');this.particles.push({x:e.x+e.facing*40,y:e.y-45,vx:-bullet.vx*.2,vy:-rand(80,200),life:.3,max:.3,color:'#fff',size:4,kind:'spark'});return 'block';}
  e.hp-=n;e.flash=.1;
  if(e.hp<=0)this.killEnemy(e,src);
  return true;}
 killEnemy(e,src){
  const base=ENEMIES[e.kind];
  this.combo++;this.comboTimer=2.8;this.kills++;this.stageKills++;
  const pts=Math.round(base.score*Math.min(this.combo,8)*this.dif.score/10)*10;this.score+=pts;
  this.popups.push({x:e.x,y:e.y-base.size,text:'+'+pts,t:0});
  const blast=src==='explosion';
  this.corpses.push({x:e.x,y:e.y,vx:(blast?rand(-260,260):-Math.sign(this.x-e.x)*rand(90,160)),vy:blast?-rand(520,720):-rand(220,320),spin:blast?rand(-12,12):Math.sign(e.x-this.x)*3,rot:0,size:base.size,kind:e.kind,life:blast?1.8:1.2,max:blast?1.8:1.2,style:src,facing:e.facing});
  this.burst(e.x,e.y-base.size*.4,src==='knife'?10:14,'#ffc86a',230);
  for(let i=0;i<4;i++)this.particles.push({x:e.x,y:e.y-base.size*.4,vx:rand(-200,200),vy:-rand(150,380),life:1,max:1,color:pick(['#ffbf49','#f7e3a1','#6fbf5a']),size:rand(4,7),kind:'debris',spin:rand(-10,10)});
  this.sound(e.kind==='turret'||e.kind==='heavy'?'bigDie':'enemyDie');
  if(e.kind==='turret'||e.kind==='heavy'){this.explode(e.x,e.y-50,120,0,'fx');this.hitstop=.07;}
  else if(this.combo>=3)this.hitstop=Math.max(this.hitstop,.025);
  if(this.combo>0&&this.combo%5===0){this.call(this.combo+' COMBO!','','');this.sound('combo');}
  if(Math.random()<(e.kind==='heavy'?.6:.12))this.dropItem(e.x,e.y-40,Math.random()<.5?'ammo':'medal');}

 // ---- bullets & explosions ----
 updateBullets(dt){
  const explosions=[];
  for(const b of this.bullets){
   b.life-=dt;const old={x:b.x,y:b.y};
   if(['grenade','lob','honey','shell2','fire','crate'].includes(b.kind))b.vy+=950*dt;
   if(b.kind==='spray')b.vy+=420*dt;
   if(b.kind==='bomb')b.vy+=700*dt;
   b.x+=b.vx*dt;b.y+=b.vy*dt;
   if(b.kind==='rocket'){b.vx*=1+dt*1.2;b.vy*=1+dt*1.2;if(Math.random()<.8)this.particles.push({x:b.x,y:b.y,vx:-b.vx*.06,vy:rand(-15,15),life:.45,max:.45,color:'#e7dbd6',size:rand(6,11),kind:'smoke'});}
   if(b.kind==='grenade'){b.spin+=dt*14;if(b.y>=568){b.y=568;b.vy*=-.45;b.vx*=.7;b.bounces++;this.sound('bounce');}if(b.bounces>=2||b.life<=0||this.grenadeContact(old,b)){explosions.push({x:b.x,y:b.y-10,r:165,dmg:22,owner:'player'});b.life=0;}}
   if(b.kind==='crate'&&b.y>=FLOOR-56){b.life=0;this.addShake(.3);this.sound('crate');this.dust(b.x,FLOOR,8);if(Math.abs(b.x-this.x)<52&&this.y>FLOOR-60)this.hurt();
    this.platforms.push({x:b.x-40,base:b.x-40,y:FLOOR-56,w:80,h:20,type:'crate',life:9});}
   if(b.kind==='spray'&&b.y>=568){b.life=0;if(Math.random()<.12)this.hazards.push({x:b.x-40,y:568,w:80,h:12,kind:'puddle',life:4});}
   if(b.kind==='fire'&&b.y>=568){b.life=0;explosions.push({x:b.x,y:b.y-10,r:120,dmg:0,owner:'enemy'});this.hazards.push({x:b.x-55,y:568,w:110,h:12,kind:'fire',life:5});}
   if(b.kind==='lob'||b.kind==='honey'||b.kind==='bomb'||b.kind==='shell2'){
    if(b.y>=568){b.life=0;
     if(b.kind==='honey'){this.burst(b.x,b.y,14,'#ffbf49',220);this.hazards.push({x:b.x-50,y:568,w:100,h:12,kind:'puddle',life:6});if(Math.abs(b.x-this.x)<70)this.hurt();}
     else explosions.push({x:b.x,y:b.y-10,r:b.kind==='shell2'?110:80,dmg:0,owner:'enemy'});}}
   if(b.kind==='wave'){b.y=FLOOR-14;if(Math.random()<.5)this.dust(b.x,FLOOR,1);}
   if(b.friendly&&b.kind!=='grenade'){
    for(const e of this.enemies){
     if(e.hp<=0||b.hit.includes(e.id))continue;
     const s=ENEMIES[e.kind].size;
     if(intersects(old,b,{x:e.x-s*.4,y:e.y-s*.75,w:s*.8,h:s*.75})){
      const r=this.damageEnemy(e,b.damage,'shot',b);b.hit.push(e.id);
      this.spark(b.x,b.y,b.kind);
      if(b.kind==='rocket')explosions.push({x:b.x,y:b.y,r:150,dmg:16,owner:'player'});
      if(r==='block'||b.pierce<=0){b.life=0;break;}b.pierce--;}}
    if(b.life>0)for(const c of this.pows)if(c.state==='caged'&&intersects(old,b,{x:c.x-43,y:c.y-95,w:86,h:95})){this.damageCage(c,b.damage);this.spark(b.x,b.y,'cage');b.life=0;break;}
    if(b.life>0)for(const p of this.props)if(p.hp>0&&intersects(old,b,{x:p.x-28,y:p.y-56,w:56,h:56})){this.damageProp(p,b.damage);this.spark(b.x,b.y,'prop');if(b.kind==='rocket')explosions.push({x:b.x,y:b.y,r:150,dmg:16,owner:'player'});b.life=0;break;}
    if(b.life>0&&this.boss?.started&&!this.boss.dead&&this.boss.state!=='enter'){const bs=this.boss;
     for(const k of ['A','B'])if(b.life>0&&!bs.parts[k].dead&&intersects(old,b,this.bossPartBox(k))){this.damageBossPart(k,b.damage);this.spark(b.x,b.y,'boss');b.life=0;if(b.kind==='rocket')explosions.push({x:b.x,y:b.y,r:150,dmg:10,owner:'player'});}
     if(b.life>0&&intersects(old,b,this.bossBox())){this.hitBossBody(b.damage);this.spark(b.x,b.y,'boss');b.life=0;if(b.kind==='rocket')explosions.push({x:b.x,y:b.y,r:150,dmg:10,owner:'player'});}}}
   else if(!b.friendly&&this.dying<=0){
    const h=this.crouch?38:68,box={x:this.x-15,y:this.y-h,w:30,h};
    if(b.kind==='wave'?Math.abs(b.x-this.x)<26&&this.y>FLOOR-30:intersects(old,b,box)){this.hurt();if(b.kind!=='wave'){b.life=0;if(['lob','bomb','shell2'].includes(b.kind))explosions.push({x:b.x,y:b.y,r:80,dmg:0,owner:'enemy'});}}}
   if(b.x<this.camera-300||b.x>this.camera+W+400||b.y< -400||b.y>780)b.life=0;}
  this.bullets=this.bullets.filter(b=>b.life>0);
  for(const p of explosions)this.explode(p.x,p.y,p.r,p.dmg,p.owner);}
 spark(x,y,kind){this.particles.push({x,y,vx:0,vy:0,life:.12,max:.12,color:'#fff8d0',size:kind==='rocket'?18:11,kind:'flash'});this.burst(x,y,3,'#fff1b7',150);}
 explode(x,y,r=150,dmg=22,owner='player'){
  this.blasts.push({x,y,r,t:0,max:.55});
  for(let i=0;i<8;i++)this.particles.push({x:x+rand(-r*.3,r*.3),y:y+rand(-r*.3,r*.1),vx:rand(-60,60),vy:-rand(30,110),life:rand(.7,1.3),max:1.3,color:'#c9bcb8',size:rand(r*.12,r*.22),kind:'smoke'});
  for(let i=0;i<6;i++)this.particles.push({x,y,vx:rand(-320,320),vy:-rand(200,520),life:1.1,max:1.1,color:pick(['#6b4b3f','#8c6b55','#ffbf49']),size:rand(4,8),kind:'debris',spin:rand(-14,14)});
  this.addShake(r>140?.55:.35);this.sound(r>140?'explode':'explodeSmall');
  if(owner==='enemy'){if(Math.hypot(this.x-x,this.y-30-y)<r*.6)this.hurt();return;}
  if(owner==='fx'||!dmg)return;
  for(const e of this.enemies)if(Math.hypot(e.x-x,e.y-ENEMIES[e.kind].size*.4-y)<r)this.damageEnemy(e,dmg,'explosion');
  for(const c of this.pows)if(c.state==='caged'&&Math.hypot(c.x-x,c.y-40-y)<r)this.damageCage(c,9);
  for(const p of this.props)if(p.hp>0&&Math.hypot(p.x-x,p.y-28-y)<r)this.damageProp(p,dmg);
  if(this.boss?.started&&!this.boss.dead&&this.boss.state!=='enter'){const near=h=>x>h.x-r*.5&&x<h.x+h.w+r*.5&&y>h.y-r*.5&&y<h.y+h.h+r*.5;
   for(const k of ['A','B'])if(!this.boss.parts[k].dead&&near(this.bossPartBox(k)))this.damageBossPart(k,dmg);
   if(near(this.bossBox())){this.hitBossBody(dmg);this.hitstop=Math.max(this.hitstop,.04);}}}
 addShake(n){this.shake=Math.min(1,Math.max(this.shake,n));}
 damageProp(p,n){if(p.hp<=0)return;p.hp-=n;p.flash=.1;if(p.hp>0){this.sound('thud');return;}
  this.score+=50;
  if(p.kind==='barrel'){this.explode(p.x,p.y-30,170,24,'player');}
  else{this.sound('crate');for(let i=0;i<8;i++)this.particles.push({x:p.x,y:p.y-30,vx:rand(-240,240),vy:-rand(200,450),life:1,max:1,color:pick(['#c99152','#a87444','#f6ce86']),size:rand(6,12),kind:'debris',spin:rand(-12,12)});
   if(Math.random()<.7)this.dropItem(p.x,p.y-40,pick(['weapon','medal','food','ammo']));}}
 damageCage(c,n){if(c.state!=='caged')return;c.hp-=n;c.flash=.1;this.sound('thud');
  if(c.hp<=0){c.state='tied';this.sound('crate');for(let i=0;i<10;i++)this.particles.push({x:c.x,y:c.y-50,vx:rand(-240,240),vy:-rand(150,400),life:1,max:1,color:'#7d8b78',size:rand(5,9),kind:'debris',spin:rand(-12,12)});}}

 // ---- POWs (captured honeybees) & items ----
 updatePows(dt){
  for(const p of this.pows){p.t+=dt;
   if(p.state==='thanks'&&p.t>.55&&!p.dropped){p.dropped=true;this.dropItem(p.x+this.face*10,p.y-60,p.reward,p.weapon);}
   if(p.state==='thanks'&&p.t>1.3){p.state='leave';p.t=0;}
   if(p.state==='leave'){p.x-=260*dt;p.y-=140*dt;}}
  this.pows=this.pows.filter(p=>p.state!=='leave'||p.t<2.5);}
 collectPows(){for(const p of this.pows)if(p.state==='tied'&&Math.abs(this.x-p.x)<60&&Math.abs(this.y-p.y)<90){
  p.state='thanks';p.t=0;this.rescued++;this.stageRescued++;this.score+=Math.round(1000*this.dif.score);
  this.popups.push({x:p.x,y:p.y-110,text:'THANK YOU!',t:0,big:true});this.sound('rescue');this.voice('Thank you!');
  for(let i=0;i<10;i++)this.particles.push({x:p.x,y:p.y-50,vx:rand(-160,160),vy:-rand(120,300),life:.9,max:.9,color:pick(['#ffd8d9','#fff2b6','#bee9d0']),size:rand(3,6),kind:'spark'});}}
 dropItem(x,y,kind,weapon){
  if(kind==='weapon'&&weapon==null)weapon=this.randomWeapon();
  this.items.push({x,y,vy:-260,kind,weapon,t:0,grounded:false,life:kind==='weapon'||kind==='support'?999:12});}
 updateItems(dt){
  for(const it of this.items){
   it.t+=dt;it.life-=dt;
   if(!it.grounded){it.vy+=1200*dt;it.y+=it.vy*dt;
    let floor=FLOOR;for(const p of this.platforms)if(it.x>p.x&&it.x<p.x+p.w&&it.y-it.vy*dt<=p.y+2&&it.y>=p.y)floor=Math.min(floor,p.y);
    if(this.hazards.some(h=>h.kind==='water'&&it.x>h.x&&it.x<h.x+h.w))floor=H+100;
    if(it.y>=floor){it.y=floor;it.vy=0;it.grounded=true;}}
   if(this.dying<=0&&Math.abs(this.x-it.x)<48&&this.y-90<it.y&&this.y+10>it.y-40){this.takeItem(it);it.life=-1;}}
  this.items=this.items.filter(it=>it.life>0&&it.y<H+50);}
 takeItem(it){
  switch(it.kind){
   case'weapon':this.giveWeapon(it.weapon);break;
   case'bomb':this.grenades=Math.min(30,this.grenades+10);this.call('BOMB +10','수류탄 보충','Bomb!');this.sound('pickup');break;
   case'food':this.hp=Math.min(this.dif.hp,this.hp+2);this.score+=500;this.popups.push({x:it.x,y:it.y-50,text:'+500',t:0});this.call('HONEY CHURRO!','체력 회복','');this.sound('food');break;
   case'medal':this.score+=1000;this.popups.push({x:it.x,y:it.y-50,text:'+1000',t:0});this.sound('medal');break;
   case'ammo':{if(this.weapon!==PISTOL)this.ammo[this.weapon]=Math.min(WEAPONS[this.weapon].ammo,this.ammo[this.weapon]+Math.ceil(WEAPONS[this.weapon].ammo*.4));else this.giveWeapon(this.randomWeapon());  // ammo with only the Glock in hand turns into a gun
this.score+=100;this.sound('pickup');break;}
   case'support':this.support=22;this.supportTimer=0;this.call('HONEY SUPPORT!','22초 지원 사격','Support!');this.sound('rescue');break;}}
 weaponPool(){return WEAPON_UNLOCK.slice(0,this.stage+1).flat();}
 randomWeapon(){return pick(this.weaponPool());}
 giveWeapon(w){
  const had=this.unlocked.includes(w)&&this.ammo[w]>0;
  if(!this.unlocked.includes(w))this.unlocked.push(w);
  this.ammo[w]=WEAPONS[w].ammo<0?-1:had?Math.min(WEAPONS[w].ammo*2,this.ammo[w]+WEAPONS[w].ammo):WEAPONS[w].ammo;
  this.weapon=w;this.weaponPop=1.2;this.muzzle=0;
  if(w!==PISTOL){this.call(WEAPONS[w].name+'!',WEAPONS[w].label,WEAPONS[w].call);this.sound('weapon');}}
 updateSupport(dt){
  if(this.support<=0)return;
  this.support-=dt;this.supportTimer-=dt;
  if(this.supportTimer<0){this.supportTimer=.3;
   const ox=this.x-this.face*55,oy=this.y-95,t=this.enemies.find(e=>e.hp>0&&(e.x-this.x)*this.face>0&&Math.abs(e.x-this.x)<650);
   const a=t?Math.atan2(t.y-30-oy,t.x-ox):this.face>0?.1:Math.PI-.1;
   this.addBullet(ox,oy,Math.cos(a)*900,Math.sin(a)*900,true,3,'support');}}

 // ---- player damage & death ----
 hurt(fall=false){
  if(this.dying>0||this.mode!=='play')return;
  if((this.invincible>0||this.entering||this.knife>0)&&!fall)return;  // brief i-frames during the melee swing
  this.hp-=fall?2:1;this.stageHits++;this.invincible=1.6;this.hurtTimer=.3;this.addShake(.5);this.combo=0;this.sound('hurt');
  this.burst(this.x,this.y-40,12,'#ffafc3',200);
  if(fall){this.respawnPoint();this.y=-40;this.vy=0;}
  else if(this.hp>0){this.vx=-this.face*240;this.vy=Math.min(this.vy,-220);this.grounded=false;}
  if(this.hp<=0){this.hp=0;this.lives--;this.dying=1.4;this.vx=-this.face*160;this.vy=-420;this.sound('die');
   if(this.weapon!==PISTOL){this.ammo[this.weapon]=0;this.unlocked=this.unlocked.filter(w=>w!==this.weapon);this.weapon=PISTOL;}}}
 // Respawns drop in from the top-left of the current screen (past open water and anything the lock walls off).
 respawnPoint(){let x=Math.max(this.camera+140,this.lock?.left!=null?this.lock.left+60:-1e9);for(let i=0;i<40&&this.hazards.some(h=>h.kind==='water'&&x>h.x-30&&x<h.x+h.w+30);i++)x+=30;this.x=x;this.vx=0;}
 respawn(){this.hp=this.dif.hp;this.respawnPoint();this.y=-60;this.vy=200;this.dying=0;this.invincible=3;this.grenades=Math.max(this.grenades,GRENADE_FLOOR);this.hurtTimer=0;this.toast(`다시 출동! · 남은 목숨 ${this.lives}`);}

 // ---- bosses ----
 // Bosses are rigs of parts (BOSS_RIG): a body plus weapon A/B with their own HP, and a hatch that releases troops and supply bees.
 // Pattern 0 fires weapon A, 1 weapon B, 2 is the body's own move; a destroyed weapon's pattern is skipped.
 // A rig with left:true sits on the left of the arena mirrored to face right (boss.flip). The renderer draws the rig
 // inside a mirrored transform, so it asks for raw (unmirrored) points; gameplay always uses world points.
 bossSign(raw=false){return this.boss.flip&&!raw?-1:1;}
 bossFwd(){return this.boss.flip?1:-1;}  // direction the boss faces
 bossBodyPt(u,v,raw=false){const b=this.boss,r=BOSS_RIG[b.type],S=512*r.k;return{x:b.x+(u-.5)*S*this.bossSign(raw),y:b.y+(v-r.base)*S};}
 bossPartPt(name,cu,cv,raw=false){
  const b=this.boss,r=BOSS_RIG[b.type],P=r[name],S=512*r.k,pv=this.bossBodyPt(P.u,P.v,raw),a=(b.parts?.[name]?.ang||0)+(P.rot||0);
  const dx=(cu-P.pu)*S*P.ps,dy=(cv-P.pv)*S*P.ps;return{x:pv.x+(dx*Math.cos(a)-dy*Math.sin(a))*this.bossSign(raw),y:pv.y+dx*Math.sin(a)+dy*Math.cos(a)};}
 bossPartBox(name,raw=false){const b=this.boss,r=BOSS_RIG[b.type],P=r[name],S=512*r.k*P.ps,pv=this.bossBodyPt(P.u,P.v,raw),q=P.box;
  return{x:pv.x+(this.bossSign(raw)>0?(q[0]/512-P.pu)*S:-(q[2]/512-P.pu)*S),y:pv.y+(q[1]/512-P.pv)*S,w:(q[2]-q[0])/512*S,h:(q[3]-q[1])/512*S};}
 bossMuzzle(name,raw=false){const P=BOSS_RIG[this.boss.type][name];return this.bossPartPt(name,P.mu,P.mv,raw);}
 bossBox(){const b=this.boss,r=BOSS_RIG[b.type],S=512*r.k,q=r.box;
  return{x:b.x+(this.bossSign()>0?(q[0]/512-.5)*S:-(q[2]/512-.5)*S),y:b.y+(q[1]/512-r.base)*S,w:(q[2]-q[0])/512*S,h:(q[3]-q[1])/512*S};}
 // Clamp an x into the open floor in front of the boss (crates, supply drops).
 bossFrontClamp(x,margin,edge){const h=this.bossBox();return this.boss.flip?clamp(x,h.x+h.w+margin,this.camera+W-edge):clamp(x,this.camera+edge,h.x-margin);}
 bossHalf(){const r=BOSS_RIG[this.boss.type];return(r.box[2]-r.box[0])/1024*512*r.k;}
 startBoss(){
  const type=this.level.boss,c=BOSSES[type],r=BOSS_RIG[type],len=STAGES[this.stage].length,hp=Math.round(c.hp*(this.difficulty==='hard'?1.25:this.difficulty==='easy'?.8:1));
  const flip=!!r.left,home=flip?len-W+r.home:len-r.home,part=k=>({hp:Math.round(hp*r[k].hp),max:Math.round(hp*r[k].hp),dead:false,flash:0,recoil:0,ang:0});
  this.boss={type,started:true,x:home,home,y:FLOOR,hp,max:hp,active:true,dead:false,t:0,phase:1,flash:0,warn:false,pattern:0,state:'enter',clock:2.6,recoil:0,track:0,vy:0,vx:0,air:false,shots:0,
   sweep:null,zones:[],aimX:null,aimY:null,burst:false,parts:{A:part('A'),B:part('B')},hatch:{clock:7,open:0,released:false,count:0},charge:0,chargeDir:0,sink:0,landed:false,crashed:false,flip};
  const b=this.boss;
  if(type==='king'){b.y=FLOOR-900;b.air=true;}
  else if(type==='boat')b.y=FLOOR+420;
  else b.x=len+420;
  this.lock=flip?{zone:null,cam:len-W,right:len,left:home+this.bossHalf()-40}:{zone:null,cam:len-W,right:home-this.bossHalf()+40};
  // Harbor: the ship casts off — open sea opens up behind it, where the landing ship surfaces.
  if(this.ship){this.ship.sea={x:this.ship.x,y:571,w:0,h:150,kind:'water',sea:true};this.hazards.push(this.ship.sea);this.lock.left=this.ship.x-10;}
  this.call('WARNING!',c.title+' · '+c.name,type==='tank'?'Warning! Big tank approaching!':'Warning! Boss approaching!');
  this.sound('warning');this.addShake(.4);}
 bossEnter(dt){
  const b=this.boss,len=STAGES[this.stage].length;
  switch(b.type){
   case'king':// drops from the sky and slams down
    if(b.air){b.vy+=1900*dt;b.y+=b.vy*dt;if(b.y>=FLOOR){b.y=FLOOR;b.air=false;b.vy=0;b.landed=true;this.addShake(1);this.sound('slam');this.dust(b.x,FLOOR,26);this.dust(b.x-160,FLOOR,10);this.dust(b.x+160,FLOOR,10);
     for(const p of this.platforms)p.shake=.8;}}
    break;
   case'cannon':// rams in from the right through the factory wall
    b.x+=(b.home-b.x)*(1-Math.exp(-dt*3));this.addShake(.14);
    if(!b.crashed&&b.x<len+120){b.crashed=true;this.explode(len-40,FLOOR-160,190,0,'fx');
     for(let i=0;i<18;i++)this.particles.push({x:len-30,y:FLOOR-rand(20,320),vx:-rand(120,520),vy:-rand(80,420),life:1.6,max:1.6,color:pick(['#b98b5a','#8a6a4a','#d8c0a0']),size:rand(10,22),kind:'debris',spin:rand(-10,10)});}
    break;
   case'boat':{// rises out of the water
    const k=Math.max(0,b.clock)/2.6;b.y=FLOOR+420*k*k;
    if(Math.random()<.5)this.particles.push({x:b.x+rand(-280,280),y:FLOOR-4,vx:rand(-90,90),vy:-rand(160,380),life:.8,max:.8,color:'#e9fbff',size:rand(5,10),kind:'spark'});break;}
   default:// rolls in, crushing what's in its way
    b.x+=(b.home-b.x)*(1-Math.exp(-dt*2.4));this.addShake(.12);
    for(const p of this.props){const h=this.bossBox();if(p.hp>0&&p.x>h.x&&p.x<h.x+h.w)this.damageProp(p,99);}}
  if(b.clock<=0){b.x=b.home;b.y=FLOOR;b.air=false;b.vy=0;b.state='idle';b.clock=1;}}
 updateBoss(dt){
  const b=this.boss;if(!b?.started||b.dead)return;
  const trackX=b.x,grounded=!b.air;
  b.t+=dt;b.clock-=dt;b.flash=Math.max(0,b.flash-dt);b.recoil=Math.max(0,b.recoil-dt*3);b.warn=b.state==='windup';
  for(const p of this.platforms)if(p.shake)p.shake=Math.max(0,p.shake-dt);
  for(const k of ['A','B']){const p=b.parts[k];p.flash=Math.max(0,p.flash-dt);p.recoil=Math.max(0,p.recoil-dt*3);}
  if(this.ship?.sea){const open=Math.min(1,b.t/2.2);this.ship.sail=(this.ship.sail||0)+SHIP_SPEED*dt*open;  // scenery scroll (eases in as it casts off)
   this.ship.sea.x=this.ship.x-SHIP_SEA*open;this.ship.sea.w=SHIP_SEA*open;}
  if(b.state==='enter'){this.bossEnter(dt);if(grounded)b.track+=b.x-trackX;return;}
  if(b.phase===1&&(b.hp<b.max*.5||(b.parts.A.dead&&b.parts.B.dead)))this.bossRage();
  if(b.air){b.vy+=1600*dt;b.y+=b.vy*dt;b.x+=b.vx*dt;if(b.y>=FLOOR){b.y=FLOOR;b.air=false;b.vy=0;this.bossLand();}}
  const fast=b.phase===2;
  this.bossAim(dt);
  if(b.charge)this.bossChargeStep(dt);
  if(b.state==='idle'){
   if(!b.air&&!b.charge){if(b.type==='king')b.x+=(b.home-b.x)*Math.min(1,dt*1.5);else if(b.type!=='boat')b.x=b.home+Math.sin(b.t*1.2)*12;}
   if(b.clock<=0){if(b.pattern!==2&&b.parts[b.pattern===0?'A':'B'].dead)this.bossNextPattern();b.state='windup';b.clock=fast?.75:1;this.planBoss();this.sound('charge');}}
  else if(b.state==='windup'&&b.clock<=0){b.state='attack';b.clock=fast?1:1.25;b.shots=0;this.bossAttack();}
  else if(b.state==='attack'){this.bossSustain(dt);if(b.clock<=0&&!b.air&&!b.charge&&b.sweep==null){b.state='recover';b.clock=.6;}}
  else if((b.state==='recover'||b.state==='break')&&b.clock<=0){this.bossNextPattern();b.state='idle';b.clock=fast?.5:1.05;}
  if(b.type==='boat')b.y=FLOOR+Math.sin(b.t*1.6)*6;
  this.updateHatch(dt);
  if(grounded)b.track+=b.x-trackX;
  const h=this.bossBox();
  if(!b.flip&&(b.type!=='king'||!b.air))this.lock.right=Math.min(STAGES[this.stage].length,b.x-this.bossHalf()+40);
  if(this.dying<=0&&overlap({x:this.x-14,y:this.y-68,w:28,h:68},{x:h.x+30,y:h.y+h.h*.35,w:h.w-60,h:h.h*.65}))this.hurt();}
 bossNextPattern(){const b=this.boss;for(let i=0;i<3;i++){b.pattern=(b.pattern+1)%3;if(b.pattern===2||!b.parts[b.pattern===0?'A':'B'].dead)return;}b.pattern=2;}
 // Guns track the player smoothly within their arc.
 bossAim(dt){
  const b=this.boss;
  for(const k of ['A','B']){const p=b.parts[k],P=BOSS_RIG[b.type][k];if(p.dead||!P.aim)continue;
   const pv=this.bossBodyPt(P.u,P.v),norm=a=>((a+Math.PI*3)%(Math.PI*2))-Math.PI,locked=b.state==='attack'&&b.pattern===(k==='A'?0:1)&&b.aimX!=null;
   const target=clamp(norm(Math.atan2((locked?b.aimY:this.y)-50-pv.y,((locked?b.aimX:this.x)-pv.x)*this.bossSign())-Math.PI),-P.aim,P.aim);p.ang+=clamp(target-p.ang,-dt*1.6,dt*1.6);}}
 bossRage(){const b=this.boss;b.phase=2;b.state='break';b.clock=1.3;b.sweep=null;b.charge=0;this.addShake(.8);this.hitstop=.12;
  for(let i=0;i<14;i++)this.particles.push({x:b.x+rand(-200,170),y:b.y-rand(60,260),vx:rand(-260,220),vy:rand(-420,-120),life:1.8,max:1.8,color:'#8c9b70',size:rand(14,26),kind:'armor',spin:rand(-8,8)});
  this.explode(b.x+this.bossFwd()*40,b.y-200,170,0,'fx');this.call('ARMOR BREAK!','코어 노출 · 공격이 거세진다!','');this.sound('alarm');b.hatch.clock=Math.min(b.hatch.clock,2.5);}
 bossMouth(){const b=this.boss;return b.pattern===2||b.parts[b.pattern===0?'A':'B'].dead?this.bossBodyPt(...BOSS_RIG[b.type].core):this.bossMuzzle(b.pattern===0?'A':'B');}
 bossAttack(){
  const b=this.boss,fast=b.phase===2,s=this.dif.bullet,ax=b.aimX??this.x,ay=b.aimY??this.y;b.recoil=1;this.addShake(.25);this.sound('bossFire');
  const part=b.pattern===0?'A':b.pattern===1?'B':null;if(part)b.parts[part].recoil=1;
  const m=this.bossMouth(),lob=(kind,tx,t)=>{const bl=this.addBullet(m.x,m.y,(tx-m.x)/t,(FLOOR-8-m.y-.5*950*t*t)/t,false,1,kind);bl.life=4;return bl;};
  switch(b.type+b.pattern){
   case'king0':case'tank1':b.sweep=0;break;                                 // chin guns burst / gatling sweep
   case'king1':for(let i=0;i<(fast?6:4);i++)lob('lob',ax+(i-(fast?2.5:1.5))*95,1+i*.1);break;  // missile volley
   case'king2':b.air=true;b.vy=-860;b.vx=clamp((Math.max(ax+170,b.home-520)-b.x)/1.075,-520,120);this.sound('jump');break;  // jump stomp
   case'cannon0':for(let i=0;i<(fast?6:4);i++)lob('honey',ax+(i-(fast?2.5:1.5))*90,1+i*.12);break;  // honey mortar
   case'cannon1':b.sweep=0;break;                                            // flamethrower
   case'cannon2':case'tank2':b.charge=1;b.chargeDir=-1;this.sound('charge');break;  // ram / advance
   case'boat0':for(let i=0;i<(fast?5:3);i++)lob('shell2',ax+(i-(fast?2:1))*120,1.1+i*.15);break;  // deck guns
   case'boat1':{const c=this.bossMuzzle('B');for(let i=0;i<(fast?3:2);i++){const x=this.bossFrontClamp(ax+(i-(fast?1:.5))*150,60,80),bl=this.addBullet(x,-60-i*80,0,120,false,1,'crate');bl.life=4;}
    if(this.enemies.filter(e=>e.hp>0).length<5){const e=this.spawnEnemy(c.x,c.y,'grunt');e.launch=1.5;e.vx=this.bossFwd()*180;e.vy=-200;e.alert=1;e.arena=true;}break;}  // crane drops
   case'boat2':for(let i=0;i<(fast?4:3);i++){const e=this.spawnEnemy(b.x+this.bossFwd()*(120+i*30),b.y-180,'hopper');e.launch=1.6;e.vx=this.bossFwd()*(260+i*90);e.vy=-420-i*50;e.alert=1;}break;  // landing party
   case'tank0':for(let i=0;i<(fast?2:1);i++){const bl=lob('fire',ax+i*140,1.15+i*.2);bl.life=5;}break;}}  // main cannon fire shells
 // Lock the attack target when the windup starts and describe the danger zones so the renderer can telegraph them.
 planBoss(){
  const b=this.boss,m=this.bossMouth(),fast=b.phase===2,zones=[];b.aimX=this.x;b.aimY=this.y;
  const aim=Math.atan2(this.y-40-m.y,this.x-m.x),cone=(angle,spread,r)=>zones.push({kind:'cone',x:m.x,y:m.y,angle,spread,r:r||1500});
  const land=(x,y,vx,vy,g)=>{const a=.5*g,t=(-vy+Math.sqrt(vy*vy+4*a*Math.max(0,FLOOR-8-y)))/(2*a);return x+vx*t;};
  const spot=(x,r)=>zones.push({kind:'spot',x,r}),h=this.bossBox();
  switch(b.type+b.pattern){
   case'king0':cone(aim,.4);break;
   case'king1':for(let i=0;i<(fast?6:4);i++)spot(this.x+(i-(fast?2.5:1.5))*95,70);break;
   case'king2':{const lx=b.x+clamp((Math.max(this.x+170,b.home-520)-b.x)/1.075,-520,120)*1.075;spot(lx,150);zones.push({kind:'lane',x:lx-120,dir:-1},{kind:'lane',x:lx+120,dir:1});break;}
   case'cannon0':for(let i=0;i<(fast?6:4);i++)spot(this.x+(i-(fast?2.5:1.5))*90,70);break;
   case'cannon1':cone(Math.PI+.12,.5,520);break;
   case'cannon2':case'tank2':zones.push({kind:'lane',x:h.x,dir:-1});break;
   case'boat0':for(let i=0;i<(fast?5:3);i++)spot(this.x+(i-(fast?2:1))*120,80);break;
   case'boat1':for(let i=0;i<(fast?3:2);i++)zones.push({kind:'drop',x:this.bossFrontClamp(this.x+(i-(fast?1:.5))*150,60,80)});break;
   case'boat2':for(let i=0;i<(fast?4:3);i++)zones.push({kind:'drop',x:land(b.x+this.bossFwd()*(120+i*30),b.y-180,this.bossFwd()*(260+i*90),-420-i*50,1250)});break;
   case'tank0':for(let i=0;i<(fast?2:1);i++)spot(this.x+i*140,90);break;
   case'tank1':cone(Math.PI-.25,.9);break;}
  b.zones=zones;}
 bossSustain(dt){
  const b=this.boss;if(b.sweep==null)return;
  b.sweep+=dt;const fast=b.phase===2,s=this.dif.bullet;
  if(b.type==='cannon'){// flamethrower: short-range spray of honey globs
   const m=this.bossMuzzle('B'),every=fast?.035:.05,max=fast?34:24;
   while(b.shots*every<b.sweep&&b.shots<max){const a=Math.PI+.12+rand(-.25,.25),sp=rand(380,520)*s,bl=this.addBullet(m.x,m.y,Math.cos(a)*sp,Math.sin(a)*sp,false,1,'spray');bl.life=rand(.8,1.05);b.shots++;}
   b.parts.B.recoil=.5;if(b.shots>=max)b.sweep=null;return;}
  const k=b.type==='king'?'A':'B',m=this.bossMuzzle(k),every=fast?.07:.1,max=fast?14:10;
  while(b.shots*every<b.sweep&&b.shots<max){
   const t=b.shots/(max-1),a=b.type==='king'?Math.atan2((b.aimY??this.y)-40-m.y,(b.aimX??this.x)-m.x)+Math.sin(t*6)*.1:Math.PI+.5-t*1.0;
   const sp=330*s;this.addBullet(m.x,m.y,Math.cos(a)*sp,Math.sin(a)*sp,false,1,'enemy');b.shots++;b.parts[k].recoil=.6;this.sound('enemyShot');}
  if(b.shots>=max)b.sweep=null;}
 // Ram (cannon train) / advance (tank): drive at the player, then back off to home.
 bossChargeStep(dt){
  const b=this.boss,stop=b.home-(b.phase===2?420:330);
  if(b.chargeDir<0){b.x-=(b.phase===2?520:400)*dt;this.addShake(.1);if(Math.random()<.4)this.dust(b.x+this.bossHalf()*.6,FLOOR,1);
   if(b.type==='tank'&&b.phase===2&&Math.random()<dt*1.2&&this.enemies.filter(e=>e.hp>0).length<5){const m=this.bossMuzzle('A'),e=this.spawnEnemy(m.x,m.y,'hopper');e.launch=1.4;e.vx=-240;e.vy=-300;e.alert=1;}
   if(b.x<=stop){b.x=stop;b.chargeDir=1;this.addShake(.4);this.sound('slam');}}
  else{b.x+=200*dt;if(b.x>=b.home){b.x=b.home;b.charge=0;b.chargeDir=0;}}}
 bossLand(){const b=this.boss;this.addShake(.7);this.sound('slam');this.dust(b.x,FLOOR,18);
  for(const p of this.platforms)p.shake=.6;
  for(const dir of [-1,1])this.addBullet(b.x+dir*120,FLOOR-14,dir*360*this.dif.bullet,0,false,1,'wave');
  if(b.phase===2){for(const dir of [-1,1])this.addBullet(b.x+dir*120,FLOOR-14,dir*250*this.dif.bullet,0,false,1,'wave');}}
 // Hatch: every so often it pops open and releases soldiers, and (every other time, or when the player runs low) a supply bee.
 updateHatch(dt){
  const b=this.boss,hc=b.hatch;hc.clock-=dt;if(hc.open>0)hc.open-=dt;
  if(hc.clock<=0&&b.state!=='break'){hc.clock=b.phase===2?7:10;hc.open=1.6;hc.released=false;this.sound('alarm');}
  if(hc.open>0&&hc.open<1.1&&!hc.released){hc.released=true;hc.count++;
   const P=BOSS_RIG[b.type].H,o=this.bossBodyPt(P.u,P.v),kinds={king:['grunt','hopper'],cannon:['bomber','grunt'],boat:['hopper','grunt'],tank:['grunt','heavy']}[b.type];
   const n=b.phase===2?2:1;
   if(this.enemies.filter(e=>e.hp>0).length<6)for(let i=0;i<n;i++){const e=this.spawnEnemy(o.x+this.bossFwd()*20,o.y-30,kinds[(hc.count+i)%2]);e.launch=1.6;e.vx=this.bossFwd()*(200+i*110);e.vy=-420-i*60;e.alert=1;}
   const low=this.grenades===0||this.hp<this.dif.hp*.6||this.weapon===PISTOL;
   if(hc.count%2===1||low)this.releaseSupply(o.x,o.y-40);}}
 releaseSupply(x,y){
  const item=this.grenades===0?'bomb':  // bombs only when out
   this.hp<this.dif.hp?'food':this.weapon===PISTOL?'weapon':'ammo';
  const tx=this.bossFrontClamp(this.x+rand(-80,80),90,120);
  this.supplies.push({x,y,tx,ty:rand(200,250),item,weapon:item==='weapon'?this.randomWeapon():null,t:0,state:'fly',dropped:false});
  this.popups.push({x,y:y-30,text:'보급!',t:0});this.sound('rescue');}
 updateSupplies(dt){
  for(const s of this.supplies){s.t+=dt;
   if(s.state==='fly'){const dx=s.tx-s.x,dy=s.ty-s.y,d=Math.hypot(dx,dy),sp=280*dt;
    if(d<=sp+2){s.x=s.tx;s.y=s.ty;s.state='drop';s.t=0;}else{s.x+=dx/d*sp;s.y+=dy/d*sp;}}
   else if(s.state==='drop'){if(!s.dropped&&s.t>.25){s.dropped=true;this.dropItem(s.x,s.y+20,s.item,s.weapon);}if(s.t>.6){s.state='leave';s.t=0;}}
   else{s.x-=220*dt;s.y-=180*dt;}}
  this.supplies=this.supplies.filter(s=>s.state!=='leave'||s.t<2.5);}
 // A grenade goes off the moment it touches a live enemy or the boss.
 grenadeContact(old,b){if(this.enemies.some(e=>{const s=ENEMIES[e.kind].size;return e.hp>0&&intersects(old,b,{x:e.x-s*.4,y:e.y-s*.75,w:s*.8,h:s*.75});}))return true;
  const bs=this.boss;return !!(bs?.started&&!bs.dead&&bs.state!=='enter'&&intersects(old,b,this.bossBox()));}
 // Weapons have their own HP (not shown on screen): shooting one off ends its attack and chips the core.
 damageBossPart(name,n){
  const b=this.boss;if(!b?.started||b.dead||b.state==='enter')return;
  const p=b.parts[name];if(p.dead)return;p.hp-=n;p.flash=.06;this.score+=5;
  if(p.hp<=0){p.hp=0;p.dead=true;const m=this.bossPartBox(name);
   this.explode(m.x+m.w/2,m.y+m.h/2,170,0,'fx');this.hitstop=.08;this.score+=Math.round(1500*this.dif.score);
   this.popups.push({x:m.x+m.w/2,y:m.y,text:'+'+Math.round(1500*this.dif.score),t:0,big:true});
   this.bossDebris(m.x+m.w/2,m.y+m.h/2,6);
   this.call('WEAPON DESTROYED!',name==='A'?BOSS_RIG[b.type].nameA:BOSS_RIG[b.type].nameB,'');
   b.hp=Math.max(1,b.hp-Math.round(b.max*.1));
   if((b.pattern===0&&name==='A')||(b.pattern===1&&name==='B')){b.sweep=null;if(b.state==='windup'||b.state==='attack'){b.state='recover';b.clock=.4;}}}}
 // Body hits: armored (30%) while either weapon still works; the exposed core in phase 2 takes full damage.
 hitBossBody(n){const b=this.boss;this.damageBoss(b.phase===1&&(!b.parts.A.dead||!b.parts.B.dead)?n*.3:n);}
 bossDebris(x,y,n){for(let i=0;i<n;i++)this.particles.push({x:x+rand(-30,30),y:y+rand(-30,30),vx:rand(-360,260),vy:-rand(260,620),life:1.8,max:1.8,color:'#6b4b3f',size:rand(34,56),kind:'bossdebris',chunk:i%4,sheet:BOSS_RIG[this.boss.type].sheet,spin:rand(-8,8)});}
 damageBoss(n){
  const b=this.boss;if(!b?.started||b.dead||b.state==='enter')return;
  b.hp-=n;b.flash=.06;this.score+=5;
  if(b.hp<=0){
   b.hp=0;b.dead=true;b.active=false;b.sink=0;b.sweep=null;b.charge=0;const c=BOSSES[b.type];this.score+=Math.round(c.score*this.dif.score);
   for(const k of ['A','B'])if(!b.parts[k].dead){b.parts[k].dead=true;const m=this.bossPartBox(k);this.bossDebris(m.x+m.w/2,m.y+m.h/2,3);}
   this.bullets.forEach(x=>{if(!x.friendly)x.life=0;});
   for(const e of this.enemies)if(e.hp>0){e.hp=0;this.corpses.push({x:e.x,y:e.y,vx:rand(-260,260),vy:-rand(500,700),spin:rand(-12,12),rot:0,size:ENEMIES[e.kind].size,kind:e.kind,life:1.8,max:1.8,style:'explosion',facing:e.facing,settle:0});}
   this.enemies=[];this.spawnQueue=[];this.hitstop=.25;this.addShake(1);this.sound('bossDie');
   // MISSION COMPLETE waits until the wreck has finished blowing apart (see updateCelebrate).
   this.mode='celebrate';this.celebrate=CELEBRATE_TIME;this.chain=0;this.callout=null;this.save();}}
 updateCelebrate(dt){
  this.celebrate-=dt;this.chain-=dt;this.shake=Math.max(0,this.shake-dt*1.2);
  // A win mid-jump still lands first; the victory dance only starts on the ground.
  if(!this.grounded&&this.dying<=0){const oldY=this.y;this.vy=Math.min(1100,this.vy+1650*dt);this.vx*=.9;this.x+=this.vx*dt;this.y+=this.vy*dt;
   for(const p of this.platforms)if(this.x>p.x-12&&this.x<p.x+p.w+12&&oldY<=p.y+3&&this.y>=p.y&&this.vy>=0){this.y=p.y;this.grounded=true;}
   if(this.y>=FLOOR){this.y=FLOOR;this.grounded=true;}
   if(this.grounded){this.vy=0;this.vx=0;this.dust(this.x,this.y,8);this.landed=.12;}}
  if(this.callout)this.callout.t=Math.min(this.callout.t+dt*.5,1.2);
  const b=this.boss;b.sink=Math.min(1,(b.sink||0)+dt/3.2);b.t+=dt;
  if(this.celebrate>CELEBRATE_BURST-.2&&this.chain<=0){this.chain=.16;const h=this.bossBox();this.explode(h.x+rand(0,h.w),h.y+rand(0,h.h),rand(90,170),0,'fx');this.shake=Math.min(this.shake,.35);  // chain blasts rumble gently; the final burst still jolts
  }
  if(this.celebrate<=CELEBRATE_CALLOUT&&!b.cleared){b.cleared=true;this.call('MISSION COMPLETE!','','Mission complete!');}
  if(this.celebrate<=CELEBRATE_BURST&&!b.burst){b.burst=true;this.explode(b.x,b.y-150,260,0,'fx');this.addShake(1);this.bossDebris(b.x,b.y-150,8);
   for(let i=0;i<40;i++)this.particles.push({x:b.x+rand(-180,120),y:b.y+rand(-200,-70),vx:rand(-420,300),vy:rand(-650,-150),life:3,max:3,color:'#fff',size:rand(20,36),kind:'fish',spin:rand(-8,8)});}
  this.updateFx(dt);
  if(this.celebrate<=0)this.finishStage();}
 finishStage(){
  const time=Math.floor(this.stageTime),par=this.level.par;
  const rows=[
   {label:'허니비 구출',detail:`${this.stageRescued} × 1000`,value:this.stageRescued*1000},
   {label:'처치한 과메기',detail:`${this.stageKills} × 50`,value:this.stageKills*50},
   {label:'클리어 시간',detail:`${Math.floor(time/60)}:${String(time%60).padStart(2,'0')}`,value:Math.max(0,par-time)*20},
   {label:'노 데미지',detail:this.stageHits?`피격 ${this.stageHits}회`:'PERFECT!',value:this.stageHits?0:5000}];
  const bonus=rows.reduce((n,r)=>n+r.value,0),total=this.stageRescued+(this.stageHits?0:2)+(time<par?1:0);
  this.score+=bonus;this.save();
  this.result={rows,bonus,rank:total>=6?'S':total>=4?'A':total>=2?'B':'C',t:0};
  this.mode='result';this.sound('result');}

 // ---- particles & effects ----
 updateFx(dt){
  for(const p of this.particles){p.life-=dt;p.x+=p.vx*dt;p.y+=p.vy*dt;
   if(p.kind==='smoke'){p.vy-=20*dt;p.vx*=.98;p.size+=dt*14;}
   else if(p.kind!=='flash'){p.vy+=(p.kind==='fish'?700:900)*dt;
    if((p.kind==='casing'||p.kind==='debris')&&p.y>FLOOR-2&&p.vy>0){p.y=FLOOR-2;p.vy*=-.35;p.vx*=.6;}}
   if(p.spin)p.rot=(p.rot||0)+p.spin*dt;}
  this.particles=this.particles.filter(p=>p.life>0).slice(-320);
  for(const c of this.corpses){c.life-=dt;c.vy+=1300*dt;c.x+=c.vx*dt;c.y+=c.vy*dt;c.rot+=c.spin*dt;
   if(c.y>=FLOOR&&c.vy>0){c.y=FLOOR;c.vy*=-.25;c.vx*=.5;c.spin*=.4;if(c.style!=='explosion'&&Math.abs(c.vy)<80){c.vy=0;c.spin=0;}}
   // Ease into the knocked-out pose instead of snapping, so the body never visibly pops in size.
   if(c.vy===0){c.settle=Math.min(1,(c.settle||0)+dt*6);c.rot+=(0-c.rot)*Math.min(1,dt*10);}}
  this.corpses=this.corpses.filter(c=>c.life>0);
  for(const b of this.blasts)b.t+=dt;this.blasts=this.blasts.filter(b=>b.t<b.max);
  for(const p of this.popups)p.t+=dt;this.popups=this.popups.filter(p=>p.t<(p.big?1.4:.9));
  for(const p of this.props)p.flash=Math.max(0,p.flash-dt);
  for(const p of this.pows)p.flash=Math.max(0,(p.flash||0)-dt);
  for(const h of this.hazards)if(h.life!=null)h.life-=dt;this.hazards=this.hazards.filter(h=>h.life==null||h.life>0);
  for(const p of this.platforms)if(p.life!=null)p.life-=dt;this.platforms=this.platforms.filter(p=>p.life==null||p.life>0);}
 burst(x,y,count,color,speed){for(let i=0;i<count;i++){const a=rand(0,Math.PI*2),s=rand(speed*.3,speed),life=rand(.2,.6);this.particles.push({x,y,vx:Math.cos(a)*s,vy:Math.sin(a)*s,life,max:life,color,size:rand(2,6),kind:'spark'});}}
 dust(x,y,n){for(let i=0;i<n;i++)this.particles.push({x:x+rand(-14,14),y:y-4,vx:rand(-90,90),vy:-rand(10,60),life:rand(.3,.55),max:.55,color:'#efe2cf',size:rand(5,10),kind:'smoke'});}
}
const api={STORY_LEN,WEAPON_UNLOCK,THROW_TIME,CELEBRATE_BURST,SHIP_SEA,Game,STAGES,LEVELS,WEAPONS,VISUALS,ENEMIES,BOSSES,BOSS_RIG,DIFFICULTY,PISTOL,W,H,FLOOR,playerFrame,weaponPose,intersects,clamp};
root.HoneyGame=api;if(typeof module!=='undefined')module.exports=api;
})(typeof window!=='undefined'?window:globalThis);
