const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..'),out=path.join(root,'build','web-standalone');
fs.mkdirSync(path.join(out,'assets','characters'),{recursive:true});
fs.mkdirSync(path.join(out,'fonts'),{recursive:true});
for(const name of ['index.html','game.js','audio.js','visuals.js'])fs.copyFileSync(path.join(root,'web',name),path.join(out,name));
fs.mkdirSync(path.join(out,'music'),{recursive:true});
for(const name of fs.readdirSync(path.join(root,'web','music')))fs.copyFileSync(path.join(root,'web','music',name),path.join(out,'music',name));
for(const name of fs.readdirSync(path.join(root,'web','fonts')))fs.copyFileSync(path.join(root,'web','fonts',name),path.join(out,'fonts',name));
fs.writeFileSync(path.join(out,'render.js'),fs.readFileSync(path.join(root,'web','render.js'),'utf8').replace("'../assets/'","'assets/'"));
fs.copyFileSync(path.join(root,'assets','backgrounds.png'),path.join(out,'assets','backgrounds.png'));
fs.mkdirSync(path.join(out,'assets','generated'),{recursive:true});
for(const name of fs.readdirSync(path.join(root,'assets','generated')).filter(n=>n.endsWith('.png')))fs.copyFileSync(path.join(root,'assets','generated',name),path.join(out,'assets','generated',name));
for(const sub of ['enemies','ground','bosses']){fs.mkdirSync(path.join(out,'assets','generated',sub),{recursive:true});for(const name of fs.readdirSync(path.join(root,'assets','generated',sub)).filter(n=>n.endsWith('.png')))fs.copyFileSync(path.join(root,'assets','generated',sub,name),path.join(out,'assets','generated',sub,name));}
for(const name of ['hero_aim_sheet.png','menu_friends.png','menu_friends_v2.png','profile.jpg','hero_sheet.png','hero_body_sheet.png','hero_body_pistol.png','weapons_clean.png','m4_black.png','fish_sheet.png','boss_parts.png','honeybee.webp','enemy.webp','tank.png'])fs.copyFileSync(path.join(root,'assets','characters',name),path.join(out,'assets','characters',name));
fs.writeFileSync(path.join(out,'README.txt'),'Honey Churros / Rescue Operation\n\nOpen index.html in a modern desktop or mobile browser, or serve this directory with any static HTTP server.\nNo install, build step, account or remote service is required. Keep index.html next to game.js, audio.js, render.js, fonts/ and assets/.\n\nKeyboard: Arrows/WASD move & aim, Z fire (knife at point blank), X/Space jump, C grenade, Q swap weapon, Esc pause, M mute.\nGamepad: A jump, X fire, B grenade, Y swap, Start pause.\nTouch: on-screen pad and buttons appear automatically on touch devices.\n\nFonts: Black Han Sans and Jua, SIL Open Font License 1.1 (see fonts/OFL-*.txt).\n');
console.log('Packaged static browser build:',out);
