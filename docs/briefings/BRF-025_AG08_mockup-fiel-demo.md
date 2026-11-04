# BRF-025 — AG08 — Mockup A fiel à demo
**Objetivo:** ajustar `assets/backgrounds/mockup_cartoon_a_upgrades.*` (BRF-024) para refletir exatamente a demo do M1 (decisões 28 e 35).
**Mudanças:**
- Bandeja de skills com **3 slots**: slot 1 ativo (skill de área, pronta, ícone atual), slots 2 e 3 **bloqueados** com cadeado e o nível de desbloqueio (slot 2 = "NV 7", slot 3 = "NV 12"). **Remova** o botão de escudo / 4º slot "ESPAÇO" e o cooldown "4s" do slot 2.
- **Botões de skill maiores e mais espaçados**: Ø de 144 px ou mais (hoje 128), centros bem distribuídos (ex.: x = 150 / 360 / 570) com folga clara entre eles; o número do slot continua visível.
- Mantenha a fileira de 5 upgrades e o resto do HUD; ajuste a altura da bandeja e da arena só o necessário, sem cobrir inimigos nem o núcleo.
**Entrega:** sobrescreva `mockup_cartoon_a_upgrades.svg` e `.png` (720×1280, mesmo método de render; o gerador está em `C:\Users\marca\AppData\Local\Temp\claude\C--Repos-projectanima\2d0298e1-bff0-492f-8129-2d89e7b24add\scratchpad\gen_upgrades.py`). Confira o PNG visualmente. Atualize a seção HUD de `docs/arte.md` (3 slots, Ø das skills) e a linha em `assets/LICENSES.md` se preciso.
**Arquivos permitidos:** `assets/backgrounds/`, `assets/LICENSES.md`, `docs/arte.md` (só HUD).
**Entrega ao AG00:** no máximo 10 linhas.
