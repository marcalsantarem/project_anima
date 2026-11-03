# Marcos

> Mantido pelo AG06. Tasks em [backlog.md](backlog.md). O AG06 propõe quando um marco está pronto para validação; quem fecha é o AG00, com o veredito do AG03 e o aval do usuário.

| Marco | Status | Tasks feitas |
|---|---|---|
| M0 — Fundação | em andamento | 5/8 (63%) · 1 em validação |
| M1 — Demo do combate | em andamento | 13/39 (33%) |
| M2 — Meta-jogo local | não quebrado | 0/2 (T-109, T-110 movidas do M1) |
| M3 — Online | não quebrado | — |
| M4 — Monetização e polimento | não quebrado | — |

## M0 — Fundação

**Objetivo:** docs, ambiente, projeto Godot e exportação Web vazia rodando no PC e no iPhone.

**Já feito antes do backlog:** Bíblia v1.0, docs dos agentes, projeto Godot 4.7.2 com Input Map, export templates Web instalados.

**Critérios de fechamento:**
- [x] Layers de colisão nomeadas e documentadas (T-001)
- [x] GUT roda headless com 1 teste passando (T-002)
- [x] `docs/ui.md` escrito (T-003)
- [x] Preset Web single-threaded exporta sem erros (T-004)
- [x] Deploy automático de teste no Netlify (T-008)
- [ ] Build vazio abre no Chrome do PC e no Safari do iPhone (T-005: PC ok, falta o iPhone)
- [ ] Metas de fps e tamanho confirmadas por medição, com ADR (T-006, T-007)
- [ ] AG00 atualiza `decisoes.md` (#4) com base na ADR de T-007

**Bloqueios:**
- Nenhum. T-005 aguarda só o teste do usuário no iPhone.

**Riscos:**

| Risco | Prob. | Impacto | Mitigação |
|---|---|---|---|
| GUT sem versão compatível com Godot 4.7.2 | média | médio | Testar a versão mais recente do GUT cedo (T-002); alternativa: gdUnit4 (subir decisão) |
| Safari do iOS com problemas no build (gestos, viewport, WebGL 2) | média | alto | Validar build vazio já no M0 (T-005) antes de qualquer gameplay |
| Build acima de ~15 MB: wasm com 37,7 MB brutos (~9,7 MB com gzip) | alta | alto | Confirmar que o Netlify serve o wasm comprimido (gzip/brotli); avaliar build customizado do Godot sem módulos não usados (T-007, T-119) |
| Metas de desempenho irreais no iPhone | média | alto | Cena de estresse no M0 (T-006) e revisão das metas em T-007 |

## M1 — Demo do combate

**Objetivo:** 1 fase completa, divertida e **visualmente polida, pronta para divulgar como demo** (Bíblia v1.1; decisões #23 a #28).

**Critérios de fechamento:**
- [x] Arena em retrato com Anima fixo e ataque automático com pool (T-103, T-104)
- [ ] 1 skill de área no slot 1 (meteoro ou onda de choque, decisão do usuário), com cooldown por toque, mouse e tecla `1` (T-108 ✔, T-125, T-139)
- [ ] Slots 2 e 3 visíveis e bloqueados com cadeado (T-136)
- [ ] Upgrades da partida: escolher 1 de 3 entre ondas, pagos com Partículas (T-133, T-134, T-135)
- [ ] Moeda da partida chamada Partículas nos sinais, no HUD e nos docs (T-140, T-141)
- [ ] 4 arquétipos de inimigo e 1 chefe com fases (T-103 ✔, T-111 ✔, T-115)
- [ ] Fase 1 com ~10 ondas + chefe, balanceada com 1 skill + upgrades, partida de 3–10 min (T-116)
- [x] HUD completo ligado por sinais (T-112)
- [x] Fluxo Toque para começar → Partida → Resultado → Jogar de novo, com pausa ao perder foco (T-102, T-113, T-122)
- [x] Tema global com fonte Outfit aplicado (T-106, T-121)
- [ ] Guia de estilo e mockup **aprovados pelo usuário** (T-126)
- [ ] Arte final na partida e na UI, sem placeholders (T-127, T-128, T-137, T-138)
- [ ] VFX de ataque, acertos, mortes, skill e chefe, com pool e modo de efeitos reduzidos (T-129 a T-132)
- [ ] Game feel de demo (T-117)
- [x] Testes GUT passando headless (T-114; seed determinística em T-123)
- [ ] ≥ 50 fps no iPhone na carga-alvo, com VFX, e build ≤ ~15 MB (T-118, T-119)
- [ ] Veredito "passa" do AG03, incluindo a qualidade visual de demo (T-120), e aval do usuário

**Bloqueios:** T-139 aguarda a decisão do usuário entre meteoro e onda de choque (T-125). O 4º slot (`Espaço`) está fora do M1.

**Riscos:**

| Risco | Prob. | Impacto | Mitigação |
|---|---|---|---|
| Desempenho no iPhone com muitos inimigos/projéteis | alta | alto | Pools desde T-104, overlay de debug cedo (T-107), medição contínua |
| Contrato de sinais entre AG01 e AG02 mudar no meio | média | médio | Fixar sinais em `docs/gameplay.md` (T-101) antes do HUD |
| Conflito de arquivos entre sessões paralelas | média | médio | Seguir a seção "Paralelismo e conflitos" do backlog |
| Partida não ser divertida com 1 skill | média | alto | Jogar cedo após T-134 + T-139; upgrades dão variedade; ajustar dados antes do chefe |
| Aprovação do estilo (T-126) atrasar toda a arte e os VFX | média | alto | Priorizar a T-126; mockup cedo com 2 ou 3 variações |
| VFX derrubarem o fps no iPhone | alta | alto | Pool desde a T-129, custo medido por efeito, modo de efeitos reduzidos (T-132) |
| Arte gerada sem licença clara | baixa | alto | `assets/LICENSES.md` obrigatório em toda entrega do AG08 |
