class_name PlayerProfile
extends RefCounted
## Modelo de dados do perfil do jogador (T-185). Sem cena e sem logica de XP (T-186).
## Campos novos devem ser opcionais com padrao, para nao quebrar saves antigos.

const MAX_LEVEL := 100  # provisorio; o teto real vem da T-186 (AG04)
const MAX_AMOUNT := 2000000000

var level := 1
var xp := 0
var coins := 0  ## Moeda (meta)
var settings := {"sound_on": true, "music_volume": 1.0, "sfx_volume": 1.0}
## Espaco para crescer (Modulos, Componentes, Nucleos): chaves desconhecidas do save ficam aqui.
var extra := {}


func to_dict() -> Dictionary:
	var d := extra.duplicate(true)
	d["level"] = level
	d["xp"] = xp
	d["coins"] = coins
	d["settings"] = settings.duplicate()
	return d


## Cria a partir de um Dictionary sem validar (use `is_valid_dict` antes, ou `sanitize` depois).
static func from_dict(d: Dictionary) -> PlayerProfile:
	var p := PlayerProfile.new()
	p.level = int(d.get("level", 1))
	p.xp = int(d.get("xp", 0))
	p.coins = int(d.get("coins", 0))
	var s: Variant = d.get("settings", {})
	if s is Dictionary:
		for k in s:
			p.settings[k] = s[k]
	for k in d:
		if not (k in ["level", "xp", "coins", "settings"]):
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
	return true


## Corrige valores invalidos (negativos, acima do maximo, volumes fora de 0..1).
func sanitize() -> void:
	level = clampi(level, 1, MAX_LEVEL)
	xp = clampi(xp, 0, MAX_AMOUNT)
	coins = clampi(coins, 0, MAX_AMOUNT)
	settings["sound_on"] = bool(settings.get("sound_on", true))
	for k in ["music_volume", "sfx_volume"]:
		var v: Variant = settings.get(k, 1.0)
		settings[k] = clampf(float(v) if (v is float or v is int) else 1.0, 0.0, 1.0)
