class_name UiArt
## Arte final da UI (T-128/T-138). Tamanhos, margens e posições em assets/ui/README.md.
## Todos os PNG estão em 2x: desenhe na metade do tamanho (os tamanhos abaixo já estão em 1x).

## HUD holográfico da partida (T-290, decisão 64): 1 px do PNG = 1 px da tela (art_scale 1), docs/arte.md §12.
const HUD_PAUSE := preload("res://assets/ui/ui_hud_btn_pause.png")
const HUD_PAUSE_PRESSED := preload("res://assets/ui/ui_hud_btn_pause_pressed.png")
## Botão de velocidade (T-275): 96x96, corpo 68x68. O estado é o da velocidade ativa.
const SPEED_X1 := preload("res://assets/ui/ui_speed_x1.png")
const SPEED_X1_PRESSED := preload("res://assets/ui/ui_speed_x1_pressed.png")
const SPEED_X2 := preload("res://assets/ui/ui_speed_x2.png")
const SPEED_X2_PRESSED := preload("res://assets/ui/ui_speed_x2_pressed.png")
const LOCK_HOLO := preload("res://assets/ui/ui_icon_lock_holo.png")
## Partículas (T-160/T-161).
const PARTICLE := preload("res://assets/ui/ui_icon_particles.png")
const PARTICLE_OFF := preload("res://assets/ui/ui_icon_particles_off.png")
## Ícone do meteoro (decisão 37): fonte única, padrão do SkillButton `Icon.CIRCLE`. Carregado por caminho: se faltar, o botão desenha o ícone de formas.
const SKILL_METEOR_PATH := "res://assets/ui/ui_icon_skill_meteor.png"

const UPGRADE_ICONS := {
	&"upgrade_atk_power": preload("res://assets/ui/ui_icon_upgrade_atk_power.png"),
	&"upgrade_atk_spd": preload("res://assets/ui/ui_icon_upgrade_atk_speed.png"),
	&"upgrade_defense": preload("res://assets/ui/ui_icon_upgrade_defense.png"),
	&"upgrade_max_hp": preload("res://assets/ui/ui_icon_upgrade_max_hp.png"),
	&"upgrade_cooldown": preload("res://assets/ui/ui_icon_upgrade_cooldown.png"),
}
## Botões de upgrade: canvas 144x96, corpo 128x80 em (8, 8).
const HUD_UPGRADE_NORMAL := preload("res://assets/ui/ui_hud_upgrade_normal.png")
const HUD_UPGRADE_PRESSED := preload("res://assets/ui/ui_hud_upgrade_pressed.png")
const HUD_UPGRADE_DISABLED := preload("res://assets/ui/ui_hud_upgrade_disabled.png")
const HUD_UPGRADE_MAX := preload("res://assets/ui/ui_hud_upgrade_max.png")
const UPGRADE_FRAME_RECT := Rect2(-8, -8, 144, 96)

## Slots de Módulo: canvas 176x184 com o centro do círculo em (88, 88); raio do anel 72.
const HUD_SKILL_READY := preload("res://assets/ui/ui_hud_skill_ready.png")
const HUD_SKILL_COOLDOWN := preload("res://assets/ui/ui_hud_skill_cooldown.png")
const HUD_SKILL_RING := preload("res://assets/ui/ui_hud_skill_cooldown_ring.png")
const HUD_SKILL_MASK := preload("res://assets/ui/ui_hud_skill_cooldown_mask.png")
const HUD_SKILL_LOCKED := preload("res://assets/ui/ui_hud_skill_locked.png")
const HUD_SKILL_EMPTY := preload("res://assets/ui/ui_hud_skill_empty.png")
const HUD_KEY_BADGE := preload("res://assets/ui/ui_hud_key_badge.png")
const HUD_KEY_BADGE_OFF := preload("res://assets/ui/ui_hud_key_badge_off.png")
const SKILL_FRAME_SIZE := Vector2(176, 184)
const SKILL_FRAME_CENTER := Vector2(88, 88)
const SKILL_MASK_RADIUS := 72.0
const SKILL_RING_RADIUS := 92.0
## Centro do badge da tecla em relação ao centro do slot; arte 44x44.
const KEY_BADGE_OFFSET := Vector2(52, -60)
const KEY_BADGE_SIZE := 44.0

## Barras (Energia e chefe) e ícones.
const HUD_BAR_TRACK := preload("res://assets/ui/ui_hud_bar_track.png")
const HUD_BAR_TRACK_BOSS := preload("res://assets/ui/ui_hud_bar_track_boss.png")
const HUD_BAR_FILL := preload("res://assets/ui/ui_hud_bar_fill.png")
const HUD_BAR_FILL_BOSS := preload("res://assets/ui/ui_hud_bar_fill_boss.png")
const HUD_BAR_FLASH := preload("res://assets/ui/ui_hud_bar_flash.png")
const HUD_BAR_TIP := preload("res://assets/ui/ui_hud_bar_tip.png")
const HUD_ICON_ENERGY := preload("res://assets/ui/ui_hud_icon_energy.png")
const HUD_ICON_BOSS := preload("res://assets/ui/ui_hud_icon_boss.png")
const HUD_PILL := preload("res://assets/ui/ui_hud_pill.png")
const HUD_PILL_WAVE := preload("res://assets/ui/ui_hud_pill_wave.png")
const HUD_TRAY := preload("res://assets/ui/ui_hud_tray.png")
const HUD_TRAY_BAND := preload("res://assets/ui/ui_hud_tray_band.png")

const PANEL := preload("res://assets/ui/ui_panel.png")
const BUTTON_BIG_NORMAL := preload("res://assets/ui/ui_button_big_normal.png")
const BUTTON_BIG_PRESSED := preload("res://assets/ui/ui_button_big_pressed.png")
## Botão secundário (branco → lavanda) e pílulas do topo do HUD (T-153, BRF-075).
const BUTTON_SECONDARY := preload("res://assets/ui/ui_button_secondary.png")
const BUTTON_SECONDARY_PRESSED := preload("res://assets/ui/ui_button_secondary_pressed.png")


## Textura do caminho, ou null se vazio/inexistente (quem chama decide o fallback).
static func load_icon(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func upgrade_icon(id: StringName) -> Texture2D:
	return UPGRADE_ICONS.get(id)


## 9-patch na escala 1x. Margens da textura em px do PNG (2x); conteúdo em px da tela.
static func nine(tex: Texture2D, margins: Vector4, content := Vector4(-1, -1, -1, -1)) -> UiNinePatch:
	var sb := UiNinePatch.new()
	sb.texture = tex
	sb.margin_left = margins.x
	sb.margin_top = margins.y
	sb.margin_right = margins.z
	sb.margin_bottom = margins.w
	sb.content_margin_left = content.x
	sb.content_margin_top = content.y
	sb.content_margin_right = content.z
	sb.content_margin_bottom = content.w
	return sb


## Painel com moldura: conteúdo a 20 px da borda (26 embaixo).
static func panel() -> UiNinePatch:
	return nine(PANEL, Vector4(56, 56, 56, 68), Vector4(20, 20, 20, 26))


## Botão grande (ciano). Pressionado: o corpo desce 4 px, o conteúdo acompanha.
static func button_big(pressed: bool) -> UiNinePatch:
	return _button(BUTTON_BIG_PRESSED if pressed else BUTTON_BIG_NORMAL, pressed)


## Botão secundário (branco → lavanda), mesma geometria e content margins do grande.
static func button_secondary(pressed: bool) -> UiNinePatch:
	return _button(BUTTON_SECONDARY_PRESSED if pressed else BUTTON_SECONDARY, pressed)


static func _button(tex: Texture2D, pressed: bool) -> UiNinePatch:
	var dy := 4 if pressed else 0
	return nine(tex, Vector4(52, 52, 52, 68),
		Vector4(UiTokens.SPACE_M, UiTokens.SPACE_S + dy, UiTokens.SPACE_M, UiTokens.SPACE_S + UiTokens.SHADOW_BASE - dy))


## 9-patch holográfico 1:1 (px do PNG = px da tela). Margens (E, C, D, B) e `expand` (E, C, D, B) do brilho.
static func nine1(tex: Texture2D, margins: Vector4, content := Vector4(0, 0, 0, 0), expand := Vector4.ZERO) -> UiNinePatch:
	var sb := nine(tex, margins, content)
	sb.art_scale = 1.0
	sb.expand = expand
	return sb


## Pílula "ONDA X/Y": corpo 96x64 em (8, 8) do PNG; estica na largura.
static func hud_pill_wave() -> UiNinePatch:
	return nine1(HUD_PILL_WAVE, Vector4(40, 28, 40, 28), Vector4(24, 8, 24, 8), Vector4(8, 8, 8, 8))


## Pílula de Partículas (ícone 32 px à esquerda).
static func hud_pill() -> UiNinePatch:
	return nine1(HUD_PILL, Vector4(40, 28, 40, 28), Vector4(20, 8, 24, 8), Vector4(8, 8, 8, 8))


## Bandeja: miolo opaco, linha ciano no topo com brilho de 12 px para cima. Conteúdo a 4 px do topo (a linha).
static func hud_tray() -> UiNinePatch:
	return nine1(HUD_TRAY, Vector4(8, 24, 8, 8), Vector4(0, 4, 0, 0), Vector4(0, 12, 0, 0))


## Faixa dos upgrades (96 de altura com o filete de 4 px embaixo).
static func hud_tray_band() -> UiNinePatch:
	return nine1(HUD_TRAY_BAND, Vector4(4, 4, 4, 6), Vector4(0, 0, 0, 4))


## Trilho (Energia ou chefe) e enchimento: corpo do trilho a 8 px da borda do PNG, margens 20 e 10.
static func hud_bar_track(boss: bool) -> UiNinePatch:
	return nine1(HUD_BAR_TRACK_BOSS if boss else HUD_BAR_TRACK, Vector4(20, 20, 20, 20), Vector4.ZERO, Vector4(8, 8, 8, 8))


static func hud_bar_fill(boss: bool) -> UiNinePatch:
	return nine1(HUD_BAR_FILL_BOSS if boss else HUD_BAR_FILL, Vector4(10, 10, 10, 10))


static func hud_bar_flash() -> UiNinePatch:
	return nine1(HUD_BAR_FLASH, Vector4(20, 20, 20, 20), Vector4.ZERO, Vector4(8, 8, 8, 8))
