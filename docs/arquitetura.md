# Arquitetura técnica

> Dono: AG07. As seções são adicionadas conforme as tasks.

## Camadas de colisão 2D (T-001)

Configuradas em `project.godot` → `[layer_names]`. A tabela segue a proposta do AG01 em [gameplay.md](gameplay.md).

| Bit | Nome | Mask (detecta) |
|---|---|---|
| 1 | `anima` | `enemies`, `enemy_projectiles` |
| 2 | `enemies` | `anima`, `player_projectiles`, `skill_areas` |
| 3 | `player_projectiles` | `enemies` |
| 4 | `enemy_projectiles` | `anima`, `shield` |
| 5 | `skill_areas` | `enemies` |
| 6 | `shield` | `enemy_projectiles`, `enemies` |

Regras:
- No Godot, um nó detecta outro quando a **mask dele** contém a **layer do outro**. Basta configurar o lado que reage. A tabela lista os dois lados como referência.
- Cada nó ocupa **uma** layer. A mask pode ter várias.
- No código, use constantes, nunca números soltos. Quando surgir a necessidade, elas ficam em `src/core/`.
- Layers novas (por exemplo `pickups`) só entram com uma task do AG07.

## Fluxo de cenas (T-102)

Autoload **`SceneFlow`** (`src/core/scene_flow.gd`): **Toque para começar → Partida → Resultado → Toque para começar**.

| Cena | Arquivo | Estado |
|---|---|---|
| Toque para começar | `src/core/main.tscn` (cena principal) | placeholder; final: AG02 (T-113) |
| Partida | `MatchConfig.match_scene_path` | placeholder em `src/core/placeholder/`; final: arena do AG01 |
| Resultado | `SceneFlow.RESULT_SCENE` | placeholder; final: AG02 |

API:
- `SceneFlow.start_match(config: MatchConfig = null)`: instancia a partida, chama `setup(config)` e troca a cena.
- `SceneFlow.go_to_title()`: volta à tela inicial.
- `SceneFlow.last_result: MatchResult`: o resultado mais recente, lido pela tela de resultado.
- Sinal `SceneFlow.scene_changed(scene_path)`: emitido depois de cada troca. Trocas pedidas durante uma troca são ignoradas.

**Contrato da cena de partida** (nó raiz):
- `setup(config: MatchConfig)`: chamado **antes** de o nó entrar na árvore.
- Sinal `match_ended(result: MatchResult)`: emitido **uma vez**. O `SceneFlow` leva à tela de resultado.
- A partida não chama o `SceneFlow` nem conhece `meta/`, `backend/` ou a UI.

**Tipos** (`src/core/`, `RefCounted`):
- `MatchConfig`: `stage_id`, `match_scene_path`. O AG04 adiciona `anima_data` e `skills` quando esses tipos existirem.
- `MatchResult`: `outcome` (`Outcome.VICTORY|DEFEAT`), `wave_reached`, `waves_total`, `coins`, `enemies_killed`, `duration_s`.

**Entrada:** as telas placeholder herdam de `TapScreen`, que avança com toque, clique ou `ui_accept`. Na web, o primeiro toque é o gesto que destrava o áudio.
