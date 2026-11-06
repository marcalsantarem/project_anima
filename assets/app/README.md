# Ícones do app (BRF-084 / T-181; substitui os da T-174)

Cristal holográfico ciano sobre azul-marinho (`#0B3350` → `#021423`, igual ao `theme_color` do manifesto), com névoa roxa e anéis HUD, redesenhado em vetor no estilo da arte-base `assets/splash/tech/tech_splash_clean.png`. Sem texto e sem transparência. A pasta tem `.gdignore` (fica fora do `.pck`).

| Arquivo | Tamanho | Uso |
|---|---|---|
| `app_icon_master.png` | 1024×1024 | Arte-mestre (lojas, derivados futuros) |
| `apple-touch-icon-180.png` | 180×180 | `<link rel="apple-touch-icon">` (iPhone; o iOS arredonda os cantos) |
| `icon-192.png`, `icon-512.png` | 192 / 512 | Manifesto, `purpose: "any"` |
| `icon-maskable-512.png` | 512×512 | Manifesto, `purpose: "maskable"` (cristal e anéis dentro da zona segura de 80%) |
| `favicon-32.png`, `favicon-48.png` | 32 / 48 | `<link rel="icon" type="image/png" sizes="…">` (variante sem anéis, cristal maior e opaco) |
| `favicon.ico` | 16/32/48 | Favicon legado (entradas PNG) |

Derivados em PNG de 128 cores (≤ 50 KB). Gerar: `python assets/app/_src/gen_icons.py` (Chrome + ffmpeg); folha de contato: `python assets/app/_src/gen_preview.py` → `_src/preview_contact.png`. Copiar para `web/pwa/`: `bash web/copy_pwa.sh --sync-icons`.
