const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const listeners={};let tick;const gradient={addColorStop(){}};
const ctx=new Proxy({measureText:s=>({width:s.length*10}),createLinearGradient:()=>gradient,createRadialGradient:()=>gradient},{get:(o,k)=>o[k]||(()=>{})});
const canvas={style:{},width:1280,height:720,focus(){},setPointerCapture(){},getBoundingClientRect:()=>({left:0,top:0,width:1280,height:720}),getContext:()=>ctx,addEventListener:(n,f)=>(listeners[n]??=[]).push(f)};
const sandbox={HoneyVisuals:require('../web/visuals.js'),HoneyGame:require('../web/game.js'),console,Map,Set,JSON,Promise,Image:class{constructor(){this.width=1024;this.height=1024;}set src(v){queueMicrotask(()=>this.onload());}},document:{querySelector:s=>s==='#game'?canvas:{remove(){},textContent:'',addEventListener(){}},addEventListener(){}},
 localStorage:{getItem:()=>null,setItem(){}},performance:{now:()=>0},requestAnimationFrame:f=>tick=f,queueMicrotask,setTimeout};
sandbox.window={addEventListener(){}};sandbox.globalThis=sandbox;
vm.createContext(sandbox);vm.runInContext(fs.readFileSync('web/render.js','utf8'),sandbox);
setTimeout(()=>{const g=sandbox.window.__honey.game;g.start();g.confirm();g.entering=false;g.sound=()=>{};let time=0;const frame=()=>tick(time+=17);
 const emit=(name,id,x,y)=>{for(const f of listeners[name]||[])f({pointerId:id,pointerType:'touch',clientX:x,clientY:y,preventDefault(){}});};
 emit('pointerdown',1,165,612);emit('pointerdown',2,1182,618);frame();assert(g.input.right&&g.input.fire,'simultaneous move and fire');
 emit('pointerup',2,1182,618);frame();assert(g.input.right&&!g.input.fire,'fire release preserves movement');
 emit('pointermove',1,160,570);frame();assert(g.input.right&&g.input.up,'diagonal aim from the pad');
 emit('pointermove',1,60,612);frame();assert(g.input.left&&!g.input.right,'drag changes direction');
 emit('pointercancel',1,60,612);frame();assert(!g.input.left,'cancel releases movement');
 emit('pointerdown',3,1068,656);frame();assert(g.vy<0,'jump button jumps');emit('pointerup',3,1068,656);
 emit('pointerdown',4,1229,51);frame();assert.equal(g.mode,'pause','pause button');
 console.log('PASS touch controls: multitouch, 8-way pad, release, drag, cancellation, jump and pause');},50);
