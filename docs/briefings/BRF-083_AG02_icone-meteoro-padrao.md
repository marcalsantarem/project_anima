# BRF-083 — AG02 — T-159 Ícone do meteoro como padrão
**Leia:** `docs/agentes/AG02_uiweb.md`, backlog T-159. **Regra:** respostas curtas; sem commit/push/branch.
**Fazer:** o ícone do meteoro vem de fonte única (`UiArt.SKILL_METEOR_PATH`; hoje o HUD usa `Hud.slot_icon_paths` em `src/ui/hud/hud.gd`). Remover o ícone provisório `ui_icon_skill_pulse.png`/`skill_pulse` do jogo e das demos: referências em `src/ui/components/skill_button.gd`, `src/ui/theme/ui_art.gd`, `tests/unit/ui/test_skill_icon.gd`, `docs/ui.md`. Não apague `data/skills/skill_pulse.tres` nem mude `src/match/` (é do AG01); só pare de usá-lo na UI. Se algum teste de skills depender do id, não mexa (reporte). Confirme que o número de recarga segue legível sobre o ícone (quadro de 88 px).
**Arquivos permitidos:** `src/ui/`, `tests/unit/ui/`, `docs/ui.md`. **Proibido:** `assets/app/`, `web/`, `src/match/`, `project.godot`. O AG08 trabalha em `assets/app/` e `web/pwa/` ao mesmo tempo.
**Validação:** rode os testes GUT (`godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit`).
**Se o PNG do pulse ficar sem uso:** não o apague (assets são do AG08); reporte.
**Entrega:** até 6 linhas: o que mudou, testes, o que não foi verificado.
