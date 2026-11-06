extends SceneTree
const SRC := "C:/Repos/projectanima/assets/splash/tech/result_bg_source.jpg"
const OUT := "C:/Repos/projectanima/assets/backgrounds/"
# [x0, y0, x1, y1] (exclusive) em pixels da fonte 768x1376
const PATCHES := [
	[646, 37, 735, 80],    # bateria
	[90, 146, 180, 166],   # barra topo-esq
	[90, 171, 180, 244, 1],   # texto topo-esq (borda sup. com linha: usa a inferior)
	[631, 169, 683, 209],  # texto topo-dir
	[677, 761, 721, 797],  # texto direita-meio
	[649, 815, 719, 826],  # "FREQUENCY" direita
	[62, 809, 144, 833],   # texto esquerda-meio
	[592, 1109, 676, 1130],# "SYSTEM STATUS"
	[39, 1317, 183, 1339], # texto rodapé-esq
]
var rng := RandomNumberGenerator.new()

func _strip(img: Image, horiz: bool, fixed: int, a: int, b: int, dir: int) -> Array:
	var out = []
	for t in range(a - 1, b + 1):
		var c = Color(0, 0, 0)
		for k in 3:
			var x = t if horiz else fixed + dir * k
			var y = fixed + dir * k if horiz else t
			c += img.get_pixel(clampi(x, 0, img.get_width() - 1), clampi(y, 0, img.get_height() - 1))
		out.append(c / 3.0)
	var sm = []
	for i in out.size():
		var c = Color(0, 0, 0); var n = 0
		for d in range(-3, 4):
			var j = i + d
			if j >= 0 and j < out.size(): c += out[j]; n += 1
		sm.append(c / n)
	return sm

func _patch(img: Image, r: Array) -> void:
	var x0: int = r[0]; var y0: int = r[1]; var x1: int = r[2]; var y1: int = r[3]
	var top = _strip(img, true, y0 - 1, x0, x1, -1)
	var bot = _strip(img, true, y1, x0, x1, 1)
	if r.size() > 4: top = bot
	var lef = _strip(img, false, x0 - 1, y0, y1, -1)
	var rig = _strip(img, false, x1, y0, y1, 1)
	var w = float(x1 - x0 + 1); var h = float(y1 - y0 + 1)
	var tl: Color = top[0]; var tr: Color = top[top.size() - 1]
	var bl: Color = bot[0]; var br: Color = bot[bot.size() - 1]
	for y in range(y0, y1):
		var v = (y - y0 + 1) / h
		for x in range(x0, x1):
			var u = (x - x0 + 1) / w
			var c: Color = top[x - x0 + 1] * (1 - v) + bot[x - x0 + 1] * v + lef[y - y0 + 1] * (1 - u) + rig[y - y0 + 1] * u
			c -= tl * ((1 - u) * (1 - v)) + tr * (u * (1 - v)) + bl * ((1 - u) * v) + br * (u * v)
			var g = rng.randf_range(-0.008, 0.008)
			img.set_pixel(x, y, Color(c.r + g, c.g + g, c.b + g, 1.0))

func _dim(src: Image, strength: float) -> Image:
	var img = src.duplicate()
	var W = img.get_width(); var H = img.get_height()
	for y in H:
		for x in W:
			var dx = (x - W * 0.5) / (W * 0.62)
			var dy = (y - H * 0.70) / (H * 0.36)
			var d = sqrt(dx * dx + dy * dy)
			var f = clampf(1.0 - d, 0.0, 1.0)
			f = f * f * (3.0 - 2.0 * f)
			var c = img.get_pixel(x, y)
			var base = Color(0.02, 0.03, 0.07)
			img.set_pixel(x, y, c.lerp(base, f * strength))
	return img

func _init() -> void:
	rng.seed = 92
	var img = Image.load_from_file(SRC)
	img.convert(Image.FORMAT_RGB8)
	for r in PATCHES: _patch(img, r)
	_dim(img, 0.35).save_webp(OUT + "result_tech_bg.webp", true, 0.82)
	_dim(img, 0.72).save_webp(OUT + "result_tech_bg_dim.webp", true, 0.82)
	print("ok")
	quit()
