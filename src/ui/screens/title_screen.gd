class_name TitleScreen
extends Control
## "Toque para começar" (docs/ui.md §8, §11.1). É o primeiro gesto do usuário: na web, destrava o áudio.
## Continuação da splash tecnológica do `web/shell.html` (T-179, decisão 48): mesma arte, título e animações
## nas mesmas posições; o botão holográfico ocupa o lugar da barra. Contrato: emite `start_requested` uma vez,
## no primeiro toque, clique ou tecla; em seguida um véu escuro some em ~0,3 s sobre a partida (sem corte seco).
## Gancho `TXT_BUILD_TAG`: se não vazio, mostra o subtítulo (ex. "ALFA", T-283) entre o título e o botão; vazio = nada é criado.

signal start_requested

const BG_ART := preload("res://assets/ui/title_bg_tech.webp")
const STUDIO_LOGO := preload("res://assets/ui/ui_studio_logo_h.png") ## Anima Games, 2x (BRF-068)
const BUTTON_TEXT := "TITLE_TAP_TO_START" ## chave de tradução (Loc.t)
const PULSE_TIME := 0.8
const GLOW_TIME := 2.4
const FADE_TIME := 0.3 ## véu escuro → partida
const FADE_NAME := &"TitleFade"

# Medidas do shell em px da arte (768×1376). Mude junto com `web/shell.html` (#status-art e filhos).
const ART := Vector2(768, 1376)
const ART_MIN_FILL := 0.88 ## a arte ocupa ao menos 88% da altura; o resto embaixo é BG_DEEP
const EDGE_W := 38.4 ## 5% da largura: laterais somem na cor da base
const EDGE_BOTTOM := 140.0
const GLOW := Rect2(164, 150, 440, 440)
const RINGS := [ # centro, raio, achatamento, segundos por volta (negativo = sentido contrário), opacidade
	[Vector2(384, 340), 260.0, 0.36, 60.0, 0.35],
	[Vector2(384, 680), 300.0, 0.3, -90.0, 0.22],
]
const SPARKS := [Vector2(108, 117), Vector2(215, 138), Vector2(607, 255), Vector2(77, 385),
	Vector2(238, 516), Vector2(561, 468), Vector2(660, 578), Vector2(138, 716)]
const TITLE_TOP := 895.0
const SUB_FONT := 74.0 ## "PROJECT:"
const TITLE_FONT := 132.0 ## "ANIMA"
const SUB_GAP := 12.0
const BUTTON_CENTER_Y := 1211.0 ## centro da barra do shell
const BUTTON_SIZE := Vector2(495, 110)
const BUTTON_FONT := 36.0
const TXT_BUILD_TAG := "TITLE_BUILD_TAG" ## chave (texto "ALFA"); vazio = sem subtítulo (T-283)
const TAG_FONT := 38.0 ## entre "PROJECT:" e "ANIMA" e o rodapé
const TAG_COLOR := Color("#FF5A6E") ## vermelho `danger` da paleta
const TAG_GLOW := Color(1.0, 0.25, 0.35, 0.7)
const STUDIO_W := 0.30 ## largura do logo do estúdio / largura da tela
const STUDIO_W_MAX := 240.0
const STUDIO_BOTTOM := 32.0 ## folga acima da safe area inferior
const STUDIO_ALPHA := 0.88

const BG_DEEP := Color("#021423") ## base da arte; cor da página no título
const CYAN := Color("#2FE6F2")
const CYAN_SOFT := Color(0.47, 0.94, 1.0, 0.85)
const TEXT_GLOW := Color("#E6FFFF")
const GLOW_SHADOW := Color(0.18, 0.85, 1.0, 0.6)

var _started := false
var _art: Control
var _sub_title: Label
var _title: Label
var _button: Button
var _studio_logo: TextureRect
## `v<versão> · <sha>` no canto inferior direito (T-165), alinhado à base do logo do estúdio.
var version_label: Label
var _build_tag: Label


func _ready() -> void:
	SessionInfo.mark_title()
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var root := ScreenKit.root(self, BG_DEEP)
	ScreenKit.set_page_color(BG_DEEP)
	var reduced := DebugSettings.reduced_effects()
	_art = build_art(reduced)
	root.add_child(_art)

	_sub_title = title_label(Loc.t("TITLE_LOGO_SUB"))
	root.add_child(_sub_title)
	_title = title_label(Loc.t("TITLE_LOGO_MAIN"))
	root.add_child(_title)

	if TXT_BUILD_TAG != "":
		_build_tag = title_label(Loc.t(TXT_BUILD_TAG))
		_build_tag.name = "BuildTag"
		_build_tag.add_theme_color_override("font_color", TAG_COLOR)
		_build_tag.add_theme_color_override("font_shadow_color", TAG_GLOW)
		root.add_child(_build_tag)

	_button = Button.new()
	_button.name = "StartButton"
	_button.text = Loc.t(BUTTON_TEXT)
	_button.focus_mode = FOCUS_NONE
	_button.mouse_filter = MOUSE_FILTER_IGNORE # o gesto vale na tela toda (_input)
	_style_holo(_button, false)
	root.add_child(_button)

	_studio_logo = TextureRect.new()
	_studio_logo.name = "StudioLogo"
	_studio_logo.texture = STUDIO_LOGO
	_studio_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_studio_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_studio_logo.modulate.a = STUDIO_ALPHA
	_studio_logo.mouse_filter = MOUSE_FILTER_IGNORE
	root.add_child(_studio_logo)
	version_label = ScreenKit.version_label()
	version_label.add_theme_color_override("font_color", Color(0.75, 0.95, 1.0, 0.6))
	root.add_child(version_label)
	_layout()
	get_viewport().size_changed.connect(_layout)

	var pulse := _button.create_tween().set_loops()
	pulse.tween_property(_button, "scale", Vector2.ONE * 1.04, PULSE_TIME).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_button, "scale", Vector2.ONE, PULSE_TIME).set_trans(Tween.TRANS_SINE)


## Quadro da arte em px da arte (768×1376), escalado como o `#status-art` do shell.
static func build_art(reduced: bool) -> Control:
	var art := Control.new()
	art.name = "Art"
	art.size = ART
	art.mouse_filter = MOUSE_FILTER_IGNORE

	var bg := TextureRect.new()
	bg.name = "Background"
	bg.texture = BG_ART
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = ART
	art.add_child(bg)
	art.add_child(EdgeFade.new())

	for r in RINGS:
		art.add_child(_ring(r[0], r[1], r[2], r[3], r[4], reduced))

	var glow := TextureRect.new()
	glow.name = "Glow"
	glow.texture = _glow_texture()
	glow.position = GLOW.position
	glow.size = GLOW.size
	glow.pivot_offset = GLOW.size / 2.0
	art.add_child(glow)
	_loop(glow, "modulate:a", 0.6, 1.0, GLOW_TIME)
	_loop(glow, "scale", Vector2.ONE * 0.92, Vector2.ONE * 1.05, GLOW_TIME)

	var i := 0
	for p in SPARKS:
		var s := Spark.new()
		s.position = p
		art.add_child(s)
		if not reduced:
			_loop(s, "modulate:a", 0.15, 1.0, 2.0 + 0.17 * i)
		i += 1
	for c in art.get_children():
		(c as Control).mouse_filter = MOUSE_FILTER_IGNORE
	return art


## Anel tracejado achatado: o suporte achata (scale.y) e o anel gira dentro dele, como no CSS.
static func _ring(center: Vector2, radius: float, squash: float, period: float, alpha: float, reduced: bool) -> Control:
	var holder := Control.new()
	holder.position = center
	holder.scale = Vector2(1.0, squash)
	var ring := DashedRing.new()
	ring.radius = radius
	ring.color = Color(0.47, 0.94, 1.0, alpha)
	holder.add_child(ring)
	if not reduced:
		var t := ring.create_tween().set_loops()
		var full := TAU if period > 0.0 else -TAU
		t.tween_property(ring, "rotation", full, absf(period)).from(0.0)
	return holder


## Vai e volta (alternate), como as animações CSS da splash. Sem alocação por quadro.
static func _loop(node: Node, prop: String, from: Variant, to: Variant, time: float) -> void:
	var t := node.create_tween().set_loops()
	t.tween_property(node, prop, to, time).from(from).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(node, prop, from, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


static func _glow_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(0.59, 0.98, 1.0, 0.5), Color(CYAN, 0.2), Color(CYAN, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	return tex


static func title_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"LabelDisplay"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", TEXT_GLOW)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_color_override("font_shadow_color", GLOW_SHADOW)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 0)
	return l


## Botão holográfico: contorno ciano com brilho, fundo escuro translúcido; pressionado acende.
func _style_holo(b: Button, pressed: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.9, 0.95, 0.3) if pressed else Color(0.01, 0.08, 0.14, 0.62)
	sb.border_color = CYAN_SOFT
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(999)
	sb.corner_detail = 12
	sb.shadow_color = Color(0.18, 0.86, 1.0, 0.6 if pressed else 0.4)
	sb.shadow_size = 14
	sb.anti_aliasing = true
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, sb)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, TEXT_GLOW)
	b.add_theme_color_override("font_outline_color", Color(0.18, 0.85, 1.0, 0.35))
	b.add_theme_constant_override("outline_size", 4)


## Escala da arte, igual ao `--s` do shell: cobre a altura; em telas estreitas corta as laterais, mas a arte
## ocupa ao menos 88% da altura (o resto embaixo é BG_DEEP).
static func art_scale(view: Vector2) -> float:
	return minf(view.y / ART.y, maxf(view.x / ART.x, view.y * ART_MIN_FILL / ART.y))


func _layout() -> void:
	var view := get_viewport_rect().size
	var safe := ScreenKit.safe_area(get_viewport())
	var s := art_scale(view)
	var left := (view.x - ART.x * s) / 2.0
	_art.scale = Vector2.ONE * s
	_art.position = Vector2(left, 0)

	var sub_font := roundi(SUB_FONT * s)
	var title_font := roundi(TITLE_FONT * s)
	var tag_font := maxi(UiTokens.FONT_CAPTION, roundi(TAG_FONT * s))

	var tex := STUDIO_LOGO.get_size()
	var lw := minf(view.x * STUDIO_W, STUDIO_W_MAX)
	var lsize := Vector2(lw, lw * tex.y / tex.x)
	_studio_logo.size = lsize
	_studio_logo.position = Vector2((view.x - lsize.x) / 2.0, view.y - safe.bottom - STUDIO_BOTTOM - lsize.y)
	# Botão no lugar da barra; em telas baixas sobe o necessário para não encostar no logo do estúdio.
	var bsize := Vector2(minf(BUTTON_SIZE.x * s, view.x - 2 * UiTokens.SPACE_M), maxf(BUTTON_SIZE.y * s, UiTokens.TOUCH_MIN))
	var by := minf(BUTTON_CENTER_Y * s - bsize.y / 2.0, _studio_logo.position.y - UiTokens.SPACE_M - bsize.y)
	_button.size = bsize
	_button.position = Vector2((view.x - bsize.x) / 2.0, by)
	_button.pivot_offset = bsize / 2.0
	_button.add_theme_font_size_override("font_size", maxi(UiTokens.FONT_BODY, roundi(BUTTON_FONT * s)))
	# Título e subtítulo sobem o necessário para caber o subtítulo entre "ANIMA" e o botão (telas baixas).
	var gap := UiTokens.SPACE_XS
	var title_end := (TITLE_TOP + SUB_FONT + SUB_GAP + TITLE_FONT) * s
	var shift := 0.0
	if _build_tag != null:
		shift = minf(0.0, by - gap * 2.0 - tag_font - title_end)
	_place_title(_sub_title, sub_font, TITLE_TOP * s + shift, view.x)
	_place_title(_title, title_font, (TITLE_TOP + SUB_FONT + SUB_GAP) * s + shift, view.x)
	if _build_tag != null:
		_place_title(_build_tag, tag_font, by - gap - tag_font * 1.05, view.x)
	ScreenKit.place_corner_label(version_label, get_viewport(), STUDIO_BOTTOM)


## Label de largura total, topo em `top`; o brilho é a sombra sem deslocamento (proporcional à fonte).
func _place_title(l: Label, font: int, top: float, width: float) -> void:
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_constant_override("shadow_outline_size", maxi(4, roundi(font * 0.09)))
	l.size = Vector2(width, 0)
	l.position = Vector2(0, top - font * 0.18) # compensa o espaço acima das maiúsculas


# _input: o gesto precisa ser tratado no mesmo evento do navegador para destravar o áudio.
func _input(event: InputEvent) -> void:
	if _started or not is_visible_in_tree():
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
	fade_from_dark(get_tree())
	start_requested.emit()


func _show_pressed() -> void:
	if _button == null:
		return
	_style_holo(_button, true)
	_button.scale = Vector2.ONE


## O Godot retoma o AudioContext no gesto do usuário. Aqui liberamos o `Audio` (música e SFX só tocam depois disto).
func _unlock_audio() -> void:
	AudioServer.set_bus_mute(0, false)
	var audio := get_node_or_null(^"/root/Audio")
	if audio != null:
		audio.unlock()


## Véu na cor da base por cima de tudo, que some em FADE_TIME: a troca para a partida (cartoon claro) não corta
## seco. Fica na raiz da árvore (sobrevive à troca de cena), ignora o toque e se libera ao terminar.
static func fade_from_dark(tree: SceneTree) -> CanvasLayer:
	var old := tree.root.get_node_or_null(NodePath(FADE_NAME))
	if old != null:
		old.free()
	var layer := CanvasLayer.new()
	layer.name = FADE_NAME
	layer.layer = 128
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var veil := ColorRect.new()
	veil.color = BG_DEEP
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(veil)
	tree.root.add_child(layer)
	var t := veil.create_tween()
	t.tween_property(veil, "modulate:a", 0.0, FADE_TIME).from(1.0).set_ease(Tween.EASE_IN)
	t.tween_callback(layer.queue_free)
	return layer


## Laterais e base da arte somem na cor da base (como os ::before/::after do shell).
class EdgeFade extends Control:
	func _init() -> void:
		size = ART
		mouse_filter = MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var clear := Color(BG_DEEP, 0.0)
		var w := ART.x
		var h := ART.y
		var b := h - EDGE_BOTTOM
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(EDGE_W, 0), Vector2(EDGE_W, h), Vector2(0, h)]),
			PackedColorArray([BG_DEEP, clear, clear, BG_DEEP]))
		draw_polygon(PackedVector2Array([Vector2(w - EDGE_W, 0), Vector2(w, 0), Vector2(w, h), Vector2(w - EDGE_W, h)]),
			PackedColorArray([clear, BG_DEEP, BG_DEEP, clear]))
		draw_polygon(PackedVector2Array([Vector2(0, b), Vector2(w, b), Vector2(w, h + 1), Vector2(0, h + 1)]),
			PackedColorArray([clear, clear, BG_DEEP, BG_DEEP]))


## Círculo tracejado centrado na origem (desenhado uma vez; só a rotação anima).
class DashedRing extends Control:
	const DASHES := 48
	var radius := 100.0
	var color := Color.WHITE

	func _draw() -> void:
		var step := TAU / DASHES
		for i in DASHES:
			var a := i * step
			draw_arc(Vector2.ZERO, radius, a, a + step * 0.55, 6, color, 2.5, true)


## Partícula: ponto ciano-claro com halo.
class Spark extends Control:
	func _draw() -> void:
		draw_circle(Vector2.ZERO, 9.0, Color(CYAN, 0.18))
		draw_circle(Vector2.ZERO, 5.5, Color(CYAN, 0.35))
		draw_circle(Vector2.ZERO, 3.5, Color("#BFFBFF"))
