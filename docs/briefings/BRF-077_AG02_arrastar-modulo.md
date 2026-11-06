# BRF-077 — AG02 — T-178 Arrastar do botão do Módulo para mirar
Decisão 46 em [docs/decisoes.md](../decisoes.md). O AG01 implementa em paralelo a API da arena (BRF-076); **use este contrato** (se ainda não existir, simule na demo/testes; adapte se o real divergir e registre): `Arena.use_skill(slot, at := Vector2.INF) -> bool`, `Arena.show_skill_aim(slot, at)`, `Arena.hide_skill_aim()`, `Arena.can_aim_at(at) -> bool`; `at` em coordenadas do viewport.
**Fazer:**
- **Toque/clique simples** no `SkillButton` = como hoje (`use_skill(slot)` automático).
- **Arrastar** a partir do botão: passou de um limiar (~24 px do jogo) ⇒ modo mira: o botão mostra estado "mirando", a arena mostra a prévia (`show_skill_aim`) seguindo o dedo/mouse (com `can_aim_at` para indicar área inválida, ex.: prévia vermelha/sem preenchimento); **soltar** sobre a arena válida ⇒ `use_skill(slot, ponto)`; soltar **sobre o próprio botão** ou fora da área válida ⇒ cancela (`hide_skill_aim`). Só com o Módulo pronto (em recarga ou bloqueado: sem mira). Funciona com toque (iPhone: sem rolagem nem zoom do navegador) e mouse.
- **PC:** segurar a action `skill_1` (tecla `1`) mostra a prévia no cursor; clicar na arena com ela pressionada lança ali; soltar a tecla sem clicar ⇒ automático como hoje (decida se dispara ao soltar ou ao apertar e documente; o padrão atual é ao apertar: mantenha "apertar e soltar rápido = automático"). Use Input Actions, sem teclas fixas.
- Sem tooltips; sem alocar por quadro; atualize `docs/ui.md` e a demo; testes (toque simples, arrasto lança, arrasto cancelado, Módulo em recarga não mira).
**Arquivos permitidos:** `src/ui/`, `docs/ui.md`, `tests/` (UI e integração). **Proibido:** `src/match/`, `web/`, `assets/`, `project.godot`.
**Validação:** `--import` e GUT completo; teste de integração com a Arena real se a API já existir.
**Entrega:** no máximo 8 linhas.
