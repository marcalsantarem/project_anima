class_name ScreenShake
extends RefCounted
## Tremor de tela (T-117): um tremor por vez; um novo só substitui o atual se for mais forte que o
## que resta dele. Amplitude decai em k² (k = tempo restante / duração). Sem alocar por quadro.

var amplitude := 0.0
var duration := 0.0
var left := 0.0
## Multiplicador aplicado a novos tremores (1 = normal; "Efeitos reduzidos" usa < 1; 0 = desligado).
var scale := 1.0

var _rng := RandomNumberGenerator.new() # separado do RNG da partida (não muda a seed dos spawns)


## Pede um tremor de `amp` px por `time` s. Devolve true se passou a valer.
func add(amp: float, time: float) -> bool:
	amp *= scale
	if amp <= 0.0 or time <= 0.0 or amp < current_amplitude():
		return false
	amplitude = amp
	duration = time
	left = time
	return true


func current_amplitude() -> float:
	if left <= 0.0:
		return 0.0
	var k := left / duration
	return amplitude * k * k


func is_active() -> bool:
	return left > 0.0


## Avança `delta` s e devolve o deslocamento deste quadro (ZERO quando parado).
func step(delta: float) -> Vector2:
	if left <= 0.0:
		return Vector2.ZERO
	left = maxf(left - delta, 0.0)
	return Vector2.from_angle(_rng.randf() * TAU) * current_amplitude()


func stop() -> void:
	left = 0.0
