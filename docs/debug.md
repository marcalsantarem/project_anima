# Debug: gravador da partida, logs e overlay (T-107, BRF-063)

Módulo `src/debug/` (sem autoload). O `SceneFlow` cria o gravador e o overlay no nó da partida e entrega o log ao Resultado.

| Arquivo | Papel |
|---|---|
| `match_recorder.gd` (`MatchRecorder`) | Gravador sempre ligado; arquivos em `user://logs/` |
| `log_report.gd` (`LogReport`) | Resumo, linhas de texto e JSON do envio (só no fim) |
| `session_info.gd` (`SessionInfo`) | Tag `?tag=`, id da sessão, nº da partida e leituras do navegador (T-294) |
| `debug_overlay.gd` (`DebugOverlay`) | Painel de FPS e contadores |
| `debug_settings.gd` (`DebugSettings`) | Liga/desliga o overlay (`user://debug.cfg`) |
| `debug_ring.gd`, `frame_stats.gd` | Buffer circular e histograma de quadros (pré-alocados) |

**Dependência:** `debug/` só **lê** `match/` (sinais e API pública) e usa o tema de `ui/`. `match/` não conhece `debug/`. O HUD emite `ui_pressed(button, ok)` para o gravador.

## 1. O que é registrado

- **Cabeçalho:** jogo, versão, Godot, data/hora local, plataforma, modelo, renderer, GPU, tela, janela, viewport, safe area, núcleos, efeitos reduzidos e seed da partida. Na web (`header.web`): user agent, `devicePixelRatio`, tela CSS, orientação, safe area do shell, `WEBGL_debug_renderer_info` (vendor/renderer), `deviceMemory`, `hardwareConcurrency`, `window.ANIMA_BUILD` (se existir) e a URL **sem query string**. `header.ui_insets`: insets que a UI usa (px do jogo; `bottom` já pela regra de docs/ui.md §9.1, `bottom_raw`, `covers_bottom`, `css_k`). `header.web.viewport` (T-172, `animaViewportInfo()` do shell, lido na hora): `inner` (innerWidth e innerHeight **nativo**), `app_h` (altura usada no canvas), `outer_h`, `vv` (visualViewport width, height, offsetTop, scale), `client_h`, `screen`, sondas `svh`/`dvh`/`lvh`, `canvas` (top, bottom, height do `getBoundingClientRect`), `canvas_h` (altura aplicada pelo Godot no estilo do canvas), `standalone` e `safe` (o mesmo `animaGetSafeArea()` que a UI lê).
- **Amostras** a cada 1 s (0,25 s com o chefe vivo). Colunas em `samples_cols`:
  - tempo, FPS da janela, ms médio e máximo, quadros > 33 e > 50 ms;
  - tempo de processo e de física, draw calls, objetos, nós, órfãos;
  - memória estática, de texturas e de vídeo (MB);
  - inimigos (total e por tipo), projéteis do jogador e dos inimigos, efeitos vivos no pool;
  - Energia, onda, Partículas, vida e defesa do chefe, pausado.
- **Eventos** (`events`, `{t, e, ...}`):
  - partida: `inicio`, `onda`, `fim`;
  - combate: `dano` (valor, fonte, Energia), `mortes` e `contatos` (por segundo e tipo);
  - upgrades: `upgrade` (id, nível, custo, Partículas restantes) e `upgrade_negado`;
  - skills: `skill`, `meteoro`/`skill_impacto` (alvo, raio, atingidos, chefe);
  - chefe: `chefe`, `chefe_defesa` (início, cada quarto perdido, zero e recarga), `chefe_lancado`, `chefe_derrotado`;
  - sessão: `pausa`/`retomada`, `foco_perdido`/`foco_voltou`, `aba_oculta`/`aba_visivel`, `toque` (botão do HUD e se foi aceito, sem posição).
- **Fonte do dano:** `projetil_inimigo`, `contato:<inimigo>`, `chefe` ou `?`. É inferida pelo sinal do mesmo quadro de física, porque a Arena não informa a fonte.
- **Travadas** (`hitches`): cada quadro > 50 ms, com inimigos, projéteis, efeitos, onda, chefe, tempo desde a anterior e `apos_gravacao`.
- **Erros** (`errors`):
  - `OS.add_logger` (disponível no 4.7.2): `push_error`, `push_warning`, erros de script e `printerr`;
  - na web, um gancho JS: `window.onerror`, `unhandledrejection`, `console.error/warn`, com no máximo 200 por drenagem. Linhas do console que o Logger já pegou são ignoradas.
- **Quadros:** histograma de 1 ms da partida inteira (`frames.hist_1ms`). Quadros pausados não contam.
- **Gravador:** `recorder.cost_us_avg/max`, número de gravações e o tempo máximo de uma gravação.

## 2. Arquivos e limites

- `user://logs/last_match.json` é gravado a cada 10 s e no fim (no fim, com `summary`). Na web, `user://` fica no IndexedDB e sobrevive a recarregar a aba.
- Antes de cada partida o arquivo roda: `last` → `prev_match_1` → `prev_match_2` → `prev_match_3`. O mais antigo sai.
- Partida interrompida (Recomeçar, troca de cena): o log fecha com `resultado: "interrompida"`.
- **Buffers circulares:** 1500 amostras, 3000 eventos, 300 travadas e 200 erros.
  - Os descartados são contados em `truncated`.
  - Acima de 1 MB, a metade mais antiga de amostras e eventos sai, com `truncated.size_limit = true`.
- **Custo:** cerca de 23 µs/quadro em média no desktop (meta: < 0,3 ms), com 1 gravação de ~2 ms a cada 10 s. Não aloca por quadro.
- **Privacidade:** nada sai do aparelho sem o toque em **Enviar log**. A URL vai sem query; só a `tag` (`?tag=`) é lida dela.

## 3. Formato do JSON (`format: "anima_log/1"`)

`header`, `result`, `frames`, `samples_cols`, `samples` (linhas na ordem das colunas), `events`, `hitches`, `errors`, `truncated`, `recorder` e `summary` (no fim; se faltar, é calculado ao enviar).

### Campos novos (T-294, BRF-136)

Todos **opcionais**: log antigo continua válido. Fora do navegador ficam ausentes; o que o navegador não expõe vem `null`.

| Onde | Campo | Conteúdo |
|---|---|---|
| raiz (só no envio) | `resumo` | 5 a 8 linhas: tag, aparelho/SO, modo, velocidade, estresse, fps médio/p95/p99, resultado, onda, erros. Sempre a **primeira chave** |
| raiz (só no envio) | `upload` | `samples_stride` (1 = todas), `events_dropped`, `limit_bytes`: o que foi cortado para caber em ~150 KB |
| `header.run` | `tag`, `session_id`, `run_index`, `run_started_at` | `?tag=` (até 64 caracteres), id aleatório por abertura do app (8 hex), nº da partida na sessão, UTC (`...Z`) |
| `header` | `os` | SO e navegador do UA (ex. `iOS 17.2 · Safari 17.2`) |
| `header` | `speed_initial`, `load` | velocidade ao iniciar; `load.title_ms` (`performance.now()` no título) e `load.match_start_ms` (na partida) |
| `header.env` e `web_end` | `display_mode` (`standalone`/`browser`), `standalone_mq`, `standalone_nav`, `orientation`, `dpr`, `screen`, `inner`, `cores`, `device_memory`, `connection` (`type`, `downlink`, `rtt`, `save_data`), `language`, `online`, `perf_now_ms`, `nav` (`response_end`, `dcl`, `load`), `resources` (`count`, `transfer_bytes`, `encoded_bytes`, `decoded_bytes`), `audio_state`, `life` | `env` = início da partida; `web_end` = a mesma leitura no fim. Só na web |
| `…life` | `hidden_count`, `hidden_ms`, `longest_hidden_ms`, `pagehide`, `pageshow`, `freeze`, `resume`, `gl_lost`, `gl_restored` | ciclo de vida **acumulado desde a 1ª partida da sessão** (o gancho JS nasce nela). Por partida: eventos `aba_oculta`/`aba_visivel` |
| `samples_cols` | `render_objects`, `time_scale` | `RENDER_TOTAL_OBJECTS_IN_FRAME` e `Engine.time_scale` (a cada 1 s) |
| `events` | `velocidade` | `{t, de, para}` a cada troca x1/x2 |
| raiz | `worst_frames` | os 5 piores quadros `[t, ms, onda]`, mesmo sem passar de 50 ms |
| `summary` | `velocidades`, `pausas`, `skills_usadas` (por slot), `mortes_por_tipo`, `energia_5s`, `piores_quadros`, `erros_por_tipo`; `erros_primeiros` com até 20 | derivados dos eventos e das amostras |

A série de 1 s (fps, ms médio, `proc_ms`, `phys_ms`, objetos, nós, draw calls, memória, inimigos, projéteis) já estava em `samples`. No Safari/iOS não existem `deviceMemory` e `navigator.connection` (vêm `null`); `transferSize` de recursos de outra origem vem 0; `audio_state` depende de `GodotAudio.ctx` (`null` se ausente).

## 4. Overlay

- Painel translúcido no canto superior esquerdo, abaixo do HUD. Ignora toques e fica abaixo da pausa.
- Mostra: FPS, ms do quadro (atual e máximo da última janela), inimigos, projéteis, efeitos, draw calls, nós, memória, travadas > 50 ms e as 3 últimas linhas de erro. Na web, 4 linhas do viewport com os mesmos números de `header.web.viewport`: `in` (inner nativo), `app`, `out`, `cli`; `vv`, `scr`; `svh`/`dvh`/`lvh` e `standalone`/`aba`; `cv` (top..bottom, altura), `safe` topo/base (CSS) e `cobre` (sim/não).
- **Simulação para capturas fora do iPhone** (shell, T-172): `?simih=768` limita o `innerHeight` nativo (o canvas fica com 768 e a sobra mostra a cor da etapa); `?simsafe=44,0,34,0` fixa a safe area (topo, direita, base, esquerda, px CSS).
- Liga por: `?debug=1` na URL (`?debug=0` desliga), **F3** (action `debug_toggle`) ou o botão **"Debug"** do menu de pausa.
- Vem desligado e o estado fica salvo. O gravador grava de qualquer jeito.

### 4.1 Seção "Meta" (T-193, BRF-134)

- Dentro do overlay (só visível com `?debug=1`/F3/botão "Debug"; nunca em build sem debug): botão **Meta ▸** (recolhido por padrão) abre a linha `Nível · XP · Moeda` e os botões (>= 64 px, tokens `HOLO_*`): **+100 XP**, **+1000 XP**, **+500 Moeda**, **Nível −/+** (1..30, XP no início do nível) e **Zerar save** (2 toques: "Confirmar?" por 3 s).
- Tudo passa por `DebugMeta` (`src/debug/debug_meta.gd`) → `MetaProgress`/`Backend` (`apply_xp` e teto 30 respeitados; salva em seguida; zerar = `Backend.reset_profile()` + recarga do perfil). Novo em `src/meta/`: `MetaProgress.debug_set_level`.
- **Log:** eventos `meta_antes` (início da partida), `debug_meta` (`acao`, `antes`, `depois`) e `meta_depois` (após a recompensa, gravado no 1º save do perfil depois do fim), além de `meta: {antes, depois}` na raiz (campo aditivo; `format` igual).

## 5. Como enviar o log (BRF-136)

Não há mais visualizador: a única saída é **Enviar log** no Resultado (build de teste; contrato em [logs-api.md](logs-api.md), sem reenvio depois de enviado). O campo `log` enviado é o JSON `anima_log/1` (§3) com `resumo` (5 a 8 linhas de texto) em primeiro lugar. Se a aba recarregar, o último JSON fica em `user://logs/last_match.json` (IndexedDB), mas o botão só envia o da partida atual. Consultas SQL: [logs-api.md](logs-api.md) ("Consultas úteis").

## 6. Como ler o resumo

- **FPS p1/p5:** o FPS das piores 1% e 5% das amostras de 1 s. Mostra quedas sustentadas.
- **Quadro p95/p99:** a resolução é de 1 ms (limite superior do balde). O máximo é exato. Travadas isoladas aparecem no p99 e em "Maiores travadas".
- **`apos_gravacao`:** a travada veio logo depois de uma gravação do log. Desconsidere-a ao avaliar o jogo.
- **Memória e nós "→ (+x)":** comparação da primeira com a última amostra. Crescimento contínuo de nós ou órfãos indica vazamento.

## 7. Versão e build (T-165)

- O deploy (`.github/workflows/deploy-web.yml`) roda `bash web/inject_build.sh build/web` depois do export e do `copy_pwa.sh`: troca o marcador `/*ANIMA_BUILD*/` do `web/shell.html` por `window.ANIMA_BUILD = {sha, sha_full, branch, built_at, run}` **inline no `index.html`** (sem arquivo extra, sem cache antigo, sem segredos).
- O jogo lê o objeto em `BuildInfo` (`src/debug/build_info.gd`, só na web). Sem ele (export local, editor): `"dev local"`, sem erro.
- `version`: `application/config/version` do `project.godot`, se existir; senão `BuildInfo.DEFAULT_VERSION`. Hoje `config/version="0.1.0"` (T-285); o valor guardado e enviado no log é sem `v` (`0.1.0`), e o `v` só entra na exibição.
- Onde aparece: cabeçalho do log (`version`, `build`), resumo em texto (`Build: <sha> (<branch>) · <data UTC> · exec #<n>`), overlay `?debug=1` (`<sha> · v<versão>`) e canto inferior direito da pausa e da tela de título (`v0.1.0 · <sha>`, ou `v0.1.0 · dev local` no build local; `ScreenKit.version_label`).
- Teste local: `GITHUB_SHA=abc1234def... GITHUB_REF_NAME=dev GITHUB_RUN_NUMBER=42 bash web/inject_build.sh build/web` (roda uma vez por export: depois o marcador some).
