const fs=require('node:fs');let p='web/render.js',s=fs.readFileSync(p,'utf8');
s=s.replace("const off=Math.round(g.camera*.12)%1280;panelBG(g.stage,-off,0,1280,576);panelBG(g.stage,1280-off,0,1280,576);", "const scroll=Math.round(g.camera*.12),off=scroll%1280,tile=Math.floor(scroll/1280);for(let i=0;i<2;i++){const flip=(tile+i)%2;c.save();c.translate(i*1280-off+(flip?1280:0),0);c.scale(flip?-1:1,1);panelBG(g.stage,0,0,1280,576);c.restore();}");fs.writeFileSync(p,s);
p='scripts/presentation.gd';s=fs.readFileSync(p,'utf8');s=s.replace('region_texture(Rect2(-offset,0,1280,576),g.bg_tex,region)\n\t\tregion_texture(Rect2(1280-offset,0,1280,576),g.bg_tex,region)',`for i in range(2):
\t\t\tvar flip: bool=(int(g.camera_x*0.12/1280)+i)%2==1
\t\t\tdraw_set_transform(Vector2(i*1280-offset+(1280 if flip else 0),0),0,Vector2(-1 if flip else 1,1))
\t\t\tregion_texture(Rect2(0,0,1280,576),g.bg_tex,region)
\t\tdraw_set_transform(Vector2.ZERO)`);fs.writeFileSync(p,s);
