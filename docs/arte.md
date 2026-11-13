# Arte — Project: Anima

> Dono: AG08. Estado: **Aprovado** (decisões 31–36): a demo usa o mockup A "Jardim Arcano" (claro); o B "Noite Rúnica" (escuro) fica para a 2ª fase. A HUD ganha a fileira de 5 upgrades acima das skills (decisão 35). As cores de UI são do [docs/ui.md](ui.md) (dono AG02); a retematização da UI é a T-145.
> Mockups (PNG 720×1280, fonte SVG gerada por script): [`mockup_cartoon_a.png`](../assets/backgrounds/mockup_cartoon_a.png) e [`mockup_cartoon_b.png`](../assets/backgrounds/mockup_cartoon_b.png).

## 1. Direção: Cyber-Mystic em 2D cartoon casual

- **Formas arredondadas e "fofas-ameaçadoras":** corpos em gota, bolha e cúpula; olhos grandes com sobrancelha brava nos inimigos. Nada de anatomia complexa.
- **Contorno + sombra suave + brilho:** todo objeto tem contorno, uma sombra própria (meia-lua no lado de baixo/direita), um ponto de brilho em cima/esquerda e uma **sombra elíptica no chão**.
- **Luz fixa** vindo de cima-esquerda. A sombra no chão fica logo abaixo do objeto (sem projeção longa).
- **Cyber-Mystic** aparece nos detalhes: runas e anéis no chão, cristais, pedestal com aro de energia, orbes flutuantes. Sem texturas realistas.
- **Leitura por cor + silhueta:** nada depende só da cor (daltonismo).

### As duas variações (mesmas silhuetas e regras)

| | A — "Jardim Arcano" | B — "Noite Rúnica" |
|---|---|---|
| Clima | dia, chão de pedra clara (creme) com runas lilás | crepúsculo, ilha de pedra índigo flutuando no vazio, runas douradas |
| Contorno | **colorido** (tom escuro da própria cor), 3–4 px | **único escuro** `#1E1838`, 5 px |
| Sombreamento | suave (sombra a ~45% de opacidade) | **cel duro** (sombra chapada 100%) + brilho forte |
| HUD | bandeja inferior: fileira de 5 upgrades + 3 slots de skill (1 ativo, 2 e 3 bloqueados), Ø ≥ 144 px (demo) | painel superior com moldura dourada, defensiva grande no centro, barra do chefe |
| Leitura | mais "casual/família", contraste de inimigos muito alto | mais "épico/mágico", o ciano do jogador brilha mais |

## 2. Paleta

**Regra de ouro: ciano = jogador.** Anima, projéteis, skills e anel de alcance são ciano. Inimigos, projéteis inimigos e o cenário **nunca** usam ciano (o cenário usa lilás, índigo, creme e dourado).

| Token | A | B | Uso |
|---|---|---|---|
| `accent` (jogador) | `#2FE6D2` | `#3DF5E0` | alma do Anima, projéteis, skills, anel de alcance |
| `soul` | `#E8FFFC` | `#E8FFFC` | núcleo branco dos projéteis e faceta clara do cristal |
| `vessel` | `#E4E9F5` | `#C9D6EA` | pedestal neutro do Anima (troca na skin) |
| `enemy_runner` | `#FF8A3D` | `#FF7A2E` | corredor (laranja) |
| `enemy_tank` | `#E8344E` | `#E8344E` | tanque (carmim) |
| `enemy_shooter` | `#FF3DB4` | `#FF3DB4` | atirador (magenta) |
| `enemy_swarm` | `#9B5CFF` | `#B07CFF` | enxame (violeta) |
| `boss` | `#C040F5` | `#C040F5` | chefe (igual a `boss_hp`) |
| `projectile_enemy` | `#FF2DAA` + núcleo `#FFD6F0` | igual | projéteis inimigos |
| `gold` | `#FFC93D` | `#FFD23D` | Moeda do M2 (antes Partículas; decisão 40), coroa do chefe, runas (B) |
| `floor` / `floor_alt` | `#F6E9CF` / `#EEDDBD` | `#3A3178` / `#433A86` | piso em xadrez (A) ou lajotas (B) |
| `rune` | `#B9A5E8` | `#8A6CFF` | círculo rúnico do chão |
| `wall` | `#9C8BE0` / `#6E5CC0` | `#5B4EB0` / `#221C4A` | borda da arena (topo / face frontal) |
| `outline` | tom da cor −55% | `#1E1838` | contorno |
| `shadow` | `#6B4E8C` a 22% | `#0E0A24` a 45% | sombra no chão |
| `hit_flash` | `#FFFFFF` + traço `accent` | igual | impacto do tiro do jogador |

- Barras: HP do Núcleo segue `core_hp` do `ui.md` (verde → amarelo → vermelho); barra do chefe em `boss`.
- Os `color` de `data/enemies/*.tres` são placeholders; a troca é com o AG01 (T-127).

## 3. Perspectiva 3/4

- **Câmera 3/4:** o chão é plano e visto de cima; os objetos mostram a **face da frente** (pedestal, pilares, borda da arena) e "ficam em pé" sobre o chão.
- **Círculos no chão viram elipses** com razão **0,75** (ex.: alcance de 180 px → elipse 180×135). Vale para anel de skill, runas e telegraphs. A colisão continua sendo no plano do chão (T-144 decide se é círculo ou elipse no código).
- **Âncora do sprite = ponto de contato com o chão** (centro da sombra), não o centro do desenho. Ordenação por Y (Y-sort) usa essa âncora.
- **Inimigos olham para a câmera** e só as **pupilas** seguem o Anima; não giram o corpo. O que indica direção é o rastro (linhas de velocidade) e o projétil. Espelhar no eixo X é permitido.
- Projéteis são a exceção: **giram** na direção do movimento (são vistos de cima).

## 4. Núcleo-Anima

Pedestal cilíndrico neutro (`vessel`) com aro ciano + **cristal losango ciano flutuando** acima, com faceta clara (`soul`), halo ciano e 3 nós orbitando. Fica no centro da arena (360, ~690 na referência 720×1280).
- **Skins (decisão 33):** separar em `anima_<skin>_base` (pedestal) e `anima_<skin>_crystal` (parte que flutua/anima). A skin troca formas e cores do pedestal; o cristal mantém ciano para não quebrar a regra.
- Animação por transformação: cristal sobe/desce 4–6 px em ~1,5 s; nós giram; brilho pulsa no tiro.
- **Holográfico (T-291, BRF-126; decisão 64):** o Anima da partida segue o estilo do título/menu: pedestal de aço em dois degraus com aros ciano, cápsulas de luz e emissor de vidro com anéis; feixe suave até o cristal; cristal losango em 4 facetas `#E6FFFF`→`#0B6E86` com halo; nós como orbes de energia. Contorno `holo_ink` (`#03202E`) mantém a leitura no chão creme. Mesmos canvas e âncoras (sem mudança de código). Prévia: [`anima-holo-arena.png`](img/anima-holo-arena.png) e [`-375x812`](img/anima-holo-arena-375x812.png); fonte `assets/sprites/_src/gen_anima_holo.py`. **Exceção à §12:** a arena segue cartoon, mas o Anima passa a ser holográfico.

## 5. Silhuetas por arquétipo

| Entidade | Silhueta | Por quê | Colisão (raio) | Sombra no chão (largura) | Altura visual | Canvas 1x |
|---|---|---|---|---|---|---|
| **Anima** | pedestal + cristal losango flutuante | ponto focal, alto | 40 | ~130 | ~160 | 128×192 |
| **Corredor** | bolinha laranja com duas orelhas pontudas e linhas de velocidade | rápido, "vem direto" | 16 | ~38 | ~58 | 64×64 |
| **Tanque** | cúpula grande carmim, chifres, placa frontal, pezinhos, barra de HP | pesado, blindado | 28 | ~72 | ~95 | 128×128 |
| **Atirador** | gota magenta pontuda com garras laterais e **orbe** acima | angular; o orbe anuncia o tiro | 18 | ~48 | ~90 | 128×128 |
| **Enxame** | bolinha violeta de um olho com asinhas, em bando | pequeno, numeroso | 10 | ~23 | ~37 | 64×64 |
| **Chefe** | **ogro** barrigudo, pele oliva quente, cabeça pequena, presas, colete e clava curta (decisão 39, BRF-057: `boss_ogre*`, poses parado/wind-up/atordoado e caminhada em 4 quadros `boss_ogre_walk_1..4` (BRF-065); substitui a massa violeta com anel) | domina a tela; só corpo a corpo, sem anel | [A definir] | ~145 | ~200 | 256×256 |
| Projétil do jogador | cápsula ciano com núcleo branco e rastro | lado "amigo" | 6 | — | 26×14 | 32×16 |
| Projétil inimigo | losango magenta com núcleo rosado e halo | lê como ameaça | [AG01] | — | 26×18 | 32×32 |
| Partícula (moeda) | estrela de 4 pontas **verde "chip"** (decisão 40, BRF-061: `ui_icon_particles.png`, paleta no `assets/ui/README.md`); o `pickup_particle` dourado ainda não foi trocado | não confundir com projétil | — | ~16 | 22 | 32×32 |

- **Arquivos finais (T-127):** tamanhos, âncoras e offsets de cada sprite em [`assets/sprites/README.md`](../assets/sprites/README.md). O atirador e o enxame ganharam canvas maior (garras e asas); o anel do chefe e os nós do Anima são sprites separados.
- **Proporções:** inimigos têm cabeça = corpo (1 "cabeça" de altura), olhos ocupando ~30% da largura. Quanto mais perigoso, **maior e mais saturado**, nunca mais escuro.
- **Visual × colisão:** a **sombra no chão** é o "tamanho real": deve ter entre 100% e 125% do diâmetro da colisão. O corpo pode subir acima disso (altura 3/4).
- Contorno: A 3–4 px, B 5 px, na escala 1x. Brilho/halo só com forma de opacidade baixa, **sem blur**.

## 6. HUD e molduras por raridade (guia para a T-145)

> **Arte pronta (T-128):** ícones, botões de upgrade, molduras de skill, barra, painel e botão grande em `assets/ui/` (lista, tamanhos e margens 9-patch no [`assets/ui/README.md`](../assets/ui/README.md)). O botão principal usa `accent` (ciano), como manda o `ui.md`.

- **Botões encorpados:** forma arredondada, contorno escuro de 4 px, "sombra de base" sólida deslocada 4–6 px para baixo, faixa de brilho branca a ~18% no topo.
- **Skill (demo M1, decisão 28):** bandeja com **3 slots**, sem botão defensivo/`ESPAÇO`. Botão redondo **Ø ≥ 144 px**, centros em x = 150 / 360 / 570 (folga ~66 px), cy ≈ 1192 em 720×1280. Pronta = anel ciano + halo; recarga = setor escuro a 55% + segundos; bloqueada = cinza com cadeado e o nível de desbloqueio (slot 2 "NV 7", slot 3 "NV 12"). Badge da tecla (`1`, `2`, `3`) no canto superior direito.
- **Fileira de upgrades (decisão 35):** faixa própria no topo da bandeja, logo acima das skills; 5 botões de 128×80 px (gap 12, margem 16), na ordem Atk power, Atk spd, Defesa, Vida máxima, Cooldown. Cada botão: ícone num círculo colorido (espada laranja, chevrons âmbar, placa hexagonal azul, coração rosa com "+", ampulheta verde-água), "Nv X" e pílula escura com a estrela de Partículas + custo. Estados: comprável = anel ciano interno e custo dourado (toque mostra "+1" ciano); sem Partículas = cinza, ícone a 55% e custo vermelho-claro; máximo = moldura dourada e pílula dourada "MAX". A arena encolhe (87%) para caber, com o núcleo ainda no centro. Mockup: [`mockup_cartoon_a_upgrades.png`](../assets/backgrounds/mockup_cartoon_a_upgrades.png).
- **Texto:** fonte arredondada pesada (os mockups usam Outfit 800, OFL, já no projeto) com contorno escuro (paint-order stroke).
- **Molduras por raridade** (cores do `ui.md`): moldura grossa da cor + contorno escuro + fundo do card num tom mais escuro da mesma cor; quanto mais rara, mais ornamento.

| Raridade | Cor | Moldura |
|---|---|---|
| Comum | `#9AA4B8` | borda lisa |
| Raro | `#3D8BF5` | borda lisa + cantos em losango |
| Épico | `#A04DF5` | borda dupla + cantos em losango + brilho interno |
| Lendário | `#F5B83D` | borda dupla + 4 gemas nos cantos + brilho animado (AG09) |

## 7. Nomes

`<prefixo>_<id>[_<parte>][_<variante>].png`, snake_case, com os prefixos da Base.

| Tipo | Pasta | Exemplo |
|---|---|---|
| Anima / skins | `assets/sprites/` | `anima_default_base.png`, `anima_default_crystal.png` |
| Inimigos / chefe | `assets/sprites/` | `enemy_runner.png`, `boss_warden.png` |
| Projéteis / moeda | `assets/sprites/` | `projectile_player.png`, `pickup_particle.png` |
| Skills (sprites base) | `assets/sprites/` | `skill_meteor.png`, `skill_meteor_crater.png` (cores quentes, sem ciano: o efeito é do jogador, mas o fogo lê melhor em laranja; BRF-047) |
| Ícones / UI | `assets/ui/` | `ui_icon_skill_meteor.png`, `ui_frame_epic.png` |
| Fundos | `assets/backgrounds/` | `floor_tile.png`, `floor_pillar.png` (o `floor_ring.png`, selo rúnico, saiu da arena na T-292 e está órfão) (tela cheia em peças, BRF-040; ver `assets/sprites/README.md`) |
| Atlas | `assets/sprites/atlas/` | `atlas_enemies.png` |

## 8. Checklist de um asset

- [ ] Origem registrada em `assets/LICENSES.md`
- [ ] Só cores da paleta; **sem ciano em nada inimigo**
- [ ] Contorno, sombra própria, brilho e sombra no chão presentes
- [ ] Silhueta reconhecível em preto chapado numa tela de 375 px
- [ ] Âncora na base (centro da sombra); sombra = 100–125% da colisão
- [ ] Exportado em 2x (§9.3), PNG com transparência, canvas potência de 2
- [ ] Importa no Godot sem erro; tamanho importado conferido; sem blur/filtro

## 9. Fonte da arte final e pipeline (T-143)

### 9.1 Opções

| Opção | Qualidade | Custo (estimativa) | Prazo | Licença / risco |
|---|---|---|---|---|
| **Gerada pelos agentes** (SVG por código → PNG) | Média: limpa e coerente (ver mockups), mas "chapada": sem pintura, textura, anatomia ou expressão rica; personagens tendem a parecer clip-art | ~0 (tokens) | horas por lote | própria, sem risco |
| **Pacotes CC0** (ex.: Kenney, OpenGameArt) | Média; raramente casa com Cyber-Mystic; mistura de estilos | 0 | imediato + adaptação | CC0, claro; arte genérica (outros jogos usam a mesma) |
| **Pacotes pagos** (itch.io, lojas de assets) | Média a alta | ~US$ 10–60 por pacote | imediato + adaptação | ler a EULA de cada um (uso comercial, engine, revenda); mesmo risco de genericidade |
| **IA de imagem** | Alta por imagem, **baixa consistência** entre peças; exige limpeza manual (recorte, contorno, paleta, âncora) | ~US$ 10–60/mês | dias | termos variam por serviço; direito autoral incerto (sem autoria humana pode não haver proteção); lojas como a Steam exigem declarar uso de IA; risco de parecer com obras existentes |
| **Artista (freelancer)** | Alta e coerente, com "appeal" de loja | ~US$ 1.500–5.000 pelo pacote do M1 (Anima, 5 inimigos, chefe, projéteis, fundo, ~20 ícones, kit de UI); valores de mercado variam muito | 3–6 semanas | contrato com cessão de direitos; o mais seguro para loja |

**Limite honesto da arte por agente:** consigo formas geométricas arredondadas, contorno, sombra chapada e UI muito bem; não consigo pintura, volume suave convincente, personagens com personalidade forte nem animação quadro a quadro de qualidade. Também não "vejo" enquanto desenho: cada ajuste exige renderizar e conferir. Para o nível "vende em screenshot", isso não basta sozinho.

### 9.2 Decisão (decisão 34): agentes no M1, refino depois

1. **M1 (demo):** arte dos **agentes**, no estilo do mockup escolhido. Custo zero, já cumpre legibilidade e o visual cartoon, e destrava T-144/T-145.
2. **Arte de loja (M2+):** contratar **artista** para Anima, inimigos, chefe e ícones, usando o `docs/arte.md` e os mockups como brief. UI, molduras, FX e fundos podem continuar com os agentes.
3. **IA de imagem só para moodboard/conceito**, nunca como asset final (consistência e licença). Pacotes CC0 só para enchimento (props), se casarem com a paleta.

### 9.3 Formato técnico

- **PNG 32 bits** com transparência; sem SVG em runtime (o import de SVG do Godot vira textura de qualquer forma e o PNG dá controle).
- **Desenhar em 2x** da escala 720×1280 (ex.: corredor em 128×128 para exibir a 64) e usar `scale 0.5` no nó; nitidez no iPhone (tela 3x) sem pesar demais.
- **Canvas potência de 2**; nada acima de 512 px em 2x, exceto fundos.
- **Atlas** por grupo (`atlas_enemies`, `atlas_projectiles`, `atlas_ui`) de até **2048×2048**, montados no Godot (`AtlasTexture`/SpriteFrames) ou por script; margem de 2 px entre peças.
- **Import:** filtro Linear, mipmaps desligados, compressão **Lossless** para UI e **VRAM Compressed** só se o orçamento apertar (testar artefatos no WebGL 2).
- **Pivô** na base (âncora no chão, §3); sombra no chão como **sprite separado** (reaproveitável e fácil de escalar).
- **Animação:** por transformação (squash/stretch, bob, rotação) e shader (AG09); no máximo 2–4 quadros onde for indispensável.
- **Orçamento:** arte 2D do M1 ≤ ~2 MB no `.pck`.

### 9.3 Splash de carregamento (BRF-052, proposta)
Em `assets/splash/` (com `.gdignore`; fica fora do `.pck`): `splash_a.png` (chão creme + selo + pilares, logotipo no topo) e `splash_b.png` (roxo da UI + selo suave, núcleo sobre disco de xadrez, logotipo abaixo). Para o shell: fundo em SVG/CSS (`splash_bg_a.svg` 1,7 KB, `splash_bg_b.svg` 3,2 KB; esticam de 1280 a 1560 px) e só o `splash_logo_core.webp` (22 KB, alfa) como imagem; brilho do cristal e sombra em CSS. Barra: pílula `#5B4A7A` com contorno `#3A2A55` e preenchimento dourado (sem ciano). Gerar: `python assets/splash/_src/gen_splash.py`.

### 9.4 Ícones do app (BRF-071)
Em `assets/app/` (com `.gdignore`): núcleo-Anima sobre o degradê roxo da splash B, selo rúnico discreto, sem texto nem transparência; mestre 1024, apple-touch 180, PWA 192/512 + maskable (zona segura 80%) e favicons 32/48/ICO (variante sem selo, núcleo maior). Ver `assets/app/README.md`.

### 9.5 Pílulas do topo, botão secundário e texto das pílulas (BRF-073)
Todas as peças da UI agora têm arte 9-patch em `assets/ui/` (`ui_pill_wave`, `ui_pill_particles`, `ui_button_secondary*`). Regra: a arte de pílulas e botões **não leva texto**; a UI desenha com a fonte do tema (ex.: "MAX" branco com contorno `ink`). Margens em `assets/ui/README.md`.

## 10. Pendências

| Item | Com quem |
|---|---|
| Escolher A ou B (ou combinar: ex. cenário de A + HUD de B) | usuário, via AG00 |
| Decisão 34 (fonte da arte final, §9.2) | usuário, via AG00 |
| Colisão em círculo × elipse no chão; raio do chefe e do projétil inimigo | AG01 (T-144) |
| Quem desenha o brilho base (sprite × shader) | AG09 |
| Mockups fora do build Web | AG07 (T-146); `assets/mockups/` já tem `.gdignore` |
| Aprovar os mockups holográficos (§11) antes da T-189 | usuário, via AG00 |

## 11. Menus holográficos (T-180, BRF-105; decisões 48, 49 e 60)

Vale para o **menu principal e o Resultado do M2** (hangar no M3). A partida segue no cartoon claro (decisão 50). Base: as artes do dono (`title_bg_tech.webp`, `result_tech_bg.webp`): azul-marinho, brilhos ciano, roxo discreto, linhas finas de HUD.

**Mockups** (375×812 @2x; fonte `assets/mockups/_src/mockup_holo.html`, gerar com `bash assets/mockups/_src/render.sh`; pasta fora do `.pck`):
- [`mockup_holo_menu.png`](../assets/mockups/mockup_holo_menu.png): menu, conta nível 4: no topo só a engrenagem; no terço inferior, um bloco único (logotipo → linha "selo + nível/barra de XP | Moeda" → Jogar), sem espaço vazio entre logotipo e Jogar;
- [`mockup_holo_menu_lvl1.png`](../assets/mockups/mockup_holo_menu_lvl1.png): conta nova (nível 1, 0 Moeda), mesmo layout;
- **O menu principal não mostra Módulos** (BRF-109): nada de slots, ícones, lista nem dica de slot/desbloqueio; eles vivem no hangar (M3). Também sem "ALFA" e sem rótulo de versão solto. **Layout do menu (375×812):** "PROJECT:" em y 440 e "ANIMA" em 462; linha de nível/Moeda em y 548–606 (selo à esquerda em x 44, pílula da Moeda à direita até x 332, centrada); Jogar 281×78 em y 636 (folga ~22 px abaixo do bloco e ~98 px até a base). O bloco fica ancorado embaixo; a arte de fundo (cristal e plataforma) ocupa a metade de cima;
- [`mockup_holo_result.png`](../assets/mockups/mockup_holo_result.png): vitória, XP e Moeda ganhos, nível 2 → 3, "Slot 1 liberado";
- [`mockup_holo_parts.png`](../assets/mockups/mockup_holo_parts.png): estados dos botões, painel, selo, ícones, barra, raridades e paleta.

### 11.1 Paleta (tokens `holo_*`, propostos ao AG02)

| Token | Hex | Uso | Contraste |
|---|---|---|---|
| `holo_bg` | `#021423` | fundo e cor da página (já usada na splash/título) | — |
| `holo_panel` | `#06223A` a 78% | preenchimento dos painéis | base das medidas |
| `holo_line` | `#3FE8F5` (100% / 38% `holo_line_dim`) | molduras, colchetes, varredura, ponta da barra | 12,5:1 no `holo_bg` |
| `holo_text` | `#E6FFFF` | texto principal e números | 15,5:1 |
| `holo_text2` | `#9FF6FF` | títulos de painel, rótulos | 13,2:1 |
| `holo_muted` | `#7FA3B8` | legendas, "320 / 500 XP" | 6,0:1 |
| `holo_violet` | `#8A6CFF` (claro `#B9A5FF`) | XP: início do degradê da barra, selo, rótulo "XP" | 7,6:1 (claro) |
| `gold` | `#FFC93D` (claro `#FFE08A`) | Moeda, "VITÓRIA", aviso de desbloqueio | 10,5:1 |
| `holo_ink` | `#03202E` | texto do botão primário (ciano) | 11:1 (6:1 pressionado) |
| `holo_dis_fill` / `holo_dis_line` / `holo_dis_text` | `#0E2233` / `#36506A` / `#5F7A92` | desabilitado e bloqueado | 3,6:1 (isento) |
| `danger` | `#FF5A6E` | derrota, erro | — |

- **Contraste mínimo:** 4,5:1 para texto até 18 px; 3:1 para texto grande, ícones e bordas de estado. Medido sobre `holo_panel` opaco; sobre o fundo, o texto sempre fica num painel ou tem brilho.
- **Ciano continua do jogador** (Jogar, foco, XP, Módulos). Roxo é só apoio (XP, selo); dourado é Moeda e prêmio. Raridades seguem o `ui.md`.

### 11.2 Formas e peças

- **Painel:** retângulo de **cantos chanfrados** (12 px a 1x), moldura `holo_line_dim` de 1,5 px, preenchimento `holo_panel` translúcido, **colchetes** `holo_line` de 22×2 px no canto superior esquerdo e inferior direito, título centrado em `holo_text2` com espaçamento 3 e linha de varredura abaixo.
- **Botão primário** (Jogar, Continuar): ≥ 280×72, chanfro 16, degradê vertical `#7FF5FF` → `#2FE6F2` → `#0FA9C4`, filete branco a 75% no topo, base escura de 6 px, brilho externo ciano a 55%. Texto `holo_ink` 26–30 px. **Pressionado:** degradê um passo mais escuro, desce 3 px, brilho cai para 4 px.
- **Botão secundário:** moldura ciano 2 px + interior `holo_panel` a 90%, texto `holo_text` 17 px. **Pressionado:** moldura `holo_text2` e interior `#0E5A70`, desce 2 px. **Desabilitado:** tokens `holo_dis_*`, sem brilho.
- Alvos de toque ≥ 44×44 (engrenagem, slots).
- **Engrenagem (configurações):** botão de ícone 44×44 no canto superior direito, mesmo painel chanfrado da pílula da Moeda (sozinho no topo do menu). **Sem ação no M2** (o toque não faz nada: sem tela, sem toggle); as configurações vêm no M8. A arte nunca leva texto (§9.5).
- **Barra de XP:** trilho 12 px (14 no Resultado), moldura `holo_line_dim`, fundo `#071A2B`, preenchimento em degradê `holo_violet` → `holo_line` e **ponta clara** `#E6FFFF` de 3 px com brilho. No Resultado, marcas a cada 25%. Números tabulares abaixo, em `holo_muted`.
- **Selo de nível:** hexágono em pé (52×58 no menu, 64×70 no Resultado), degradê índigo `#3B2C9A` → `#150F4A`, contorno `holo_line` 2,5 px e hexágono interno `holo_violet`; número `holo_text` 800. Na subida de nível, anel tracejado ciano em volta.
- **Ícone de XP:** hexágono violeta com losango ciano e faceta clara (lembra o cristal, sem copiar o núcleo). **Moeda:** moeda dourada com losango em relevo; **o desenho final é da T-162**, os mockups usam um provisório no mesmo espírito.
- **Slots de Módulo** (só no Resultado no M2; o resto fica para o hangar, M3): 60×60, chanfro 10. Com Módulo: moldura ciano + brilho; liberado vazio (no Resultado): cadeado aberto ciano; bloqueado: `holo_dis_*` com cadeado e "NV 7"/"NV 12"; o próximo a abrir usa moldura `holo_line_dim` e "NV 3" em `holo_text2`.
- **Aviso de desbloqueio:** painel com moldura `gold` e brilho dourado, interior escuro quente `#1E1A14` a 88%, título `gold` 22 px.
- **Molduras por raridade (M3+):** mesma forma chanfrada; comum = borda lisa; rara = + 2 losangos de canto; épica = borda dupla + 4 losangos + brilho interno; lendária = borda dupla + 4 gemas claras + brilho (animação do AG09). Cores do `ui.md`.

### 11.3 Tipografia (Outfit, já no projeto; tamanhos a 1x em 375 px)

| Uso | Tamanho / peso | Cor e efeito |
|---|---|---|
| "ANIMA" / "PROJECT:" | 58 / 22, 800 / 700 | `holo_text` + brilho ciano (sombra sem deslocamento, como o título) |
| "VITÓRIA" | 48, 900 | `gold` + brilho dourado + sombra `#6A4300` 2 px |
| Destaques ("NÍVEL 3!", "+180") | 26–32, 800 | `holo_text` + brilho ciano; Moeda em `#FFE08A` |
| Botão primário / secundário | 26–30 / 17, 800, espaçamento 2 | `holo_ink` / `holo_text` |
| Título de painel, "NÍVEL 4" | 12–13, 700, espaçamento 3 | `holo_text2` |
| Texto corrido | 12, 600 | `holo_text`/`holo_text2` |
| Legenda | 11, 600 (mínimo absoluto) | `holo_muted` |

Sem contorno escuro grosso (é do cartoon); o brilho só em títulos e números de destaque.

### 11.4 Animações baratas (só `Tween` de posição, escala e `modulate`)

- **Pulsar:** Jogar escala 1 → 1,03 e brilho 60% → 100% em 1,6 s, em laço.
- **Varredura:** sprite de linha (`ui_holo_scanline`) desce pelo painel a cada 4 s, alfa 0,5.
- **Contagem:** XP e Moeda contam de 0 ao valor em 0,8 s (ease-out); depois a barra enche em 0,6 s; ao completar, flash branco de 0,1 s, selo "pula" (1,25 → 1 em 0,25 s), anel gira e some em 0,6 s; o aviso do slot entra deslizando (0,3 s).
- Tocar a tela pula a sequência para o fim.

### 11.5 Desempenho no iPhone

- **Sem blur, sem shader de tela** (`BackBufferCopy`, `SCREEN_TEXTURE`) e sem glow do `WorldEnvironment`. O brilho é **pintado na textura** (margem extra usada como `expand_margin` do `StyleBoxTexture`) ou é um **sprite aditivo** (`ui_holo_glow`).
- Painéis e botões em **9-patch** (`StyleBoxTexture`/`NinePatchRect`); todas as peças num atlas `atlas_ui_holo` ≤ 1024×1024, para o batching do Compatibility.
- Um único fundo por tela (`title_bg_tech.webp` / `result_tech_bg.webp`, Lossy 0,85); nada de fundo em tela cheia novo.
- Alvo: ≤ 40 draw calls no menu; brilho de texto (sombra) só nos títulos; translucidez só em painéis (pouca sobreposição).
- Arte nova da T-189 ≤ ~300 KB no `.pck`.
- **Altura curta (375×616):** engrenagem ancorada na área segura; o bloco logotipo + nível/Moeda + Jogar fica junto, ancorado embaixo (Jogar a 24 px + área segura); o fundo segue a escala do shell; abaixo de 700 px "ANIMA" cai para 44 px.

### 11.6 Peças da T-189 (PNG 2x, `assets/ui/`; margens 9-patch em px 2x: esq/dir/topo/base)

| Arquivo | Canvas 2x | 9-patch | Observação |
|---|---|---|---|
| `ui_holo_panel.png` | 192×192 | 72/72/72/72 | moldura + preenchimento + colchetes nos cantos |
| `ui_holo_panel_gold.png` | 192×192 | 72/72/72/72 | aviso de desbloqueio (brilho dourado incluído, +16 de margem) |
| `ui_holo_pill.png` | 96×64 | 20/20/20/20 | Moeda e botão de ícone (engrenagem) |
| `ui_holo_btn_primary_normal.png` / `_pressed.png` | 192×160 | 40/40/40/48 | brilho pintado com 16 px de margem (`expand_margin` 8 a 1x) |
| `ui_holo_btn_secondary_normal.png` / `_pressed.png` / `_disabled.png` | 128×96 | 24/24/24/24 | |
| `ui_holo_bar_track.png` | 64×32 | 8/8/8/8 | |
| `ui_holo_bar_fill.png` | 64×24 | 6/6/6/6 | degradê violeta → ciano (ou branco tingido por `modulate`) |
| `ui_holo_bar_tip.png` | 16×40 | — | ponta clara com brilho |
| `ui_holo_level_badge.png` | 128×144 | — | selo sem número |
| `ui_holo_level_ring.png` | 192×192 | — | anel tracejado da subida de nível |
| `ui_holo_slot_ready.png` | 128×128 | — | slot liberado do aviso do Resultado (`_locked`/`_next` ficam para o hangar, M3) |
| `ui_icon_xp.png` | 64×64 | — | |
| `ui_icon_settings.png` | 48×48 | — | engrenagem `holo_text2`; sem ação no M2 (configurações no M8) |
| `ui_icon_lock_holo.png` / `ui_icon_unlock_holo.png` | 64×64 | — | |
| `ui_holo_scanline.png` | 256×4 | 64/64/0/0 | varredura |
| `ui_holo_glow.png` | 128×128 | — | brilho radial aditivo |

**Status (BRF-110):** as 20 peças foram geradas (`assets/ui/_src/gen_ui_holo.py`, ~65 KB no total); detalhes e uso no `assets/ui/README.md`. Ajuste: o botão primário usa margens **48/48/56/56** (as 40/40/40/48 não cabiam o chanfro de 16 + brilho + o deslocamento do pressionado).

**Botão de velocidade (T-274, BRF-121):** exceção holográfica no HUD cartoon da partida, `ui_speed_x1` / `ui_speed_x2` (+ `_pressed`), 96×96, corpo chanfrado 68×68. x1 = painel escuro com moldura ciano; x2 = ciano cheio com brilho forte. Setas e "x1"/"x2" vêm na arte. Sugestão: no topo, ao lado da pausa. Prévia: [`docs/img/botao-velocidade.png`](img/botao-velocidade.png). Detalhes no `assets/ui/README.md`.

A Moeda (`ui_icon_coin`) veio da T-162 (§11.7); as molduras por raridade (`ui_frame_<raridade>`) ficam para o M3.

### 11.7 Moeda e ícones do glossário (T-162, BRF-130)

Uma forma e uma cor por conceito, reconhecíveis a 28 px sem texto; contorno `#021423`, brilho pintado. Prévia: [`icones-glossario.png`](img/icones-glossario.png).

| Conceito | Arquivo | Forma | Cor |
|---|---|---|---|
| Moeda | `ui_icon_coin` (128) / `ui_icon_coin_small` (48) | disco com losango em relevo | `gold` `#FFC93D` |
| Módulo | `ui_icon_module` | placa chanfrada com raio | ciano `#3FE8F5` |
| Componente | `ui_icon_component` | peça com pinos e soquete | laranja `#FF9F43` |
| Núcleo | `ui_icon_core` | esfera ligada a três nós | azul `#4F8DFF` |
| Fragmento de Módulo | `ui_icon_module_fragment` | cacos de cristal com o raio do Módulo | orquídea `#E07BFF` |

Formas exclusivas: círculo = Moeda, estrela = Partículas, hexágono = XP. Laranja, azul e orquídea são **cores de interface do hangar** (não entram na arena; o laranja fica longe do `enemy_runner` por ser só menu).

### 11.8 Interruptor liga/desliga (T-296, BRF-138)

`ui_holo_toggle_{off,on}[_pressed]` e `ui_holo_toggle_disabled` (228×88, corpo igual ao secundário esticado). Rótulo à esquerda (texto da UI), chave chanfrada à direita (trilho 48×28). O estado não depende só da cor: **posição do botão** (esquerda = desligado, direita = ligado), **marca** no trilho (`O` desligado, `I` ligado) e **brilho** (só o ligado brilha). Desligado = moldura ciano escuro `#1C7F8E`; ligado = moldura `holo_line` + trilho ciano cheio; desabilitado = tokens `holo_dis_*`. Contorno `#021423`. Prévia: [`interruptor-holo.png`](img/interruptor-holo.png). Detalhes e margens em `assets/ui/README.md`.

### 11.9 Hangar: navegação (T-198, BRF-143; opção A aprovada pelo dono)

Prévias: [`hangar-opcao-a-375x812.png`](img/hangar-opcao-a-375x812.png) (barra inferior), [`hangar-opcao-b-375x812.png`](img/hangar-opcao-b-375x812.png) (abas no topo), [`hangar-opcao-a-tela-filha-375x812.png`](img/hangar-opcao-a-tela-filha-375x812.png) ("Em breve" + Voltar), [`hangar-1280x720.png`](img/hangar-1280x720.png). Fonte: `assets/ui/_src/hangar_mockup.html` (`bash assets/ui/_src/hangar_render.sh`). Conta nível 2 nas prévias.

- **Recomendada: A (barra inferior).** Ordem Módulos · Componentes · **Jogar (centro)** · Núcleos · Ajustes. Cada item 75×76 (+ 34 da faixa segura embaixo); ícone 28 (32 ativo) e rótulo 11,5/700 sob o ícone. A engrenagem sai do topo e vira o item "Ajustes" (tela "Configurações").
- **Estados:** ativo = placa chanfrada com degradê ciano, moldura `holo_line`, brilho e traço claro 40×4 na borda da barra; rótulo `holo_text`. Normal = ícone na cor do conceito, rótulo `#9FC4D6`. Bloqueado = ícone cinza a 45% + selo chanfrado (cadeado + "NV n", 11/800) sobre o canto do ícone; rótulo `#6F8BA3`. Um toque no bloqueado só mostra o aviso (sem trocar de tela).
- **Tela filha:** topo com Voltar (pílula 104×56, alvo 64) e título 20/800; painel central com o ícone do conceito, "Em breve" 30/800 e legenda. A barra continua visível, com a aba da tela ativa. O bloco do Jogar sobe 30 px (Jogar termina 16 px acima da barra).
- **Largura 1280×720:** mesma coluna em retrato centralizada (como o menu atual), sem faixa segura.

 (T-289, BRF-125; decisão 64)

O estilo dos menus (§11) e do botão de velocidade vale para **todo o HUD da partida**; a arena (chão, inimigos, Anima) segue cartoon 3/4. **Posições, tamanhos de toque e comportamento não mudam** (`docs/ui.md` §4); a T-290 (AG02) só troca a arte.

**Mockups:** [`hud-holo-mockup.png`](img/hud-holo-mockup.png) (720×1280: chefe com barra, slot 1 pronto, slot 2 em recarga, slot 3 bloqueado "NV 8", Atk power sem saldo, Cooldown no máximo) e [`hud-holo-mockup-375x812.png`](img/hud-holo-mockup-375x812.png) (sem chefe, Energia baixa com flash de dano, slot 2 liberado vazio, upgrade pressionado e outro sem saldo). Folha de estados: `assets/ui/_src/hud_sheet.png`.

### 12.1 Regras

- **Legibilidade sobre a arena clara:** toda peça tem miolo escuro (`#041626` a 90%) e moldura ciano; todo texto do HUD tem contorno `#021423` de 4–5 px (exceção do HUD à regra "sem contorno grosso" do §11.3). O degradê do topo (`TopScrim`) passa de `ink` 35% para `holo_bg` `#021423` **60% → 0**, até 24 px abaixo do HUD.
- **Cores:** ciano = jogador (pílula da onda, Energia, slots, upgrades compráveis); **magenta-vermelho `#FF4F8B`** = chefe (trilho, enchimento, emblema; proposta de token `boss_holo` ao AG02, no lugar do `boss_hp` vermelho); `gold` = máximo; `holo_dis_*` = bloqueado e sem Partículas. Cores da Energia por faixa mantidas (`core_hp_color`, via `modulate` do enchimento branco).
- **Bandeja opaca** `#06182A`: a cor da página na partida (`ScreenKit.set_page_color`, `web/shell.html`) passa de `#5A4A9A` para `#06182A`, senão aparece uma faixa lilás no rodapé do Safari.
- **Desempenho:** sem shader nem blur em tempo real (brilhos pintados, §11.5); 26 PNG, ~110 KB; cabem num atlas 512×512 com as peças `ui_holo_*`.

### 12.2 Peças, tamanhos e margens (px do PNG = px de tela no viewport 720)

| Elemento | Peças | Tamanho na tela | 9-slice E/D/C/B · `expand_margin` |
|---|---|---|---|
| "ONDA X/Y" | `ui_hud_pill_wave` | 220×64 | 40/40/28/28 · 8 |
| Partículas | `ui_hud_pill` + `ui_icon_particles` 32 | ~184×64 | 40/40/28/28 · 8 |
| Pausa | `ui_hud_btn_pause(_pressed)` | arte 96, corpo 68, toque 88 | — |
| Energia | `ui_hud_icon_energy` 56×64 · `ui_hud_bar_track` · `ui_hud_bar_fill` (branco + `modulate`) · `ui_hud_bar_tip` · `ui_hud_bar_flash` | barra 40, enchimento 32 (recuo 4) | trilho e flash 20 · 8; enchimento 10 · 0 |
| Chefe | `ui_hud_icon_boss` 48 · `ui_hud_bar_track_boss` · `ui_hud_bar_fill_boss` · ponta com `scale.y` 0,8 | trilho 32, enchimento 24 | igual à Energia |
| Bandeja | `ui_hud_tray` · `ui_hud_tray_band` | 720 × 266 (+ safe area) · faixa 96 | 8/8/24/8 · topo 12; faixa 4/4/4/6 |
| Slots de Módulo | `ui_hud_skill_ready/cooldown/locked/empty` · `_cooldown_ring` (progresso radial) · `_cooldown_mask` 144 · `ui_hud_key_badge(_off)` 44 · `ui_icon_lock_holo` 64 | Ø144, canvas 176×184 com centro em (88, 88) | — |
| Upgrades | `ui_hud_upgrade_normal/pressed/disabled/max` | corpo 128×80, canvas 144×96 | fixo · 8 |

- **Estados dos slots:** pronto = anel ciano 6 px + brilho; recarga = anel apagado + véu do setor restante + anel de progresso ciano + segundos (56 px); bloqueado = `holo_dis_*`, anel tracejado, cadeado e "NV n" em `holo_muted` 30 px, badge `_off`; vazio = anel tracejado apagado.
- **Estados dos upgrades:** comprável = moldura ciano + brilho, custo `#FFE08A`; pressionado = moldura `holo_text2`, miolo `#0E5A70` (escala 0,94 do código); sem Partículas = `holo_dis_*`, ícone a 55%, "Nv" em `holo_dis_text`, custo `#FF9AA6`; máximo = dourado com "MAX".
- **Dano na Energia:** `ui_hud_bar_flash` com `modulate` `danger`, alfa 1 → 0 em ~250 ms (o flash `danger` atual continua; a barra fantasma usa o enchimento com branco a 45%).
- Detalhes de uso por peça: `assets/ui/README.md` ("HUD holográfico da partida").
