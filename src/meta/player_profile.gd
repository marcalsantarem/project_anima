class_name PlayerProfile
extends RefCounted
## Modelo de dados do perfil do jogador (T-185). Sem cena e sem logica de XP (T-186).
## Campos novos devem ser opcionais com padrao, para nao quebrar saves antigos.

const MAX_LEVEL := 30  # teto da conta (BRF-108)
const MAX_AMOUNT := 2000000000
## Módulos equipáveis (ids das skills; catálogo em data/skills/module_catalog.tres).
const MODULE_IDS: Array[StringName] = [&"skill_meteor", &"skill_shock", &"skill_freeze", &"skill_shield"]

var level := 1
var xp := 0
var coins := 0  ## Moeda (meta)
var last_first_win_date := ""  ## "YYYY-MM-DD" (data local) da última 1ª vitória do dia, ou ""
## Núcleos comprados {id: nível} (T-204); ausente = nível 0.
var talents := {}
## Módulos {id: nível 1..5} (T-213); ausente = Nv 1 se a conta já liberou o Módulo.
var module_levels := {}
## Módulo por slot (índice 0 = slot 1; &"" = vazio). `[]` = nunca personalizado (padrão automático, `MetaModules`).
var module_slots: Array = []
var settings := {"sound_on": true, "music_volume": 1.0, "sfx_volume": 1.0}
## Espaco para crescer (Modulos, Componentes, Nucleos): chaves desconhecidas do save ficam aqui.
var extra := {}


func to_dict() -> Dictionary:
	var d := extra.duplicate(true)
	d["level"] = level
	d["xp"] = xp
	d["coins"] = coins
	d["last_first_win_date"] = last_first_win_date
	d["settings"] = settings.duplicate()
	d["talents"] = talents.duplicate()
	d["module_levels"] = module_levels.duplicate()
	d["module_slots"] = module_slots.duplicate()
	return d


## Cria a partir de um Dictionary sem validar (use `is_valid_dict` antes, ou `sanitize` depois).
static func from_dict(d: Dictionary) -> PlayerProfile:
	var p := PlayerProfile.new()
	p.level = int(d.get("level", 1))
	p.xp = int(d.get("xp", 0))
	p.coins = int(d.get("coins", 0))
	var lf: Variant = d.get("last_first_win_date", "")
	p.last_first_win_date = lf if lf is String else ""
	var s: Variant = d.get("settings", {})
	if s is Dictionary:
		for k in s:
			p.settings[k] = s[k]
	var tl: Variant = d.get("talents", {})
	if tl is Dictionary:
		for k in tl:
			p.talents[StringName(k)] = int(tl[k]) if (tl[k] is int or tl[k] is float) else 0
	var ml: Variant = d.get("module_levels", {})
	if ml is Dictionary:
		for k in ml:
			p.module_levels[StringName(k)] = int(ml[k]) if (ml[k] is int or ml[k] is float) else 1
	var ms: Variant = d.get("module_slots", [])
	if ms is Array:
		for v in ms:
			p.module_slots.append(StringName(v) if (v is String or v is StringName) else &"")
	for k in d:
		if not (k in ["level", "xp", "coins", "settings", "last_first_win_date", "talents", "module_levels", "module_slots"]):
			p.extra[k] = d[k]
	return p


## Verificacao estrita (usada na leitura do disco): tipos e faixas.
static func is_valid_dict(d: Dictionary) -> bool:
	for k in ["level", "xp", "coins"]:
		if d.has(k):
			var v: Variant = d[k]
			if not (v is int or (v is float and v == floorf(v))):
				return false
	var lv := int(d.get("level", 1))
	if lv < 1 or lv > MAX_LEVEL:
		return false
	for k in ["xp", "coins"]:
		var n := int(d.get(k, 0))
		if n < 0 or n > MAX_AMOUNT:
			return false
	if d.has("settings"):
		var s: Variant = d["settings"]
		if not (s is Dictionary):
			return false
		if s.has("sound_on") and not (s["sound_on"] is bool):
			return false
		for k in ["music_volume", "sfx_volume"]:
			if s.has(k):
				var v: Variant = s[k]
				if not ((v is float or v is int) and v >= 0.0 and v <= 1.0):
					return false
	if d.has("talents"):
		var tl: Variant = d["talents"]
		if not (tl is Dictionary):
			return false
		for k in tl:
			var v: Variant = tl[k]
			if not (v is int or (v is float and v == floorf(v))) or v < 0:
				return false
	return true


## Corrige valores invalidos (negativos, acima do maximo, volumes fora de 0..1).
func sanitize(tree: TalentTree = null) -> void:
	_sanitize_talents(tree)
	_sanitize_modules()
	level = clampi(level, 1, MAX_LEVEL)
	xp = clampi(xp, 0, MAX_AMOUNT)
	coins = clampi(coins, 0, MAX_AMOUNT)
	if not is_valid_date(last_first_win_date):
		last_first_win_date = ""
	settings["sound_on"] = bool(settings.get("sound_on", true))
	for k in ["music_volume", "sfx_volume"]:
		var v: Variant = settings.get(k, 1.0)
		settings[k] = clampf(float(v) if (v is float or v is int) else 1.0, 0.0, 1.0)


## "" ou "YYYY-MM-DD" com mês 1..12 e dia 1..31.
static func is_valid_date(s: String) -> bool:
	if s == "":
		return true
	var re := RegEx.new()
	re.compile("^\\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01])$")
	return re.search(s) != null

## Módulos (T-213): só ids conhecidos, níveis em 1..5, no máximo 3 slots sem repetir Módulo.
func _sanitize_modules() -> void:
	var levels := {}
	for k in module_levels:
		if StringName(k) in MODULE_IDS:
			levels[StringName(k)] = clampi(int(module_levels[k]), 1, 5)
	module_levels = levels
	var slots: Array = []
	for i in mini(module_slots.size(), 3):
		var id := StringName(module_slots[i])
		slots.append(id if (id in MODULE_IDS and not (id in slots)) else &"")
	module_slots = slots


## Núcleo de compra única: nível >= 1 (save antigo) vira 1 (comprado); <= 0 sai. Com a árvore, ids desconhecidos saem.
func _sanitize_talents(tree: TalentTree) -> void:
	var clean := {}
	for k in talents:
		var lv := maxi(int(talents[k]), 0)
		if tree != null:
			var t := tree.get_talent(StringName(k))
			if t == null:
				continue
		if lv > 0:
			clean[StringName(k)] = 1
	talents = clean
