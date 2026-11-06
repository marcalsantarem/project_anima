# BRF-080 — AG02 — T-117 (parte AG02) + opção "Efeitos reduzidos" (T-132)
Em paralelo: AG01 (`src/match/`, tremor/hit-stop/números de dano e `Arena.reduced_effects`) e AG09 (`src/fx/`, efeitos e `FxDirector.reduced_effects`).
**Fazer:**
- **Pulso do botão do Módulo** quando ele fica pronto (`skill_ready`): escala 1→1,12→1 + brilho do anel, ~0,3 s; e um "afundar" curto + flash no uso. Também um leve pulso na pílula de Partículas quando ganha e quando um upgrade fica comprável pela primeira vez (discreto).
- **Opção "Efeitos reduzidos"** no menu de pausa (interruptor, no estilo dos botões; ao lado do "Debug" existente), salva em `user://` junto com as configurações já existentes do debug/overlay, e **aplicada já na partida em curso e nas próximas**: o `SceneFlow` (edição mínima e pontual em `src/core/scene_flow.gd`, autorizada) repassa o valor para `Arena.reduced_effects` (AG01) e `FxDirector.reduced_effects` (AG09), e o gravador de log já registra `reduced_effects`. Se a propriedade ainda não existir na Arena, use `has_method/"reduced_effects" in arena` e registre.
- Atualize `docs/ui.md` e testes (pulso dispara no `skill_ready`; opção salva e recarrega; SceneFlow repassa).
**Arquivos permitidos:** `src/ui/`, `src/core/scene_flow.gd` (pontual), `src/debug/` (só se a configuração morar lá), `docs/ui.md`, `tests/`. **Proibido:** `src/match/`, `src/fx/`, `web/`, `assets/`.
**Validação:** `--import` e GUT completo; render da pausa com a opção.
**Entrega:** no máximo 6 linhas.
