# BRF-060 — AG02 — T-155 "Voltar ao título" a partir do Resultado
**Contexto:** a tela de Resultado só tem "Jogar de novo" (`play_again_requested`). O dono aprovou também **"Voltar ao título"**. O fluxo é do `SceneFlow` (`src/core/scene_flow.gd`): título → partida (Arena + HUD + PauseScreen + efeitos) → Resultado. A pausa e o Resultado vivem em `src/ui/screens/`. O botão secundário (branco) ainda é `StyleBoxFlat` por código (a arte é a T-153).
**Fazer:**
- `ResultScreen` ganha o botão secundário **"Voltar ao título"** abaixo de "Jogar de novo" (alvo ≥ 44 px, toque/mouse/teclado, foco visível, sem tooltip), e o sinal `title_requested`. O layout deve continuar sem quebrar em 720 e 360 de largura.
- `SceneFlow` liga `title_requested` e leva à cena de título **sem reiniciar o jogo e sem vazar a partida** (libere Arena, HUD, FxPool/FxDirector e pausa como já faz em "Jogar de novo"; o áudio já liberado continua liberado, então a tela de título pode **não** pedir o toque de novo se o fluxo existente permitir; se pedir, tudo bem, mas documente). Você está **autorizado a editar `src/core/scene_flow.gd`** com edição mínima e pontual para isso (o AG07 não está trabalhando nele agora) e `tests/integration/test_match_flow.gd`.
- Teste de integração: ir do Resultado ao título e de lá começar outra partida sem erros, sem nós órfãos e sem sinais duplicados; e que "Jogar de novo" continua funcionando.
- Atualize `docs/ui.md` (fluxo de telas e botões do Resultado).
**Arquivos permitidos:** `src/ui/screens/`, `src/core/scene_flow.gd`, `docs/ui.md`, `tests/` (UI e integração). Não toque em `src/match/` nem em `project.godot`.
**Validação:** `--import` e GUT completo passando; renderize o Resultado em 720×1280 e 720×1560 e confira.
**Entrega:** no máximo 8 linhas.
