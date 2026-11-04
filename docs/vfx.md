# VFX — Project: Anima

> Dono: AG09. Estado: **base da T-129** (catálogo + pool). Ligação aos sinais da partida: T-130/T-131. Modo reduzido completo: T-132.
> Estilo: 2D cartoon casual (docs/arte.md, variação A): formas sólidas com contorno (tom da cor −55%), cores vivas, **poucas gotas grandes** em vez de muitas partículas. Ciano (`#2FE6D2`) só no que é do jogador.

## 1. Pool de efeitos (`src/fx/`)

- `FxEffect` (`fx_effect.gd`): efeito desenhado por código (`_draw`), **sem textura**, sem alocar por quadro. Estilos: `BURST` (flash + anel + gotas, acima da âncora), `GROUND_RING` (decalque elíptico 0,75 no chão, `z_index = -1`; com `fill` = telegraph), `SPARKLE` (gotas subindo).
- Cenas `fx_*.tscn` = `FxEffect` com os parâmetros do tipo (duração, raio, gotas, altura, cor padrão).
- `FxPool` (`fx_pool.gd`): `setup_default()` ou `register(tipo, cena, n)` **pré-criam** as instâncias (fora da partida). `play(tipo, âncora, cor = padrão, tamanho = 1.0) -> FxEffect` religa uma livre; cheio, **recicla a mais antiga** (limite nunca passa). `reduced_effects`, `capacity()`, `active_count()`, `stop_all()`.
- **Âncora** = ponto de contato com o chão, em coordenadas de tela (mesma regra de `GroundPlane`). O pool tem `y_sort_enabled`: como filho da `Arena` (Y-sort), os efeitos se ordenam com as entidades; decalques ficam abaixo dos corpos (z −1) e acima do piso (z −10).
- `fx/` não depende de `match/` (o `Y_SCALE = 0,75` é repetido em `FxEffect`). Quem aciona é `match/` ou `ui/`, chamando `play()` ao receber um sinal.
- Demo: `src/fx/demo/fx_demo.tscn` (loop de todos os tipos; clique alterna o modo reduzido). Testes: `tests/unit/fx/test_fx_pool.gd`.

## 2. Catálogo da demo

Custo = gotas desenhadas no pico (cada gota = 2 círculos) + arcos. "Sinal existe?" refere-se ao que a `Arena` expõe hoje (docs/gameplay.md).

| Tipo | Efeito | Sinal de gameplay | Sinal existe? | Duração | Cor | Tamanho | Instâncias | Custo estimado |
|---|---|---|---|---|---|---|---|---|
| `fx_muzzle` | disparo do Anima | `projectile_fired(from, dir)` | **falta** | 0,12 s | `accent` | r 16, 44 px acima | 6 | 3 gotas + 2 arcos |
| (no projétil) | rastro/brilho do projétil | — (desenho do próprio projétil, T-130) | — | contínuo | `accent` + `soul` | — | sem pool | 1 sprite aditivo por projétil (a medir) |
| `fx_hit` | impacto do tiro | `projectile_hit(at, target)` | **falta** | 0,22 s | `accent` + flash branco | r 24 | 24 | 4 gotas + flash + 2 arcos |
| `fx_death` | morte por arquétipo (cor do arquétipo) | `enemy_died(at, archetype_id, cause)` na Arena | **falta** (só `Enemy.died` por instância) | 0,4 s | runner `#FF8A3D`, tank `#E8344E`, shooter `#FF3DB4`, swarm `#9B5CFF` (tank `size` 1,4; swarm 0,7) | r 42 | 16 | 6 gotas + flash + 2 arcos |
| `fx_pickup` | coleta de Partícula | `particles_gained(at, amount)` (não há drop no chão; nasce na morte) | **falta** (`particles_changed` não tem posição) | 0,5 s | `gold` | r 18, sobe 48 px | 12 | 4 gotas (3 círculos) |
| `fx_upgrade` | compra de upgrade (no Anima) | `upgrade_changed` com nível maior | existe | 0,6 s | `accent` | r 56, sobe 90 px | 2 | 8 gotas |
| (UI) | skill pronta | `skill_ready(slot)` | existe | 0,3 s | `accent` | no botão (AG02/`ui.md`) | — | tween no botão |
| `fx_skill_cast` | skill usada (onda no chão) | `skill_cast(slot, at, radius)` | **falta** (`skill_used(slot)` não traz área) | 0,45 s | `accent` | r = raio da skill | 2 | 2 arcos |
| `fx_telegraph` | telegraph do chefe | `boss_telegraph_started(pattern_id, duration, at, radius)` na Arena | **falta** (`Boss.telegraph_started` sem área; hoje o `BossTelegraph` de `match/` desenha) | = `duration` do padrão | `boss` `#C040F5` | r = área | 6 | 1 elipse + 2 arcos |
| `fx_death` (`size` 3) + flash | troca de fase / morte do chefe | `boss_phase_changed(phase)` na Arena; `boss_defeated` | fase **falta** na Arena; `boss_defeated` existe | 0,4 s | `boss` | r 126 | (pool de morte) | 6 gotas |
| `fx_core_pulse` | pulso de dano no Núcleo | `core_hp_changed` com `current` menor | existe | 0,35 s | `#E8344E` | r 110 | 3 | 2 arcos |

**Sinais que faltam (para o AG00 virar tarefa do AG01), todos na `Arena`:** `projectile_fired(from: Vector2, dir: Vector2)`, `projectile_hit(at: Vector2, target_kind: StringName)`, `enemy_died(at: Vector2, archetype_id: StringName, cause: int)`, `particles_gained(at: Vector2, amount: int)`, `skill_cast(slot: int, at: Vector2, radius: float)`, `boss_telegraph_started(pattern_id: StringName, duration: float, at: Vector2, radius: float)`, `boss_phase_changed(phase: int)`. Alternativa sem sinal novo: a `Arena` recebe um `FxPool` e chama `play()` nos pontos onde esses eventos já acontecem.

## 3. Orçamento por quadro (iPhone, WebGL 2)

- **Máximo de efeitos vivos:** 71 instâncias no pool padrão (soma da coluna). Pico realista da demo: ~25 vivos.
- **Gotas por quadro:** alvo ≤ **120 gotas** (≈ 240 círculos) + ≤ 40 arcos. Pico estimado com ~150 inimigos: 24 hits × 4 + 16 mortes × 6 = 192 gotas → acima do alvo; por isso o limite do pool (o 25º hit recicla o mais antigo) e o modo reduzido.
- **Proibido:** instanciar durante a partida, `GPUParticles2D` sem medir no iPhone, glow de `WorldEnvironment`, shader de tela cheia.
- **Custo medido:** ainda não (T-130, no build Web com ~150 inimigos). Valores acima são estimativas.

## 4. Modo de efeitos reduzidos (T-132)

- `FxPool.reduced_effects = true` (já implementado): metade das gotas (arredonda para cima) e **sem flash** branco.
- Regras a completar na T-132: sem tremor de câmera; telegraphs **sempre** mantidos (são leitura de gameplay); pulso do Núcleo mantido; pool de `fx_hit` cai para 12; sem rastro do projétil; opção salva nas configurações (AG02/AG04).

## 5. Pendências

- Medir o custo no build Web e no iPhone (T-130).
- Substituir o `BossTelegraph` de `match/` pelo `fx_telegraph` quando o sinal com área existir (T-131).
- Rastro/brilho do projétil (sprite aditivo) com o AG08.
