# Sprites da partida (T-127, BRF-031)

Estilo A "Jardim Arcano" (`docs/arte.md`). Todos os PNG estão em **2x** com fundo transparente: use `scale = 0.5` no nó. **Sombra no chão fora do sprite** (o jogo desenha; `shadow_ground.png` é opcional).
Âncora em **pixels do PNG**. No `Sprite2D`: `centered = false` e `offset = -âncora`. Assim a posição do nó é o ponto de contato com o chão (Y-sort).
Fonte: `_src/gen_sprites.py` (SVG por código → Chrome headless). Para regenerar, rode `python assets/sprites/_src/gen_sprites.py`. A pasta `_src/` tem `.gdignore`.

| Arquivo | PNG (2x) | Tela (1x) | Âncora (px do PNG) | Uso |
|---|---|---|---|---|
| `anima_default_base.png` | 256×256 | 128×128 | (128, 200) chão | Pedestal do Anima (camada de baixo) |
| `anima_default_crystal.png` | 256×256 | 128×128 | (128, 128) centro | Cristal + halo. Centro a **110 px (1x) acima** da âncora da base. Bob de 4–6 px |
| `anima_default_node.png` | 64×64 | 32×32 | (32, 32) centro | 3 nós orbitando o centro do cristal (elipse ~58×24 px 1x) |
| `enemy_runner.png` | 128×128 | 64×64 | (64, 120) chão | Corredor. Linhas de velocidade ficam com o VFX |
| `enemy_tank.png` | 256×256 | 128×128 | (128, 224) chão | Tanque. A barra de HP é do jogo, não do sprite |
| `enemy_shooter.png` | 256×256 | 128×128 | (128, 224) chão | Atirador, com o orbe que anuncia o tiro |
| `enemy_swarm.png` | 128×128 | 64×64 | (64, 104) chão | Enxame |
| `boss_warden.png` | 512×512 | 256×256 | (256, 472) chão | Chefe (id provisório até a T-115) |
| `boss_warden_ring.png` | 512×256 | 256×128 | (256, 128) centro | Anel de fases do chefe. Centro a **70 px (1x) acima** da âncora do chefe, atrás do corpo |
| `projectile_player.png` | 64×32 | 32×16 | (32, 16) centro | Projétil do jogador (ciano). Aponta para +X: `rotation = direção.angle()` |
| `projectile_enemy.png` | 64×64 | 32×32 | (32, 32) centro | Projétil inimigo (magenta, sem ciano). Aponta para +X |
| `pickup_particle.png` | 64×64 | 32×32 | (32, 56) chão | Partícula dropada (moeda da partida) |
| `shadow_ground.png` | 128×64 | 64×32 | (64, 32) centro | Sombra elíptica opcional (`#6B4E8C` a 22%). Escalar para a largura do §5 |

Fundo: `assets/backgrounds/stage_01_floor.png` tem **1440×2560 (2x)**, ocupa a tela inteira (720×1280) e usa âncora no canto superior esquerdo. A arena vai de y = 164 a 987 (`arena_top_inset` / `arena_bottom_inset`), e o círculo rúnico fica centrado em (360, 575,5), o centro da `arena_rect`, onde o Anima nasce. O fundo não tem HUD; a faixa de baixo fica lisa para a bandeja.
