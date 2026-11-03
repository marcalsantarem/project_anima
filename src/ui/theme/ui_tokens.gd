class_name UiTokens
## Tokens de UI (docs/ui.md §3). Fonte única de cores, tamanhos e tempos.

# Cores
const BG_VOID := Color("#07090F")
const BG_PANEL := Color("#111726d9") # 85%
const BG_PANEL_ALT := Color("#1A2236")
const LINE := Color("#2A3550")
const TEXT_PRIMARY := Color("#E8EEF8")
const TEXT_SECONDARY := Color("#8A96B0")
const ACCENT := Color("#3DF5E0")
const CORE_HP_HIGH := Color("#3DF58A")
const CORE_HP_MID := Color("#F5C53D")
const CORE_HP_LOW := Color("#F5455C")
const BOSS_HP := Color("#C040F5")
const DANGER := Color("#F5455C")
const COIN := Color("#F5C53D")
const COOLDOWN_DIM := Color(0, 0, 0, 0.55)

# Tipografia (px na resolução base 720×1280)
const FONT_DISPLAY := 72
const FONT_TITLE := 48
const FONT_HUD := 32
const FONT_BODY := 28
const FONT_CAPTION := 22

# Espaçamento e forma
const SPACE_XS := 8
const SPACE_S := 16
const SPACE_M := 24
const SPACE_L := 32
const SPACE_XL := 48
const MARGIN_SCREEN := 24
const RADIUS_S := 8
const RADIUS_M := 16
const TOUCH_MIN := 88
const BORDER := 2
const BORDER_FOCUS := 3

# Tempos (s)
const ANIM_FAST := 0.1
const ANIM_UI := 0.2

const FONT_PATH := "res://assets/fonts/Outfit-Variable.ttf"


## Cor do HP do Núcleo por faixa: > 50% / 25–50% / < 25%.
static func core_hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return CORE_HP_HIGH
	if ratio >= 0.25:
		return CORE_HP_MID
	return CORE_HP_LOW
