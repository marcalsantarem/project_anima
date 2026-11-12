class_name UiTokens
## Tokens de UI (docs/ui.md §3). Fonte única de cores, tamanhos e tempos.
## Estilo cartoon claro "Jardim Arcano" (decisões 31–36, T-145): contorno escuro, sombra de base sólida.

# Cores — base
const INK := Color("#3A2A55") # contorno, sombra de base e texto sobre fundo claro
const BG_VOID := Color("#7C6BC9") # fundo das telas (lavanda)
const BG_PANEL := Color("#8E7CD8") # painéis e pílulas
const BG_PANEL_ALT := Color("#5A4A9A") # bandeja inferior, fundo de botão secundário escuro
const BG_DIM := Color("#3A2A55b3") # véu atrás de diálogos (70%)
const TRAY_BAND := Color("#64549F") # faixa da fileira de upgrades
const SURFACE := Color("#FFFFFF") # botão/cartão claro
const LINE := Color("#3A2A55")
const TEXT_PRIMARY := Color("#FFFFFF")
const TEXT_SECONDARY := Color("#E2DAFF")
const TEXT_ON_LIGHT := Color("#3A2A55")
const ACCENT := Color("#2FE6D2") # pronto / foco / primário
const SKILL_FILL := Color("#957CE6")
const BADGE := Color("#CDF1FF")
const LOCKED := Color("#9D98AE")
const BAR_TRACK := Color("#5B4A7A")
const CORE_HP_HIGH := Color("#6CF0A4")
const CORE_HP_MID := Color("#FFC93D")
const CORE_HP_LOW := Color("#FF5A6E")
const BOSS_HP := Color("#FF5A6E") # barra "Boss" (decisão 39: vermelha, igual a `danger`)
const DANGER := Color("#FF5A6E")
# HUD holográfico da partida (decisão 64, docs/arte.md §11.1 e §12)
const HOLO_BG := Color("#021423") # contorno dos textos do HUD e véu do topo
const HOLO_TRAY := Color("#06182A") # bandeja opaca; cor da página na partida
const HOLO_LINE := Color("#3FE8F5")
const HOLO_TEXT := Color("#E6FFFF")
const HOLO_TEXT2 := Color("#9FF6FF")
const HOLO_MUTED := Color("#7FA3B8")
const HOLO_DIS_TEXT := Color("#5F7A92") # desabilitado e bloqueado
const BOSS_HOLO := Color("#FF4F8B") # chefe: trilho, enchimento e emblema (no lugar do `boss_hp` vermelho)
const COST_GOLD := Color("#FFE08A") # custo comprável dos upgrades
const COST_POOR := Color("#FF9AA6") # custo sem Partículas
const HOLO_OUTLINE := 5 # contorno dos textos do HUD (px, total)
const PARTICLES := Color("#7CF05A") # Partículas (verde do ícone `ui_icon_particles`, decisão 40); sempre com contorno `ink`
const GOLD := Color("#FFC93D") # "Vitória", "+1" de nível, MAX; reservado à futura Moeda (M2)
const COOLDOWN_DIM := Color(0.10, 0.06, 0.18, 0.55)
const HIGHLIGHT := Color(1, 1, 1, 0.18) # faixa de brilho no topo dos botões

# Raridade (docs/arte.md §6)
const RARITY_COMMON := Color("#9AA4B8")
const RARITY_RARE := Color("#3D8BF5")
const RARITY_EPIC := Color("#A04DF5")
const RARITY_LEGENDARY := Color("#F5B83D")

# Tipografia (px na resolução base 720×1280)
const FONT_DISPLAY := 72
const FONT_TITLE := 48
const FONT_HUD := 32
const FONT_BODY := 28
const FONT_CAPTION := 22
const FONT_WEIGHT_REGULAR := 600
const FONT_WEIGHT_BOLD := 800
const TEXT_OUTLINE := 8 # contorno do texto claro (px, total)

# Espaçamento e forma
const SPACE_XS := 8
const SPACE_S := 16
const SPACE_M := 24
const SPACE_L := 32
const SPACE_XL := 48
const MARGIN_SCREEN := 16
const RADIUS_S := 12
const RADIUS_M := 20
const RADIUS_L := 28
const TOUCH_MIN := 88
const BORDER := 4 # contorno escuro de tudo
const BORDER_FOCUS := 4
const SHADOW_BASE := 6 # sombra de base sólida (borda inferior extra)

# HUD (docs/arte.md §6)
const SKILL_DIAMETER := 144
const SKILL_GAP := 66 # centros em x = 150 / 360 / 570
const UPGRADE_SIZE := Vector2(128, 80)
const UPGRADE_GAP := 12
const UPGRADE_COUNT := 5
const CORE_BAR_HEIGHT := 40

# Tempos (s)
const ANIM_FAST := 0.1
const ANIM_UI := 0.2

const FONT_PATH := "res://assets/fonts/Outfit-Variable.ttf"


## Cor da Energia (vida do Anima) por faixa: > 50% / 25–50% / < 25%.
static func core_hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return CORE_HP_HIGH
	if ratio >= 0.25:
		return CORE_HP_MID
	return CORE_HP_LOW


## Caixa cartoon: contorno INK, sombra de base sólida (borda inferior mais grossa), cantos redondos.
static func cartoon_box(bg: Color, radius: int = RADIUS_M, shadow: int = SHADOW_BASE, border: Color = INK) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(BORDER)
	sb.border_width_bottom = BORDER + shadow
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = SPACE_M
	sb.content_margin_right = SPACE_M
	sb.content_margin_top = SPACE_S
	sb.content_margin_bottom = SPACE_S
	sb.anti_aliasing = true
	return sb


## Número com separador de milhar pt-BR (1.250).
static func format_int(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	while s.length() > 3:
		out = "." + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("-" if v < 0 else "") + s + out
