class_name Canvas2D
extends RefCounted
## A subset of the HTML5 CanvasRenderingContext2D API on top of RenderingServer,
## so web/render.js can be ported to GDScript line for line.
## Paths are transformed into device space while they are built (as the browser does),
## images and text are drawn with the current transform. Blend mode, CSS filter and clip
## changes start a new pooled canvas item so draw order is preserved.

const DISPLAY_FAMILY := "Black Han Sans"
const BODY_FAMILY := "Jua"

# ---- public state (same names as the browser API) ----
var globalAlpha := 1.0
var fillStyle: Variant = "#000000"
var strokeStyle: Variant = "#000000"
var lineWidth := 1.0
var lineCap := "butt"
var lineJoin := "miter"
var font := "10px sans-serif"
var textAlign := "start"
var textBaseline := "alphabetic"
var globalCompositeOperation := "source-over"
var filter := "none"
var shadowColor: Variant = "rgba(0,0,0,0)"
var shadowBlur := 0.0
var imageSmoothingEnabled := true
var imageSmoothingQuality := "high"

var xf := Transform2D.IDENTITY
var _dash: Array = []
var _clip: Variant = null  # Rect2 in device space or null
var _stack: Array = []

# ---- path ----
var _subs: Array = []  # Array of {pts: PackedVector2Array, closed: bool}
var _cur: PackedVector2Array = PackedVector2Array()
var _cur_closed := false

# ---- backend ----
var _host: RID
var _pool: Array[RID] = []
var _used := 0
var _item := RID()
var _item_key := "~"
var _item_xf := Transform2D.IDENTITY
var _materials := {}
var _colors := {}
var _grad_tex := {}
var _fonts := {}
var _shader_mix: Shader
var _shader_add: Shader
var _white: Texture2D

class Gradient2D:
	var radial := false
	var p := PackedFloat32Array()  # x0,y0,r0,x1,y1,r1
	var stops: Array = []
	func addColorStop(offset: float, color: Variant) -> void:
		stops.append([clampf(offset, 0, 1), color])

func _init(host_canvas_item: RID) -> void:
	_host = host_canvas_item
	var code := "shader_type canvas_item;\nrender_mode %s;\nuniform float brightness = 1.0;\nuniform float saturation = 1.0;\nuniform float hue = 0.0;\n" + \
		"void fragment(){\n vec4 c = COLOR;\n vec3 rgb = c.rgb * brightness;\n float l = dot(rgb, vec3(0.2126, 0.7152, 0.0722));\n rgb = mix(vec3(l), rgb, saturation);\n" + \
		" if (hue != 0.0) { float a = radians(hue); float co = cos(a), si = sin(a);\n  mat3 m = mat3(vec3(.213+co*.787-si*.213, .213-co*.213+si*.143, .213-co*.213-si*.787), vec3(.715-co*.715-si*.715, .715+co*.285+si*.140, .715-co*.715+si*.715), vec3(.072-co*.072+si*.928, .072-co*.072-si*.283, .072+co*.928+si*.072));\n  rgb = m * rgb; }\n" + \
		" COLOR = vec4(clamp(rgb, 0.0, 1.0), c.a);\n}\n"
	_shader_mix = Shader.new(); _shader_mix.code = code % "blend_mix"
	_shader_add = Shader.new(); _shader_add.code = code % "blend_add"
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8); img.fill(Color.WHITE)
	_white = ImageTexture.create_from_image(img)

## Release the pooled canvas items (call when the host leaves the tree).
func free_items() -> void:
	for rid in _pool: RenderingServer.free_rid(rid)
	_pool.clear(); _used = 0; _item = RID()

## Call once per frame before drawing.
func begin_frame() -> void:
	for i in range(_used):
		var rid := _pool[i]
		RenderingServer.canvas_item_clear(rid)
		RenderingServer.canvas_item_set_material(rid, RID())
		RenderingServer.canvas_item_set_clip(rid, false)
		RenderingServer.canvas_item_set_custom_rect(rid, false)
	_used = 0; _item = RID(); _item_key = "~"
	_stack.clear(); _reset_state()

func _reset_state() -> void:
	globalAlpha = 1.0; fillStyle = "#000000"; strokeStyle = "#000000"; lineWidth = 1.0
	lineCap = "butt"; lineJoin = "miter"; font = "10px sans-serif"; textAlign = "start"; textBaseline = "alphabetic"
	globalCompositeOperation = "source-over"; filter = "none"; shadowColor = "rgba(0,0,0,0)"; shadowBlur = 0.0
	xf = Transform2D.IDENTITY; _dash = []; _clip = null
	_subs.clear(); _cur = PackedVector2Array()

func set_font_files(display: Font, body: Font) -> void:
	_fonts[DISPLAY_FAMILY] = display; _fonts[BODY_FAMILY] = body

# ================= state =================
func save() -> void:
	_stack.append([globalAlpha, fillStyle, strokeStyle, lineWidth, lineCap, lineJoin, font, textAlign, textBaseline,
		globalCompositeOperation, filter, shadowColor, shadowBlur, xf, _dash, _clip])

func restore() -> void:
	if _stack.is_empty(): return
	var s: Array = _stack.pop_back()
	globalAlpha = s[0]; fillStyle = s[1]; strokeStyle = s[2]; lineWidth = s[3]; lineCap = s[4]; lineJoin = s[5]
	font = s[6]; textAlign = s[7]; textBaseline = s[8]; globalCompositeOperation = s[9]; filter = s[10]
	shadowColor = s[11]; shadowBlur = s[12]; xf = s[13]; _dash = s[14]; _clip = s[15]

func translate(x: float, y: float) -> void: xf = xf * Transform2D(0.0, Vector2(x, y))
func rotate(a: float) -> void: xf = xf * Transform2D(a, Vector2.ZERO)
func scale(x: float, y: float) -> void: xf = xf * Transform2D(Vector2(x, 0), Vector2(0, y), Vector2.ZERO)
func setTransform(a: float, b: float, c: float, d: float, e: float, f: float) -> void: xf = Transform2D(Vector2(a, b), Vector2(c, d), Vector2(e, f))
func resetTransform() -> void: xf = Transform2D.IDENTITY
func setLineDash(d: Array) -> void: _dash = d.duplicate()

func createLinearGradient(x0: float, y0: float, x1: float, y1: float) -> Gradient2D:
	var g := Gradient2D.new(); g.p = PackedFloat32Array([x0, y0, 0, x1, y1, 0]); return g

func createRadialGradient(x0: float, y0: float, r0: float, x1: float, y1: float, r1: float) -> Gradient2D:
	var g := Gradient2D.new(); g.radial = true; g.p = PackedFloat32Array([x0, y0, r0, x1, y1, r1]); return g

# ================= colours =================
func color(v: Variant) -> Color:
	if v is Color: return v
	var s := str(v)
	if _colors.has(s): return _colors[s]
	var c := Color(0, 0, 0, 1)
	var t := s.strip_edges().to_lower()
	if t.begins_with("#"):
		c = Color.html(t)
	elif t.begins_with("rgb"):
		var inner := t.substr(t.find("(") + 1).trim_suffix(")")
		var parts := inner.replace("/", ",").split(",", false)
		var n: Array = []
		for p in parts: n.append(p.strip_edges())
		var f := func(i: int) -> float:
			var x: String = n[i]
			return float(x.trim_suffix("%")) * 2.55 if x.ends_with("%") else float(x)
		c = Color(f.call(0) / 255.0, f.call(1) / 255.0, f.call(2) / 255.0, 1.0)
		if n.size() > 3:
			var a: String = n[3]
			c.a = float(a.trim_suffix("%")) / 100.0 if a.ends_with("%") else float(a)
	elif t == "transparent": c = Color(0, 0, 0, 0)
	elif Color.html_is_valid(t): c = Color.html(t)
	else: c = Color.from_string(t, Color.BLACK)
	_colors[s] = c
	return c

func _paint(style: Variant) -> Color:
	if style is Gradient2D: return Color(1, 1, 1, globalAlpha)
	var c := color(style); c.a *= globalAlpha; return c

# ================= backend items =================
func _filter_params() -> Vector3:
	var b := 1.0; var s := 1.0; var h := 0.0
	var f := filter
	if f == "" or f == "none": return Vector3(b, s, h)
	for part in f.split(")", false):
		var p := part.strip_edges()
		var i := p.find("(")
		if i < 0: continue
		var name := p.substr(0, i).strip_edges(); var arg := p.substr(i + 1).strip_edges()
		var val := float(arg.trim_suffix("%")) / 100.0 if arg.ends_with("%") else float(arg.trim_suffix("deg"))
		match name:
			"brightness": b *= val
			"saturate": s *= val
			"grayscale": s *= 1.0 - clampf(val, 0, 1)
			"hue-rotate": h += val
	return Vector3(b, s, h)

func _ci() -> RID:
	var add := globalCompositeOperation == "lighter"
	var fp := _filter_params()
	var key := "%s|%s|%s|%s" % [add, fp, _clip, imageSmoothingEnabled]
	if key != _item_key or not _item.is_valid():
		if _used >= _pool.size():
			var rid := RenderingServer.canvas_item_create()
			RenderingServer.canvas_item_set_parent(rid, _host)
			_pool.append(rid)
		_item = _pool[_used]; _used += 1; _item_key = key
		RenderingServer.canvas_item_clear(_item)
		RenderingServer.canvas_item_set_default_texture_filter(_item, RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if imageSmoothingEnabled else RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST)
		var plain := not add and fp == Vector3(1, 1, 0)
		RenderingServer.canvas_item_set_material(_item, RID() if plain else _material(add, fp).get_rid())
		if _clip != null:
			RenderingServer.canvas_item_set_custom_rect(_item, true, _clip)
			RenderingServer.canvas_item_set_clip(_item, true)
		else:
			RenderingServer.canvas_item_set_clip(_item, false)
			RenderingServer.canvas_item_set_custom_rect(_item, false)
		_item_xf = Transform2D.IDENTITY
	return _item

func _material(add: bool, fp: Vector3) -> ShaderMaterial:
	var key := "%s|%s" % [add, fp]
	if not _materials.has(key):
		var m := ShaderMaterial.new(); m.shader = _shader_add if add else _shader_mix
		m.set_shader_parameter("brightness", fp.x); m.set_shader_parameter("saturation", fp.y); m.set_shader_parameter("hue", fp.z)
		_materials[key] = m
	return _materials[key]

func _set_xf(ci: RID, t: Transform2D) -> void:
	if t != _item_xf:
		RenderingServer.canvas_item_add_set_transform(ci, t); _item_xf = t

func _xscale() -> float: return sqrt(absf(xf.determinant()))

# ================= paths =================
func beginPath() -> void:
	_subs.clear(); _cur = PackedVector2Array(); _cur_closed = false

func _flush_sub() -> void:
	if _cur.size() > 0: _subs.append({"pts": _cur, "closed": _cur_closed})
	_cur = PackedVector2Array(); _cur_closed = false

func moveTo(x: float, y: float) -> void:
	_flush_sub(); _cur.append(xf * Vector2(x, y))

func lineTo(x: float, y: float) -> void:
	_cur.append(xf * Vector2(x, y))

func closePath() -> void:
	if _cur.size() > 0:
		var first := _cur[0]
		_cur_closed = true; _flush_sub(); _cur.append(first)

func _last_local() -> Vector2:
	return xf.affine_inverse() * _cur[_cur.size() - 1] if _cur.size() > 0 else Vector2.ZERO

func bezierCurveTo(c1x: float, c1y: float, c2x: float, c2y: float, x: float, y: float) -> void:
	var p0 := _last_local(); var c1 := Vector2(c1x, c1y); var c2 := Vector2(c2x, c2y); var p3 := Vector2(x, y)
	if _cur.is_empty(): _cur.append(xf * c1)
	var n := clampi(int((p0.distance_to(c1) + c1.distance_to(c2) + c2.distance_to(p3)) * _xscale() / 6.0), 6, 40)
	for i in range(1, n + 1):
		var t := float(i) / n; var u := 1.0 - t
		_cur.append(xf * (p0 * u * u * u + c1 * 3 * u * u * t + c2 * 3 * u * t * t + p3 * t * t * t))

func quadraticCurveTo(cx: float, cy: float, x: float, y: float) -> void:
	var p0 := _last_local(); var c := Vector2(cx, cy); var p2 := Vector2(x, y)
	if _cur.is_empty(): _cur.append(xf * c)
	var n := clampi(int((p0.distance_to(c) + c.distance_to(p2)) * _xscale() / 6.0), 4, 30)
	for i in range(1, n + 1):
		var t := float(i) / n; var u := 1.0 - t
		_cur.append(xf * (p0 * u * u + c * 2 * u * t + p2 * t * t))

func arc(x: float, y: float, r: float, a0: float, a1: float, ccw := false) -> void:
	ellipse(x, y, r, r, 0.0, a0, a1, ccw)

func ellipse(x: float, y: float, rx: float, ry: float, rot: float, a0: float, a1: float, ccw := false) -> void:
	rx = maxf(0.0, rx); ry = maxf(0.0, ry)
	var sweep := a1 - a0
	if not ccw:
		if sweep >= TAU: sweep = TAU
		elif sweep < 0: sweep = fposmod(sweep, TAU)
	else:
		if sweep <= -TAU: sweep = -TAU
		elif sweep > 0: sweep = fposmod(sweep, TAU) - TAU
	var n := clampi(int(absf(sweep) * maxf(rx, ry) * _xscale() / 4.0), 8, 96)
	var r := Transform2D(rot, Vector2(x, y))
	for i in range(n + 1):
		var a := a0 + sweep * i / n
		_cur.append(xf * (r * Vector2(cos(a) * rx, sin(a) * ry)))

func rect(x: float, y: float, w: float, h: float) -> void:
	moveTo(x, y); lineTo(x + w, y); lineTo(x + w, y + h); lineTo(x, y + h); closePath()

func roundRect(x: float, y: float, w: float, h: float, radii: Variant = 0.0) -> void:
	var r := float(radii[0]) if radii is Array else float(radii)
	if w < 0: x += w; w = -w
	if h < 0: y += h; h = -h
	r = clampf(r, 0.0, minf(w, h) / 2.0)
	if r <= 0.0: rect(x, y, w, h); return
	_flush_sub()
	var corners := [[x + w - r, y + r, -PI / 2], [x + w - r, y + h - r, 0.0], [x + r, y + h - r, PI / 2], [x + r, y + r, PI]]
	var n := clampi(int(r * _xscale() / 3.0), 3, 16)
	for cnr in corners:
		for i in range(n + 1):
			var a: float = cnr[2] + PI / 2 * i / n
			_cur.append(xf * Vector2(cnr[0] + cos(a) * r, cnr[1] + sin(a) * r))
	closePath()

func _all_subs() -> Array:
	var subs := _subs.duplicate()
	if _cur.size() > 0: subs.append({"pts": _cur, "closed": _cur_closed})
	return subs

func clip() -> void:
	var box := Rect2(); var first := true
	for s in _all_subs():
		for p in s.pts:
			if first: box = Rect2(p, Vector2.ZERO); first = false
			else: box = box.expand(p)
	if _clip != null: box = (_clip as Rect2).intersection(box)
	_clip = box

func fill() -> void:
	for s in _all_subs(): _fill_pts(s.pts, fillStyle)

func stroke() -> void:
	for s in _all_subs(): _stroke_pts(s.pts, s.closed)

func fillRect(x: float, y: float, w: float, h: float) -> void:
	if w == 0 or h == 0: return
	var pts := PackedVector2Array([xf * Vector2(x, y), xf * Vector2(x + w, y), xf * Vector2(x + w, y + h), xf * Vector2(x, y + h)])
	_fill_pts(pts, fillStyle)

func strokeRect(x: float, y: float, w: float, h: float) -> void:
	var pts := PackedVector2Array([xf * Vector2(x, y), xf * Vector2(x + w, y), xf * Vector2(x + w, y + h), xf * Vector2(x, y + h), xf * Vector2(x, y)])
	_stroke_pts(pts, true)

func clearRect(_x: float, _y: float, _w: float, _h: float) -> void:
	pass

func _clean(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		if out.is_empty() or out[out.size() - 1].distance_squared_to(p) > 0.0001: out.append(p)
	if out.size() > 2 and out[0].distance_squared_to(out[out.size() - 1]) < 0.0001: out.remove_at(out.size() - 1)
	return out

func _fill_pts(raw: PackedVector2Array, style: Variant) -> void:
	var pts := _clean(raw)
	if pts.size() < 3: return
	var col := _paint(style)
	if col.a <= 0.001: return
	var idx := Geometry2D.triangulate_polygon(pts)
	if idx.is_empty():
		for i in range(1, pts.size() - 1): idx.append_array([0, i, i + 1])
	var ci := _ci(); _set_xf(ci, Transform2D.IDENTITY)
	var cols := PackedColorArray(); cols.resize(pts.size()); cols.fill(col)
	var uvs := PackedVector2Array(); var texrid := RID()
	if style is Gradient2D:
		var g: Gradient2D = style
		texrid = _gradient_texture(g).get_rid()
		uvs = _gradient_uvs(g, pts)
	RenderingServer.canvas_item_add_triangle_array(ci, idx, pts, cols, uvs, PackedInt32Array(), PackedFloat32Array(), texrid)
	# Soft edge, like the browser's anti-aliased fill.
	if col.a > 0.98 and not (style is Gradient2D):
		var ring := pts.duplicate(); ring.append(pts[0])
		RenderingServer.canvas_item_add_polyline(ci, ring, PackedColorArray([col]), 1.0, true)

func _stroke_pts(raw: PackedVector2Array, closed: bool) -> void:
	var pts := _clean(raw)
	if pts.size() < 2: return
	if closed: pts.append(pts[0])
	var col := _paint(strokeStyle)
	var w := lineWidth * _xscale()
	if col.a <= 0.001 or w <= 0: return
	var ci := _ci(); _set_xf(ci, Transform2D.IDENTITY)
	if not _dash.is_empty():
		_stroke_dashed(ci, pts, col, w); return
	RenderingServer.canvas_item_add_polyline(ci, pts, PackedColorArray([col]), w, true)
	if w >= 2.5:
		var joins := lineJoin == "round"
		for i in range(pts.size()):
			var end := (i == 0 or i == pts.size() - 1) and not closed
			if (end and lineCap == "round") or (not end and (joins or w >= 4)):
				RenderingServer.canvas_item_add_circle(ci, pts[i], w / 2.0, col, true)

func _stroke_dashed(ci: RID, pts: PackedVector2Array, col: Color, w: float) -> void:
	var pattern: Array = []
	for d in _dash: pattern.append(float(d) * _xscale())
	if pattern.size() % 2 == 1: pattern.append_array(pattern.duplicate())
	var di := 0; var left: float = pattern[0]; var on := true
	for i in range(pts.size() - 1):
		var a := pts[i]; var b := pts[i + 1]; var seg := a.distance_to(b); var pos := 0.0
		while pos < seg:
			var step := minf(left, seg - pos)
			if on: RenderingServer.canvas_item_add_line(ci, a.lerp(b, pos / seg), a.lerp(b, (pos + step) / seg), col, w, true)
			pos += step; left -= step
			if left <= 0.0001:
				di = (di + 1) % pattern.size(); left = pattern[di]; on = not on

# ================= gradients =================
func _gradient_texture(g: Gradient2D) -> Texture2D:
	var p := g.p
	var stops := g.stops.duplicate()
	if g.radial and p[5] > 0:
		var k := p[2] / p[5]
		var mapped := []
		for s in stops: mapped.append([k + s[0] * (1.0 - k), s[1]])
		if k > 0 and not mapped.is_empty(): mapped.push_front([0.0, mapped[0][1]])
		stops = mapped
	var key := str(g.radial) + str(stops)
	if _grad_tex.has(key): return _grad_tex[key]
	var gr := Gradient.new()
	var offs := PackedFloat32Array(); var cols := PackedColorArray()
	for s in stops: offs.append(s[0]); cols.append(color(s[1]))
	if offs.is_empty(): offs = PackedFloat32Array([0.0]); cols = PackedColorArray([Color(0, 0, 0, 0)])
	gr.offsets = offs; gr.colors = cols
	var t: Texture2D
	if g.radial:
		var t2 := GradientTexture2D.new(); t2.gradient = gr; t2.width = 256; t2.height = 256
		t2.fill = GradientTexture2D.FILL_RADIAL; t2.fill_from = Vector2(0.5, 0.5); t2.fill_to = Vector2(1.0, 0.5)
		t = t2
	else:
		var t1 := GradientTexture1D.new(); t1.gradient = gr; t1.width = 256; t = t1
	_grad_tex[key] = t
	return t

func _gradient_uvs(g: Gradient2D, pts: PackedVector2Array) -> PackedVector2Array:
	var uvs := PackedVector2Array(); uvs.resize(pts.size())
	var p := g.p
	if g.radial:
		var c := xf * Vector2(p[3], p[4]); var r := maxf(0.001, p[5] * _xscale())
		for i in range(pts.size()): uvs[i] = (pts[i] - c) / (2.0 * r) + Vector2(0.5, 0.5)
	else:
		var a := xf * Vector2(p[0], p[1]); var b := xf * Vector2(p[3], p[4]); var d := b - a
		var len2 := maxf(0.0001, d.length_squared())
		for i in range(pts.size()): uvs[i] = Vector2(clampf((pts[i] - a).dot(d) / len2, 0.002, 0.998), 0.5)
	return uvs

# ================= images =================
## drawImage(img, dx, dy) / (img, dx, dy, dw, dh) / (img, sx, sy, sw, sh, dx, dy, dw, dh)
func drawImage(img: Texture2D, a: float, b: float, c: float = NAN, d: float = NAN, e: float = NAN, f: float = NAN, g: float = NAN, h: float = NAN) -> void:
	if img == null: return
	var src: Rect2; var dst: Rect2
	var iw := img.get_width(); var ih := img.get_height()
	if not is_nan(e):
		src = Rect2(a, b, c, d); dst = Rect2(e, f, g, h)
	elif not is_nan(c):
		src = Rect2(0, 0, iw, ih); dst = Rect2(a, b, c, d)
	else:
		src = Rect2(0, 0, iw, ih); dst = Rect2(a, b, iw, ih)
	if src.size.x == 0 or src.size.y == 0 or dst.size.x == 0 or dst.size.y == 0: return
	# The browser clips the source rect to the image and shrinks the destination to match.
	var clipped := src.intersection(Rect2(0, 0, iw, ih))
	if clipped.size.x <= 0 or clipped.size.y <= 0: return
	if clipped != src:
		var sx := dst.size.x / src.size.x; var sy := dst.size.y / src.size.y
		dst = Rect2(dst.position + (clipped.position - src.position) * Vector2(sx, sy), clipped.size * Vector2(sx, sy))
		src = clipped
	var mod := Color(1, 1, 1, globalAlpha)
	if mod.a <= 0.001: return
	var ci := _ci()
	if shadowBlur > 0:
		var sc := color(shadowColor)
		if sc.a > 0:
			sc.a *= globalAlpha * 0.55
			_set_xf(ci, xf)
			var cen := dst.get_center(); var rad := maxf(absf(dst.size.x), absf(dst.size.y)) * 0.5 + shadowBlur
			var glow := createRadialGradient(cen.x, cen.y, 0, cen.x, cen.y, rad)
			glow.addColorStop(0.0, sc); glow.addColorStop(0.55, sc); glow.addColorStop(1.0, Color(sc.r, sc.g, sc.b, 0))
			RenderingServer.canvas_item_add_texture_rect(ci, Rect2(cen - Vector2(rad, rad), Vector2(rad, rad) * 2), _gradient_texture(glow).get_rid())
	_set_xf(ci, xf)
	RenderingServer.canvas_item_add_texture_rect_region(ci, dst, img.get_rid(), src, mod, false, true)

# ================= text =================
func _font_info() -> Array:
	var size := 10.0
	var m := RegEx.create_from_string("([0-9.]+)px").search(font)
	if m: size = float(m.get_string(1))
	var f: Font = _fonts.get(BODY_FAMILY)
	var i_display := font.find(DISPLAY_FAMILY); var i_body := font.find(BODY_FAMILY)
	if i_display >= 0 and (i_body < 0 or i_display < i_body): f = _fonts.get(DISPLAY_FAMILY)
	if f == null: f = ThemeDB.fallback_font
	return [f, size]

func measureText(s: Variant) -> Dictionary:
	var fi := _font_info(); var f: Font = fi[0]
	return {"width": f.get_string_size(str(s), HORIZONTAL_ALIGNMENT_LEFT, -1, int(round(fi[1]))).x}

func _text_origin(f: Font, s: String, size: int, x: float, y: float) -> Vector2:
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	match textAlign:
		"center": x -= w / 2.0
		"right", "end": x -= w
	var asc := f.get_ascent(size); var desc := f.get_descent(size)
	match textBaseline:
		"top", "hanging": y += asc
		"middle": y += (asc - desc) / 2.0
		"bottom", "ideographic": y -= desc
	return Vector2(x, y)

func fillText(s: Variant, x: float, y: float) -> void:
	var t := str(s)
	if t.is_empty(): return
	var fi := _font_info(); var f: Font = fi[0]; var size := int(round(fi[1]))
	var col := _paint(fillStyle)
	if fillStyle is Gradient2D: col = Color(1, 1, 1, globalAlpha)
	if col.a <= 0.001 or size <= 0: return
	var ci := _ci(); _set_xf(ci, xf)
	f.draw_string(ci, _text_origin(f, t, size, x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func strokeText(s: Variant, x: float, y: float) -> void:
	var t := str(s)
	if t.is_empty(): return
	var fi := _font_info(); var f: Font = fi[0]; var size := int(round(fi[1]))
	var col := _paint(strokeStyle)
	if col.a <= 0.001 or size <= 0 or lineWidth <= 0: return
	var ci := _ci(); _set_xf(ci, xf)
	f.draw_string_outline(ci, _text_origin(f, t, size, x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, maxi(1, int(round(lineWidth))), col)
