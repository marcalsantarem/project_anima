# Registro de decisões

Estados possíveis:

- **Decidido:** vale como regra.
- **Proposta:** sugestão ainda não aprovada.
- **A definir:** em aberto.

Ao mudar uma decisão, atualize esta tabela e, se for o caso, o `CLAUDE.md`.

| # | Tema | Estado | Decisão / opções | Motivo |
|---|---|---|---|---|
| 1 | Plataforma | Decidido | Web-first (Chrome no PC, Safari no iPhone); nativo no futuro | Teste instantâneo por link (GDD) |
| 2 | Engine | Decidido | Godot 4.x, exportação Web, renderer Compatibility | GDD; o WebGL 2 é o que roda em todos os navegadores-alvo |
| 3 | Linguagem | Proposta | GDScript | O Godot 4 com C#/.NET não exporta para Web |
| 4 | Exportação Web | Proposta | Single-threaded (sem SharedArrayBuffer) | Evita os headers COOP/COEP e problemas no Safari do iOS |
| 5 | Backend | A definir | Favorito: Firebase. Alternativa: Nakama. Protótipo com save local | O Firebase não tem SDK para Godot e não traz recursos de jogo; o Nakama tem SDK para Godot e economia pronta, mas exige hospedar o servidor |
| 6 | Economia | Proposta | Autoridade no servidor (fusão, moedas, caixas) | O cliente web é manipulável |
| 7 | Testes | A definir | GUT ou gdUnit4 | — |
| 8 | Ads e pagamentos web | A definir | Ads: Google H5 Games Ads ou SDK de portal. Pagamentos: Stripe ou similar | O AdMob não cobre web |
| 9 | Git | Decidido | Ver [git-workflow.md](git-workflow.md) | Definido pelo dono do projeto |
| 10 | Idioma | Decidido | Docs e commits em pt-BR; código em inglês | Definido pelo dono do projeto |
| 11 | Estrutura de pastas | Proposta | Ver [estrutura.md](estrutura.md) | — |
| 12 | Divisão em agentes | Proposta | Ver [agentes.md](agentes.md) | — |
| 13 | Coordenação | Decidido | O Claude principal é o game dev líder e o único interlocutor do dono do projeto; ele distribui e gerencia os agentes | Definido pelo dono do projeto |
