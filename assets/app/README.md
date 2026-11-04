# Ícones do app (BRF-071 / T-174)

Núcleo-Anima sobre o degradê roxo (`#8E72EC` → `#7B5CE0` → `#5A4A9A`), selo rúnico discreto, sem texto e sem transparência. A pasta tem `.gdignore` (fica fora do `.pck`).

| Arquivo | Tamanho | Uso |
|---|---|---|
| `app_icon_master.png` | 1024×1024 | Arte-mestre (lojas, derivados futuros) |
| `apple-touch-icon-180.png` | 180×180 | `<link rel="apple-touch-icon">` (iPhone; o iOS arredonda os cantos) |
| `icon-192.png`, `icon-512.png` | 192 / 512 | Manifesto, `purpose: "any"` |
| `icon-maskable-512.png` | 512×512 | Manifesto, `purpose: "maskable"` (símbolo dentro da zona segura de 80%) |
| `favicon-32.png`, `favicon-48.png` | 32 / 48 | `<link rel="icon" type="image/png" sizes="…">` (variante sem selo, núcleo maior) |
| `favicon.ico` | 16/32/48 | Favicon legado (entradas PNG) |

Derivados em PNG de 128 cores (≤ 40 KB). Gerar: `python assets/app/_src/gen_icons.py` (Chrome + ffmpeg); folha de contato: `python assets/app/_src/gen_preview.py` → `_src/preview_contact.png`.
