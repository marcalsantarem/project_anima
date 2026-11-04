# VFX — Project: Anima

> Dono: AG09. Estado: **T-130** (pool + `FxDirector` ligado aos sinais da Arena, testado com emissor falso; falta a ligação na partida, ver §1.1). Skill/chefe: T-131. Modo reduzido completo: T-132.
> Estilo: 2D cartoon casual (docs/arte.md, variação A): formas sólidas com contorno (tom da cor −55%), cores vivas, **poucas gotas grandes** em vez de muitas partículas. Ciano (`#2FE6D2`) só no que é do jogador.

## 1. Pool de efeitos (`src/fx/`)

- `FxEffect` (`fx_effect.gd`): efeito desenhado por código (`_draw`), sem arquivo de textura, sem alocar por quadro. Gotas e anéis são retângulos de um **atlas branco único** gerado uma vez (`FxEffect.prepare_textures()`, chamado pelo `FxPool.register`) e tingidos pela cor: assim caem no mesmo lote (`draw_circle`/`draw_arc` custavam 1 draw call cada no Compatibility). Exports de cor: `default_color`, `outline_color` (fixo da paleta quando usada a cor padrão; alfa 0 = cor −55%) e `highlight_color` (faísca do `SPARKLE`). Estilos: `BURST` (flash + anel + gotas, acima da âncora), `GROUND_RING` (decalque elíptico 0,75 no chão, `z_index = -1`; com `fill` = telegraph), `SPARKLE` (gotas subindo), `STREAK` (traço curto em `direction`: rastro do disparo).
- Cenas `fx_*.tscn` = `FxEffect` com os parâmetros do tipo (duração, raio, gotas, altura, cor padrão).
- `FxPool` (`fx_pool.gd`): `setup_default()` ou `register(tipo, cena, n)` **pré-criam** as instâncias (fora da partida). `play(tipo, âncora, cor = padrão, tamanho = 1.0) -> FxEffect` religa uma livre; cheio, **recicla a mais antiga** (limite nunca passa). `reduced_effects`, `capacity()`, `active_count()`, `stop_all()`.
- **Âncora** = ponto de contato com o chão, em coordenadas de tela (mesma regra de `GroundPlane`). O pool tem `y_sort_enabled`: como filho da `Arena` (Y-sort), os efeitos se ordenam com as entidades; decalques ficam abaixo dos corpos (z −1) e acima do piso (z −10).
- `fx/` não depende de `match/` (o `Y_SCALE = 0,75` é repetido em `FxEffect`). Quem aciona é `match/` ou `ui/`, chamando `play()` ao receber um sinal.
- `FxDirector` (`fx_director.gd`): `bind(arena)` conecta, **só se existirem** (`has_signal`), os sinais de `FxDirector.SIGNALS` aos efeitos do catálogo (§2); `unbind()`; `reduced_effects` repassa ao pool e corta o rastro. Converte posições do espaço da arena para o do pool. Âncora do Núcleo = filho `Anima` da arena (senão `core_anchor`). Não depende de `match/`.
- Demo: `src/fx/demo/fx_demo.tscn`: o próprio nó é uma arena falsa e emite os sinais (disparo → impacto → morte → coleta, dano no Núcleo, skill, telegraph, fase do chefe); clique alterna o modo reduzido; `-- --fx-bench [--fx-reduced]` mede (§3). Testes: `tests/unit/fx/test_fx_pool.gd`, `tests/unit/fx/test_fx_director.gd`.

### 1.1 Como ligar na partida (pedido ao AG00: arquivos fora do escopo do AG09)

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

Os sinais marcados T-148 estão sendo criados pelo AG01; o `FxDirector` só conecta os que existirem.

## 3. Orçamento por quadro (iPhone, WebGL 2)

- **Máximo de efeitos vivos:** 79 instâncias no pool padrão (soma da coluna). Pico realista da demo: ~25 vivos.
- **Gotas por quadro:** alvo ≤ **120 gotas** (≈ 240 círculos) + ≤ 40 arcos. Pico estimado com ~150 inimigos: 24 hits × 4 + 16 mortes × 6 = 192 gotas → acima do alvo; por isso o limite do pool (o 25º hit recicla o mais antigo) e o modo reduzido.
- **Proibido:** instanciar durante a partida, `GPUParticles2D` sem medir no iPhone, glow de `WorldEnvironment`, shader de tela cheia.
- **Custo medido (T-130, desktop, editor Windows, Compatibility, sem vsync; relativo):** `fx_demo.tscn -- --fx-bench` desenha 150 inimigos + 300 projéteis (450 polígonos, cenário falso) e emite por quadro 5 disparos + 5 acertos + 1 morte + 1 coleta (~300 tiros/s a 60 fps); média de 540 quadros após 60 de aquecimento.

| Modo | Quadro sem efeitos | Quadro com efeitos | Δ | Efeitos vivos | Draw calls (sem → com) | Sinais (CPU) |
|---|---|---|---|---|---|---|
| normal | 8,9 ms | 12,1 ms | +3,2 ms | 66 | 454 → 471 | 0,34 ms |
| reduzido | 8,9 ms | 10,5 ms | +1,7 ms | 58 | 454 → 455 | 0,27 ms |

  Antes do atlas (`draw_circle`/`draw_arc`), o normal custava +15 ms e 1153 draw calls: o atlas é obrigatório. O resto do Δ é o `_draw` em GDScript (~1 nó redesenhado por efeito vivo). **Falta medir no build Web e no iPhone.**

## 4. Modo de efeitos reduzidos (T-132)

- `FxPool.reduced_effects = true` (já implementado): metade das gotas (arredonda para cima) e **sem flash** branco.
- Regras a completar na T-132: sem tremor de câmera; telegraphs **sempre** mantidos (são leitura de gameplay); pulso do Núcleo mantido; pool de `fx_hit` cai para 12; sem rastro do projétil; opção salva nas configurações (AG02/AG04).

## 5. Pendências

- Medir o custo no build Web e no iPhone (o `--fx-bench` só roda no desktop).
- Ligação na partida (§1.1), pelo AG00/AG01.
- Substituir o `BossTelegraph` de `match/` pelo `fx_telegraph` quando o sinal com área existir (T-131).
- Brilho contínuo do próprio projétil (no sprite, AG08/AG01); o `fx_trail` cobre só o rastro do disparo.
