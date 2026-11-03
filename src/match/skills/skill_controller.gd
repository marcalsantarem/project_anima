class_name SkillController
extends Node2D
## Slots de skill (1-based): cooldown, entrada por Input Action e sinais para a UI.

signal skill_used(slot: int)
signal cooldown_changed(slot: int, remaining: float, total: float)
signal skill_ready(slot: int)

const ACTIONS: Array[StringName] = [&"skill_1", &"skill_2", &"skill_3"]
const COOLDOWN_EMIT_INTERVAL := 0.1 ## s; no máximo ~10 emissões/s por slot

## Skills por slot (índice 0 = slot 1). Entrada vazia = slot sem skill.
@export var skills: Array[SkillData] = []

var enabled := true

var _slots: Array[SkillSlot] = []
var _behaviors: Array[SkillBehavior] = []
var _emit_timer := 0.0


func setup(context: SkillContext) -> void:
	for data in skills:
		var behavior := behavior_for(data)
		_slots.append(SkillSlot.new(data) if behavior else null)
		_behaviors.append(behavior)
		if behavior:
			behavior.setup(data, context)
			add_child(behavior)


## Comportamento por tipo. Tipo novo = novo script + uma linha aqui.
static func behavior_for(data: SkillData) -> SkillBehavior:
	if data == null:
		return null
	match data.type:
		SkillData.Type.AREA:
			return AreaSkill.new()
		_:
			push_warning("Skill sem comportamento: %s" % data.id)
			return null


func slot_count() -> int:
	return _slots.size()


func get_slot(slot: int) -> SkillSlot:
	if slot < 1 or slot > _slots.size():
		return null
	return _slots[slot - 1]


## Aciona a skill do slot (1-based). Usado pela entrada e pelos botões de toque da UI.
func use_skill(slot: int) -> bool:
	var s := get_slot(slot)
	if not enabled or s == null or not s.is_ready():
		return false
	var behavior := _behaviors[slot - 1]
	if not behavior.can_activate():
		return false
	s.start_cooldown()
	behavior.activate()
	skill_used.emit(slot)
	cooldown_changed.emit(slot, s.remaining, s.data.cooldown)
	return true


func _unhandled_input(event: InputEvent) -> void:
	for i in ACTIONS.size():
		if event.is_action_pressed(ACTIONS[i]):
			if use_skill(i + 1):
				get_viewport().set_input_as_handled()
			return


func _physics_process(delta: float) -> void:
	_emit_timer += delta
	var emit_now := _emit_timer >= COOLDOWN_EMIT_INTERVAL
	if emit_now:
		_emit_timer = 0.0
	for i in _slots.size():
		var s := _slots[i]
		if s == null or s.is_ready():
			continue
		if s.tick(delta):
			cooldown_changed.emit(i + 1, 0.0, s.data.cooldown)
			skill_ready.emit(i + 1)
		elif emit_now:
			cooldown_changed.emit(i + 1, s.remaining, s.data.cooldown)
