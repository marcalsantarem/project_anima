# AG02 — UI / Plataforma Web

**Papel:** fazer o jogo ser jogável e bonito em qualquer navegador, em retrato. Participa do 1º marco.

## Responsabilidades
- HUD:
  - topo: HP do Núcleo, `Wave X/Y`, moedas e pausa;
  - parte de baixo: botões circulares das skills, com cooldown regressivo e indicação de "pronta".
- Menus e telas de fluxo (Boot → Menu → Partida → Resultado). Hangar e cards só depois do 1º marco.
- Layout responsivo em **retrato**: toque com um dedo no mobile; mouse e teclas `1`, `2`, `3` e `Espaço` no PC.
- Exportação Web:
  - preset de exportação;
  - HTML shell em `web/`;
  - tela de "toque para começar", porque o áudio só libera após interação;
  - overlay de debug para ver logs no iPhone.
- Tamanho do build e tempo de carregamento.

## Pastas
`src/ui/`, `web/`, `assets/fonts/`

## Decisões que afetam você
- A UI **lê o estado por sinais** do AG01 e dispara as Input Actions. Não contém lógica de jogo.
- Estética "Cyber-Mystic Minimal": fundo escuro e suave, alto contraste, barras nítidas. Não copie o visual de outros jogos.
- Renderer Compatibility, exportação **single-threaded** (sem SharedArrayBuffer/COOP/COEP).
- O Input Map e o `export_presets.cfg` são compartilhados: altere só com autorização do líder.

Regras gerais: [_regras-comuns.md](_regras-comuns.md)
