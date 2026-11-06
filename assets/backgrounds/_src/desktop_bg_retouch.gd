extends SceneTree
# T-278 (BRF-096): retoque dos fundos paisagem do PC (decisão 61).
# Remove bateria e textos miúdos de pseudo-HUD; mantém anéis, grade, molduras e réguas.
const SRC := "C:/Repos/projectanima/assets/splash/tech/desktop_%s_bg_source.jpg"
const OUT := "C:/Repos/projectanima/assets/backgrounds/"
# [x0, y0, x1, y1, modo] (exclusivo) em pixels da fonte 1376x768. As duas artes têm o mesmo layout de HUD.
# modo 1: a borda superior tem uma linha (usa a inferior); modo 2: a inferior tem uma linha (usa a superior);
# modo 3: a borda direita tem uma linha (repete a esquerda).
const PATCHES := [
	[1268, 32, 1344, 168],     # bateria + textos + caixa "BATTERY" (topo-dir)
	[1114, 84, 1190, 168, 3],  # colunas de texto (topo-dir; à direita há uma linha)
	[1203, 84, 1215, 168],     # código de barras (topo-dir)
	[1172, 31, 1226, 38, 1],   # texto na régua do topo
	[1239, 264, 1250, 270, 2], # rótulos do gráfico (direita)
	[1239, 309, 1252, 315, 2],
	[1239, 375, 1250, 381, 2],
	[1288, 258, 1320, 273],    # textos do gráfico
	[1280, 275, 1318, 291],
	[1299, 645, 1340, 732],    # bateria vertical (rodapé-dir)
	[80, 121, 137, 133],       # barra (topo-esq)
	[80, 140, 112, 158, 1],    # texto sob a linha (topo-esq)
	[80, 160, 155, 202],       # texto (topo-esq)
	[510, 63, 535, 141],       # colunas de texto (topo-centro)
	[37, 510, 47, 612],        # texto vertical (esquerda)
	[240, 585, 260, 665],      # texto vertical (baixo-esq)
	[541, 634, 551, 701],      # texto vertical (baixo-centro)
	[572, 662, 604, 702],      # barrinhas (baixo-centro)
	[42, 676, 430, 714],       # bloco de texto (rodapé-esq)
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
	var mode: int = r[4] if r.size() > 4 else 0
	if mode == 1: top = bot
	if mode == 2: bot = top
	var lef = _strip(img, false, x0 - 1, y0, y1, -1)
	var rig = _strip(img, false, x1, y0, y1, 1)
	if mode == 3:
		rig = lef
		for i in top.size():
			top[i] = top[0]; bot[i] = bot[0]
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

func _init() -> void:
	rng.seed = 96
	for name in ["title", "game"]:
		var img = Image.load_from_file(SRC % name)
		img.convert(Image.FORMAT_RGB8)
		for r in PATCHES: _patch(img, r)
		img.save_webp(OUT + "desktop_%s_bg.webp" % name, true, 0.82)
	print("ok")
	quit()
