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
| `gold` | `#FFC93D` | `#FFD23D` | Partículas, coroa do chefe, runas (B) |
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

## 5. Silhuetas por arquétipo

| Entidade | Silhueta | Por quê | Colisão (raio) | Sombra no chão (largura) | Altura visual | Canvas 1x |
|---|---|---|---|---|---|---|
| **Anima** | pedestal + cristal losango flutuante | ponto focal, alto | 40 | ~130 | ~160 | 128×192 |
| **Corredor** | bolinha laranja com duas orelhas pontudas e linhas de velocidade | rápido, "vem direto" | 16 | ~38 | ~58 | 64×64 |
| **Tanque** | cúpula grande carmim, chifres, placa frontal, pezinhos, barra de HP | pesado, blindado | 28 | ~72 | ~95 | 128×128 |
| **Atirador** | gota magenta pontuda com garras laterais e **orbe** acima | angular; o orbe anuncia o tiro | 18 | ~48 | ~90 | 128×128 |
| **Enxame** | bolinha violeta de um olho com asinhas, em bando | pequeno, numeroso | 10 | ~23 | ~37 | 64×64 |
| **Chefe** | **ogro** barrigudo, pele oliva quente, cabeça pequena, presas, colete e clava curta (decisão 39, BRF-057: `boss_ogre*`, poses parado/wind-up/atordoado; substitui a massa violeta com anel) | domina a tela; só corpo a corpo, sem anel | [A definir] | ~145 | ~200 | 256×256 |
| Projétil do jogador | cápsula ciano com núcleo branco e rastro | lado "amigo" | 6 | — | 26×14 | 32×16 |
| Projétil inimigo | losango magenta com núcleo rosado e halo | lê como ameaça | [AG01] | — | 26×18 | 32×32 |
| Partícula (moeda) | estrela de 4 pontas dourada com brilho | não confundir com projétil | — | ~16 | 22 | 32×32 |

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
| Fundos | `assets/backgrounds/` | `floor_tile.png`, `floor_ring.png`, `floor_pillar.png` (tela cheia em peças, BRF-040; ver `assets/sprites/README.md`) |
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

## 10. Pendências

| Item | Com quem |
|---|---|
| Escolher A ou B (ou combinar: ex. cenário de A + HUD de B) | usuário, via AG00 |
| Decisão 34 (fonte da arte final, §9.2) | usuário, via AG00 |
| Colisão em círculo × elipse no chão; raio do chefe e do projétil inimigo | AG01 (T-144) |
| Quem desenha o brilho base (sprite × shader) | AG09 |
| Mockups fora do build Web | AG07 (T-146) |
