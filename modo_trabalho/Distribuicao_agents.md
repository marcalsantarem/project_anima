# Agentes especialistas

## Princípio

O trabalho é dividido entre **agentes especialistas**, cada um dono de uma área e de um conjunto de arquivos. O **AG00 (Líder)** não implementa: ele quebra, distribui, confere e integra.

## Tipos (exemplo de um jogo)

| Agente | Área | Arquivos típicos |
|---|---|---|
| AG00 (Líder) | Gestão, backlog, decisões, git, integração | `docs/`, `CLAUDE.md` |
| AG01 (Gameplay) | Regras da partida, inimigos, skills | `src/match/` |
| AG02 (UI) | Telas, HUD, navegação, textos | `src/ui/` |
| AG03 (QA) | Testes, validação de marco, relatórios | `tests/`, `docs/qa/` |
| AG04 (Meta-jogo) | Progressão, economia, dados de balanceamento | `src/meta/`, `data/` |
| AG05 (Backend) | Save, rede, servidor | `src/backend/` |
| AG07 (Arquiteto) | Estrutura, configuração do projeto, núcleo compartilhado, versão | `project.godot`, `src/core/` |
| AG08 (Arte) | Assets 2D, ícones, guia visual | `assets/` |
| AG09 (VFX) | Efeitos visuais | `src/fx/` |
| AG06 (Narrativa) | História, mundo, diálogos, glossário | `docs/narrativa.md`, `data/dialogue/` |
| AG10 (Plataforma) | Build, export, CI, hosting | `.github/`, `web/` |
| AG11 (Áudio), AG12 (Conteúdo) | Som; fases e itens em volume | `assets/audio/`, `data/` |
| AG13 (Monetização) | Anúncios, compras, loja, ofertas | `src/monetization/`, `data/store/` |

Quais começam ativos e quais ficam reservados: [Time_inicial.md](Time_inicial.md).

Em outro tipo de projeto (ex.: site estático) os papéis mudam (ex.: Conteúdo, Front-end, Design, SEO, QA), mas a regra é a mesma: **uma área, um dono, arquivos sem sobreposição**.

## Definição de cada agente

Cada agente tem um arquivo `docs/agentes/AGxx_<nome>.md` com:

1. **Missão** em uma ou duas linhas e exemplos de pedido ("Implemente a fusão…").
2. **Base do projeto** (igual em todos): o que é o produto, plataforma, stack, estilo, IDs, ordem da fonte da verdade (dono > bíblia > decisões > doc do agente), lista do time.
3. **Arquivos que ele possui** e os que ele não pode tocar.
4. **Regras próprias** da área (desempenho, padrões, testes).
5. **Formato da entrega**: resposta curta ao líder com o que foi entregue, validação, suposições, o que não foi testado e o próximo passo.

Opcionalmente, o agente também vira um tipo de subagent (`.claude/agents/agxx-<nome>.md`) que manda ler o arquivo do agente e o briefing, e repete as proibições de git.

## Regras para todos os agentes

- Trabalham **só** no escopo e nos arquivos do briefing.
- **Nunca** fazem commit, push ou branch.
- Não alteram arquivos compartilhados (configuração do projeto, autoloads, mapa de entrada) sem autorização no briefing.
- Não inventam decisão: se falta algo, registram na entrega.
- Ao terminar, reportam o que mudou e **o que não foi verificado**.

## Quando dividir um agente

Crie um agente novo, separando uma área, quando:

- o agente aparece em **quase todas as tasks** e vira gargalo (ondas não conseguem rodar em paralelo por causa dele);
- os briefings dele precisam explicar **duas especialidades diferentes** (ex.: UI e efeitos visuais; arte e animação);
- os arquivos dele se dividem naturalmente em duas pastas que raramente mudam juntas;
- o documento do agente fica grande demais para ler em cada sessão.

Exemplos: VFX saiu da UI; Áudio e Conteúdo ganharam agentes próprios. Um agente que deixou de ser útil é **arquivado** (ex.: o de backlog, cujo trabalho voltou para o líder). O número só é reaproveitado por decisão do dono e passa a valer para todos os projetos (ex.: o AG06 vago virou Narrativa).
