# Time inicial de um projeto de jogo

Começar **enxuto**: 7 agentes fixos e especialistas **reservados**, ativados só quando a área ganhar trabalho de verdade. Agentes demais no início fazem o líder gastar mais tempo com briefing do que o time produz.

A **numeração é a mesma em todos os projetos**: AG03 é sempre QA, AG08 é sempre Arte. Número de agente só muda de área por decisão do dono, e a mudança vale para todos os projetos.

## Time base (ativo desde o dia 1)

- **AG00 (Líder):** produção, backlog, roadmap, decisões, briefings, git, PR e tag. Não implementa.
- **AG01 (Gameplay):** loop principal: regras, controles, inimigos, combate, física, IA. Dono de `src/match/` (ou equivalente).
- **AG02 (UI):** telas, HUD, navegação, input (toque, mouse, teclado, controle), textos com localização. Dono de `src/ui/`.
- **AG03 (QA):** testes automatizados, validação de marco, regressão, build no aparelho real, roteiro para o dono. Reporta, não corrige.
- **AG04 (Sistemas/Meta):** progressão, economia, recompensas, dados de balanceamento, simulação com bot. Dono de `src/meta/` e `data/`. Em jogo sem meta-jogo, vira "Design de sistemas".
- **AG07 (Arquiteto):** estrutura de pastas, configuração da engine, núcleo compartilhado (fluxo de cenas, save, autoloads), versão. No começo também cuida de build e CI.
- **AG08 (Arte):** guia visual, assets 2D/3D, ícones, mockups. No começo também cobre animação simples e efeitos básicos.

## Reservados (ativar quando a área pesar)

| Agente | Área | Nasce de | Ativar quando |
|---|---|---|---|
| AG05 (Backend) | Servidor, contas, nuvem, multiplayer, autoridade da economia | AG07 | Houver qualquer coisa online |
| AG06 (Narrativa) | História, mundo, personagens, diálogos, textos de missão, tom e nomes | AG01 / AG02 | O jogo tiver história, diálogos ou um mundo com nomes e lore |
| AG09 (VFX) | Efeitos visuais, partículas, feedback de impacto | AG08 / AG02 | Os efeitos virarem uma task por marco |
| AG10 (Plataforma) | Export, lojas, CI, hosting, desempenho no aparelho | AG07 | Várias plataformas, lojas ou CI complexo |
| AG11 (Áudio) | Trilha, SFX, mixagem, áudio por evento | AG08 | Houver trilha e som por evento |
| AG12 (Conteúdo) | Fases, ondas, inimigos e itens em volume | AG01 / AG04 | O conteúdo for produzido em escala |
| AG13 (Monetização) | Anúncios recompensados, compras no app, moeda premium, loja, ofertas, passe, eventos de LiveOps | AG04 | O jogo tiver qualquer receita dentro dele |
| AG14+ | Analytics, Localização em várias línguas, Comunidade… | Conforme o projeto | Quando a área existir |

### AG06 (Narrativa)
- **Missão:** dar voz e sentido ao jogo sem travar o gameplay: premissa, mundo, personagens, glossário oficial de nomes, diálogos, textos de missão e de interface com tom.
- **Arquivos típicos:** `docs/narrativa.md` (bíblia do mundo e glossário), `data/dialogue/`, chaves de texto em `data/i18n/` (só as de narrativa; as de UI são do AG02).
- **Trabalha com:** AG01 (onde a história entra na partida), AG02 (onde o texto aparece), AG08 (visual dos personagens), AG12 (fases e missões).
- **Regra:** nomes e termos novos passam pelo glossário e viram decisão quando afetam o jogo todo.

### AG13 (Monetização)
- **Missão:** desenhar como o jogo gera receita **sem quebrar a economia nem a experiência**: anúncios recompensados (ex.: dobrar moedas, reviver), compras no app, moeda premium, skins, ofertas, passe de temporada e eventos.
- **Arquivos típicos:** `docs/monetizacao.md`, `src/monetization/` (atrás de uma interface, como o backend: o jogo nunca chama um SDK de anúncio ou de pagamento direto), `data/store/`.
- **Trabalha com:** AG04 (preços e impacto na economia), AG05 (validação de compra no servidor), AG02 (loja e telas de oferta), AG10 (SDKs por plataforma), AG03 (testes em modo de teste do provedor).
- **Regras:** toda compra é validada no servidor; nada de pagar para vencer sem decisão do dono; testes só com contas e chaves de teste.

## Ajustes por tipo de jogo

- **Multiplayer ou online:** o AG05 (Backend) entra no time base.
- **Narrativo:** o AG06 (Narrativa) entra no time base.
- **Free-to-play mobile:** o AG13 (Monetização) entra cedo, ao menos para desenhar a economia com o AG04.
- **Jogo pequeno ou de game jam:** fundir o AG04 com o AG01 e o AG07 com o AG10, começando com 5 agentes.

## Regra de crescimento

Divida um agente quando ele aparecer em quase toda onda e travar o paralelismo, ou quando os briefings dele precisarem explicar duas especialidades. Detalhe em [Distribuicao_agents.md](Distribuicao_agents.md).
