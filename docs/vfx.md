# VFX — Project: Anima

> Dono: AG09. Estado: **T-130** (pool + `FxDirector`, ligado na partida pelo `SceneFlow`), **T-131** (meteoro e chefe ogro), **T-132** (modo reduzido) e **T-117 parte AG09** (flash de acerto, Módulo pronto/usado), **T-208** (UI dos Núcleos).
> Estilo: 2D cartoon casual (docs/arte.md, variação A): formas sólidas com contorno (tom da cor −55%), cores vivas, **poucas gotas grandes** em vez de muitas partículas. Ciano (`#2FE6D2`) só no que é do jogador.

## 1. Pool de efeitos (`src/fx/`)

- `FxEffect` (`fx_effect.gd`): efeito desenhado por código (`_draw`), sem arquivo de textura, sem alocar por quadro. Gotas e anéis são retângulos de um **atlas branco único** gerado uma vez (`FxEffect.prepare_textures()`, chamado pelo `FxPool.register`) e tingidos pela cor: assim caem no mesmo lote (`draw_circle`/`draw_arc` custavam 1 draw call cada no Compatibility). Exports de cor: `default_color`, `outline_color` (fixo da paleta quando usada a cor padrão; alfa 0 = cor −55%) e `highlight_color` (faísca do `SPARKLE`). Estilos: `BURST` (flash + anel + gotas, acima da âncora; `flash_scale`/`flash_window`), `GROUND_RING` (decalque elíptico 0,75 no chão, `z_index = -1`; com `fill` = telegraph), `SPARKLE` (gotas subindo), `STREAK` (traço curto em `direction`: rastro do disparo), `EXPLOSION` (miolo `secondary_color` → `color`, chamas, brasas `highlight_color` e fumaça curta; brasas e fumaça só fora do reduzido), `PUFF` (poeira/fumaça espalhando no chão e subindo), `TRAVEL` (rastro de 0 até `target` em `travel_time`, com `arc`, `accelerate`, `stars`; depois a cauda some), `ORBIT` (estrelas girando acima da âncora), `GLOW` (halo pulsando até o fim + flash). `TRAVEL`/`ORBIT`/`GLOW` têm `z_index = 1` (acima dos corpos). Por uso, quem chama pode definir após o `play()`: `direction`, `target`, `delay` (invisível até lá; a duração conta depois) e `duration`.
- Cenas `fx_*.tscn` = `FxEffect` com os parâmetros do tipo (duração, raio, gotas, altura, cor padrão).
- `FxPool` (`fx_pool.gd`): `setup_default()` ou `register(tipo, cena, n)` **pré-criam** as instâncias (fora da partida). `play(tipo, âncora, cor = padrão, tamanho = 1.0) -> FxEffect` religa uma livre; cheio, **recicla a mais antiga** (limite nunca passa). `reduced_effects`, `capacity()`, `active_count()`, `stop_all()`.
- **Âncora** = ponto de contato com o chão, em coordenadas de tela (mesma regra de `GroundPlane`). O pool tem `y_sort_enabled`: como filho da `Arena` (Y-sort), os efeitos se ordenam com as entidades; decalques ficam abaixo dos corpos (z −1) e acima do piso (z −10).
- `fx/` não depende de `match/` (o `Y_SCALE = 0,75` é repetido em `FxEffect`). Quem aciona é `match/` ou `ui/`, chamando `play()` ao receber um sinal.
- `FxDirector` (`fx_director.gd`): `bind(arena)` conecta, **só se existirem** (`has_signal`), os sinais de `FxDirector.SIGNALS` aos efeitos do catálogo (§2); `unbind()`; `reduced_effects` repassa ao pool e corta o rastro. Converte posições do espaço da arena para o do pool. Âncora do Núcleo = filho `Anima` da arena (senão `core_anchor`). Não depende de `match/`.
- Demo: `src/fx/demo/fx_demo.tscn`: o próprio nó é uma arena falsa e emite os sinais (disparo → impacto → morte → coleta, dano no Núcleo, Módulo usado/pronto, queda e impacto do meteoro, anulação, wind-up e golpe do chefe, lançamento, morte do chefe); clique alterna o modo reduzido; `-- --fx-bench [--fx-reduced] [--fx-boss]` mede (§3). Testes: `tests/unit/fx/test_fx_pool.gd`, `tests/unit/fx/test_fx_director.gd`.

### 1.1 Como ligar na partida (feito no `SceneFlow._link_fx`)

Na `arena.tscn` (ou no `SceneFlow`), sem tocar na lógica:
1. Um `FxPool` como **filho direto da `Arena`** (Y-sort; posições sem conversão) e `pool.setup_default()` no `_ready` (fora da partida: ~80 instâncias + atlas).
2. Um `FxDirector` com `director.pool = pool` e `director.bind(arena)` depois do `_ready` da arena (para pegar o `core_hp_changed` inicial como referência).
3. `director.reduced_effects` ligado à opção de efeitos reduzidos (T-132, AG02/AG04).
- Contrato assumido dos sinais do AG01 (T-148): posições = âncora no chão no espaço local da `Arena`; `projectile_fired` só para tiros do Anima; `target_kind` ∈ {`enemy`, `boss`, `core`}; `cause` = `Enemy.DeathCause` (1 = contato).

## 2. Catálogo da demo

Custo = gotas desenhadas no pico (cada gota = 2 círculos) + arcos. "Sinal existe?" refere-se ao que a `Arena` expõe hoje (docs/gameplay.md).

| Tipo | Efeito | Sinal de gameplay | Sinal existe? | Duração | Cor | Tamanho | Instâncias | Custo estimado |
|---|---|---|---|---|---|---|---|---|
| `fx_muzzle` | disparo do Anima | `projectile_fired(from, dir)` | T-148 | 0,12 s | `accent` | r 16, 44 px acima | 6 | 3 gotas + 2 arcos |
| `fx_trail` | rastro curto do disparo (traço ao longo de `dir`; cortado no modo reduzido) | `projectile_fired(from, dir)` | T-148 | 0,16 s | `accent` + núcleo `soul` | 70 px, 44 px acima | 8 | 3 linhas + 1 gota |
| `fx_hit` | impacto do tiro | `projectile_hit(at, target_kind)` | T-148 | 0,22 s | `accent` + flash branco; chefe `boss` ×1,3; núcleo `#E8344E` | r 24 | 24 | 4 gotas + flash + 2 arcos |
| `fx_death` | morte por arquétipo (cor do arquétipo) | `enemy_died(at, archetype_id, cause)` na Arena | T-148 | 0,4 s | runner `#FF8A3D`, tank `#E8344E`, shooter `#FF3DB4`, swarm `#9B5CFF` (tank `size` 1,4; swarm 0,7; contato ×0,8; `boss_*` `size` 3) | r 42 | 16 | 6 gotas + flash + 2 arcos |
| `fx_pickup` | coleta de Partícula: só brilho no ponto da morte, **não há item no chão** (contador do HUD é do AG02) | `particles_gained(at, amount)` | T-148 | 0,5 s | verde de Partículas (T-161, `assets/ui/README.md`): corpo `#7CF05A`, contorno `#124F24`, faísca `#D2FFB0`; dourado fica para a Moeda | r 18, sobe 48 px | 12 | 4 gotas (3 círculos) |
| `fx_upgrade` | compra de upgrade (no Anima) | `upgrade_changed` com nível maior | existe | 0,6 s | `accent` | r 56, sobe 90 px | 2 | 8 gotas |
| (UI) | skill pronta | `skill_ready(slot)` | existe | 0,3 s | `accent` | no botão (AG02/`ui.md`) | — | tween no botão |
| `fx_skill_cast` | skill usada (onda no chão) | `skill_cast(slot, at, radius)` | T-148 | 0,45 s | `accent` | r = raio da skill | 2 | 2 arcos |
| `fx_telegraph` | telegraph do chefe | `boss_telegraph_started(pattern_id, duration, at, radius)` na Arena | T-148 (o `BossTelegraph` de `match/` ainda desenha: T-131) | = `duration` do padrão | `boss` `#C040F5` | r = área | 6 | 1 elipse + 2 arcos |
| `fx_death` (`size` 3) + flash | troca de fase / morte do chefe | `boss_phase_changed(phase)` na Arena; `boss_defeated` | T-148; `boss_defeated` existe (no último ponto do chefe) | 0,4 s | `boss` | r 126 | (pool de morte) | 6 gotas |
| `fx_core_pulse` | pulso de dano no Núcleo | `core_hp_changed` com `current` menor | existe | 0,35 s | `#E8344E` | r 110 | 3 | 2 arcos |

**T-131 / T-117 (meteoro, chefe ogro, Módulos).** "Reduzido" = o que o `FxDirector` faz com `reduced_effects`.

| Tipo | Efeito | Sinal | Duração | Cor | Inst. | Pico | Reduzido |
|---|---|---|---|---|---|---|---|
| `fx_meteor_trail` (TRAVEL) | rastro de fogo da queda (360 px, acelerando) | `skill_fall_started(slot, at, fall_time)` (percurso = `fall_time`; fallback sem o sinal: no `skill_cast`, só a cauda) | `fall_time` + 0,15 s | `#FF8A3D`, cabeça `#FFE066` | 2 | 7 gotas | cortado |
| `fx_skill_cast` (GROUND_RING) | anel de choque do impacto (agora quente) | `skill_cast` | 0,45 s | `#FF9A3D` | 2 | 2 arcos | mantido |
| `fx_meteor_explosion` (EXPLOSION) | flash + bola de fogo + chamas + brasas + fumaça curta | `skill_cast` (`size` = raio / 160) | 0,55 s | `#FF8A3D`/`#FFE066`, brasas `#FFF3B0` | 2 | 6 chamas + miolo + 6 brasas + 3 fumaças | sem flash, brasas e fumaça; 3 chamas |
| `fx_crater_smoke` (PUFF) | cratera fumegando | `skill_cast` (atraso 0,12 s) | 0,9 s | `#8A7F8C` | 2 | 5 gotas | cortado |
| `fx_fizzle` (PUFF) | "puf" discreto do meteoro anulado | `skill_fizzled` | 0,35 s | `#B8B0BC` | 2 | 4 gotas | 2 gotas |
| `fx_telegraph` (GROUND_RING fill) | aviso do golpe do ogro, **vermelho** | `boss_telegraph_started` | `duration` | `#E8344E` | 6 | 1 elipse + 2 arcos | **mantido** |
| `fx_boss_windup` (GLOW) | brilho vermelho pulsando no corpo do ogro + flash no fim | `boss_telegraph_started` (some no lançamento/morte) | `duration` | `#E8344E` | 1 | 4 gotas | cortado |
| `fx_boss_wave` (GROUND_RING) | onda do golpe no Núcleo | `boss_attack_landed(at)` (fallback sem o sinal: queda de `core_hp_changed` com wind-up pendente, sem `boss_launched` entre eles) | 0,4 s | poeira `#D9B98C` | 2 | 2 arcos | mantido |
| `fx_boss_slam` (PUFF) | poeira do golpe no Núcleo | idem | 0,45 s | `#D9B98C` | 2 | 6 gotas | cortado |
| `fx_boss_launch` (TRAVEL) | voo: rastro de poeira + 3 estrelas na cabeça | `boss_launched(from, to)` | 0,6 + 0,2 s | `#D9B98C`, estrelas `#FFE066` | 1 | 7 gotas + 3 | cortado |
| `fx_boss_land` (PUFF) | poeira do pouso | `boss_launched` (atraso 0,6 s = `launch_time`) | 0,45 s | `#D9B98C` | 1 | 6 gotas | cortado |
| `fx_boss_stun` (ORBIT) | estrelas girando sobre a cabeça (235 px) | `boss_launched` (atraso 0,6 s; dura 2 s = `stun_time`; some na morte) | 2 s | `#FFE066` | 1 | 4 estrelas | 2 estrelas |
| `fx_death` `size` 3 + `fx_meteor_explosion` `size` 1,8 | morte do chefe (explosão maior) | `boss_defeated` | 0,55 s | `boss` + fogo | (pools) | ~20 gotas | sem flash, brasas e fumaça |
| `fx_hit` (flash maior) | flash branco de acerto (T-117): `flash_scale` 0,9 nos primeiros 35% (~0,08 s) | `projectile_hit` | 0,22 s | branco | 24 | +0 (mesma gota) | sem flash |
| `fx_module_used` (BURST) | flash no Anima ao usar o Módulo | `skill_used(slot)` | 0,25 s | `accent` | 2 | flash + 2 arcos | só o anel |
| `fx_module_ready` (SPARKLE) | brilho subindo no Anima quando o Módulo fica pronto | `skill_ready(slot)` | 0,5 s | `accent` | 2 | 6 gotas | 3 gotas |

Tempos repetidos no `FxDirector` (fx/ não lê data/): `BOSS_LAUNCH_TIME` 0,6, `BOSS_STUN_TIME` 2, `METEOR_FALL_HEIGHT` 360, `METEOR_BASE_RADIUS` 160; se os dados mudarem, atualizar. `boss_phase_changed` saiu (não existe mais). O aviso no chão e a cratera do meteoro continuam desenhados pelo `match/` (`meteor_skill.gd`).

Os sinais marcados T-148 estão sendo criados pelo AG01; o `FxDirector` só conecta os que existirem.

**T-208 — UI da tela de Núcleos** (`src/fx/ui/cores_fx.gd`, `CoresFx`, estático; ligado em `cores_screen.gd`). `Tween` + `CPUParticles2D` com gota radial e material aditivo gerados uma vez; nós temporários (prefixo `Fx`) criados por ação do jogador e liberados por timer; nada bloqueia o toque. Reduzido (`CoresFx.reduced_effects`, a tela lê `DebugSettings`): só a troca de estado; na falha, tom vermelho sem tremida.

| Chamada | Efeito | Gatilho na tela | Duração | Cor | Pico |
|---|---|---|---|---|---|
| `play_buy(node, cor)` | pulso 1,12 + brilho, anel, gotas; selo n/máx pula | compra de nível | 0,45 s | ramo (`BRANCH_COLORS`) | 8 partículas + 1 arco |
| `play_max(node, tex_max)` | brilho dourado, anel, gotas; moldura `_max` entra (1,35 → 1) | compra que chega ao máximo | 0,55 s | `#FFD34D` | 12 partículas + 1 arco + 1 textura |
| `play_unlock(line, alvo, cor)` | ligação acende, ponto de luz corre origem → destino com rastro; alvo pisca | link com `need` = nível comprado (alvo só se deixou de ser LOCKED) | 0,32 + 0,24 s | ramo | 1 sprite + 10 partículas |
| `play_respec(nós, label, de, até, fmt)` | nós comprados apagam em sequência (≤ 0,3 s de escalonamento) e o saldo conta (para se outro código mudar o texto) | confirmar Redistribuir | ≤ 0,55 s | — | só tweens |
| `play_fail(botão)` | tremida horizontal 8 px + tom vermelho | Comprar falha (sem Moeda / bloqueado / Núcleos travados; não no máximo), inclusive toque no botão desabilitado | 0,3 s | `#FF8080` | só tween |

Custo estimado: ≤ ~25 partículas e 2 arcos vivos no pior caso (compra que desbloqueia 2 ligações), só enquanto o efeito dura; fora da partida. Testes: `tests/unit/fx/test_cores_fx.gd`. Não medido no iPhone.

## 3. Orçamento por quadro (iPhone, WebGL 2)

- **Máximo de efeitos vivos:** 79 instâncias no pool padrão (soma da coluna). Pico realista da demo: ~25 vivos.
- **Gotas por quadro:** alvo ≤ **120 gotas** (≈ 240 círculos) + ≤ 40 arcos. Pico estimado com ~150 inimigos: 24 hits × 4 + 16 mortes × 6 = 192 gotas → acima do alvo; por isso o limite do pool (o 25º hit recicla o mais antigo) e o modo reduzido.
- **Proibido:** instanciar durante a partida, `GPUParticles2D` sem medir no iPhone, glow de `WorldEnvironment`, shader de tela cheia.
- **Custo medido (T-130, desktop, editor Windows, Compatibility, sem vsync; relativo):** `fx_demo.tscn -- --fx-bench` desenha 150 inimigos + 300 projéteis (450 polígonos, cenário falso) e emite por quadro 5 disparos + 5 acertos + 1 morte + 1 coleta (~300 tiros/s a 60 fps); média de 540 quadros após 60 de aquecimento.

| Modo | Quadro sem efeitos | Quadro com efeitos | Δ | Efeitos vivos | Draw calls (sem → com) | Sinais (CPU) |
|---|---|---|---|---|---|---|
| normal | 8,9 ms | 12,1 ms | +3,2 ms | 66 | 454 → 471 | 0,34 ms |
| reduzido | 8,9 ms | 10,5 ms | +1,7 ms | 58 | 454 → 455 | 0,27 ms |

  **T-131/T-132 (mesma máquina, outra sessão; compare só o Δ):** `--fx-boss` soma, a cada 20 quadros, um ciclo inteiro de meteoro e chefe (queda, impacto, anulação, wind-up, golpe, lançamento, atordoamento, morte e Módulos), muito acima do real (1 meteoro a cada ~8 s).

| Cenário | Sem efeitos | Com efeitos | Δ | Vivos | Draw calls | Sinais (CPU) |
|---|---|---|---|---|---|---|
| normal (T-130 + flash maior) | 5,7 ms | 8,4 ms | +2,7 ms | 66 | 454 → 471 | 0,25 ms |
| reduzido | 5,2 ms | 7,7 ms | +2,5 ms | 58 | 454 → 455 | 0,20 ms |
| normal + `--fx-boss` | 5,4 ms | 8,7 ms | +3,3 ms | 95 | 454 → 472 | 0,25 ms |
| reduzido + `--fx-boss` | 5,8 ms | 8,3 ms | +2,4 ms | 79 | 454 → 456 | 0,23 ms |

  Os efeitos novos custam ~+0,6 ms no pior caso (normal) e o reduzido corta ~0,9 ms desse cenário; +1 draw call (mesmo atlas). Ruído entre execuções: ~±0,5 ms.

  Antes do atlas (`draw_circle`/`draw_arc`), o normal custava +15 ms e 1153 draw calls: o atlas é obrigatório. O resto do Δ é o `_draw` em GDScript (~1 nó redesenhado por efeito vivo). **Falta medir no build Web e no iPhone.**

## 4. Modo de efeitos reduzidos (T-132)

- `FxPool.reduced_effects = true` (já implementado): metade das gotas (arredonda para cima) e **sem flash** branco.
- **T-132 (no `FxDirector`):** sem rastros (tiro, meteoro, voo do chefe), sem fumaça da cratera, sem brilho do wind-up, sem poeiras (golpe, pouso); explosão sem flash, brasas e fumaça. **Sempre mantidos** (leitura): aviso do golpe no chão, onda do golpe, pulso do Núcleo, anel e explosão do meteoro, estrelas do atordoamento (metade), "puf" da anulação. O aviso do meteoro é do `match/`. Tremor e hit-stop: AG01 (`Arena.reduced_effects`). A opção vem da pausa (AG02) pelo `SceneFlow`.

## 5. Pendências

- Medir o custo no build Web e no iPhone (o `--fx-bench` só roda no desktop).
- Ligação na partida (§1.1), pelo AG00/AG01.
- `skill_fall_started` e `boss_attack_landed` existem (AG01); os fallbacks ficam só para arenas sem eles.
- Flash branco **no sprite** do inimigo atingido (70 ms) é feito pelo `match/` (AG01); o `fx_hit` soma um flash maior sobre o ponto do acerto.
- Brilho contínuo do próprio projétil (no sprite, AG08/AG01); o `fx_trail` cobre só o rastro do disparo.
