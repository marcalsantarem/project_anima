extends Node
## Autoload `SpeedController` (T-273, decisão 59): velocidade do jogo x1/x2. É o ÚNICO escritor do
## valor de repouso de `Engine.time_scale`. Pausa usa `get_tree().paused` e não toca no time_scale;
## o hit-stop devolve `rest_scale()` ao terminar. Bot e headless ficam sempre em x1.
## A escolha é salva em `user://settings.cfg` (seção `game`, chave `speed`).

signal speed_changed(speed: float)
## Ponto de extensão para travas futuras (nível, anúncio): o botão (T-275) mostra o cadeado.
signal speed_lock_changed(speed: float, unlocked: bool)

const SPEED_X1 := 1.0
const SPEED_X2 := 2.0
const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "game"
const KEY := "speed"

## Velocidade escolhida pelo jogador (1.0 ou 2.0). Lida do arquivo no boot.
var chosen := SPEED_X1
## true = ignora `set_speed` e mantém x1 (headless/testes/bot). Testes que exercitam x2 desligam.
var locked_to_x1 := DisplayServer.get_name() == "headless"
## true durante um hit-stop: `restore()` não mexe no time_scale; vale `chosen` quando ele termina.
var held := false
## Só testes: caminho do arquivo de configuração.
var settings_path := SETTINGS_PATH


func _ready() -> void:
	chosen = load_saved()
	restore()


## Trava futura: hoje todo valor válido (x1, x2) está liberado.
func can_use_speed(speed: float) -> bool:
	return is_valid_speed(speed)


static func is_valid_speed(speed: float) -> bool:
	return is_equal_approx(speed, SPEED_X1) or is_equal_approx(speed, SPEED_X2)


## Define e salva a escolha. false = recusado (valor inválido, trava ou headless/bot em x1).
func set_speed(speed: float) -> bool:
	if locked_to_x1 or not can_use_speed(speed):
		return false
	var new_speed := SPEED_X2 if is_equal_approx(speed, SPEED_X2) else SPEED_X1
	if is_equal_approx(new_speed, chosen):
		return true
	chosen = new_speed
	restore()
	save()
	speed_changed.emit(chosen)
	return true


## Valor de repouso do `Engine.time_scale` (x1 se travado).
func rest_scale() -> float:
	return SPEED_X1 if locked_to_x1 else chosen


## Devolve `Engine.time_scale` ao valor escolhido (fim de hit-stop, saída de câmera lenta de debug).
func restore() -> void:
	if held:
		return
	Engine.time_scale = rest_scale()


## Uma trava mudou. Se o que cai é a velocidade ativa, volta a x1 pela mesma regra.
func notify_lock(speed: float, unlocked: bool) -> void:
	speed_lock_changed.emit(speed, unlocked)
	if not unlocked and is_equal_approx(speed, chosen) and not is_equal_approx(chosen, SPEED_X1):
		set_speed(SPEED_X1)


## Lê a escolha salva; ausente, ilegível ou inválido vira x1.
func load_saved() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(settings_path) != OK:
		return SPEED_X1
	var v: Variant = cfg.get_value(SECTION, KEY, SPEED_X1)
	if not (v is float or v is int):
		return SPEED_X1
	var f := float(v)
	if is_valid_speed(f) and can_use_speed(f):
		return SPEED_X2 if is_equal_approx(f, SPEED_X2) else SPEED_X1
	return SPEED_X1


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(settings_path) # preserva outras chaves; falha = arquivo novo
	cfg.set_value(SECTION, KEY, chosen)
	cfg.save(settings_path)
