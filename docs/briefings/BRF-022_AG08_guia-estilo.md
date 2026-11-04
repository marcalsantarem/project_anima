# BRF-022 — AG08 — T-126 Guia de estilo + mockup da arena
**Objetivo e pronto quando:** ver T-126 em [docs/backlog.md](../backlog.md).
**Contexto:**
- O M1 é uma **demo polida para divulgação**, com objetivo comercial: decisões #23 e #24 em [decisoes.md](../decisoes.md).
- Leia na Bíblia o pitch, a premissa (o Anima é um receptáculo neutro) e o visual.
- Os tokens de UI estão em [docs/ui.md](../ui.md): o ciano é do jogador e os projéteis inimigos são magenta.
- Arquétipos atuais: corredor, tanque, atirador, enxame e o chefe `boss_warden`. A moeda da partida é **Partículas**.
**Escopo:**
- **`docs/arte.md`:** paleta, formas, silhuetas por arquétipo, tamanhos, nomes e a checklist de um asset.
- **Mockup:** `assets/backgrounds/mockup_arena.svg`, em 720×1280, com fundo, Anima, os 4 inimigos, projéteis dos dois lados, a skill de área e o HUD (HP, Wave, Partículas, 3 slots com 2 bloqueados).
  - **Arte 100% própria** (SVG). Registre-a em `assets/LICENSES.md`.
- **Variações (opcional):** se tiver duas direções boas, entregue `mockup_arena_b.svg` para o usuário escolher.
**Arquivos permitidos:** `docs/arte.md`, `assets/backgrounds/`, `assets/LICENSES.md`.
**Validação:** o SVG abre no navegador e importa no Godot sem erros (`--import`).
**Entrega:** formato padrão, com no máximo 10 linhas. Inclua os caminhos dos mockups, que o AG00 vai mostrar ao usuário.
