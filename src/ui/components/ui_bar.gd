@tool
class_name UiBar
extends Control
## Barra de vida (Núcleo ou chefe). docs/ui.md §5.2.
## Arte em assets/ui/ (ui_bar_*); trilho de `track_height` (36 px por padrão), centrado no controle.
## O preenchimento vai direto ao valor; a "barra fantasma" vai atrás e mostra a perda.

enum ColorMode { FIXED, CORE_HP }

const GHOST_DELAY := 0.15
const GHOST_TIME := 0.3

@export var color_mode := ColorMode.CORE_HP:
	set(v):
		color_mode = v
		queue_redraw()
@export var fill_color := UiTokens.BOSS_HP:
	set(v):
		fill_color = v
		queue_redraw()
## Texto antes dos números (ex.: "NÚCLEO ").
@export var label_prefix := "":
	set(v):
		label_prefix = v
		queue_redraw()
@export var show_numbers := true:
	set(v):
		show_numbers = v
		queue_redraw()
## Altura do trilho; preenchimento, folga e brilho acompanham na mesma proporção.
@export var track_height := UiArt.BAR_TRACK_HEIGHT:
	set(v):
		track_height = v
		queue_redraw()
## Rótulo à esquerda, dentro da barra (ex.: "Boss"); com ele, os números vão para a direita.
@export var title := "":
	set(v):
		title = v
		queue_redraw()
## Duração da queda do preenchimento (0 = direto ao valor).
@export var fill_time := 0.0

var current := 100
var maximum := 100
var _fill := 1.0
var _ghost := 1.0
var _flash := 0.0
var _ghost_tween: Tween
var _flash_tween: Tween
var _fill_tween: Tween
var _track_box := UiArt.bar_track()
var _fill_box := UiArt.bar_fill()
var _ghost_box := UiArt.bar_fill()
var _shine_box := UiArt.bar_shine()


func _init() -> void:
	custom_minimum_size = Vector2(0, UiTokens.CORE_BAR_HEIGHT)
	mouse_filter = MOUSE_FILTER_IGNORE
	_ghost_box.modulate_color = Color(UiTokens.TEXT_PRIMARY, 0.45)


## Liga direto a core_hp_changed(current, max) / boss_hp_changed(current, max).
func set_value(value: int, max_value: int) -> void:
	var lost := value < current
	current = value
	maximum = maxi(max_value, 1)
	var ratio := clampf(float(current) / maximum, 0.0, 1.0)
	if _fill_tween:
		_fill_tween.kill()
	if fill_time > 0.0 and ratio < _fill and is_inside_tree():
		_fill_tween = create_tween()
		_fill_tween.tween_method(_set_fill, _fill, ratio, fill_time).set_ease(Tween.EASE_OUT)
	else:
		_fill = ratio
	if _ghost_tween:
		_ghost_tween.kill()
	if ratio < _ghost:
		_ghost_tween = create_tween()
		_ghost_tween.tween_interval(GHOST_DELAY)
		_ghost_tween.tween_method(_set_ghost, _ghost, ratio, GHOST_TIME).set_ease(Tween.EASE_OUT)
	else:
		_ghost = ratio
	if lost and is_inside_tree():
		_play_flash()
	queue_redraw()


func _set_fill(v: float) -> void:
	_fill = v
	queue_redraw()


func _set_ghost(v: float) -> void:
	_ghost = v
	queue_redraw()


func _set_flash(v: float) -> void:
	_flash = v
	queue_redraw()


func _play_flash() -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_method(_set_flash, 1.0, 0.0, UiTokens.ANIM_UI)


func _current_color() -> Color:
	var c := UiTokens.core_hp_color(_fill) if color_mode == ColorMode.CORE_HP else fill_color
	return c.lerp(UiTokens.DANGER, _flash * 0.6) if _flash > 0.0 else c


func _draw() -> void:
	# Arte T-128: trilho (centrado), preenchimento branco tingido e brilho no topo, na escala de track_height.
	var k := track_height / UiArt.BAR_TRACK_HEIGHT
	var y0 := (size.y - track_height) * 0.5
	draw_style_box(_track_box, Rect2(0.0, y0, size.x, track_height))
	var pad := UiArt.BAR_FILL_INSET * k
	var h := UiArt.BAR_FILL_HEIGHT * k
	var inner := Rect2(pad, y0 + pad, maxf(size.x - 2.0 * pad, 0.0), h)
	if _ghost > _fill:
		draw_style_box(_ghost_box, Rect2(inner.position, Vector2(maxf(inner.size.x * _ghost, h), h)))
	if _fill > 0.0:
		var fill_w := maxf(inner.size.x * _fill, h)
		_fill_box.modulate_color = _current_color()
		draw_style_box(_fill_box, Rect2(inner.position, Vector2(fill_w, h)))
		var shine_w := fill_w - h * 0.5
		if shine_w >= UiArt.BAR_SHINE_HEIGHT * k * 2.0:
			draw_style_box(_shine_box, Rect2(inner.position + Vector2(h * 0.25, 2.0 * k), Vector2(shine_w, UiArt.BAR_SHINE_HEIGHT * k)))
	if not show_numbers and title.is_empty():
		return
	var font := get_theme_font("font", "UiBar")
	var fs := get_theme_font_size("font_size", "UiBar")
	var baseline := inner.get_center().y + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
	var side := UiTokens.SPACE_S
	if not title.is_empty():
		_text(font, Vector2(side, baseline), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 2 * side, fs)
	if show_numbers:
		var text := "%s%s / %s" % [label_prefix, UiTokens.format_int(current), UiTokens.format_int(maximum)]
		if title.is_empty():
			_text(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs)
		else:
			_text(font, Vector2(side, baseline), text, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 2 * side, fs)


func _text(font: Font, at: Vector2, text: String, align: HorizontalAlignment, width: float, fs: int) -> void:
	draw_string_outline(font, at, text, align, width, fs, UiTokens.TEXT_OUTLINE - 2, UiTokens.INK)
	draw_string(font, at, text, align, width, fs, UiTokens.TEXT_PRIMARY)
