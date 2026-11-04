class_name SkillController
extends Node2D
## Slots de skill (1-based): cooldown, entrada por Input Action e sinais para a UI.

signal skill_used(slot: int)
signal cooldown_changed(slot: int, remaining: float, total: float)
signal skill_ready(slot: int)
## Efeito aplicado no chão (impacto do meteoro): posição de tela (âncora no chão), raio no chão.
signal skill_cast(slot: int, at: Vector2, radius: float)

const ACTIONS: Array[StringName] = [&"skill_1", &"skill_2", &"skill_3"]
const COOLDOWN_EMIT_INTERVAL := 0.1 ## s; no máximo ~10 emissões/s por slot

## Skills por slot (índice 0 = slot 1). Entrada vazia = slot sem skill.
@export var skills: Array[SkillData] = []

var enabled := true
## Multiplicador de cooldown (upgrade_cooldown). Vale a partir do próximo uso.
var cooldown_scale := 1.0

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
			behavior.cast.connect(_on_cast.bind(_slots.size()))
			add_child(behavior)


## Comportamento por tipo. Tipo novo = novo script + uma linha aqui.
static func behavior_for(data: SkillData) -> SkillBehavior:
	if data == null:
		return null
	match data.type:
		SkillData.Type.AREA:
			if data.delivery == SkillData.Delivery.METEOR:
				return MeteorSkill.new()
			return AreaSkill.new()
		_:
			push_warning("Skill sem comportamento: %s" % data.id)
			return null


func _on_cast(at: Vector2, radius: float, slot: int) -> void:
	skill_cast.emit(slot, at, radius)


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
	s.start_cooldown(cooldown_scale)
	behavior.activate()
	skill_used.emit(slot)
	cooldown_changed.emit(slot, s.remaining, s.total)
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
			cooldown_changed.emit(i + 1, 0.0, s.total)
			skill_ready.emit(i + 1)
		elif emit_now:
			cooldown_changed.emit(i + 1, s.remaining, s.total)
