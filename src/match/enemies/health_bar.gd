class_name HealthBar
extends Node2D
## Barra pequena de vida sobre um inimigo comum (decisão 38). Desenhada por código, só redesenha
## quando a fração muda (set_ratio); nada por quadro. Filho do inimigo: anda e some com ele.
## Também serve para a barra de defesa do chefe (cor fixa via `fixed_color`).

const HEIGHT := 6.0 ## px
const MIN_WIDTH := 40.0 ## px
const MAX_WIDTH := 56.0 ## px
const WIDTH_BASE := 28.0 ## px; largura = base + raio do inimigo, limitada a [MIN, MAX]
const OUTLINE := 1.5 ## px (contorno escuro fino)
const GAP := 6.0 ## px entre o topo do sprite e a barra
const Z := 1 ## acima dos corpos
## Faixas (decisão 38): verde ≥ 60%, amarela < 60%, vermelha ≤ 30%.
const YELLOW_BELOW := 0.6
const RED_AT_OR_BELOW := 0.3
## Cores da UI (docs/ui.md: core_hp, bar_track, ink); sem ciano.
const GREEN := Color("#3FD27F")
const YELLOW := Color("#FFC93D")
const RED := Color("#FF5A6E")
const TRACK := Color("#5B4A7A")
const INK := Color("#3A2A55")

var width := MIN_WIDTH
var ratio := 1.0
## Se definida (alfa > 0), ignora as faixas e usa esta cor (barra de defesa do chefe).
var fixed_color := Color(0, 0, 0, 0)
## Quantas vezes desenhou (testes: prova que não há trabalho por quadro).
var draw_count := 0


## radius: raio do inimigo no chão; top: px (1x) do topo do sprite acima da âncora.
## p_width > 0 fixa a largura (barra de defesa do chefe).
func configure(radius: float, top: float, p_width: float = 0.0) -> void:
	width = p_width if p_width > 0.0 else clampf(WIDTH_BASE + radius, MIN_WIDTH, MAX_WIDTH)
	position = Vector2(-width * 0.5, -top - GAP - HEIGHT)
	z_index = Z
	set_process(false)
	set_physics_process(false)
	queue_redraw()


func set_ratio(value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	if is_equal_approx(value, ratio):
		return
	ratio = value
	queue_redraw()


static func color_for(r: float) -> Color:
	if r <= RED_AT_OR_BELOW:
		return RED
	if r < YELLOW_BELOW:
		return YELLOW
	return GREEN


func _draw() -> void:
	draw_count += 1
	draw_rect(Rect2(-OUTLINE, -OUTLINE, width + OUTLINE * 2.0, HEIGHT + OUTLINE * 2.0), INK)
	draw_rect(Rect2(0.0, 0.0, width, HEIGHT), TRACK)
	if ratio > 0.0:
		var c := fixed_color if fixed_color.a > 0.0 else color_for(ratio)
		draw_rect(Rect2(0.0, 0.0, width * ratio, HEIGHT), c)
