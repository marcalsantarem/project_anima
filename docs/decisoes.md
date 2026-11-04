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
| 3 | Linguagem | Decidido | GDScript | O Godot 4 com C#/.NET não exporta para Web |
| 4 | Exportação Web | Proposta | Single-threaded (sem SharedArrayBuffer) | Evita os headers COOP/COEP e problemas no Safari do iOS |
| 5 | Backend | A definir | Favorito: Firebase. Alternativa: Nakama. Protótipo com save local | O Firebase não tem SDK para Godot e não traz recursos de jogo; o Nakama tem SDK para Godot e economia pronta, mas exige hospedar o servidor |
| 6 | Economia | Proposta | Autoridade no servidor (fusão, moedas, caixas) | O cliente web é manipulável |
| 7 | Testes | Decidido | GUT | Aprovado pelo dono do projeto em 2026-11-03 |
| 8 | Ads e pagamentos web | A definir | Ads: Google H5 Games Ads ou SDK de portal. Pagamentos: Stripe ou similar | O AdMob não cobre web |
| 9 | Git | Decidido | Ver [git-workflow.md](git-workflow.md) | Definido pelo dono do projeto |
| 10 | Idioma | Decidido | Docs e commits em pt-BR; código em inglês | Definido pelo dono do projeto |
| 11 | Estrutura de pastas | Proposta | Ver [estrutura.md](estrutura.md) | — |
| 12 | Divisão em agentes | Proposta | Ver [00_biblia_projeto.md](00_biblia_projeto.md) e [agentes/](agentes/) | — |
| 13 | Coordenação | Decidido | O Claude principal é o game dev líder e o único interlocutor do dono do projeto; ele distribui e gerencia os agentes | Definido pelo dono do projeto |
| 14 | Forma dos agentes | Decidido | Sessões próprias do Claude Code, iniciadas pelo líder quando há trabalho | Definido pelo dono do projeto |
| 15 | Regras das sessões | Proposta | Mesma pasta na `dev`, sem commits (o líder commita), paralelas só com arquivos diferentes | Compatibilizar sessões paralelas com a regra de branch única |
| 16 | 1º marco | Decidido | Protótipo jogável do combate, com Gameplay, UI/Web e QA | Validar a diversão antes do meta-jogo e do backend |
| 17 | Economia de tokens | Decidido | Mínimo gasto de tokens em todas as interações (com o dono do projeto e entre agentes); commits por etapa concluída | Definido pelo dono do projeto |
| 18 | Bíblia v1.0 | Decidido | Aprovada: pilares, roadmap M0–M4, escopo do M1 e metas iniciais de desempenho | Aprovada pelo dono do projeto em 2026-11-03 |
| 19 | Agente de backlog | Decidido | AG06 gerencia backlog, tasks e marcos (docs/backlog.md, docs/marcos.md); responde ao AG00 | Definido pelo dono do projeto |
| 20 | AG00 não implementa | Decidido | O líder só gerencia; trabalho técnico vai para agentes. Criado o AG07 Arquiteto Técnico, dono de `project.godot` e `src/core/` | Definido pelo dono do projeto |
| 21 | Ritmo de delegação | Decidido | Trabalho por partes: o AG00 só envia novos briefings com OK do usuário; nada de disparar o marco inteiro | Definido pelo dono do projeto |
| 22 | Hosting de teste | Decidido | Netlify | Definido pelo dono do projeto |
| 23 | M1 vira demo polida | Decidido | O M1 é uma fase só, mas com visual e game feel finais, para divulgar como demo. Isso vem do objetivo comercial: lançar nas lojas com receita | Definido pelo dono do projeto em 2026-11-03 |
| 24 | Agentes de arte | Decidido | Criados o AG08 Diretor de Arte (estilo, paleta, sprites, ícones, arte da UI) e o AG09 VFX (shaders, partículas, impactos) | Definido pelo dono do projeto em 2026-11-03 |
| 25 | Nível de conta e slots | Decidido | A conta começa sem skills; o slot 1 abre no nível 3, o slot 2 no 7 e o slot 3 no 12 (ajustáveis; revisado em 2026-11-03). Skills são poderes com cooldown, não cards | Definido pelo dono do projeto em 2026-11-03 |
| 26 | Módulos e fusão | Decidido | Módulos são os equipamentos do Anima, melhorados com gold, com raridade e fusão 3→1. Os cards de skill do GDD saem | Definido pelo dono do projeto em 2026-11-03 |
| 27 | Upgrades da partida | Decidido | Upgrades temporários comprados com as moedas da partida. ~~Na demo: escolher 1 de 3 entre as ondas~~ **Revisto na decisão 35**: compra em tempo real | Definido pelo dono do projeto em 2026-11-03 |
| 28 | Skills da demo | Decidido | O M1 tem 1 skill (área, meteoro ou onda de choque) no slot 1; as skills de controle e defesa (T-109, T-110) vão para o M2 | Definido pelo dono do projeto em 2026-11-03 |
| 29 | Moedas | Decidido | **Gold** é a moeda do jogo (meta), com ganho variável por partida. **Partículas** é a moeda da partida: começa em zero e é zerada a cada partida | Definido pelo dono do projeto em 2026-11-03 |
| 30 | Árvore de talentos | Decidido | Continua no meta-jogo, comprada com Gold | Definido pelo dono do projeto em 2026-11-03 |
| 31 | Direção de arte | Decidido | O tema continua Cyber-Mystic; o estilo passa a **2D cartoon casual**: colorido, formas arredondadas, contorno e sombra suave, UI "encorpada" (botões grandes, molduras por raridade). Referência de acabamento: jogos mobile casuais como o Archero, sem copiar nada. Mockups A "Facetado" e B "Glifo" rejeitados | Definido pelo dono do projeto em 2026-11-03 |
| 32 | Técnica de arte | Decidido | Sprites 2D ilustrados (sem 3D), por desempenho no Safari do iPhone | Definido pelo dono do projeto em 2026-11-03 |
| 33 | Câmera e protagonista | Decidido | Câmera 3/4. O "herói" do centro pode ser um objeto; na 1ª versão, um núcleo simples. Preparar para skins | Definido pelo dono do projeto em 2026-11-03 |
| 34 | Produção da arte | Decidido | A arte do M1 é feita pelos agentes; será refinada depois do M1 (artista ou outra fonte, ver T-143) | Definido pelo dono do projeto em 2026-11-03 |
| 35 | Upgrades da partida em tempo real | Decidido | Fileira de 5 botões acima das skills: **Atk power, Atk spd, Defesa, Vida máxima, Cooldown**. Cada toque compra 1 nível com Partículas, custo crescente, sem pausar a partida. Substitui o "1 de 3 entre ondas" | Definido pelo dono do projeto em 2026-11-03 |
| 36 | Visual da demo | Decidido | A demo usa o mockup A "Jardim Arcano" (versão clara). O B "Noite Rúnica" (escura, chefe) fica reservado para a 2ª fase | Definido pelo dono do projeto em 2026-11-03 |
| 37 | Skill da demo | Decidido | A skill do slot 1 é um **meteoro de fogo**: cai na área alvo, explode com raio e dano próprios. Raio da explosão e dano são atributos pensados para receber **upgrades depois** (M2, evolução das skills). Substitui a escolha meteoro × onda de choque e a `skill_pulse` provisória | Definido pelo dono do projeto em 2026-11-04 |
| 38 | Barra de vida dos inimigos | Decidido | Todo inimigo comum tem uma barra pequena de vida sobre ele: **verde** com 60% ou mais, **amarela** abaixo de 60%, **vermelha** com 30% ou menos. O chefe não usa essa barra (ver decisão 39) | Definido pelo dono do projeto em 2026-11-04 |
| 39 | Redesenho do chefe | Decidido | Chefe simples: forma humanoide grande e "gorda" (ogro), **uma única fase na demo** (sem troca de fase por vida), **só um ataque corpo a corpo**, **sem minions** (sem leque, anel nem invocação). Sobre ele, em vez da barra de vida, uma **barra de defesa** que funciona como **escudo na frente da vida**: tiros e meteoro tiram a defesa primeiro; ao esgotar, o chefe é **lançado para trás, em direção à borda do mapa**, e só então a vida sofre dano. O **meteoro lança o chefe na hora**. Na parte de cima da tela, uma **barra de vida grande e vermelha com o rótulo "Boss"**, de tamanho próximo ao da barra do Anima | Definido pelo dono do projeto em 2026-11-04 |
| 40 | Glossário e moedas | Decidido | Nomes oficiais: **Moeda** (ex-Gold; meta, dourada, futuro), **Partículas** (da partida; estrela verde "chip"; some ao fim; **não cai no mapa** por enquanto), **Fragmentos** (ex-módulos/equipamentos; 6 espaços; futuro), **Módulos** (ex-skills; ex.: o meteoro) e **Núcleos** (ex-talentos; futuro). Substitui os nomes das decisões 26, 29 e 30. Identificadores de código seguem em inglês e não são renomeados agora. **Pendente:** "Núcleo" já nomeia a vida do Anima no HUD | Definido pelo dono do projeto em 2026-11-04 |
| 41 | Rótulo da vida do Anima | Decidido | A barra de vida do Anima no HUD passa de "NÚCLEO" para **"ENERGIA"**, liberando "Núcleo" para os talentos (decisão 40). Os identificadores de código (`core_hp`, `Núcleo` nos docs técnicos) não mudam agora | Definido pelo dono do projeto em 2026-11-04 |
| 42 | Chefe sem barra de defesa | Decidido | A barra de defesa do chefe (decisão 39) **sai deste chefe** (o teste no iPhone mostrou que não funcionou bem). O código fica **arquivado e desligado por dados** (`defense_max = 0`) para outros chefes. **Continua:** o meteoro **lança o chefe para trás, em direção à borda, e o atordoa**; a barra "Boss" grande no topo; ataque só corpo a corpo; sem minions; uma fase. Passos do chefe com **animação** (ele não pode "se arrastar") | Definido pelo dono do projeto em 2026-11-04 |
| 43 | Ajustes de layout no iPhone | Decidido | O círculo rúnico do chão fica menor (~70% do tamanho atual); a bandeja de botões vai até a borda inferior da tela (sem faixa vazia), com menos espaço sob os Módulos; o Anima fica centralizado na área livre entre o topo do HUD e a bandeja | Definido pelo dono do projeto em 2026-11-04 |
