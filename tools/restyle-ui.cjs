const fs=require('node:fs');
const web='web/render.js',native='scripts/presentation.gd';
let s=fs.readFileSync(web,'utf8');
const hud=`function hud(){
 panel(24,24,278,76);circle(65,62,27,PINK);c.save();c.beginPath();c.arc(65,62,24,0,Math.PI*2);c.clip();hero(65,119,98,4);c.restore();
 text('허니츄러스',106,50,16,INK,'left',800);box(232,38,52,23,'#fcebed',11);text('× '+g.lives,258,54,12,INK,'center',700);
 for(let i=0;i<5;i++){box(106+i*34,65,28,12,i<g.hp?'#ed96ae':'#f0e2e6',6);if(i<g.hp)box(110+i*34,67,20,3,'#ffc5d2',2);}
 panel(432,24,416,87);box(447,39,57,24,PINK,12);text('0'+(g.stage+1),476,56,13,INK,'center',800);text(STAGES[g.stage].name,517,56,18,INK,'left',800);
 const z=g.zones[g.zoneIndex];text(z.name,450,91,12,'#967481');for(let i=0;i<g.zones.length;i++){const x=705+i*30;circle(x,86,10,g.zones[i].cleared?'#b8dfcd':i===g.zoneIndex?PINK:'#efe6e9');text(g.zones[i].cleared?'✓':String(i+1),x,90,10,INK,'center',700);}
 panel(1000,24,190,65);text('SCORE',1018,46,10,'#a17c89','left',800);text(String(g.score).padStart(7,'0'),1018,72,23,INK,'left',800);
 panel(1202,24,54,54,PINK);line(1225,43,1225,59,INK,3);line(1233,43,1233,59,INK,3);
 panel(24,625,278,71);box(35,636,83,49,'#fcebed',17);weaponIcon(g.weapon,41,645,72,30);text(WEAPONS[g.weapon].name,131,649,16,INK,'left',800);text(g.ammo[g.weapon]<0?'∞':String(g.ammo[g.weapon]).padStart(3,'0'),131,678,25,'#b65c7d','left',800);text('발 남음',187,676,11,'#9b7b87');box(251,646,28,28,PINK,10);text('Q',265,666,13,INK,'center',800);
 panel(1000,636,256,60);bee(1029,680,38);text(String(g.rescued).padStart(2,'0'),1051,674,20,INK,'left',800);line(1091,650,1091,682,'#f0dce3',1);text('수류탄',1108,657,11,'#9b7b87');text('× '+g.grenades,1108,680,19,INK,'left',800);box(1213,652,27,27,PINK,10);text('C',1226,671,12,INK,'center',800);
 panel(376,660,528,36,'#fff8f5ed');const hints=[['← →','이동'],['↑ ↓','조준'],['Z','사격'],['X','점프'],['ESC','쉼표']];for(let i=0;i<hints.length;i++){const x=389+i*103;box(x,667,38,22,'#f7e5ea',7);text(hints[i][0],x+19,682,10,INK,'center',800);text(hints[i][1],x+45,682,11,'#967481');}
 if(g.combo>=2){box(27,114,140,34,'#fff8f5ed',17);text(g.combo+' COMBO!',97,137,17,'#b65c7d','center',800);}
 if(g.bannerTime>0){c.font="600 15px 'Malgun Gothic',system-ui,sans-serif";const width=c.measureText(g.banner).width+44;panel(640-width/2,126,width,38,PINK);text(g.banner,640,151,15,INK,'center',700);}
 if(g.weaponPop>0){c.save();c.globalAlpha=Math.min(1,g.weaponPop*2);panel(25,554,247,55);weaponIcon(g.weapon,38,567,62,27);text('새 무기 획득!',113,574,10,'#a17c89');text(WEAPONS[g.weapon].name,113,595,16,INK,'left',800);c.restore();}
 if(g.boss&&!g.boss.dead){panel(376,598,528,50);text(g.stage===3?'오리고기 · 초거대 과메기 전차':'과메기단 기동부대',394,618,12,INK,'left',800);text('BOSS',884,618,10,'#b65c7d','right',800);box(390,628,500,8,'#f0dbe0',4);box(390,628,500*Math.max(0,g.boss.hp/g.boss.max),8,'#e98aa5',4);}
}`;
s=s.slice(0,s.indexOf('function hud(){'))+hud+'\n'+s.slice(s.indexOf('function title(){'));
s=s.replaceAll('x>=1197&&x<=1245&&y>=33&&y<=73','x>=1202&&x<=1256&&y>=24&&y<=78');
s=s.replace("box(x,y+5,w,h,'#713e5020',24);box(x,y,w,h,color,24,'#f0bcc7',1.5)","box(x,y+6,w,h,'#713e5012',22);box(x,y+2,w,h,'#713e500b',22);box(x,y,w,h,color,22,'#ffffffcc',1.5)");
s=s.replace("'#cdb68c'","'#efb8c7'").replace("text('HONEY CHURROS   /   RESCUE OPERATION',66,76,15,TEAL","text('HONEY CHURROS   /   RESCUE OPERATION',66,76,15,'#a76f85'");
s=s.replace("box(961,455,228,38,TEAL,18);text('귀여움은 무기다.',1075,481,17,PAPER","box(961,455,228,38,PINK,18);text('귀여움은 무기다.',1075,481,17,INK");
s=s.replace("c.fillStyle='#211721ab'","c.fillStyle='#50374699'").replace("text(head,635,226,31,TEAL","text(head,635,226,29,INK");
s=s.replace("box(444,405,384,67,PINK,26,'#eaa6bc',2)","box(444,410,384,67,'#edb9c7',26);box(444,405,384,67,PINK,26,'#ffffff',2)");
fs.writeFileSync(web,s);
let n=fs.readFileSync(native,'utf8');
const nh=`func hud() -> void:
\tpanel(Rect2(24,24,278,76)); draw_circle(Vector2(65,62),27,PINK)
\tregion_texture(Rect2(42,38,46,44),g.body_tex,Rect2(100,485,240,220))
\ttext_at("허니츄러스",Vector2(106,50),16,INK); box(Rect2(232,38,52,23),Color("fcebed"),11); center("× %d"%g.lives,Vector2(258,54),12,INK)
\tfor i in range(5):
\t\tbox(Rect2(106+i*34,65,28,12),Color("ed96ae") if i<g.hp else Color("f0e2e6"),6)
\t\tif i<g.hp: box(Rect2(110+i*34,67,20,3),Color("ffc5d2"),2)
\tpanel(Rect2(432,24,416,87)); box(Rect2(447,39,57,24),PINK,12); center("0%d"%(g.stage+1),Vector2(476,56),13,INK)
\ttext_at(g.STAGES[g.stage].name,Vector2(517,56),18,INK); text_at(g.zones[g.zone_index].name,Vector2(450,91),12,Color("967481"))
\tfor i in range(g.zones.size()):
\t\tvar x:=705+i*30
\t\tdraw_circle(Vector2(x,86),10,Color("b8dfcd") if g.zones[i].cleared else PINK if i==g.zone_index else Color("efe6e9"))
\t\tcenter("✓" if g.zones[i].cleared else str(i+1),Vector2(x,90),10,INK)
\tpanel(Rect2(1000,24,190,65)); text_at("SCORE",Vector2(1018,46),10,Color("a17c89")); text_at("%07d"%g.score,Vector2(1018,72),23,INK)
\tpanel(Rect2(1202,24,54,54),PINK); draw_line(Vector2(1225,43),Vector2(1225,59),INK,3,true); draw_line(Vector2(1233,43),Vector2(1233,59),INK,3,true)
\tpanel(Rect2(24,625,278,71)); box(Rect2(35,636,83,49),Color("fcebed"),17); weapon_icon(g.weapon,Rect2(41,645,72,30))
\ttext_at(g.WEAPONS[g.weapon].name,Vector2(131,649),16,INK); text_at("∞" if g.ammo[g.weapon]<0 else "%03d"%g.ammo[g.weapon],Vector2(131,678),25,Color("b65c7d"))
\ttext_at("발 남음",Vector2(187,676),11,Color("9b7b87")); box(Rect2(251,646,28,28),PINK,10); center("Q",Vector2(265,666),13,INK)
\tpanel(Rect2(1000,636,256,60)); bee(Vector2(1029,680),38); text_at("%02d"%g.rescued,Vector2(1051,674),20,INK)
\tdraw_line(Vector2(1091,650),Vector2(1091,682),Color("f0dce3"),1); text_at("수류탄",Vector2(1108,657),11,Color("9b7b87")); text_at("× %d"%g.grenades,Vector2(1108,680),19,INK)
\tbox(Rect2(1213,652,27,27),PINK,10); center("C",Vector2(1226,671),12,INK)
\tpanel(Rect2(376,660,528,36),Color("fff8f5ed"))
\tvar hints: Array=[["← →","이동"],["↑ ↓","조준"],["Z","사격"],["X","점프"],["ESC","쉼표"]]
\tfor i in range(hints.size()):
\t\tvar x:=389+i*103
\t\tbox(Rect2(x,667,38,22),Color("f7e5ea"),7); center(hints[i][0],Vector2(x+19,682),10,INK); text_at(hints[i][1],Vector2(x+45,682),11,Color("967481"))
\tif g.combo>=2:
\t\tbox(Rect2(27,114,140,34),Color("fff8f5ed"),17); center("%d COMBO!"%g.combo,Vector2(97,137),17,Color("b65c7d"))
\tif g.banner_time>0:
\t\tvar width: float=g.font.get_string_size(g.banner,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+44
\t\tpanel(Rect2(640-width/2,126,width,38),PINK); center(g.banner,Vector2(640,151),15,INK)
\tif g.weapon_pop>0:
\t\tpanel(Rect2(25,554,247,55)); weapon_icon(g.weapon,Rect2(38,567,62,27)); text_at("새 무기 획득!",Vector2(113,574),10,Color("a17c89")); text_at(g.WEAPONS[g.weapon].name,Vector2(113,595),16,INK)
\tif not g.boss.is_empty() and not g.boss.dead:
\t\tpanel(Rect2(376,598,528,50)); text_at("오리고기 · 초거대 과메기 전차" if g.stage==3 else "과메기단 기동부대",Vector2(394,618),12,INK); text_at("BOSS",Vector2(851,618),10,Color("b65c7d"))
\t\tbox(Rect2(390,628,500,8),Color("f0dbe0"),4); box(Rect2(390,628,500*maxf(0,g.boss.hp/g.boss.max),8),Color("e98aa5"),4)

`;
n=n.slice(0,n.indexOf('func hud()'))+nh+n.slice(n.indexOf('func title_screen()'));
n=n.replace('Color("713e5020"),24','Color("713e5012"),22').replace('box(rect,color,24,Color("f0bcc7"),1)','box(rect,color,22,Color("ffffffcc"),1)');
n=n.replace('Color("cdb68c")','Color("efb8c7")').replace('Color(0.13,0.09,0.13,0.67)','Color("50374699")').replace('center(heading,Vector2(635,226),31,TEAL)','center(heading,Vector2(635,226),29,INK)');
n=n.replace('box(Rect2(444,405,384,67),PINK,26,Color("eaa6bc"),2)','box(Rect2(444,410,384,67),Color("edb9c7"),26)\n\tbox(Rect2(444,405,384,67),PINK,26,Color.WHITE,2)');
fs.writeFileSync(native,n);
const game='scripts/game.gd';fs.writeFileSync(game,fs.readFileSync(game,'utf8').replace('Rect2(1197,33,48,40)','Rect2(1202,24,54,54)'));
