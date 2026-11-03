# Marcos

> Mantido pelo AG06. Tasks em [backlog.md](backlog.md). O AG06 propõe quando um marco está pronto para validação; quem fecha é o AG00, com o veredito do AG03 e o aval do usuário.

| Marco | Status | Tasks feitas |
|---|---|---|
| M0 — Fundação | em andamento | 2/7 (29%) · 1 em andamento |
| M1 — Protótipo do combate | em andamento | 1/20 (5%) |
| M2 — Meta-jogo local | não quebrado | — |
| M3 — Online | não quebrado | — |
| M4 — Monetização e polimento | não quebrado | — |

## M0 — Fundação

**Objetivo:** docs, ambiente, projeto Godot e exportação Web vazia rodando no PC e no iPhone.

**Já feito antes do backlog:** Bíblia v1.0, docs dos agentes, projeto Godot 4.7.2 com Input Map, export templates Web instalados.

**Critérios de fechamento:**
- [ ] Layers de colisão nomeadas e documentadas (T-001)
- [x] GUT roda headless com 1 teste passando (T-002)
- [x] `docs/ui.md` escrito (T-003)
- [ ] Preset Web single-threaded exporta sem erros (T-004)
- [ ] Build vazio abre no Chrome do PC e no Safari do iPhone, com link de teste documentado (T-005)
- [ ] Metas de fps e tamanho confirmadas por medição, com ADR (T-006, T-007)
- [ ] AG00 atualiza `decisoes.md` (#4 e hosting de teste) com base na ADR de T-007

**Bloqueios:**
- T-005 depende de decidir **como servir o link de teste para o iPhone** (aguarda escolha do usuário).

**Riscos:**

| Risco | Prob. | Impacto | Mitigação |
|---|---|---|---|
| GUT sem versão compatível com Godot 4.7.2 | média | médio | Testar a versão mais recente do GUT cedo (T-002); alternativa: gdUnit4 (subir decisão) |
| Safari do iOS com problemas no build (gestos, viewport, WebGL 2) | média | alto | Validar build vazio já no M0 (T-005) antes de qualquer gameplay |
| Sem hosting de teste, o iPhone não é validado | alta | alto | Decidir o meio de teste antes de T-005 |
| Metas de desempenho irreais no iPhone | média | alto | Cena de estresse no M0 (T-006) e revisão das metas em T-007 |

## M1 — Protótipo do combate

**Objetivo:** partida completa e divertida com placeholders (escopo DENTRO/FORA na Bíblia).

**Critérios de fechamento:**
- [ ] Arena em retrato com Anima fixo e ataque automático com pool (T-103, T-104)
- [ ] 3 skills (área, controle, defesa) com cooldown, por toque, mouse e teclas `1` `2` `3` (T-108–T-110)
- [ ] 4 arquétipos de inimigo e 1 chefe com fases (T-103, T-111, T-115)
- [ ] Fase 1 com ~10 ondas + chefe, partida de 3–10 min (T-116)
- [ ] HUD completo ligado por sinais (T-112)
- [ ] Fluxo Toque para começar → Partida → Resultado → Jogar de novo, com pausa ao perder foco (T-102, T-113)
- [ ] Testes GUT passando headless (T-114)
- [ ] ≥ 50 fps no iPhone na carga-alvo e build ≤ ~15 MB (ou metas revisadas no M0) (T-118, T-119)
- [ ] Veredito "passa" do AG03 (T-120) e aval do usuário sobre a diversão

**Bloqueios:** nenhum no momento. O 4º slot (`Espaço`) está fora do M1 até decisão do usuário.

**Riscos:**

| Risco | Prob. | Impacto | Mitigação |
|---|---|---|---|
| Desempenho no iPhone com muitos inimigos/projéteis | alta | alto | Pools desde T-104, overlay de debug cedo (T-107), medição contínua |
| Contrato de sinais entre AG01 e AG02 mudar no meio | média | médio | Fixar sinais em `docs/gameplay.md` (T-101) antes do HUD |
| Conflito de arquivos entre sessões paralelas | média | médio | Seguir a seção "Paralelismo e conflitos" do backlog |
| Partida não ser divertida com placeholders | média | alto | Jogar cedo (após T-110) e ajustar dados antes do chefe |
