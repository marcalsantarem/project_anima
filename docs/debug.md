# Debug: gravador da partida, logs e overlay (T-107, BRF-063)

Módulo `src/debug/` (sem autoload). O `SceneFlow` cria o gravador e o overlay no nó da partida e entrega o log ao Resultado.

| Arquivo | Papel |
|---|---|
| `match_recorder.gd` (`MatchRecorder`) | Gravador sempre ligado; arquivos em `user://logs/` |
| `log_report.gd` (`LogReport`) | Resumo e texto legível (só no fim ou no visualizador) |
| `log_viewer.gd` (`LogViewer`) | Visualizador em tela cheia (Resultado e título) |
| `debug_overlay.gd` (`DebugOverlay`) | Painel de FPS e contadores |
| `debug_settings.gd` (`DebugSettings`) | Liga/desliga o overlay (`user://debug.cfg`) |
| `debug_ring.gd`, `frame_stats.gd` | Buffer circular e histograma de quadros (pré-alocados) |

**Dependência:** `debug/` só **lê** `match/` (sinais e API pública) e usa o tema de `ui/`. `match/` não conhece `debug/`. O HUD emite `ui_pressed(button, ok)` para o gravador.

## 1. O que é registrado

- **Cabeçalho:** jogo, versão, Godot, data/hora local, plataforma, modelo, renderer, GPU, tela, janela, viewport, safe area, núcleos, efeitos reduzidos e seed da partida. Na web (`header.web`): user agent, `devicePixelRatio`, tela CSS, orientação, safe area do shell, `WEBGL_debug_renderer_info` (vendor/renderer), `deviceMemory`, `hardwareConcurrency`, `window.ANIMA_BUILD` (se existir) e a URL **sem query string**. `header.ui_insets`: insets que a UI usa (px do jogo; `bottom` já pela regra de docs/ui.md §9.1, `bottom_raw`, `covers_bottom`, `css_k`). `header.web.viewport` (T-172, `animaViewportInfo()` do shell, lido na hora): `inner` (innerWidth e innerHeight **nativo**), `app_h` (altura usada no canvas), `outer_h`, `vv` (visualViewport width, height, offsetTop, scale), `client_h`, `screen`, sondas `svh`/`dvh`/`lvh`, `canvas` (top, bottom, height do `getBoundingClientRect`), `standalone` e `safe` (o mesmo `animaGetSafeArea()` que a UI lê).
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
- **Privacidade:** nada sai do aparelho. Não há nenhum envio de rede, e a URL vai sem query.

## 3. Formato do JSON (`format: "anima_log/1"`)

`header`, `result`, `frames`, `samples_cols`, `samples` (linhas na ordem das colunas), `events`, `hitches`, `errors`, `truncated`, `recorder` e `summary` (no fim; se faltar, o visualizador calcula).

## 4. Overlay

- Painel translúcido no canto superior esquerdo, abaixo do HUD. Ignora toques e fica abaixo da pausa.
- Mostra: FPS, ms do quadro (atual e máximo da última janela), inimigos, projéteis, efeitos, draw calls, nós, memória, travadas > 50 ms e as 3 últimas linhas de erro. Na web, 4 linhas do viewport com os mesmos números de `header.web.viewport`: `in` (inner nativo), `app`, `out`, `cli`; `vv`, `scr`; `svh`/`dvh`/`lvh` e `standalone`/`aba`; `cv` (top..bottom, altura), `safe` topo/base (CSS) e `cobre` (sim/não).
- **Simulação para capturas fora do iPhone** (shell, T-172): `?simih=768` limita o `innerHeight` nativo; `?simsafe=44,0,34,0` fixa a safe area (topo, direita, base, esquerda, px CSS).
- Liga por: `?debug=1` na URL (`?debug=0` desliga), **F3** (action `debug_toggle`) ou o botão **"Debug"** do menu de pausa.
- Vem desligado e o estado fica salvo. O gravador grava de qualquer jeito.

## 5. Como baixar no iPhone

1. No fim da partida, toque em **Logs** na tela de Resultado. Se a aba recarregou, use **Último log** no canto da tela de título.
2. O visualizador mostra o **RESUMO** (resultado, FPS médio/mín/p1/p5, quadro p50/p95/p99/máx, travadas e quando ocorreram, picos, crescimento de memória e de nós, dano, upgrades, erros e as 5 maiores travadas). Depois vêm a linha do tempo e a tabela de amostras.
3. Na web aparece, no rodapé, uma **barra de botões nativos do navegador**: **Baixar .txt**, **Baixar .json**, **Copiar**, **Abrir aba** e **Selecionar**.
   - No iOS, download, área de transferência e nova aba só são garantidos dentro do toque real. Os botões do Godot rodam fora do gesto do navegador.
   - **Via garantida:** "Baixar .txt"/".json" na barra (o arquivo vai para o app **Arquivos › Downloads**) ou "Selecionar" (toque e segure › Copiar).
   - "Copiar" tenta `navigator.clipboard` e, se falhar, cai em "Selecionar". "Abrir aba" avisa se o navegador bloquear.
4. Os botões do visualizador (Baixar, Copiar, Abrir em outra aba) também tentam a ação e avisam na tela. **Fechar** (ou Esc) volta ao Resultado sem mudar nada.
5. **Fora da web** (PC/editor), "Baixar" grava `.json` e `.txt` em `user://logs/export/` e mostra o caminho. "Copiar" usa a área de transferência do sistema.

## 6. Como ler o resumo

- **FPS p1/p5:** o FPS das piores 1% e 5% das amostras de 1 s. Mostra quedas sustentadas.
- **Quadro p95/p99:** a resolução é de 1 ms (limite superior do balde). O máximo é exato. Travadas isoladas aparecem no p99 e em "Maiores travadas".
- **`apos_gravacao`:** a travada veio logo depois de uma gravação do log. Desconsidere-a ao avaliar o jogo.
- **Memória e nós "→ (+x)":** comparação da primeira com a última amostra. Crescimento contínuo de nós ou órfãos indica vazamento.
