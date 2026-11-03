class_name WaveRunner
extends RefCounted
## Progressão das ondas de uma fase. Lógica pura: quem tem a cena atende spawn_requested.
## Uma onda termina quando tudo nasceu e não há inimigos vivos; depois vem o respiro.

signal spawn_requested(enemy: EnemyData, edge: WaveEntry.SpawnEdge)
signal wave_started(current: int, total: int)
signal stage_cleared

enum Phase { IDLE, RUNNING, BREAK, CLEARED }

var stage: StageData
var phase: Phase = Phase.IDLE
var wave_index := -1 ## 0-based; -1 antes da primeira onda

var _wave_time := 0.0
var _break_left := 0.0
var _spawned := PackedInt32Array()


func _init(p_stage: StageData) -> void:
	stage = p_stage


func total_waves() -> int:
	return stage.waves.size()


## Número da onda atual, 1-based (0 antes de começar).
func current_wave() -> int:
	return wave_index + 1


func start() -> void:
	if total_waves() == 0:
		_clear()
		return
	_begin_wave(0)


## Avança o tempo. alive_count = inimigos vivos na arena.
func tick(delta: float, alive_count: int) -> void:
	match phase:
		Phase.RUNNING:
			_wave_time += delta
			var all_spawned := _spawn_due()
			if all_spawned and alive_count == 0:
				if wave_index + 1 >= total_waves():
					_clear()
				else:
					phase = Phase.BREAK
					_break_left = stage.wave_break
		Phase.BREAK:
			_break_left -= delta
			if _break_left <= 0.0:
				_begin_wave(wave_index + 1)


func _begin_wave(index: int) -> void:
	wave_index = index
	_wave_time = 0.0
	var entries := stage.waves[index].entries
	_spawned.resize(entries.size())
	_spawned.fill(0)
	phase = Phase.RUNNING
	wave_started.emit(current_wave(), total_waves())


## Emite os spawns vencidos. Devolve true quando todos os grupos terminaram.
func _spawn_due() -> bool:
	var entries := stage.waves[wave_index].entries
	var done := true
	for i in entries.size():
		var e := entries[i]
		while _spawned[i] < e.count and _wave_time >= e.start_delay + _spawned[i] * e.interval:
			_spawned[i] += 1
			spawn_requested.emit(e.enemy, e.spawn_edge)
		if _spawned[i] < e.count:
			done = false
	return done


func _clear() -> void:
	phase = Phase.CLEARED
	stage_cleared.emit()
