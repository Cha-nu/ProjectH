extends RefCounted
const DRIVE_ART := [[192,55,689,542],[835,210,1435,542],[104,673,906,915],[1016,542,1434,955]]
# Town strip wraps at x=1467 (that column repeats column 0), so the redrawn brick wall tiles without a seam.
const GROUND_ART := [[0,14,1467,260],[0,269,1536,505],[0,516,1536,736],[0,749,1536,1024]]
const SOFT_BOSSES := {"walker":{"dest":[[44,82,470,462],[44,82,470,462],[84,202,413,419],[98,205,443,442],[43,122,458,382],[57,116,442,382],[54,40,459,452],[55,74,446,383]],"source":[[41,85,451,440],[487,84,904,440],[952,155,1319,435],[1372,180,1732,446],[64,551,416,808],[500,552,868,821],[965,489,1242,825],[1342,553,1730,825]]},"cannon":{"dest":[[39,110,486,473],[39,110,486,473],[37,105,457,456],[91,176,447,455],[70,101,469,356],[69,98,486,362],[26,45,419,399],[28,54,454,400]],"source":[[26,82,482,504],[486,82,947,504],[975,218,1362,497],[1386,251,1755,506],[73,575,437,823],[527,594,928,834],[994,571,1285,837],[1357,588,1728,852]]},"ship":{"dest":[[55,82,476,446],[55,82,476,446],[68,189,437,460],[69,166,427,460],[49,96,462,404],[134,140,381,406],[49,59,461,444],[51,100,464,430]],"source":[[34,113,404,428],[514,113,901,428],[1008,229,1325,432],[1417,238,1713,438],[60,514,427,772],[562,516,918,787],[1036,565,1265,792],[1395,550,1733,795]]},"tank":{"dest":[[76,105,467,463],[76,105,467,463],[85,200,408,422],[105,194,385,422],[80,175,413,382],[69,124,388,390],[41,76,419,449],[61,149,469,435]],"source":[[34,59,472,472],[498,60,933,475],[1002,239,1361,453],[1374,239,1746,471],[105,584,423,790],[538,586,872,814],[958,537,1259,817],[1340,554,1734,833]]}}

static func boss_art(sheet: String, frame: int) -> Dictionary:
	return {"source": SOFT_BOSSES[sheet].source[frame], "dest": SOFT_BOSSES[sheet].dest[frame]}

static func tread_point(distance: float, length: float, radius: float) -> Dictionary:
	var total := 2 * length + 2 * PI * radius; var s := fposmod(distance, total)
	if s < length: return {"x": s, "y": -radius, "a": 0.0}
	s -= length
	if s < PI * radius:
		var a := s / radius - PI / 2; return {"x": length + cos(a) * radius, "y": sin(a) * radius, "a": a + PI / 2}
	s -= PI * radius
	if s < length: return {"x": length - s, "y": radius, "a": PI}
	s -= length
	var a := s / radius + PI / 2; return {"x": cos(a) * radius, "y": sin(a) * radius, "a": a + PI / 2}
## Pure presentation selection. Keep in sync with web/visuals.js.
const BOUNDS := {"walker":[[36,68,411,402],[456,63,851,403],[910,91,1303,402],[1360,81,1739,401],[46,532,420,816],[449,465,865,820],[899,475,1292,813],[1319,560,1749,821]],"cannon":[[28,87,433,414],[464,88,875,417],[900,108,1323,417],[1356,87,1761,414],[29,508,436,820],[472,503,875,824],[907,502,1316,822],[1341,574,1758,825]],"ship":[[32,61,440,410],[453,65,876,410],[904,65,1322,410],[1325,65,1748,410],[32,472,440,821],[464,477,873,824],[902,465,1321,822],[1353,505,1751,825]],"tank":[[32,45,445,426],[468,45,887,428],[903,86,1324,428],[1349,55,1771,427],[27,486,449,845],[475,471,887,847],[911,471,1330,848],[1348,547,1753,853]],"portals":[[24,11,608,573],[664,13,1235,572],[13,620,617,1200],[642,609,1239,1200]]}

static func scenery(zones: Array, boss_start: float, focus: float) -> Dictionary:
	var starts: Array = []
	for z in zones: starts.append(z.start)
	if starts.size() < 6: starts.append(boss_start)
	for i in range(1, starts.size()):
		if focus < float(starts[i]) + 400:
			var t := clampf((focus - float(starts[i]) + 400) / 800, 0, 1)
			return {"from": i - 1, "to": i, "mix": t * t * (3 - 2 * t)}
	var last := mini(5, starts.size() - 1)
	return {"from": last, "to": last, "mix": 0.0}

static func boss_frame(b: Dictionary) -> int:
	if b.dead: return 7
	if b.phase == 2 or b.state == "break": return 6
	if b.air: return 4 if b.vy < 0 else 5
	if b.state == "windup": return 2
	if b.state == "attack" and b.pattern == 2: return 4 if b.clock > .55 else 5
	if b.charge or b.state == "enter": return 1
	if b.state == "attack" or b.state == "recover" or b.recoil > .01: return 3
	return 0

static func boss_pose(b: Dictionary) -> Dictionary:
	var t: float = b.t; var k: float = b.get("sink", 0); var kick := clampf(b.recoil, 0, 1); var moving: bool = b.state == "enter" or bool(b.charge)
	var u := clampf(1 - b.clock / (.75 if b.phase == 2 else 1.0), 0, 1) if b.state == "windup" else 0.0; u = u * u * (3 - 2 * u)
	var p := {"x": kick * 5, "y": 0.0, "rot": 0.0, "sx": 1.0, "sy": 1.0}
	if b.type == "boat": p.y = sin(t * 1.6) * 2; p.rot = sin(t * 1.6) * .012 - kick * .01
	else: p.y = sin(t * 6) * 1.1 if moving else sin(t * 1.8) * .55; p.sy = 1 - u * .025; p.sx = 1 + u * .012; p.rot = kick * .008
	if b.air: p.rot = .025 if b.vy < 0 else -.025; p.sy = 1.015
	if b.dead: p.x += k * 20; p.y += 200 * k * k if b.type == "boat" else 12 * k; p.rot += (.12 if b.type == "boat" else -.06) * k; p.sy = 1 - .12 * k
	return p

static func boss_rect(sheet: String, frame: int, rig: Dictionary) -> Dictionary:
	var a: Array = BOUNDS[sheet][frame]; var box: Array = rig.box
	var w: float = (box[2] - box[0]) * rig.k; var h: float = (box[3] - box[1]) * rig.k * (.68 if frame == 7 else 1.0)
	return {"source": a, "x": ((box[0] + box[2]) / 2.0 - 256) * rig.k - w / 2, "y": (box[3] - 512 * rig.base) * rig.k - h, "w": w, "h": h}

static func portals(zones: Array, boss_start: float, camera: float, time: float = 0.0) -> Array:
	var result: Array = []
	for i in range(zones.size()):
		var x: float = zones[i + 1].start if i + 1 < zones.size() else boss_start
		var t := clampf((time - float(zones[i].get("clearedAt", time - .7))) / .7, 0, 1) if zones[i].cleared else 0.0
		if x > camera - 320 and x < camera + 1600: result.append({"x": x, "open": bool(zones[i].cleared), "reveal": t * t * (3 - 2 * t), "index": i + 1})
	return result

static func entrance_shade(entries: Array, x: float) -> float:
	var shade := 0.0
	for p in entries:
		if p.open:
			var t := clampf(1 - absf(x - p.x) / 180, 0, 1); shade = maxf(shade, t * t * (3 - 2 * t) * .3)
	return shade
