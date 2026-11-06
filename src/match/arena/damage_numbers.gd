class_name DamageNumbers
extends Node2D
## Números de dano (T-117): pool fixo desenhado num único nó (sem Label nem nós por número).
## Dano no mesmo alvo no mesmo quadro de física é somado num número só; no máximo
## `damage_max_per_frame` números novos por quadro. Pool cheio: reusa o mais velho.

var data: GameFeelData

var _font: Font
var _pos := PackedVector2Array()
var _age := PackedFloat32Array() ## < 0 = livre
var _amount := PackedInt32Array()
var _skill := PackedByteArray() ## 1 = meteoro/skill (laranja, maior)
var _width := PackedFloat32Array()
var _text := PackedStringArray()
var _key := PackedInt64Array()
var _frame := PackedInt64Array()
var _active := 0
var _spawn_frame := -1
var _spawned := 0


func setup(p_data: GameFeelData) -> void:
	data = p_data


func _ready() -> void:
	if data == null:
		data = GameFeelData.new()
	z_index = data.damage_z_index
	z_as_relative = false
	_font = _make_font()
	var n := maxi(data.damage_pool_size, 1)
	_pos.resize(n)
	_age.resize(n)
	_age.fill(-1.0)
	_amount.resize(n)
	_skill.resize(n)
	_width.resize(n)
	_text.resize(n)
	_key.resize(n)
	_frame.resize(n)
	set_process(false)


func _make_font() -> Font:
	var base: Font = data.damage_font if data.damage_font else ThemeDB.fallback_font
	var fv := FontVariation.new()
	fv.base_font = base
	var ts := TextServerManager.get_primary_interface()
	fv.variation_opentype = {ts.name_to_tag("wght"): data.damage_font_weight}
	return fv


func pool_size() -> int:
	return _age.size()


func active_count() -> int:
	return _active


## Mostra `amount` acima de `at` (coordenadas deste nó). `key` identifica o alvo (instance id) para
## somar acertos do mesmo quadro. Devolve false se descartado pelo limite por quadro.
func show_damage(key: int, at: Vector2, amount: int, skill: bool) -> bool:
	if amount <= 0 or _age.is_empty():
		return false
	var frame := Engine.get_physics_frames()
	for i in _age.size():
		if _age[i] >= 0.0 and _key[i] == key and _frame[i] == frame:
			_amount[i] += amount
			if skill:
				_skill[i] = 1
			_refresh(i)
			return true
	if _spawn_frame != frame:
		_spawn_frame = frame
		_spawned = 0
	if _spawned >= data.damage_max_per_frame:
		return false
	_spawned += 1
	var i := _slot()
	if _age[i] < 0.0:
		_active += 1
	_age[i] = 0.0
	_pos[i] = at
	_amount[i] = amount
	_skill[i] = 1 if skill else 0
	_key[i] = key
	_frame[i] = frame
	_refresh(i)
	set_process(true)
	return true


## Livre, ou o mais velho se o pool estiver cheio.
func _slot() -> int:
	var oldest := 0
	for i in _age.size():
		if _age[i] < 0.0:
			return i
		if _age[i] > _age[oldest]:
			oldest = i
	return oldest


func _refresh(i: int) -> void:
	_text[i] = str(_amount[i])
	_width[i] = _font.get_string_size(_text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, _size_of(i)).x


func _size_of(i: int) -> int:
	return data.damage_skill_size if _skill[i] == 1 else data.damage_shot_size


func clear() -> void:
	_age.fill(-1.0)
	_active = 0
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	for i in _age.size():
		if _age[i] < 0.0:
			continue
		_age[i] += delta
		if _age[i] >= data.damage_lifetime:
			_age[i] = -1.0
			_active -= 1
	if _active <= 0:
		_active = 0
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var life := maxf(data.damage_lifetime, 0.001)
	for i in _age.size():
		if _age[i] < 0.0:
			continue
		var t := clampf(_age[i] / life, 0.0, 1.0)
		var rise := data.damage_rise * (1.0 - (1.0 - t) * (1.0 - t)) # sobe rápido e freia
		var s := 1.0 + data.damage_pop * maxf(1.0 - t / 0.15, 0.0)
		var alpha := 1.0 - smoothstep(0.55, 1.0, t)
		var size := _size_of(i)
		var color := data.damage_skill_color if _skill[i] == 1 else data.damage_shot_color
		var outline := data.damage_outline_color
		color.a *= alpha
		outline.a *= alpha
		draw_set_transform(_pos[i] - Vector2(0.0, rise), 0.0, Vector2(s, s))
		var o := Vector2(-_width[i] * 0.5, 0.0)
		draw_string_outline(_font, o, _text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, data.damage_outline_size, outline)
		draw_string(_font, o, _text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	draw_set_transform(Vector2.ZERO)
