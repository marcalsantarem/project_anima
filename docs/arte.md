# Arte — Project: Anima

> **OBSOLETO (2026-11-03):** as direções A e B foram rejeitadas. Nova direção nas decisões 31–34 (2D cartoon casual, câmera 3/4). Este guia será reescrito na T-142.

> Dono: AG08. Estado: **[Proposta]** até o usuário aprovar o mockup (T-126). Cores de UI vêm do [docs/ui.md](ui.md) (dono AG02); aqui só se acrescentam as cores do mundo.
> Mockups: [`assets/backgrounds/mockup_arena.svg`](../assets/backgrounds/mockup_arena.svg) (direção A) e [`mockup_arena_b.svg`](../assets/backgrounds/mockup_arena_b.svg) (direção B).

## 1. Direção: "Cyber-Mystic Minimal"

- **Formas geométricas puras** (polígonos, círculos, losangos) + **glifos** (anéis, marcas radiais, triângulos inscritos). Sem textura, sem ruído, sem contorno preto.
- **Fundo escuro e calmo; tudo que importa brilha.** O fundo nunca passa de ~15% de luminosidade.
- **Brilho barato:** o "glow" é feito com o mesmo contorno, mais grosso e com opacidade 15–25%, por trás da forma. Nada de blur em tempo real (orçamento do iPhone; brilho dinâmico é do AG09).
- **Leitura por cor + silhueta:** cada coisa tem cor **e** forma próprias; nenhuma depende só da cor (daltonismo).

### Duas direções para escolher (mesma paleta e silhuetas)

| | A — Facetado | B — Glifo |
|---|---|---|
| Inimigos | preenchidos, borda clara, faceta escura interna | contorno grosso, preenchimento 16%, núcleo sólido |
| Anima | hexágono com hexagrama inscrito e 6 marcas | círculo com triângulo inscrito e 3 nós orbitando |
| Fundo | grade de 80 px + 3 anéis concêntricos | poeira de estrelas + selo rúnico (anéis, raios, losangos) |
| Leitura | mais forte em tela pequena | mais elegante/"místico", um pouco menos massa |

## 2. Paleta

**Regra de ouro:** **ciano = jogador**. Inimigos e projéteis inimigos ficam na família quente/magenta/violeta e **nunca** usam ciano.

| Token | Hex | Uso |
|---|---|---|
| `bg_void` | `#07090F` | fundo da arena (de `ui.md`) |
| `bg_glow` | `#12203A` | brilho radial suave no centro do fundo |
| `line` | `#2A3550` | grade, anéis e glifos do chão (opacidade 25–70%) |
| `accent` | `#3DF5E0` | **jogador:** alma do Anima, projéteis, skills, anel de alcance |
| `soul` | `#E8FFFC` | núcleo branco-ciano (centro dos projéteis e da alma) |
| `vessel` | `#C9D6EA` | casca neutra do Anima (prata) |
| `vessel_dark` | `#0E1626` | interior da casca |
| `enemy_runner` | `#FF7A2E` | corredor (laranja) |
| `enemy_tank` | `#E8344E` | tanque (carmim) |
| `enemy_shooter` | `#FF3DB4` | atirador (magenta) |
| `enemy_swarm` | `#A66BFF` | enxame (violeta: "cria" do chefe) |
| `boss` | `#C040F5` | chefe (igual a `boss_hp`) |
| `projectile_enemy` | `#FF2DAA` + núcleo `#FFD6F0` | projéteis inimigos (magenta) |
| `particles` | `#F5C53D` | Partículas (moeda da partida; igual a `coin`) |
| `hit_flash` | `#FFFFFF` | flash de dano em inimigos (1–2 frames) |
| `danger` | `#F5455C` | dano no Núcleo, alertas e telegraphs do chefe |

- Os `color` atuais em `data/enemies/*.tres` são placeholders; a troca pelos hex acima é com o AG01 (T-127).

## 3. Formas e silhuetas

Todos os inimigos **apontam para o Anima** (o "nariz" é +x no sprite; o código gira).

| Entidade | Silhueta | Por quê | Raio de colisão | Visual (Ø) | Canvas |
|---|---|---|---|---|---|
| **Anima** (`anima_core`) | casca neutra prata + alma ciano em losango no centro + anel de glifos | receptáculo neutro: skins trocam a casca, a alma ciano fica | 40 | ~116 (com anel) | 128 |
| **Corredor** (`enemy_runner`) | dardo/seta com recorte atrás | rápido, "vem direto" | 16 | ~36 | 64 |
| **Tanque** (`enemy_tank`) | octógono grosso com placa interna | pesado, lento, blindado | 28 | ~62 | 64 (2x: 128) |
| **Atirador** (`enemy_shooter`) | pinça côncava com orbe magenta carregando | angular; o orbe anuncia o tiro | 18 | ~40 | 64 |
| **Enxame** (`enemy_swarm`) | farpa pequena, em bando | pequeno, numeroso | 10 | ~20 | 32 |
| **Chefe** (`boss_warden`) | coroa hexagonal grande, anéis de glifos girando, "olho" central | domina a tela; anéis = fases | [A definir] | ~200 | 256 |
| Projétil do jogador | cápsula ciano com núcleo branco + rastro curto | velocidade, lado "amigo" | 6 | 20×7 | 32 |
| Projétil inimigo | losango magenta com núcleo rosado + halo | lê como "ameaça", diferente da cápsula | [AG01] | 22×14 | 32 |
| Partícula (moeda) | estrela de 4 pontas dourada + halo | não confundir com projétil | — | ~14 | 16 |
| Skill de área (`skill_pulse`) | anel ciano no raio da skill + 12 marcas + leve preenchimento na borda | mostra o alcance exato (180 px) | 180 | 360 | efeito (AG09) |

- **Proporção visual × colisão:** o visual pode passar a hitbox em até ~25%, **nunca** ser menor (o jogador tem que confiar no que vê).
- **Contorno:** 2–3 px na escala base; brilho com o mesmo traço em 8–10 px e 15–25% de opacidade.
- **Inimigos mais perigosos são maiores ou mais saturados**, nunca mais escuros.

## 4. Tamanhos e formato

- **Escala base 720×1280.** Sprites desenhados em 1x em SVG; quando precisar de nitidez, importar SVG com `scale` 2 (Godot rasteriza no import).
- **Canvas em potência de 2** (16, 32, 64, 128, 256). Nada maior que 256 no M1, exceto o fundo.
- **Fundo da arena:** cor sólida + gradiente + glifos simples (preferir desenhar por código/shader a uma imagem 720×1560).
- **Orçamento:** arte 2D total do M1 ≤ ~2 MB no `.pck`.

## 5. Nomes

`<prefixo>_<id>[_<variante>].<ext>`, em snake_case, com os prefixos da Base.

| Tipo | Pasta | Exemplo |
|---|---|---|
| Anima / skins | `assets/sprites/` | `anima_core.svg`, `anima_core_shell.svg` |
| Inimigos / chefe | `assets/sprites/` | `enemy_runner.svg`, `boss_warden.svg` |
| Projéteis | `assets/sprites/` | `projectile_player.svg`, `projectile_enemy_bolt.svg` |
| Moeda | `assets/sprites/` | `pickup_particle.svg` |
| Ícones / UI | `assets/ui/` | `ui_icon_skill_pulse.svg`, `ui_icon_lock.svg` |
| Fundos | `assets/backgrounds/` | `stage_01_floor.svg` |

## 6. Checklist de um asset

- [ ] Arte própria (ou terceiro aprovado) **registrada em `assets/LICENSES.md`**
- [ ] Usa só cores da paleta (§2); **sem ciano em nada inimigo**
- [ ] Silhueta reconhecível em preto chapado, a 375 px de largura de tela
- [ ] Aponta para +x (inimigos e projéteis); centro do canvas = centro da colisão
- [ ] Visual ≥ hitbox e ≤ hitbox +25%
- [ ] Canvas em potência de 2; nome com o prefixo certo
- [ ] Importa no Godot sem erro (`--import`); tamanho importado conferido
- [ ] Sem blur/filtro SVG (ThorVG/iPhone); brilho só por traço com opacidade

## 7. Pendências

| Item | Com quem |
|---|---|
| Escolha entre a direção A e B | usuário, via AG00 |
| Raio/visual do projétil inimigo e do chefe | AG01 |
| Quem desenha o brilho base dos sprites (sprite × shader) | AG09 |
| Os mockups não devem ir no build Web (filtro de export) | AG07/AG02 |
