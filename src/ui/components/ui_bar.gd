@tool
class_name UiBar
extends Control
## Barra de vida (Núcleo ou chefe). docs/ui.md §5.2.
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

var current := 100
var maximum := 100
var _fill := 1.0
var _ghost := 1.0
var _flash := 0.0
var _ghost_tween: Tween
var _flash_tween: Tween


func _init() -> void:
	custom_minimum_size = Vector2(0, UiTokens.CORE_BAR_HEIGHT)
	mouse_filter = MOUSE_FILTER_IGNORE


## Liga direto a core_hp_changed(current, max) / boss_hp_changed(current, max).
func set_value(value: int, max_value: int) -> void:
	var lost := value < current
	current = value
	maximum = maxi(max_value, 1)
	var ratio := clampf(float(current) / maximum, 0.0, 1.0)
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
	# Trilho escuro com contorno; o preenchimento fica por dentro do contorno.
	var r := Rect2(Vector2.ZERO, size)
	var radius := size.y * 0.5
	draw_style_box(_rounded(UiTokens.BAR_TRACK, radius, UiTokens.BORDER), r)
	var b := float(UiTokens.BORDER)
	var inner := r.grow(-b)
	var inner_radius := maxf(radius - b, 0.0)
	if _ghost > _fill:
		draw_style_box(_rounded(Color(UiTokens.TEXT_PRIMARY, 0.45), inner_radius), Rect2(inner.position, Vector2(inner.size.x * _ghost, inner.size.y)))
	if _fill > 0.0:
		var fill_rect := Rect2(inner.position, Vector2(maxf(inner.size.x * _fill, inner.size.y), inner.size.y))
		draw_style_box(_rounded(_current_color(), inner_radius), fill_rect)
		# Faixa de brilho no topo do preenchimento
		var hl := Rect2(fill_rect.position + Vector2(inner_radius * 0.5, inner.size.y * 0.14), Vector2(maxf(fill_rect.size.x - inner_radius, 0.0), inner.size.y * 0.22))
		draw_style_box(_rounded(UiTokens.HIGHLIGHT, hl.size.y * 0.5), hl)
	if show_numbers:
		var font := get_theme_font("font", "UiBar")
		var fs := get_theme_font_size("font_size", "UiBar")
		var text := "%s%s / %s" % [label_prefix, UiTokens.format_int(current), UiTokens.format_int(maximum)]
		var baseline := (size.y + font.get_ascent(fs) - font.get_descent(fs)) * 0.5
		draw_string_outline(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, UiTokens.TEXT_OUTLINE - 2, UiTokens.INK)
		draw_string(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, UiTokens.TEXT_PRIMARY)


static func _rounded(color: Color, radius: float, border := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(radius))
	if border > 0:
		sb.border_color = UiTokens.INK
		sb.set_border_width_all(border)
	sb.anti_aliasing = true
	return sb
