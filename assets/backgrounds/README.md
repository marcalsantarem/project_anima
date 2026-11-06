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
