const assert=require('node:assert/strict');const {Game,weaponPose}=require('../web/game.js');
const g=new Game();g.start();g.begin();g.hurtTimer=0;g.dying=0;g.knife=0;g.x=300;g.y=576;g.vx=0;g.stageTime=0;
for(let weapon=0;weapon<6;weapon++)for(const face of [-1,1]){
 g.weapon=weapon;g.face=face;g.grounded=true;g.crouch=false;g.aim=()=>({x:0,y:-1});g.muzzle=0;
 let p=weaponPose(g);assert(p.up&&p.aimFrame===0);assert(p.my<p.y);assert(Math.sign(p.x-g.x)===face);
 const anchorY=p.y;g.muzzle=.09;p=weaponPose(g);assert.equal(p.aimFrame,1);assert(p.by>0);assert(Number.isFinite(anchorY));
 g.aim=()=>({x:face/Math.sqrt(2),y:-1/Math.sqrt(2)});p=weaponPose(g);assert(!p.up,'diagonal keeps the front-facing body');assert(p.my<p.y);
 g.aim=()=>({x:0,y:-1});g.grounded=false;assert.equal(weaponPose(g).aimFrame,6);
 g.grounded=true;g.crouch=true;assert.equal(weaponPose(g).aimFrame,7);
 g.crouch=false;g.aim=()=>({x:face,y:0});assert(!weaponPose(g).up);
}
g.aim=()=>({x:0,y:-1});g.crouch=false;g.grounded=true;g.vx=300;const walk=new Set();for(let i=0;i<20;i++){g.stageTime=i*.06;walk.add(weaponPose(g).aimFrame);}assert(walk.has(2)&&walk.has(3),'rear walk cycle while moving');
console.log('PASS rear aim: six weapons, both facings, recoil, diagonal front lean, rear walk, airborne, crouch and forward fallback');
