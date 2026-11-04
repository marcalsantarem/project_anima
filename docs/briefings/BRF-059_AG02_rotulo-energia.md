# BRF-059 — AG02 — T-164 Rótulo "ENERGIA"
**Contexto:** decisão 41: a barra de vida do Anima, hoje "NÚCLEO 1.170 / 1.500", passa a ser **"ENERGIA x / y"**. "Núcleo" fica para os talentos (decisão 40).
**Fazer:** troque no texto ao jogador (HUD, tela de Resultado, pausa, demos `hud_demo`/`ui_demo`, e qualquer tooltip/`accessibility_name`) toda menção de "Núcleo" que seja a vida do Anima por "Energia" (na barra, em maiúsculas como hoje: "ENERGIA"). Atualize `docs/ui.md` (e o `docs/arte.md` só se citar o texto da barra) e os testes que conferem o texto. **Não** renomeie identificadores de código (`core_hp_changed`, `core_bar` etc.) e não mexa em `src/match/` nem em `docs/gameplay.md`.
**Arquivos permitidos:** `src/ui/`, `docs/ui.md`, `tests/` (da UI).
**Validação:** `--import` e GUT completo passando; renderize o HUD e confira o texto.
**Entrega:** no máximo 5 linhas.
