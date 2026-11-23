class_name CoreShield
extends RefCounted
## Escudo do Núcleo (Módulo Escudo, T-110). Lógica pura: absorve até `absorb` de dano ou por `duration` s.

signal started(absorb: int, duration: float)
## Dano absorvido agora e quanto ainda resta de absorção.
signal absorbed(amount: int, remaining: int)
## Fim do escudo; broken = acabou a absorção (false = acabou o tempo).
signal ended(broken: bool)

var remaining_absorb := 0
var remaining_time := 0.0


func is_active() -> bool:
	return remaining_absorb > 0 and remaining_time > 0.0


## Liga o escudo. Reativar renova (valores novos), não acumula.
func activate(absorb_amount: int, duration: float) -> void:
	if absorb_amount <= 0 or duration <= 0.0:
		return
	remaining_absorb = absorb_amount
	remaining_time = duration
	started.emit(absorb_amount, duration)


## Absorve parte do dano; devolve o que sobrou para o Núcleo.
func absorb(amount: int) -> int:
	if amount <= 0 or not is_active():
		return amount
	var taken := mini(amount, remaining_absorb)
	remaining_absorb -= taken
	absorbed.emit(taken, remaining_absorb)
	if remaining_absorb <= 0:
		remaining_time = 0.0
		ended.emit(true)
	return amount - taken


func tick(delta: float) -> void:
	if remaining_time <= 0.0:
		return
	remaining_time = maxf(remaining_time - delta, 0.0)
	if remaining_time <= 0.0:
		remaining_absorb = 0
		ended.emit(false)
