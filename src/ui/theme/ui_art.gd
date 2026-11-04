class_name UiArt
## Arte final da UI (T-128/T-138). Tamanhos, margens e posições em assets/ui/README.md.
## Todos os PNG estão em 2x: desenhe na metade do tamanho (os tamanhos abaixo já estão em 1x).

const PAUSE := preload("res://assets/ui/ui_icon_pause.png")
const LOCK := preload("res://assets/ui/ui_icon_lock.png")
## Partículas (T-160/T-161). O `ui_icon_particle.png` dourado é obsoleto (reservado à Moeda do M2).
const PARTICLE := preload("res://assets/ui/ui_icon_particles.png")
const PARTICLE_OFF := preload("res://assets/ui/ui_icon_particles_off.png")
const SKILL_PULSE := preload("res://assets/ui/ui_icon_skill_pulse.png") ## fallback do slot sem ícone
## Ícone da skill de área atual (decisão 37). Carregado por caminho: se faltar, o slot cai no SKILL_PULSE.
const SKILL_METEOR_PATH := "res://assets/ui/ui_icon_skill_meteor.png"

const UPGRADE_ICONS := {
	&"upgrade_atk_power": preload("res://assets/ui/ui_icon_upgrade_atk_power.png"),
	&"upgrade_atk_spd": preload("res://assets/ui/ui_icon_upgrade_atk_speed.png"),
	&"upgrade_defense": preload("res://assets/ui/ui_icon_upgrade_defense.png"),
	&"upgrade_max_hp": preload("res://assets/ui/ui_icon_upgrade_max_hp.png"),
	&"upgrade_cooldown": preload("res://assets/ui/ui_icon_upgrade_cooldown.png"),
}
const UPGRADE_BTN_NORMAL := preload("res://assets/ui/ui_upgrade_btn_normal.png")
const UPGRADE_BTN_DISABLED := preload("res://assets/ui/ui_upgrade_btn_disabled.png")
const UPGRADE_BTN_MAX := preload("res://assets/ui/ui_upgrade_btn_max.png")
const UPGRADE_COST_PILL := preload("res://assets/ui/ui_upgrade_cost_pill.png")
const UPGRADE_COST_PILL_MAX := preload("res://assets/ui/ui_upgrade_cost_pill_max.png")
## Canvas 1x do botão de upgrade; o corpo (128×80) começa em (2, 2).
const UPGRADE_FRAME_RECT := Rect2(-2, -2, 132, 90)

const SKILL_FRAME_READY := preload("res://assets/ui/ui_skill_frame_ready.png")
const SKILL_FRAME_COOLDOWN := preload("res://assets/ui/ui_skill_frame_cooldown.png")
const SKILL_FRAME_LOCKED := preload("res://assets/ui/ui_skill_frame_locked.png")
const SKILL_COOLDOWN_MASK := preload("res://assets/ui/ui_skill_cooldown_mask.png")
## Canvas 1x da moldura (160×168) com o centro do círculo em (80, 80).
const SKILL_FRAME_SIZE := Vector2(160, 168)
const SKILL_FRAME_CENTER := Vector2(80, 80)
const SKILL_MASK_RADIUS := 70.0

const BAR_TRACK := preload("res://assets/ui/ui_bar_track.png")
const BAR_FILL := preload("res://assets/ui/ui_bar_fill.png")
const BAR_SHINE := preload("res://assets/ui/ui_bar_shine.png")
const BAR_TRACK_HEIGHT := 36.0
const BAR_FILL_HEIGHT := 24.0
const BAR_FILL_INSET := 4.0
const BAR_SHINE_HEIGHT := 8.0

const PANEL := preload("res://assets/ui/ui_panel.png")
const BUTTON_BIG_NORMAL := preload("res://assets/ui/ui_button_big_normal.png")
const BUTTON_BIG_PRESSED := preload("res://assets/ui/ui_button_big_pressed.png")


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


static func bar_track() -> UiNinePatch:
	return nine(BAR_TRACK, Vector4(32, 0, 32, 0))


static func bar_fill() -> UiNinePatch:
	return nine(BAR_FILL, Vector4(24, 0, 24, 0))


static func bar_shine() -> UiNinePatch:
	return nine(BAR_SHINE, Vector4(8, 0, 8, 0))


## Painel com moldura: conteúdo a 20 px da borda (26 embaixo).
static func panel() -> UiNinePatch:
	return nine(PANEL, Vector4(56, 56, 56, 68), Vector4(20, 20, 20, 26))


## Botão grande (ciano). Pressionado: o corpo desce 4 px, o conteúdo acompanha.
static func button_big(pressed: bool) -> UiNinePatch:
	var dy := 4 if pressed else 0
	return nine(BUTTON_BIG_PRESSED if pressed else BUTTON_BIG_NORMAL, Vector4(52, 52, 52, 68),
		Vector4(UiTokens.SPACE_M, UiTokens.SPACE_S + dy, UiTokens.SPACE_M, UiTokens.SPACE_S + UiTokens.SHADOW_BASE - dy))
