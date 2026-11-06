# BRF-109 — AG08 — T-180 revisão dos mockups (feedback do dono)
**Leia:** `docs/arte.md` §11 (sua entrega), `assets/mockups/_src/mockup_holo.html` e `render.sh`, mockups `assets/mockups/mockup_holo_*.png`. **Regra:** respostas curtas; sem commit/push/branches.
**Feedback do dono:** os mockups ficaram muito bonitos (em especial o Resultado). Duas correções:
1. **O menu principal não mostra Módulos.** Remova qualquer ícone/área/lista de Módulo (equipados, slots de skill, "1º Módulo entra na próxima partida") da **tela inicial/menu principal** (os Módulos vivem no hangar, M3). Mantenha o aviso de progressão se couber sem citar Módulo (ex. nível, barra de XP, "Chegue ao nível 3 para desbloquear um slot" pode ficar, ou troque por algo neutro). O **Resultado** pode continuar avisando "Slot 1 liberado" (é o que o dono gostou).
2. **Troque o ícone de volume/som por um ícone de configurações (engrenagem)** no menu principal. Nesta fase **não tem comportamento**: o toque não faz nada (sem tela, sem toggle). Atualize a §11 de `docs/arte.md` (peça de ícone de engrenagem em vez de som; nota "sem ação no M2; configurações vêm no M8") e a lista de peças da T-189 (§11.6).
Regere os PNGs (`render.sh`), mantendo os nomes e o estilo; revise `mockup_holo_menu.png` e `mockup_holo_menu_lvl1.png` (e a folha `mockup_holo_parts.png` se mostrar o ícone de som); o `mockup_holo_result.png` só muda se tiver o ícone de som ou Módulos fora do aviso do slot.
**Arquivos permitidos:** `docs/arte.md`, `assets/mockups/`. **Proibido:** `src/`, `web/`, `project.godot`.
**Entrega:** até 4 linhas.
