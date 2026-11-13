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

## Fluxo de cenas (T-102, T-122, T-187)

Cena principal: `src/core/main.tscn` (**Boot**), que chama `SceneFlow.boot()`: carrega o perfil pelo `Backend` (falha = perfil novo) e abre o Título. Com `?debug=1&stress=N,M` (ou `--stress=N,M`), vai direto para a partida. Auth e config entram aqui no futuro.

Autoload **`SceneFlow`** (`src/core/scene_flow.gd`):

```
Boot ──(load_profile)──> Título ──toque──> Menu ──Jogar──> Partida ──match_ended──> [settle + save] ──> Resultado
                                            ^                ^  |                                         |  |
                                            |                |  +-- Pausa: Recomeçar (mesma config)       |  |
                                            |                +------------------ Jogar de novo -----------+  |
                                            +----------------------------------- Voltar ---------------------+
Boot (estresse) ─────────────────────────────────────────> Partida ──> Resultado (sem recompensa, sem save)
```

| Cena | Arquivo | Ligação |
|---|---|---|
| Título | `src/ui/screens/title_screen.tscn` | `start_requested` → `go_to_menu()` |
| Menu | `src/ui/screens/menu_screen.tscn` (T-190) | `setup(view)`; `play_pressed` → `start_match(build_match_config())`. Sem a cena, vai direto para a partida (aviso no log) |
| Partida | nó `Match` = HUD + Pausa + Arena (`MatchConfig.match_scene_path`) | `match_ended` → recompensa → Resultado; `PauseScreen.restart_requested` → `start_match(config)`; `menu_requested`/`title_requested` da Pausa (se existir) → Menu |
| Resultado | `src/ui/screens/result_screen.tscn` | `show_result(result)`, `set_log(log)`, `set_reward(summary)` (se existir e fora do estresse); `play_again_requested` → nova partida com o perfil atualizado; `menu_requested` (ou `title_requested`) → Menu |

**`view` do Menu:** `{level, xp, xp_to_next (0 no teto), coins, is_max}` (`SceneFlow.menu_view`).

**Hangar (T-200):** `go_to_menu()` monta um `HangarHost` (`src/core/hangar_host.gd`, nó `Hangar`, telas em `content`) sempre no destino Jogar (o Menu acima); a `current_scene` é o hangar, não o Menu.
- Ids (`HangarNav`, `src/core/hangar_nav.gd`, lógica pura): `PLAY`, `CORES`, `MODULES`, `COMPONENTS`, `SETTINGS` (`&"play"` …), em `TABS` (destinos válidos; a ordem da barra é `HangarBarLogic.ORDER`, `src/ui/hangar/hangar_bar_logic.gd`), `TITLES` e `DEFAULT_PATHS` (id → cena). Cena ausente → `coming_soon_screen.tscn` (`setup_title(text)`, `back_requested`).
- API no `SceneFlow`: `open_hangar_tab(id) -> bool`, `hangar_back() -> bool` (anterior, ou Jogar), `current_tab`, `hangar_tab_node(id)`; sinais `hangar_tab_changed(id)` e `hangar_tab_instanced(id, screen)`. Tela com `back_requested` → `hangar_back`.
- Barra (T-201): se `src/ui/hangar/hangar_bar.tscn` existir, entra no `HangarHost` acima do `content`; chama `SceneFlow.open_hangar_tab` e ouve `hangar_tab_changed` (pode ajustar `content.offset_bottom`).
- **Estado preservado = instância em cache:** cada tela é criada só na 1ª visita e depois fica oculta com `PROCESS_MODE_DISABLED`, sem cada tela ter de serializar o próprio estado. O cache é liberado ao ir à partida (menos memória no Safari); na volta, o hangar é recriado em Jogar com o perfil atualizado.

**Recompensa (`settle_and_save`):** guarda nível/XP de antes, roda `MetaFlow.settle(profile, result, rewards, progression, today)` com `today = Time.get_date_string_from_system()` (data local), salva pelo `Backend` e monta o `summary`:
`xp`, `coins`, `first_win_bonus` (bool), `levels_gained`, `slots_unlocked` (Array[int]), `level_before`, `xp_before`, `xp_to_next_before`, `level_after`, `xp_after`, `xp_to_next_after` (0 no teto), `result_outcome` (`"vitoria"`/`"derrota"`). Falha ao salvar: `push_warning` e o fluxo segue (a recompensa vale na sessão). Modo de estresse (nó `StressMode` na Arena ou `stress` no cabeçalho do log): sem `settle`, sem save, `last_summary = {}`. Dados: `data/meta/progression_m2.tres` e `rewards_m2.tres`. A partida continua sem falar com o `Backend`.

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

## Localização (T-240, decisão 56)

- **Sistema nativo:** `TranslationServer` + `data/i18n/strings.csv` (colunas `keys,pt_BR`; importado como `strings.pt_BR.translation`, registrado em `project.godot` › `internationalization/locale/translations`). Fallback `pt_BR`; o `SceneFlow` fixa o locale `pt_BR` no `_init` (o seletor de idioma, inglês e espanhol são da T-241, M8). Entra no export Web pelo `all_resources`.
- **Uso:** `Loc.t("CHAVE")` ou `Loc.t("CHAVE", {"nome": valor})` (`src/core/loc.gd`). Placeholders **nomeados** `{nome}` (a ordem pode mudar entre idiomas); nada de `%s`/`%d` nem concatenação de frases. Frases com variação (ex.: bloqueada / bloqueada até o nível) viram chaves inteiras.
- **Chaves:** `MAIÚSCULAS_COM_SUBLINHADO`, prefixo da tela ou domínio: `TITLE_`, `MENU_`, `HANGAR_`, `SOON_`, `HUD_`, `SKILL_`, `UPGRADE_`, `PAUSE_`, `RESULT_`; textos repetidos em `COMMON_`. Sufixo `_A11Y` para nomes de acessibilidade. Constantes `TXT_*` guardam a **chave**, não o texto.
- **Regra:** toda tela nova nasce com chaves; nenhum texto visível fixo em `.gd` ou `.tscn` de `src/ui/` (exceto números e ícones). Fora: debug (`src/debug/`, `src/ui/demo/`), logs, `/api/log`, nomes de nós e ids.
- **Teste:** `tests/unit/test_localization.gd` falha com chave usada inexistente, chave órfã, tradução não registrada e `text = "..."` fixo em cena de `src/ui/`.
