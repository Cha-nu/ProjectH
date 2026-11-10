/* Honey Churros — synthesized audio: step-sequenced music, layered SFX and an announcer voice.
   Everything is generated with Web Audio at runtime; no sample files. Safe to load without AudioContext. */
(function(root){'use strict';
const midi=n=>{const m=/^([A-G])(#|b)?(\d)$/.exec(n);if(!m)return null;return 12*(+m[3]+1)+{C:0,D:2,E:4,F:5,G:7,A:9,B:11}[m[1]]+(m[2]==='#'?1:m[2]==='b'?-1:0);};
const clamp01=v=>Math.min(1,Math.max(0,v));
const hz=m=>440*Math.pow(2,(m-69)/12);

// Pattern notation: one token per 16th step. Note = C4/F#3, '-' = hold previous, '.' = rest.
function parse(src){const t=src.trim().split(/\s+/),events=[];
 for(let i=0;i<t.length;i++){const m=midi(t[i]);if(m==null)continue;let len=1;while(t[i+len]==='-')len++;events.push({step:i,midi:m,len});}
 return {events,len:t.length};}
const bars=(...b)=>b.join(' ');
const rep=(s,n)=>Array(n).fill(s).join(' ');
function track(def){const out={bpm:def.bpm,loop:def.loop!==false,channels:[],drums:def.drums||null};let len=0;
 for(const [name,src] of Object.entries(def.parts)){const p=parse(src);len=Math.max(len,p.len);out.channels.push({name,...p});}
 out.len=def.len||len;return out;}

const DR={
 rock:{kick:'x.......x.x.....',snare:'....x.......x...',hat:'x.x.x.x.x.x.x.x.'},
 drive:{kick:'x...x...x...x...',snare:'....x.......x..x',hat:'xxx.xxx.xxx.xxx.'},
 march:{kick:'x.....x.x.......',snare:'....x.x.....x.xx',hat:'x.x.x.x.x.x.x.x.'},
 boss:{kick:'x..x..x.x..x..x.',snare:'....x.......x.x.',hat:'xxxxxxxxxxxxxxxx'},
 swing:{kick:'x.....x...x.....',snare:'....x.......x...',hat:'x..x..x.x..x..x.'}};

const TRACKS={
 title:track({bpm:116,drums:DR.march,parts:{
  lead:bars('C5 - - - G4 - C5 - E5 - - - D5 - C5 -','D5 - - - A4 - D5 - F5 - - - E5 - D5 -','E5 - - - C5 - E5 - G5 - - - A5 - G5 -','F5 - E5 - D5 - B4 - C5 - - - . . . .'),
  bass:bars(rep('C3 . C3 . G2 . G2 .',2),rep('D3 . D3 . A2 . A2 .',2),rep('C3 . C3 . E3 . E3 .',2),'F2 . F2 . G2 . G2 .','C3 . . . C2 . . .'),
  pad:bars('E4 - - - - - - - - - - - - - - -','F4 - - - - - - - - - - - - - - -','G4 - - - - - - - - - - - - - - -','A4 - - - - - - - G4 - - - - - - -')}}),
 town:track({bpm:150,drums:DR.rock,parts:{
  lead:bars('E5 - G5 - C6 - B5 A5 G5 - E5 - D5 - - -','C5 - E5 - A5 - G5 E5 D5 - C5 - A4 - - -','F5 - A5 - C6 - A5 F5 G5 - A5 - G5 - F5 -','E5 - D5 - B4 - D5 - G5 - - - . . G4 -',
   'C5 - C5 D5 E5 - C5 - G5 - - - E5 - - -','A5 - G5 - E5 - C5 - D5 - - - . . . .','F5 - F5 G5 A5 - F5 - C6 - B5 - A5 - G5 -','B5 - - - D6 - - - C6 - - - . . . .'),
  bass:bars('C2 . C3 . C2 . C3 . C2 . C3 . G2 . B2 .','A1 . A2 . A1 . A2 . A1 . A2 . E2 . G2 .','F1 . F2 . F1 . F2 . F1 . F2 . C2 . F2 .','G1 . G2 . G1 . G2 . G1 . G2 . B1 . D2 .',
   'C2 . C3 . C2 . C3 . C2 . C3 . G2 . B2 .','A1 . A2 . A1 . A2 . A1 . A2 . E2 . G2 .','F1 . F2 . F1 . F2 . F1 . F2 . C2 . F2 .','G1 . G2 . G1 . G2 . G1 G1 G2 G2 B1 B1 D2 D2')}}),
 factory:track({bpm:138,drums:DR.drive,parts:{
  lead:bars('D5 - - F5 - - A5 - G5 F5 E5 - D5 - - -','D5 - - F5 - - A5 - C6 - A5 - G5 - - -','Bb4 - - D5 - - F5 - E5 D5 C5 - D5 - - -','C5 - - E5 - - G5 - A5 - - - . . . .'),
  bass:bars('D2 . D2 D3 . D2 . D3 D2 . D2 D3 . F2 . G2','D2 . D2 D3 . D2 . D3 D2 . D2 D3 . A2 . C3','Bb1 . Bb1 Bb2 . Bb1 . Bb2 Bb1 . Bb1 Bb2 . D2 . F2','C2 . C2 C3 . C2 . C3 C2 . C2 C3 . E2 . G2'),
  arp:bars(rep('D4 F4 A4 F4',4),rep('D4 F4 A4 C5',4),rep('Bb3 D4 F4 D4',4),rep('C4 E4 G4 E4',4))}}),
 harbor:track({bpm:128,drums:DR.swing,parts:{
  lead:bars('G4 - - B4 - - D5 - - G5 - - F#5 - E5 -','D5 - - - B4 - - - G4 - - A4 - - B4 -','C5 - - E5 - - G5 - - E5 - - C5 - - -','D5 - - F#5 - - A5 - - - G5 - - - . .'),
  bass:bars('G2 . . D2 . . G2 . . D2 . . G2 . B2 .','G2 . . D2 . . G2 . . D2 . . E2 . F#2 .','C2 . . G2 . . C2 . . G2 . . C2 . E2 .','D2 . . A2 . . D2 . . A2 . . D2 . F#2 .')}}),
 fortress:track({bpm:162,drums:DR.drive,parts:{
  lead:bars('E5 - E5 - G5 - E5 - B5 - A5 - G5 - F#5 -','E5 - E5 - G5 - E5 - D5 - - - B4 - - -','C5 - C5 - E5 - C5 - A5 - G5 - E5 - C5 -','D5 - D5 - F#5 - A5 - B5 - - - . . . .'),
  bass:bars(rep('E2 E2 E3 E2',4),rep('E2 E2 E3 E2',3)+' D2 D2 D3 D2',rep('C2 C2 C3 C2',4),rep('D2 D2 D3 D2',2)+' B1 B1 B2 B1 B1 B1 B2 B1')}}),
 boss:track({bpm:172,drums:DR.boss,parts:{
  lead:bars('A4 - C5 - A4 - Eb5 - D5 - C5 - A4 - - -','A4 - C5 - A4 - E5 - F5 - E5 - D5 - - -','F4 - A4 - F4 - C5 - B4 - A4 - G#4 - - -','A4 - - - E5 - - - A5 - - - G#5 - - -'),
  bass:bars(rep('A1 A2 A1 A2',4),rep('A1 A2 A1 A2',4),rep('F1 F2 F1 F2',4),rep('E1 E2 E1 E2',4))}}),
 clear:track({bpm:150,loop:false,parts:{
  lead:'C5 E5 G5 C6 - - G5 - C6 - - - E6 - - - - - - - - - - - . . . .',
  bass:'C3 - - - - - G2 - C3 - - - C2 - - - - - - - - - - - . . . .'}}),
 result:track({bpm:132,loop:false,parts:{
  lead:'G4 - C5 - E5 - G5 - - - E5 - G5 - - - A5 - - - F5 - A5 - C6 - - - - - - - B5 - - - - - - - C6 - - - - - - - - - - - . . . .',
  bass:'C3 - - - - - - - C3 - - - - - - - F2 - - - - - - - F2 - - - - - - - G2 - - - - - - - C3 - - - - - - - - - - - . . . .'}}),
 gameover:track({bpm:96,loop:false,parts:{
  lead:'E5 - - - D5 - - - C5 - - - B4 - - - A4 - - - - - - - - - - - . . . .',
  bass:'A2 - - - - - - - F2 - - - - - - - E2 - - - - - - - A1 - - - - - - - . . . .'}}),
 victory:track({bpm:126,drums:DR.march,parts:{
  lead:bars('C5 - E5 - G5 - - - E5 - G5 - C6 - - -','A5 - G5 - F5 - E5 - D5 - - - G5 - - -','C5 - E5 - G5 - - - E5 - G5 - C6 - - -','B5 - A5 - G5 - B5 - C6 - - - . . . .'),
  bass:bars(rep('C3 . G2 .',4),rep('F2 . C3 .',2)+' '+rep('G2 . D3 .',2),rep('C3 . G2 .',4),rep('G2 . D3 .',2)+' C3 . G2 . C3 . . .')}})};

const TONE={lead:{type:'square',gain:.055,cut:3200,oct:0},bass:{type:'triangle',gain:.16,cut:900,oct:0},arp:{type:'square',gain:.03,cut:2200,oct:0},pad:{type:'sawtooth',gain:.025,cut:1200,oct:0}};

function create(){
 let ac=null,master,musicBus,sfxBus,noiseBuf,current=null,step=0,next=0,timer=null,voices=[],enVoice=null,fileEl=null;
 // Optional recorded BGM (e.g. exported from Suno) listed in music/tracks.js; anything missing falls back to the synth tracks.
 const files=Object.assign({},root.HONEY_MUSIC||{}),cache={},buffers={};let bufSrc=null,bufGain=null,playToken=0;
 const opts={master:.8,music:.55,sfx:.8,voice:true,muted:false,duck:false};
 function ready(){
  const AC=root.AudioContext||root.webkitAudioContext;if(!AC)return false;
  if(!ac){ac=new AC();const comp=ac.createDynamicsCompressor();comp.threshold.value=-14;comp.ratio.value=4;comp.connect(ac.destination);
   master=ac.createGain();master.connect(comp);musicBus=ac.createGain();sfxBus=ac.createGain();musicBus.connect(master);sfxBus.connect(master);
   noiseBuf=ac.createBuffer(1,ac.sampleRate,ac.sampleRate);const d=noiseBuf.getChannelData(0);for(let i=0;i<d.length;i++)d[i]=Math.random()*2-1;apply();}
  if(ac.state==='suspended')ac.resume().catch(()=>{});return true;}
 function apply(){if(fileEl)fileEl.volume=fileVolume();if(!ac)return;master.gain.value=opts.muted?0:opts.master*.7;musicBus.gain.setTargetAtTime(opts.music*(opts.duck?.3:1),ac.currentTime,.08);sfxBus.gain.value=opts.sfx;}
 function fileVolume(){return opts.muted?0:clamp01(opts.master*opts.music*(opts.duck?.3:1));}
 function set(o){Object.assign(opts,o);apply();}

 // ---- primitives ----
 function osc(type,f0,f1,dur,gain,at=0,bus=sfxBus,cut=0){if(!ac)return;const t=ac.currentTime+at,o=ac.createOscillator(),g=ac.createGain();o.type=type;o.frequency.setValueAtTime(f0,t);if(f1)o.frequency.exponentialRampToValueAtTime(Math.max(20,f1),t+dur);
  g.gain.setValueAtTime(gain,t);g.gain.exponentialRampToValueAtTime(.0008,t+dur);let node=o;if(cut){const f=ac.createBiquadFilter();f.type='lowpass';f.frequency.value=cut;o.connect(f);node=f;}node.connect(g);g.connect(bus);o.start(t);o.stop(t+dur+.03);}
 function noise(dur,gain,type='bandpass',freq=1800,q=1,at=0,f1=0,bus=sfxBus){if(!ac)return;const t=ac.currentTime+at,s=ac.createBufferSource(),f=ac.createBiquadFilter(),g=ac.createGain();s.buffer=noiseBuf;s.loop=true;f.type=type;f.frequency.setValueAtTime(freq,t);if(f1)f.frequency.exponentialRampToValueAtTime(f1,t+dur);f.Q.value=q;
  g.gain.setValueAtTime(gain,t);g.gain.exponentialRampToValueAtTime(.0008,t+dur);s.connect(f);f.connect(g);g.connect(bus);s.start(t,Math.random()*.5);s.stop(t+dur+.03);}
 const arp=(notes,gap,type='triangle',gain=.14,len=.16)=>notes.forEach((n,i)=>osc(type,hz(midi(n)),0,len,gain,i*gap));
 let lastSfx={};
 const SFX={
  akm(){noise(.09,.5,'bandpass',1700,.9);osc('square',150,50,.08,.12);},
  m4(){noise(.06,.42,'bandpass',2300,1);osc('square',190,60,.06,.09);},
  smg(){noise(.045,.34,'bandpass',3000,1.2);osc('square',240,90,.04,.06);},
  pistol(){noise(.07,.4,'bandpass',2000,1.1);osc('square',320,80,.08,.1);},
  sniper(){noise(.35,.6,'lowpass',2600,.7,0,300);osc('sawtooth',110,28,.32,.2);noise(.03,.4,'highpass',5000);},
  rocket(){noise(.45,.45,'bandpass',900,.8,0,300);osc('sawtooth',140,40,.3,.16);},
  throw(){noise(.18,.18,'bandpass',600,2,0,2400);},
  bounce(){osc('triangle',900,500,.06,.08);},
  explode(){noise(.8,.9,'lowpass',1400,.6,0,80);osc('sine',80,28,.6,.6);noise(.15,.4,'bandpass',3000,.6);},
  explodeSmall(){noise(.4,.55,'lowpass',1600,.6,0,120);osc('sine',110,40,.3,.35);},
  enemyShot(){osc('square',620,220,.07,.045);},
  enemyDie(){osc('square',700,1500,.07,.06);osc('triangle',1300,500,.14,.07,.06);},
  bigDie(){osc('square',300,60,.4,.12);noise(.3,.3,'lowpass',900);},
  hurt(){osc('sawtooth',420,140,.22,.16);noise(.12,.25,'bandpass',1200,1);},
  die(){arp(['E5','C5','A4','E4'],.09,'square',.1,.18);},
  jump(){osc('sine',320,720,.13,.12);},
  land(){noise(.07,.22,'lowpass',500);},
  knife(){osc('sine',190,60,.09,.32);noise(.08,.4,'lowpass',900);noise(.04,.18,'bandpass',2200,1.2);},
  ting(){osc('triangle',2600,0,.18,.12);osc('sine',3900,0,.12,.06);},
  thud(){osc('sine',160,80,.07,.15);noise(.05,.15,'lowpass',700);},
  crate(){noise(.22,.45,'bandpass',500,.8);osc('square',120,60,.12,.08);},
  alert(){osc('square',1300,1700,.06,.035);},
  rescue(){arp(['C5','E5','G5','C6'],.06,'triangle',.16);},
  pickup(){arp(['A5','E6'],.05,'square',.06,.1);},
  weapon(){arp(['C5','G5','C6','E6','G6'],.045,'square',.07,.12);},
  medal(){osc('triangle',1760,0,.4,.12);osc('triangle',2637,0,.4,.08,.06);},
  food(){arp(['E5','G5','B5'],.05,'sine',.16,.12);},
  click(){osc('square',900,0,.03,.05);},
  move(){osc('square',700,0,.03,.04);},
  select(){arp(['G5','D6'],.05,'square',.06,.08);},
  back(){arp(['D5','G4'],.05,'square',.05,.08);},
  tick(){osc('square',1500,0,.025,.035);},
  stamp(){osc('sine',120,40,.25,.4);noise(.12,.35,'lowpass',1200);},
  alarm(){for(let i=0;i<3;i++){osc('square',880,660,.18,.05,i*.36);osc('square',660,880,.18,.05,i*.36+.18);}},
  warning(){for(let i=0;i<4;i++){osc('sawtooth',520,980,.4,.07,i*.5);}},
  charge(){osc('sawtooth',180,520,.5,.05);},
  bossFire(){osc('sawtooth',90,35,.35,.25);noise(.3,.4,'lowpass',900,.7);},
  slam(){osc('sine',70,25,.5,.6);noise(.35,.6,'lowpass',600);},
  bossDie(){noise(1.6,.9,'lowpass',1800,.5,0,60);osc('sine',60,20,1.4,.6);},
  combo(){arp(['C6','E6','G6'],.04,'square',.05,.08);},
  clear(){arp(['G5','C6','E6'],.08,'square',.06,.16);},
  start(){},result(){},victory(){},gameover(){},continue(){}};
 function sfx(name){if(!ac||!SFX[name])return;const now=ac.currentTime;if(lastSfx[name]&&now-lastSfx[name]<.025)return;lastSfx[name]=now;SFX[name]();}

 // ---- music sequencer (look-ahead scheduling keeps timing steady) ----
 function playNote(ch,ev,t,dur){
  const tone=TONE[ch.name]||TONE.lead,o=ac.createOscillator(),g=ac.createGain(),f=ac.createBiquadFilter(),len=ev.len*dur;
  o.type=tone.type;o.frequency.value=hz(ev.midi);f.type='lowpass';f.frequency.value=tone.cut;
  g.gain.setValueAtTime(0,t);g.gain.linearRampToValueAtTime(tone.gain,t+.008);g.gain.setValueAtTime(tone.gain*.8,t+Math.min(len*.6,.2));g.gain.exponentialRampToValueAtTime(.0005,t+len*.98);
  o.connect(f);f.connect(g);g.connect(musicBus);o.start(t);o.stop(t+len+.05);}
 function drum(kind,t){
  if(kind==='kick'){const o=ac.createOscillator(),g=ac.createGain();o.frequency.setValueAtTime(150,t);o.frequency.exponentialRampToValueAtTime(40,t+.12);g.gain.setValueAtTime(.5,t);g.gain.exponentialRampToValueAtTime(.001,t+.15);o.connect(g);g.connect(musicBus);o.start(t);o.stop(t+.17);}
  else{const s=ac.createBufferSource(),f=ac.createBiquadFilter(),g=ac.createGain(),hat=kind==='hat';s.buffer=noiseBuf;f.type=hat?'highpass':'bandpass';f.frequency.value=hat?7000:1800;g.gain.setValueAtTime(hat?.06:.22,t);g.gain.exponentialRampToValueAtTime(.001,t+(hat?.04:.12));s.connect(f);f.connect(g);g.connect(musicBus);s.start(t,Math.random()*.5);s.stop(t+.14);}}
 function schedule(){
  if(!ac||!current||fileEl||files[current])return;const tr=TRACKS[current],dur=60/tr.bpm/4;
  while(next<ac.currentTime+.15){
   for(const ch of tr.channels)for(const ev of ch.events)if(ev.step===step)playNote(ch,ev,next,dur);
   if(tr.drums)for(const k of ['kick','snare','hat'])if(tr.drums[k][step%16]==='x')drum(k,next);
   next+=dur;step++;
   if(step>=tr.len){if(tr.loop)step=0;else{current=null;break;}}}}
 function stopFile(){playToken++;if(fileEl){fileEl.pause();fileEl.onended=null;fileEl=null;}
  if(bufSrc){const s=bufSrc,g=bufGain,t=ac.currentTime;g.gain.setTargetAtTime(0,t,.05);s.onended=null;try{s.stop(t+.25);}catch{}bufSrc=null;}}
 // Find where the music actually plays: skip leading silence and cut Suno's fade-out so loops stay at full energy.
 function loopPoints(buf){
  const d=buf.getChannelData(0),win=Math.floor(buf.sampleRate*.05),rms=[];
  for(let i=0;i+win<=d.length;i+=win){let s=0;for(let j=i;j<i+win;j+=4)s+=d[j]*d[j];rms.push(Math.sqrt(s/(win/4)));}
  const sorted=[...rms].sort((a,b)=>a-b),med=sorted[Math.floor(sorted.length/2)]||0,peak=sorted[sorted.length-1]||0;
  let a=rms.findIndex(v=>v>peak*.05);if(a<0)a=0;let b=rms.length-1;while(b>a&&rms[b]<med*.6)b--;
  return{start:a*win/buf.sampleRate,end:Math.max((b+1)*win/buf.sampleRate,a*win/buf.sampleRate+1)};}
 async function playBuffer(name,token){
  let buf=buffers[name];
  if(!buf){const r=await fetch('music/'+files[name]);if(!r.ok)throw new Error('missing');buf=await ac.decodeAudioData(await r.arrayBuffer());
   for(const k of Object.keys(buffers))if(k!==name&&!['clear','result','gameover'].includes(k))delete buffers[k];buffers[name]=buf;buf.loopAt=loopPoints(buf);}
  if(token!==playToken)return;
  const loop=TRACKS[name]?.loop!==false,src=ac.createBufferSource(),g=ac.createGain();src.buffer=buf;
  if(loop){src.loop=true;src.loopStart=buf.loopAt.start;src.loopEnd=buf.loopAt.end;}
  g.gain.setValueAtTime(0,ac.currentTime);g.gain.linearRampToValueAtTime(.62,ac.currentTime+.08);src.connect(g);g.connect(musicBus);
  src.onended=()=>{if(bufSrc===src){bufSrc=null;current=null;}};src.start(0,loop?buf.loopAt.start:0);bufSrc=src;bufGain=g;}
 function playFile(name){
  const el=cache[name]||(cache[name]=new root.Audio('music/'+files[name]));
  el.onerror=()=>{delete files[name];if(current===name){current=null;stopFile();music(name);}};
  el.loop=TRACKS[name]?.loop!==false;el.onended=()=>{if(fileEl===el){fileEl=null;current=null;}};
  el.currentTime=0;fileEl=el;el.volume=fileVolume();el.play()?.catch?.(()=>{});}
 function music(name){if(!ready())return;if(current===name)return;stopFile();current=name;
  if(files[name]){const token=playToken;playBuffer(name,token).catch(()=>{if(token===playToken&&current===name&&root.Audio)playFile(name);});return;}
  step=0;next=ac.currentTime+.06;if(!timer)timer=setInterval(schedule,25);}
 function stopMusic(){stopFile();current=null;}

 // ---- announcer ----
 const speech=root.speechSynthesis;
 function pickVoice(){if(!speech)return;voices=speech.getVoices();enVoice=voices.find(v=>/en-US/i.test(v.lang)&&/male|david|guy|mark|daniel/i.test(v.name))||voices.find(v=>/^en/i.test(v.lang))||null;}
 if(speech){pickVoice();speech.addEventListener?.('voiceschanged',pickVoice);}
 function voice(text){if(!text||!speech||!opts.voice||opts.muted||!enVoice)return;try{speech.cancel();const u=new root.SpeechSynthesisUtterance(text);u.voice=enVoice;u.lang=enVoice.lang;u.rate=1.05;u.pitch=.55;u.volume=Math.min(1,opts.master*1.1);speech.speak(u);}catch{}}

 return {ready,set,opts,sfx,music,stopMusic,voice,get playing(){return current;},tracks:Object.keys(TRACKS)};}
root.HoneyAudio={create,parse,TRACKS};
if(typeof module!=='undefined')module.exports=root.HoneyAudio;
})(typeof window!=='undefined'?window:globalThis);
