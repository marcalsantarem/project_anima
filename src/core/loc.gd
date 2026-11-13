class_name Loc
extends RefCounted
## Localização (T-240, decisão 56): texto visível ao jogador sai de chaves em `data/i18n/strings.csv`.
## Uso: `Loc.t("MENU_PLAY")` ou `Loc.t("HUD_WAVE", {"current": 1, "total": 3})` (placeholders `{nome}`).
## Convenção em docs/arquitetura.md, "Localização". O teste `test_localization` varre `src/` atrás das chaves.

const DEFAULT_LOCALE := "pt_BR"


## Texto traduzido de `key`; com `args`, troca cada `{nome}` pelo valor. Chave ausente devolve a própria chave.
static func t(key: String, args: Dictionary = {}) -> String:
	var s := String(TranslationServer.translate(StringName(key)))
	return s.format(args) if not args.is_empty() else s
