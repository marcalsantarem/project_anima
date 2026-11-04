class_name TitleScreen
extends Control
## "Toque para começar" (docs/ui.md §8, §11.1). É o primeiro gesto do usuário: na web, destrava o áudio.
## Continuação da splash B do `web/shell.html`: mesmo fundo, núcleo e logotipo no mesmo lugar; o botão
## grande ocupa o lugar da barra. Contrato: emite `start_requested` uma vez, no primeiro toque, clique ou tecla.
## Link pequeno "Último log" no canto (BRF-063), só se existir log salvo: abre o LogViewer sem começar a partida.

signal start_requested

const LOGO := preload("res://assets/ui/ui_title_logo_core.png")
const STUDIO_LOGO := preload("res://assets/ui/ui_studio_logo_h.png") ## Anima Games, 2x (BRF-068)
const PULSE_TIME := 0.8
const FLOAT_TIME := 2.4
const BUTTON_TEXT := "Toque para começar"

# Medidas do shell (1 u = 1 px do logotipo 560×760). Mude junto com `web/shell.html`.
const ART_W := 560.0
const STAGE_H := 830.0
const BLOCK_H := 1000.0 # palco + barra + "Carregando…" (centralizado na vertical, como o flex do shell)
const BUTTON_TOP := 856.0
const BUTTON_SIZE := Vector2(440, 120)
const BUTTON_FONT := 36.0
const LINK_SIZE := Vector2(180, 64) ## "Último log": alvo ≥ 44 px (BRF-063)
const W_VW := 0.86
const W_MAX_CSS := 440.0
const W_H_CSS := 0.55
const W_H_PAD_CSS := 64.0
const STUDIO_W := 0.30 ## largura do logo do estúdio / largura da tela
const STUDIO_W_MAX := 240.0
const STUDIO_BOTTOM := 32.0 ## folga acima da safe area inferior
const STUDIO_ALPHA := 0.88

const BG_TOP := Color("#8E72EC")
const BG_MID := Color("#7B5CE0")
const BG_BOTTOM := Color("#4E3F8F")
const GOLD := Color("#FFC93D")
const CREAM := Color("#F6E9CF")
const CREAM_ALT := Color("#EEDDBD")
const RING := Color("#B9A5E8")
const RUNE := Color("#DCD3FA")

var _started := false
var _stage: Control
var _button: Button
var _studio_logo: TextureRect
## Link "Último log" (null se não houver log salvo) e o visualizador aberto.
var last_log_link: Button
var viewer: LogViewer


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var root := ScreenKit.root(self, BG_MID)
	ScreenKit.set_page_color(BG_BOTTOM)
	var backdrop := Backdrop.new()
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root.add_child(backdrop)

	_stage = _build_stage()
	root.add_child(_stage)

	_button = Button.new()
	_button.text = BUTTON_TEXT
	_button.theme_type_variation = &"ButtonPrimary"
	_button.focus_mode = FOCUS_NONE
	_button.mouse_filter = MOUSE_FILTER_IGNORE # o gesto vale na tela toda (_input)
	root.add_child(_button)

	_studio_logo = TextureRect.new()
	_studio_logo.name = "StudioLogo"
	_studio_logo.texture = STUDIO_LOGO
	_studio_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_studio_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_studio_logo.modulate.a = STUDIO_ALPHA
	_studio_logo.mouse_filter = MOUSE_FILTER_IGNORE
	root.add_child(_studio_logo)
	if MatchRecorder.has_last_log():
		last_log_link = Button.new()
		last_log_link.name = "LastLog"
		last_log_link.text = "Último log"
		last_log_link.flat = true
		last_log_link.focus_mode = FOCUS_NONE
		last_log_link.custom_minimum_size = LINK_SIZE
		last_log_link.add_theme_font_size_override("font_size", UiTokens.FONT_CAPTION)
		last_log_link.add_theme_color_override("font_color", UiTokens.TEXT_SECONDARY)
		last_log_link.pressed.connect(open_last_log)
		root.add_child(last_log_link)

	_layout()
	get_viewport().size_changed.connect(_layout)

	var pulse := _button.create_tween().set_loops()
	pulse.tween_property(_button, "scale", Vector2.ONE * 1.05, PULSE_TIME).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_button, "scale", Vector2.ONE, PULSE_TIME).set_trans(Tween.TRANS_SINE)


## Palco em unidades da arte (560×830), escalado como o `#status-stage` do shell.
func _build_stage() -> Control:
	var stage := Control.new()
	stage.name = "Stage"
	stage.size = Vector2(ART_W, STAGE_H)
	stage.mouse_filter = MOUSE_FILTER_IGNORE
	stage.add_child(StageArt.new())

	var glow := TextureRect.new()
	glow.texture = _glow_texture()
	glow.position = Vector2(70, -6)
	glow.size = Vector2(420, 420)
	stage.add_child(glow)
	_loop(glow, "modulate:a", 0.85, 1.0)

	stage.add_child(_slice(Rect2(0, 322, ART_W, 178), Vector2(0, 322)))

	var shadow := ShadowBlob.new()
	shadow.position = Vector2(236, 368)
	shadow.size = Vector2(88, 20)
	shadow.pivot_offset = shadow.size / 2.0
	stage.add_child(shadow)
	_loop(shadow, "scale", Vector2.ONE, Vector2.ONE * 0.8)
	_loop(shadow, "modulate:a", 1.0, 0.7)

	var crystal := _slice(Rect2(0, 0, ART_W, 322), Vector2.ZERO)
	stage.add_child(crystal)
	_loop(crystal, "position:y", 0.0, -12.0)

	stage.add_child(_slice(Rect2(0, 500, ART_W, 260), Vector2(0, 570)))
	for c in stage.get_children():
		(c as Control).mouse_filter = MOUSE_FILTER_IGNORE
	return stage


func _slice(region: Rect2, at: Vector2) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = LOGO
	atlas.region = region
	var r := TextureRect.new()
	r.texture = atlas
	r.position = at
	r.size = region.size
	return r


## Vai e volta (alternate), como as animações CSS da splash. Sem alocação por quadro.
func _loop(node: Node, prop: String, from: Variant, to: Variant) -> void:
	var t := node.create_tween().set_loops()
	t.tween_property(node, prop, to, FLOAT_TIME).from(from).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(node, prop, from, FLOAT_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _glow_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var cyan := UiTokens.ACCENT
	g.colors = PackedColorArray([Color(cyan, 0.45), Color(cyan, 0.16), Color(cyan, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	return tex


## Mesma conta do shell: W = min(86vw, 440px, (100dvh − 64px) × 0,55), bloco centralizado entre as safe areas.
func _layout() -> void:
	var view := get_viewport_rect().size
	var safe := ScreenKit.safe_area(get_viewport())
	var k: float = safe.css_k
	var w := minf(view.x * W_VW, minf(W_MAX_CSS * k, (view.y - W_H_PAD_CSS * k) * W_H_CSS))
	var u := w / ART_W
	var avail_top: float = safe.top
	var avail_h: float = view.y - safe.top - safe.bottom
	var top := avail_top + (avail_h - BLOCK_H * u) / 2.0
	_stage.scale = Vector2.ONE * u
	_stage.position = Vector2((view.x - w) / 2.0, top)

	var bsize := Vector2(minf(BUTTON_SIZE.x * u, view.x - 2 * UiTokens.SPACE_M), maxf(BUTTON_SIZE.y * u, UiTokens.TOUCH_MIN))
	_button.size = bsize
	_button.position = Vector2((view.x - bsize.x) / 2.0, top + BUTTON_TOP * u)
	_button.pivot_offset = bsize / 2.0
	_button.add_theme_font_size_override("font_size", maxi(UiTokens.FONT_BODY, roundi(BUTTON_FONT * u)))

	var tex := STUDIO_LOGO.get_size()
	var lw := minf(view.x * STUDIO_W, STUDIO_W_MAX)
	var lsize := Vector2(lw, lw * tex.y / tex.x)
	_studio_logo.size = lsize
	_studio_logo.position = Vector2((view.x - lsize.x) / 2.0, view.y - safe.bottom - STUDIO_BOTTOM - lsize.y)
	if last_log_link != null:
		last_log_link.size = LINK_SIZE
		last_log_link.position = Vector2(view.x - safe.right - LINK_SIZE.x - UiTokens.SPACE_XS, safe.top + UiTokens.SPACE_XS)


# _input: o gesto precisa ser tratado no mesmo evento do navegador para destravar o áudio.
func _input(event: InputEvent) -> void:
	if _started or not is_visible_in_tree():
		return
	# O visualizador e o link "Último log" ficam com o toque (não começam a partida).
	if viewer != null or _over_link(event):
		return
	var is_gesture: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION) \
		or (event is InputEventKey and event.pressed and not event.echo)
	if not is_gesture:
		return
	_started = true
	get_viewport().set_input_as_handled()
	_show_pressed()
	_unlock_audio()
	start_requested.emit()


func _show_pressed() -> void:
	if _button == null:
		return
	_button.add_theme_stylebox_override("normal", UiArt.button_big(true))
	_button.scale = Vector2.ONE


## O Godot retoma o AudioContext no gesto do usuário. Aqui só garantimos que o bus principal não ficou mudo.
func _unlock_audio() -> void:
	AudioServer.set_bus_mute(0, false)


static func _ellipse(center: Vector2, radii: Vector2, segments: int = 72) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(segments + 1)
	for i in segments + 1:
		var a := TAU * i / segments
		pts[i] = center + Vector2(cos(a) * radii.x, sin(a) * radii.y)
	return pts


## Fundo da tela inteira: degradê roxo + brilhos dourados (SVG `#status-sparks`, viewBox 720×1560, slice).
class Backdrop extends Control:
	const SPARKS := [ # x, y, raio, opacidade
		Vector4(96, 350, 10, 0.8), Vector4(628, 440, 8, 0.7), Vector4(80, 900, 7, 0.6),
		Vector4(650, 1000, 11, 0.8), Vector4(180, 1320, 6, 0.5), Vector4(560, 1290, 8, 0.6),
	]

	func _init() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var s := size
		var mid := s.y * 0.55
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0), Vector2(s.x, mid), Vector2(0, mid)]),
			PackedColorArray([BG_TOP, BG_TOP, BG_MID, BG_MID]))
		draw_polygon(PackedVector2Array([Vector2(0, mid), Vector2(s.x, mid), s, Vector2(0, s.y)]),
			PackedColorArray([BG_MID, BG_MID, BG_BOTTOM, BG_BOTTOM]))
		var k := maxf(s.x / 720.0, s.y / 1560.0)
		var off := (s - Vector2(720, 1560) * k) / 2.0
		for sp in SPARKS:
			draw_colored_polygon(_star(off + Vector2(sp.x, sp.y) * k, sp.z * k), Color(GOLD, sp.w))

	## Estrela de 4 pontas com lados côncavos (curvas quadráticas com controle a 0,18 r).
	static func _star(c: Vector2, r: float) -> PackedVector2Array:
		var tips := [Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)]
		var pts := PackedVector2Array()
		for i in 4:
			var a: Vector2 = tips[i]
			var b: Vector2 = tips[(i + 1) % 4]
			var ctrl := (a + b).normalized() * r * 0.18 * sqrt(2.0)
			for j in 4:
				var t := j / 4.0
				pts.append(c + a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
		return pts


## Anéis rúnicos e disco de xadrez do palco (coordenadas da arte, como no shell).
class StageArt extends Control:
	const RUNE_SCALE := Vector2(567.0 / 644.0, 429.0 / 488.0)
	const OUTER_RUNES := [Vector2(635, 683.8), Vector2(473.8, 803.8), Vector2(246.2, 803.8), Vector2(85, 683.8),
		Vector2(85, 511.2), Vector2(246.2, 391.2), Vector2(473.8, 391.2), Vector2(635, 511.2)]
	const INNER_RUNES := [Vector2(536, 657.2), Vector2(432.8, 734), Vector2(287.2, 734), Vector2(184, 657.2),
		Vector2(184, 546.8), Vector2(287.2, 470), Vector2(432.8, 470), Vector2(536, 546.8)]
	const DISC_C := Vector2(280, 486)
	const DISC_R := Vector2(176, 65)
	const BORDER := 4.4

	var _checker_tex: ImageTexture

	func _init() -> void:
		size = Vector2(ART_W, STAGE_H)
		mouse_filter = MOUSE_FILTER_IGNORE
		texture_repeat = TEXTURE_REPEAT_ENABLED
		texture_filter = TEXTURE_FILTER_NEAREST

	func _draw() -> void:
		_rings()
		var shadow := TitleScreen._ellipse(DISC_C + Vector2(0, 14), Vector2(DISC_R.x * 1.02, DISC_R.y))
		draw_colored_polygon(shadow, UiTokens.INK)
		var inner := TitleScreen._ellipse(DISC_C, DISC_R - Vector2.ONE * BORDER)
		var uvs := PackedVector2Array()
		for p in inner:
			uvs.append((p - DISC_C + Vector2(35, 35)) / 70.0)
		if _checker_tex == null:
			_checker_tex = _checker()
		draw_colored_polygon(inner, Color.WHITE, uvs, _checker_tex)
		var ring_r := (DISC_R - Vector2.ONE * BORDER) * Vector2(0.76, 0.7) - Vector2.ONE * BORDER / 2.0
		draw_polyline(TitleScreen._ellipse(DISC_C, ring_r), RING, BORDER, true)
		draw_polyline(TitleScreen._ellipse(DISC_C, DISC_R - Vector2.ONE * BORDER / 2.0), UiTokens.INK, BORDER, true)

	func _map(p: Vector2) -> Vector2:
		return Vector2(-3.5, 131) + (p - Vector2(38, 366)) * RUNE_SCALE

	func _rings() -> void:
		var c := _map(Vector2(360, 610))
		var sets := [ # rx, ry, espessura, opacidade
			[312.5, 235.0, 12.5, 0.35], [282.5, 212.5, 3.75, 0.35],
			[200.0, 150.4, 8.0, 0.22], [180.8, 136.0, 2.4, 0.22],
		]
		for e in sets:
			var col := Color(RUNE, e[3])
			draw_polyline(TitleScreen._ellipse(c, Vector2(e[0], e[1]) * RUNE_SCALE, 96), col, e[2] * RUNE_SCALE.x, true)
		_runes(OUTER_RUNES, Vector2(10, 12.5), Color(RUNE, 0.35))
		_runes(INNER_RUNES, Vector2(6.4, 8.0), Color(RUNE, 0.22))

	func _runes(tops: Array, half: Vector2, col: Color) -> void:
		for t in tops:
			var p: Vector2 = t
			draw_colored_polygon(PackedVector2Array([_map(p), _map(p + half), _map(p + Vector2(0, half.y * 2)),
				_map(p + Vector2(-half.x, half.y))]), col)

	## Xadrez 2×2 (conic-gradient do shell: creme-escuro em cima à direita e embaixo à esquerda).
	static func _checker() -> ImageTexture:
		var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		img.set_pixel(0, 0, CREAM)
		img.set_pixel(1, 0, CREAM_ALT)
		img.set_pixel(0, 1, CREAM_ALT)
		img.set_pixel(1, 1, CREAM)
		return ImageTexture.create_from_image(img)


## Sombra do cristal no topo do pedestal.
class ShadowBlob extends Control:
	func _draw() -> void:
		draw_colored_polygon(TitleScreen._ellipse(size / 2.0, size / 2.0, 32), Color(21 / 255.0, 103 / 255.0, 94 / 255.0, 0.28))


func _over_link(event: InputEvent) -> bool:
	if last_log_link == null or not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return false
	return last_log_link.get_global_rect().has_point(event.position)


## Abre o log salvo da última partida por cima do título.
func open_last_log() -> void:
	if viewer != null:
		return
	viewer = LogViewer.open(self, MatchRecorder.load_last())
	viewer.closed.connect(func() -> void: viewer = null)
