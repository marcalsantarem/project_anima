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
	custom_minimum_size = Vector2(0, 32)
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
	var r := Rect2(Vector2.ZERO, size)
	var radius := minf(size.y * 0.5, UiTokens.RADIUS_S)
	draw_style_box(_rounded(UiTokens.BG_PANEL_ALT, radius), r)
	if _ghost > _fill:
		draw_style_box(_rounded(Color(UiTokens.TEXT_PRIMARY, 0.35), radius), Rect2(Vector2.ZERO, Vector2(size.x * _ghost, size.y)))
	if _fill > 0.0:
		draw_style_box(_rounded(_current_color(), radius), Rect2(Vector2.ZERO, Vector2(size.x * _fill, size.y)))
	var border := StyleBoxFlat.new()
	border.draw_center = false
	border.border_color = UiTokens.LINE
	border.set_border_width_all(UiTokens.BORDER)
	border.set_corner_radius_all(int(radius))
	draw_style_box(border, r)
	if show_numbers:
		var font := get_theme_font("font", "UiBar")
		var fs := get_theme_font_size("font_size", "UiBar")
		var text := "%d/%d" % [current, maximum]
		var baseline := (size.y + font.get_ascent(fs) - font.get_descent(fs)) * 0.5
		draw_string_outline(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, 4, UiTokens.BG_VOID)
		draw_string(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, UiTokens.TEXT_PRIMARY)


static func _rounded(color: Color, radius: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	return sb
