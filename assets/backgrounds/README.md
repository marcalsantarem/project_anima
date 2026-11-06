# assets/backgrounds

> Dono: AG08. Licenças em `assets/LICENSES.md`.

## Fundo holográfico do Resultado (T-277, BRF-092, decisão 60)

| Arquivo | Tamanho | Uso |
|---|---|---|
| `result_tech_bg_dim.webp` | 768x1376, ~70 KB | **Recomendado** para a tela de Resultado: região central-inferior (recompensa e botões) já escurecida para leitura do texto |
| `result_tech_bg.webp` | 768x1376, ~77 KB | Mesmo fundo com escurecimento leve; use se a tela já tiver painel/véu próprio atrás do texto |

- **Origem:** arte do dono do projeto gerada no Google Gemini (uso comercial liberado), `assets/splash/tech/result_bg_source.jpg`.
- **Retoque:** removidos o ícone de bateria (topo-direita) e os textos miúdos de pseudo-HUD (topo-esquerda, topo-direita, laterais do meio, "SYSTEM STATUS", rodapé-esquerda), por preenchimento interpolado das bordas. Anéis, grade, molduras e réguas mantidos.
- **Escurecimento:** elipse suave centrada em ~70% da altura, rumo a `#050812` (35% no normal, 72% no `_dim`).
- **No Godot:** `TextureRect` com `expand_mode = Ignore Size` e `stretch_mode = Keep Aspect Covered`, ancorado na tela inteira (a imagem é 0,56 de proporção; em telas mais largas corta um pouco o topo e a base).
- **Regenerar:** `godot --headless --path <projeto vazio> -s assets/backgrounds/_src/result_tech_bg_retouch.gd` (pasta `_src/` com `.gdignore`).
- **Prévia:** `_preview/result_tech_bg_contact.png` (normal à esquerda, `_dim` à direita, com textos de teste).

## Fundo paisagem do PC (T-278, BRF-096, decisão 61)

| Arquivo | Tamanho | Uso |
|---|---|---|
| `_src/desktop_title_bg.webp` | 1376x768, ~86 KB | Tela de título (com cristal e plataforma no centro) |
| `_src/desktop_game_bg.webp` | 1376x768, ~84 KB | Demais telas (sem cristal) |

- **Origem:** arte do dono (Google Gemini, uso comercial liberado), `assets/splash/tech/desktop_*_bg_source.jpg`.
- **Retoque:** removidos bateria, caixa "BATTERY", colunas de texto, rótulos do gráfico e blocos de texto (cantos, laterais e rodapé), como no fundo do Resultado. Anéis, grade, molduras, réguas e o gráfico mantidos. Sem escurecimento embutido.
- **Composição:** cristal em x≈625–760 / y≈205–415 e plataforma em x≈510–865 / y≈430–620 (centro); anéis decorativos à esquerda (x≈280–520) e à direita (x≈880–1220); molduras finas nas bordas.
- **`cover` centralizado:** 16:9 mostra tudo; 16:10 corta ~73 px de cada lateral; 21:9 corta ~94 px no topo e na base (só a moldura e a área do HUD já limpa); 4:3 a 5:4 corta ~176–208 px de cada lateral (molduras laterais somem, anéis ficam). Nada relevante se perde; versão larga 2560x1080 dispensável.
- **Atenção:** a coluna do jogo (proporção 375:616, altura total) cobre a faixa central, x≈450–925 da fonte em qualquer proporção. **O cristal e a plataforma do `desktop_title_bg` ficam inteiramente atrás da coluna**; nas laterais, as duas artes ficam praticamente iguais.
- **Escurecimento sugerido (CSS, camada acima da imagem):**
  `background: radial-gradient(ellipse 75vh 90vh at 50% 50%, rgba(5,8,18,.75) 0%, rgba(5,8,18,.45) 45%, rgba(5,8,18,0) 100%), #050812 url(desktop_game_bg.webp) center / cover no-repeat;`
  (raio em `vh` acompanha a largura da coluna, que é ~61vh.)
- **Regenerar:** `godot --headless --path <projeto vazio> -s assets/backgrounds/_src/desktop_bg_retouch.gd`.
- **Prévia:** `_preview/desktop_*_bg_contact.png` (21:9, 16:9 e 4:3, com o escurecimento sugerido e a coluna simulada).

> **Guardadas, sem uso (decisão 61 cancelada em 2026-11-06):** as artes `desktop_*_bg.webp` ficam em `_src/` (fora do jogo e do `.pck`) para um futuro fundo/título em paisagem.
