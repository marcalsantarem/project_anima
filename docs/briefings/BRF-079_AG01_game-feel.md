# BRF-079 — AG01 — T-117 Game feel (parte AG01)
Em paralelo: AG09 faz flash de acerto e efeitos de Módulo/chefe em `src/fx/`; AG02 faz o pulso do botão e a opção "Efeitos reduzidos" na pausa (`src/ui/`, e a ligação no `SceneFlow`). Você só mexe em `src/match/`.
**Fazer (barato, sem alocar por quadro, tudo por dados):**
- **Tremor de câmera** (sem `Camera2D` hoje: use um deslocamento do nó raiz da arena ou uma `Camera2D` com offset, sem mexer no HUD): meteoro no impacto (forte, ~0,25 s), golpe do ogro no Núcleo (médio), morte do chefe (forte), dano grande no Núcleo (leve). Decaimento suave; intensidade em dados (`ShakeData` ou constantes documentadas).
- **Hit-stop**: pausa curta da simulação (30–80 ms, via `Engine.time_scale` ou congelando a arena, **sem** congelar o HUD nem a música) no impacto do meteoro, no lançamento do chefe e na morte do chefe; nunca empilhar (máx. 1 ativo).
- **Números de dano**: número que salta do inimigo atingido (pool pré-criado, ex. 48 `Label`/desenho de texto barato, fonte do tema via `SystemFont`/arquivo existente em `assets/fonts/`), branco para tiro, **laranja maior para o meteoro**, sobem e somem em ~0,6 s; agregue dano no mesmo inimigo no mesmo quadro; limite por quadro.
- **`Arena.reduced_effects: bool`**: corta tremor (ou reduz a 30%), desliga hit-stop e reduz números de dano (só meteoro e chefe). O `SceneFlow` define (AG02 faz a ligação).
- Sinais extras que o AG09 possa precisar: `skill_ready(slot)`/`skill_used(slot)` repassados pela `Arena` se ainda não estiverem; documente em `docs/gameplay.md`.
- Testes: hit-stop não empilha e restaura o tempo; números de dano reusam o pool; reduzido desliga tremor/hit-stop.
**Arquivos permitidos:** `src/match/`, `data/`, `docs/gameplay.md`, `tests/`. **Proibido:** `src/ui/`, `src/fx/`, `src/core/`, `project.godot`.
**Validação:** `--import` e GUT completo (2 vezes); bot (`tests/tools/run_sim.gd`) continua funcionando (hit-stop não pode travar a simulação headless: desligue-o quando `reduced_effects` ou em modo headless/simulação se preciso).
**Entrega:** no máximo 8 linhas.
