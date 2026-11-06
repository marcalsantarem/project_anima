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

## Tema global (T-121)

`project.godot` → `[gui] theme/custom="res://src/ui/theme/anima_theme.tres"` (tema do AG02, com a fonte Outfit). Vale para toda a UI.

## Boot e splash (BRF-055)

Na web, a primeira tela é a splash do `web/shell.html` (degradê de `#8E72EC` a `#4E3F8F`) e a segunda é a cena "Toque para começar". Para não aparecer logotipo do Godot nem um quadro de outra cor entre as duas, o `project.godot` usa:
- `application/boot_splash/show_image=false`
- `application/boot_splash/bg_color` e `rendering/environment/defaults/default_clear_color` = `#8E72EC` (o topo do degradê da splash)

Efeito colateral: toda cena que não pinta o próprio fundo aparece em roxo, e não mais quase preto.

## Fluxo de cenas (T-102, T-122)

Cena principal: `src/core/main.tscn` (**Boot**), que chama `SceneFlow.go_to_title()`. Auth e config entram aqui no futuro.

Autoload **`SceneFlow`** (`src/core/scene_flow.gd`): **Título → Partida → Resultado → Partida**.

| Cena | Arquivo | Ligação |
|---|---|---|
| Título | `src/ui/screens/title_screen.tscn` | `start_requested` → `start_match()` |
| Partida | nó `Match` = HUD + Pausa + Arena (`MatchConfig.match_scene_path`) | `match_ended` → Resultado; `PauseScreen.restart_requested` → `start_match(config)` |
| Resultado | `src/ui/screens/result_screen.tscn` | `show_result(result)`; `play_again_requested` → `start_match(last_config)` |

API:
- `start_match(config: MatchConfig = null)`:
  - instancia a Arena e chama `setup(config)`;
  - monta HUD e Pausa e chama `bind(arena)` **antes** de a Arena entrar na árvore;
  - troca a cena.
- `go_to_title()`.
- `current_arena() -> Node`: a Arena em andamento ou `null`.
- `last_result: MatchResult`, `last_config: MatchConfig`.
- Sinal `scene_changed(scene_path)`, emitido depois de cada troca:
  - as trocas pedidas durante uma troca são ignoradas;
  - toda troca despausa a árvore.

**Contrato da cena de partida** (nó raiz da Arena):
- `setup(config: MatchConfig)`: chamado antes de entrar na árvore.
- Sinal `match_ended(result: MatchResult)`: emitido uma vez.
- A partida não chama o `SceneFlow` nem conhece `meta/`, `backend/` ou a UI. A montagem com a UI segue [ui.md](ui.md) §10c.

**Tipos** (`src/core/`, `RefCounted`):
- `MatchConfig`: `stage_id`, `match_scene_path` (padrão: `res://src/match/arena/arena.tscn`). O AG04 adiciona `anima_data` e `skills`.
- `MatchResult`: `outcome` (`Outcome.VICTORY|DEFEAT`), `wave_reached`, `waves_total`, `coins` (= Partículas da partida; renomear depende do AG00/T-141), `enemies_killed`, `duration_s`.

**Backend / save (T-185, [ADR 0002](adr/0002-save-local.md)):** autoload `Backend` (`src/backend/backend.gd`) delega a um `BackendProvider` (`LocalBackend`: `user://save.json`, com versão, `.bak` e escrita atômica). Perfil em `PlayerProfile` (`src/meta/`). O jogo só chama `Backend`; a partida continua sem conhecê-lo.
