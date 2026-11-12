@tool
class_name UiBar
extends Control
## Barra de vida (Energia do Anima ou chefe). docs/ui.md §5.2.
## Arte holográfica (T-290, ui_hud_bar_*, 1:1); trilho de `track_height` (40 px por padrão), centrado no controle.
## Energia: enchimento branco tingido por `modulate` (core_hp_color). Chefe (`boss_art`): arte própria, sem tingir.
## O preenchimento vai direto ao valor; a "barra fantasma" vai atrás e mostra a perda.

enum ColorMode { FIXED, CORE_HP }

const GHOST_DELAY := 0.15
const GHOST_TIME := 0.3
const TRACK_HEIGHT := 40.0
## Recuo do enchimento dentro do trilho (px).
const FILL_INSET := 4.0

@export var color_mode := ColorMode.CORE_HP:
	set(v):
		color_mode = v
		queue_redraw()
@export var fill_color := UiTokens.BOSS_HOLO:
	set(v):
		fill_color = v
		queue_redraw()
## Usa a arte do chefe (trilho magenta, enchimento já colorido, ponta a 80% da altura).
@export var boss_art := false:
	set(v):
		boss_art = v
		_track_box = UiArt.hud_bar_track(v)
		_fill_box = UiArt.hud_bar_fill(v)
		_ghost_box = UiArt.hud_bar_fill(v)
		_ghost_box.modulate_color = Color(1, 1, 1, 0.45)
		queue_redraw()
## Texto antes dos números (ex.: "ENERGIA ").
@export var label_prefix := "":
	set(v):
		label_prefix = v
		queue_redraw()
@export var show_numbers := true:
	set(v):
		show_numbers = v
		queue_redraw()
## Altura do trilho; preenchimento, folga e brilho acompanham na mesma proporção.
@export var track_height := TRACK_HEIGHT:
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
var _track_box := UiArt.hud_bar_track(false)
var _fill_box := UiArt.hud_bar_fill(false)
var _ghost_box := UiArt.hud_bar_fill(false)
var _flash_box := UiArt.hud_bar_flash()


func _init() -> void:
	custom_minimum_size = Vector2(0, UiTokens.CORE_BAR_HEIGHT)
	mouse_filter = MOUSE_FILTER_IGNORE
	_ghost_box.modulate_color = Color(1, 1, 1, 0.45)
	_flash_box.modulate_color = UiTokens.DANGER


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
	return UiTokens.core_hp_color(_fill) if color_mode == ColorMode.CORE_HP and not boss_art else (Color.WHITE if boss_art else fill_color)


func _draw() -> void:
	# Trilho centrado, enchimento recuado, ponta e flash de dano por cima; sem alocação por quadro.
	var y0 := (size.y - track_height) * 0.5
	draw_style_box(_track_box, Rect2(0.0, y0, size.x, track_height))
	var h := track_height - 2.0 * FILL_INSET
	var inner := Rect2(FILL_INSET, y0 + FILL_INSET, maxf(size.x - 2.0 * FILL_INSET, 0.0), h)
	if _ghost > _fill:
		draw_style_box(_ghost_box, Rect2(inner.position, Vector2(maxf(inner.size.x * _ghost, h), h)))
	if _fill > 0.0:
		var fill_w := maxf(inner.size.x * _fill, h)
		_fill_box.modulate_color = _current_color()
		draw_style_box(_fill_box, Rect2(inner.position, Vector2(fill_w, h)))
		var tip := UiArt.HUD_BAR_TIP
		var ts := tip.get_size() * Vector2(1.0, 0.8 if boss_art else 1.0)
		draw_texture_rect(tip, Rect2(Vector2(inner.position.x + fill_w - ts.x * 0.5, y0 + (track_height - ts.y) * 0.5), ts), false)
	if _flash > 0.0:
		_flash_box.modulate_color = Color(UiTokens.DANGER, _flash)
		draw_style_box(_flash_box, Rect2(0.0, y0, size.x, track_height))
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
	draw_string_outline(font, at, text, align, width, fs, UiTokens.HOLO_OUTLINE, UiTokens.HOLO_BG)
	draw_string(font, at, text, align, width, fs, UiTokens.HOLO_TEXT)
