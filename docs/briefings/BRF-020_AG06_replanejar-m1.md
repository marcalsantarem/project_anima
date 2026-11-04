# BRF-020 — AG06 — Replanejar o M1 (demo polida) e o "Depois"
**Contexto:** o usuário decidiu as decisões #23 a #28 ([decisoes.md](../decisoes.md)) e a Bíblia está na v1.1 (seções "Progressão" e "Escopo atual: M1").
- O M1 agora é uma **demo visualmente polida**, com **1 skill**, os slots 2 e 3 bloqueados e **upgrades da partida**.
- Há agentes novos: **AG08 Arte** e **AG09 VFX** (ver docs/agentes/).
**Escopo:**
- **Mova para o M2:** T-109 e T-110.
- **Crie as tasks novas do M1**, com dono, dependências e "pronto quando":
  - AG08: guia de estilo `docs/arte.md` com mockup da arena, **aprovado pelo usuário**; arte do Anima, inimigos, projéteis e fundo; ícones e arte da UI.
  - AG09: `docs/vfx.md` com pool de efeitos; VFX do ataque, acertos e mortes; VFX da skill e do chefe; modo de efeitos reduzidos.
  - AG07: pasta `src/fx/` em `docs/estrutura.md`.
  - AG04: dados e balanceamento dos upgrades da partida.
  - AG01: lógica dos upgrades, dando 1 de 3 opções entre as ondas.
  - AG02: tela de escolha de upgrade; slots 2 e 3 do HUD bloqueados, com um cadeado.
  - AG01 + AG08: decidir entre meteoro e onda de choque para a skill de área. Isso é decisão do usuário, via AG00.
- **Ajuste as tasks que mudam:**
  - T-115, T-116 e T-117: balanceamento com 1 skill + upgrades; game feel dividido entre AG01 e AG09.
  - T-120: o critério inclui a qualidade visual de demo.
- **Atualize o "Depois":** nível de conta, desbloqueio de slots, módulos, fusão de módulos, skills de controle e defesa.
**Arquivos permitidos:** `docs/backlog.md`, `docs/marcos.md`.
**Entrega:** no máximo 6 linhas, com as próximas tasks prontas para briefing.
