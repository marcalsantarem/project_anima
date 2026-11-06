# Backlog

> Mantido pelo AG06. O status reflete o que o AG00 confirmou. Formato e regras em [agentes/AG06_backlog.md](agentes/AG06_backlog.md). Andamento dos marcos em [marcos.md](marcos.md).

## Quadro

| ID | Título | Marco | Dono | Status |
|---|---|---|---|---|
| T-001 | Layers de colisão nomeadas | M0 | AG07 | feita |
| T-002 | Instalar GUT e teste smoke headless | M0 | AG03 | feita |
| T-003 | `docs/ui.md` (tokens, layout, fluxo de telas) | M0 | AG02 | feita |
| T-004 | Preset Web + HTML shell mínimo | M0 | AG02 | feita |
| T-005 | Build vazio no Chrome PC e no iPhone | M0 | AG02 | feita |
| T-006 | Cena de estresse para confirmar metas de desempenho | M0 | AG10 | feita no PC (BRF-085); falta medir no iPhone |
| T-007 | ADR das metas de desempenho e da exportação single-threaded | M0 | AG07 | feita (BRF-095; falta o tamanho do build, da T-119) |
| T-008 | Deploy automático Web (GitHub Actions → Netlify) | M0 | AG02 | feita |
| T-101 | `docs/gameplay.md` (parâmetros e sinais) | M1 | AG01 | feita |
| T-102 | Autoload de fluxo de cenas | M1 | AG07 | feita |
| T-103 | Protótipo cinza: arena, Anima, 1 inimigo | M1 | AG01 | feita |
| T-104 | Ataque automático com pool | M1 | AG01 | feita |
| T-105 | Ondas por dados, HP do Núcleo, moedas, vitória/derrota | M1 | AG01 | feita |
| T-106 | Tema base e componentes de UI | M1 | AG02 | feita |
| T-107 | Overlay de debug Web (FPS, logs) | M1 | AG02 | feita (com gravador de logs e botão Logs) |
| T-108 | Base de skills + skill de área | M1 | AG01 | feita |
| T-109 | Módulo de controle: congelamento | M5 | AG01 | a fazer |
| T-110 | Módulo de defesa: escudo | M5 | AG01 | a fazer |
| T-111 | Arquétipos: tanque, atirador, enxame | M1 | AG01 | feita |
| T-112 | HUD ligado aos sinais | M1 | AG02 | feita |
| T-113 | Telas: toque para começar, pausa, resultado | M1 | AG02 | feita |
| T-114 | Testes GUT de ondas, dano e cooldowns | M1 | AG03 | feita |
| T-115 | Chefe da fase 1 | M1 | AG01 | feita |
| T-116 | Fase 1 completa (~10 ondas + chefe) | M1 | AG01 | feita |
| T-117 | Game feel | M1 | AG01 + AG09 | feita |
| T-118 | Desempenho no iPhone (150 inimigos / 300 projéteis) | M1 | AG01 | feita (BRF-086, BRF-091); iPhone 11 Pro 46,9 fps; meta revisada: média >= 45 fps no pior caso (dono, 2026-11-06) |
| T-119 | Otimização do build Web | M1 | AG10 | feita (BRF-094): brotli 8,9 MB (meta ≤ 15 MB); 1º frame < 5 s em 4G em risco na 1ª visita (.wasm), aceito no M1 |
| T-120 | Validação do M1 | M1 | AG03 | feita (BRF-100): passa com ressalvas, ver docs/qa/qa-M1.md |
| T-121 | Tema global no `project.godot` | M1 | AG07 | feita |
| T-122 | Ligar a arena real ao SceneFlow | M1 | AG07 | feita |
| T-123 | Seed no `Arena._rng` para testes determinísticos | M1 | AG01 | feita |
| T-124 | Pasta `src/fx/` em `docs/estrutura.md` | M1 | AG07 | feita |
| T-125 | Proposta da skill de área: meteoro × onda de choque | M1 | AG01 + AG08 | feita (meteoro de fogo, decisão 37) |
| T-126 | Guia de estilo `docs/arte.md` + mockup da arena | M1 | AG08 | feita |
| T-127 | Arte do Anima, inimigos, chefe, projéteis e fundo | M1 | AG08 | feita |
| T-128 | Ícones e arte da UI | M1 | AG08 | feita |
| T-129 | `docs/vfx.md` + pool de efeitos | M1 | AG09 | feita |
| T-130 | VFX do ataque, acertos e mortes | M1 | AG09 | feita |
| T-131 | VFX da skill e do chefe | M1 | AG09 | feita |
| T-132 | Modo de efeitos reduzidos | M1 | AG09 | feita |
| T-133 | Dados e balanceamento dos upgrades da partida | M1 | AG04 | feita |
| T-134 | Lógica dos upgrades em tempo real (5 atributos) | M1 | AG01 | feita |
| T-135 | Fileira de 5 botões de upgrade no HUD | M1 | AG02 | feita |
| T-136 | Slots 2 e 3 do HUD bloqueados (cadeado) | M1 | AG02 | feita |
| T-137 | Trocar placeholders da partida pela arte final | M1 | AG01 | feita |
| T-138 | Aplicar a arte da UI no HUD e nas telas | M1 | AG02 | feita |
| T-139 | Meteoro de fogo como skill de área (decisão 37) | M1 | AG01 | feita |
| T-140 | Moeda da partida vira Partículas: sinais, código e `gameplay.md` | M1 | AG01 | feita |
| T-141 | Moeda da partida vira Partículas: HUD, telas e `ui.md` | M1 | AG02 | feita |
| T-142 | Novo guia de estilo 2D cartoon 3/4 + mockups PNG | M1 | AG08 | feita |
| T-143 | Pipeline e fonte da arte final (opções e custos) | M1 | AG08 | feita |
| T-144 | Arena em 3/4: Y-sort, âncoras, sombras, spawn | M1 | AG01 | feita |
| T-145 | Retema da UI no estilo cartoon (tokens, tema, fonte) | M1 | AG02 | feita |
| T-146 | Remover mockups rejeitados e excluir referências do export Web | M1 | AG07 | feita |
| T-147 | Anima com skin trocável (Resource de aparência) | M12 | AG01 | a fazer |
| T-149 | Barra de vida pequena sobre cada inimigo (verde, amarela, vermelha) | M1 | AG01 | feita |
| T-150 | Chefe ogro: ataque corpo a corpo, sem minions, defesa como escudo e lançamento | M1 | AG01 | feita |
| T-151 | Arte do chefe ogro (humanoide grande e gordo) | M1 | AG08 | feita |
| T-152 | Barra de vida grande e vermelha "Boss" no topo do HUD | M1 | AG02 | feita |
| T-153 | Arte das pílulas do topo (ONDA e Partículas) e do botão secundário | M1 | AG08 | feita |
| T-154 | Texto "MAX" na pílula de custo dos upgrades (hoje desenhado por código) | M1 | AG08 + AG02 | feita |
| T-155 | "Voltar ao título" a partir da tela de Resultado | M1 | AG02 + AG07 | feita |
| T-156 | Chão: quebrar a repetição das pedrinhas do tile | M1 | AG08 + AG01 | dispensada do M1 (dono, 2026-11-06) |
| T-157 | Ajustar o escurecimento do topo (degradê do chão + do HUD) | M1 | AG02 + AG01 | dispensada do M1 (dono, 2026-11-06) |
| T-158 | Teste no iPhone: splash, título, partida e chefe (ajustes saem daqui) | M1 | usuário + AG00 | feita |
| T-159 | Remover o ícone provisório do `skill_pulse` e deixar o do meteoro como padrão | M1 | AG02 | feita (BRF-083; sobra o PNG do pulse sem uso, limpeza com o AG08) |
| T-160 | Arte do ícone de Partículas: estrela verde, estilo "chip" (e nova cor dos efeitos de coleta) | M1 | AG08 | feita |
| T-161 | Aplicar o ícone verde de Partículas no HUD, Resultado, botões de upgrade e efeitos (hoje dourado) | M1 | AG02 + AG09 | feita |
| T-162 | Arte do ícone de Moeda (moeda dourada) e do glossário na UI (para o M2) | M2 | AG08 | a fazer |
| T-163 | Textos do jogo e docs com os nomes oficiais (Módulo, Componente, Núcleo, Moeda); decidir a colisão de "Núcleo" | M2 | AG00 + AG04 + AG02 | a fazer |
| T-164 | Rótulo da vida do Anima: "NÚCLEO" vira "ENERGIA" no HUD, Resultado e docs de UI | M1 | AG02 | feita |
| T-165 | Build e versão no cabeçalho do log (commit e data do deploy) | M1 | AG07 + AG02 | feita |
| T-166 | Chefe sem barra de defesa (mecânica arquivada, desligada por dados); meteoro lança e atordoa; rebalancear | M1 | AG01 | feita |
| T-167 | Animação de passos do chefe ogro (balanço, ritmo pelo movimento; quadros de caminhada) | M1 | AG01 + AG08 | feita |
| T-168 | Círculo rúnico do chão menor (~70%) | M1 | AG01 | feita |
| T-169 | Bandeja até a borda inferior, menos espaço sob os Módulos, Anima centralizado na área livre | M1 | AG02 + AG01 | feita |
| T-170 | Tela de logo do estúdio (preta, ~1 s) antes da splash de carregamento | M1 | AG02 | feita |
| T-171 | Logo horizontal do estúdio na base da tela de título; remover o crédito "Criado por Marçal Santarem" | M1 | AG02 | feita |
| T-172 | Canvas até a borda inferior no Safari do iPhone, sem faixa e sem somar a safe area duas vezes; diagnóstico no log | M1 | AG02 | feita |
| T-173 | Meteoro: reavaliar o alvo perto do impacto (2 dos 6 lançamentos contra a horda acertaram 0 inimigos, 1 acertou 1) | M1 | AG01 | feita |
| T-174 | Ícones do app (tela de início do iPhone, favicon, maskable) | M1 | AG08 | feita |
| T-175 | Manifesto web (modo app, tela cheia, retrato) + meta tags do iOS + cópia no deploy | M1 | AG02 | feita |
| T-176 | Foco manual: tocar num inimigo para o Anima focá-lo (marcador; volta ao automático) | M1 | AG01 | feita |
| T-177 | Mira do meteoro: API de alvo manual e prévia do raio; chefe lançado dentro do alcance | M1 | AG01 | feita |
| T-178 | Arrastar do botão do Módulo para mirar (toque/mouse), segurar 1 + clique no PC | M1 | AG02 | feita |
| T-179 | Splash e tela de título no estilo holográfico/tecnológico (arte do Gemini como base; texto, barra e brilhos vivos) | M1 | AG02 + AG08 | feita |
| T-180 | **(1ª do M2)** Guia visual "HUD holográfico" para menus + mockups do menu principal e do Resultado com recompensa | M2 | AG08 | feita (aprovada pelo dono em 2026-11-06) |
| T-181 | Ícones do app (iPhone, PWA e favicon) na nova identidade tecnológica da splash e do menu | M1 | AG08 + AG10 | feita (BRF-084; falta o dono reinstalar o atalho no iOS) |
| T-182 | Áudio básico: música de entrada (título) e som do tiro básico, com volume salvo e respeitando o 1º toque na web | M2 | AG11 | a fazer |
| T-183 | Fechar o M1 como v0.1.0: versão `0.1.0` no jogo e tag `v0.1.0`, sem branch (decisão 55; quando o dono pedir) | M1 | AG00 + AG10 | feita (tag v0.1.0 em bc638a3, 2026-11-06) |
| T-184 | Economia do M2: curva de XP (níveis 1 a 30), XP e Moeda por partida (por monstros derrotados e ondas, nunca pelo tempo; decisão 59), dados em `.tres` e `docs/economia.md` | M2 | AG04 | revisão em curso (BRF-108: sem bônus fixos, derrota 70%, bônus de 1ª vitória do dia, níveis 1 a 30, semanas até o 30) |
| T-185 | Save local: autoload `Backend` (interface) + `LocalBackend` em `user://` com versão, migração e recuperação; ADR | M2 | AG05 + AG07 | feita |
| T-186 | Lógica pura do meta em `src/meta/`: recompensa do `MatchResult`, XP → nível, slots liberados; testes GUT | M2 | AG04 | a fazer |
| T-187 | Fluxo de cenas com menu: Título → Menu → Partida → Resultado → Menu; aplica a recompensa e salva | M2 | AG07 | a fazer |
| T-188 | Partida monta os slots pelo nível da conta (`MatchConfig`); conta sem Módulo joga só com ataque básico | M2 | AG01 | a fazer |
| T-189 | Arte do menu holográfico: painéis, botões, barra de XP, selo de nível, ícone de XP | M2 | AG08 | em andamento (BRF-110) |
| T-190 | Tela do menu principal: Jogar, nível e barra de XP, saldo de Moeda e ícone de configurações (engrenagem) sem ação até o M8; sem Módulos na tela | M2 | AG02 | a fazer |
| T-191 | Resultado com recompensa: XP e Moeda animados, barra enchendo, subida de nível e aviso de slot liberado | M2 | AG02 + AG09 | a fazer |
| T-192 | HUD: slots bloqueados mostram o nível que os libera | M2 | AG02 | a fazer |
| T-193 | Debug do meta: zerar save e dar XP/Moeda pelo overlay `?debug=1`; meta no log da partida | M2 | AG02 + AG05 | a fazer |
| T-194 | Assets de áudio do M2: música de entrada e som do tiro (próprios ou CC0, licença registrada) | M2 | AG11 | a fazer |
| T-195 | Balanceamento da progressão: partidas até os níveis 3, 7 e 12 pela simulação do bot | M2 | AG04 | a fazer |
| T-196 | Validação do M2 (inclui o botão de velocidade, T-272 a T-276; inclui save persistindo no iPhone, no Safari e no modo app) | M2 | AG03 | a fazer |
| T-197 | Fechar o M2 como v0.2.0: tag `v0.2.0`, branch `alfa` e deploy em `alfa--projectanimagame.netlify.app` (quando o dono pedir) | M2 | AG00 + AG10 | a fazer (no fechamento) |
| T-198 | Mockup do hangar: navegação entre Jogar, Núcleos, Módulos, Componentes e Configurações (abas ou barra inferior) (tam. M) | M3 | AG08 | a fazer |
| T-199 | Arte do hangar: fundo, ícones das abas, estados ativo/bloqueado (tam. M) | M3 | AG08 | a fazer |
| T-200 | Fluxo de cenas do hangar: telas filhas carregadas sob demanda, voltar, estado preservado (tam. P) | M3 | AG07 | a fazer |
| T-201 | Hangar na UI: o menu vira hangar com abas; telas ainda vazias mostram "em breve" (tam. M) | M3 | AG02 | a fazer |
| T-202 | Validação e fechamento da v0.2.1 (tag) (tam. P) | M3 | AG03 + AG00 | a fazer |
| T-203 | Design da árvore de Núcleos: 10 a 12 talentos, efeitos, custos em Moeda, pré-requisitos; dados em `.tres` (tam. M) | M4 | AG04 | a fazer |
| T-204 | Lógica dos Núcleos: compra, pré-requisitos, soma dos efeitos; save; testes GUT (tam. M) | M4 | AG04 + AG05 | a fazer |
| T-205 | Partida aplica os Núcleos comprados (via `MatchConfig`) (tam. M) | M4 | AG01 | a fazer |
| T-206 | Arte dos ícones dos Núcleos e das ligações da árvore (tam. M) | M4 | AG08 | a fazer |
| T-207 | Tela de Núcleos: árvore, detalhe do talento, compra e saldo (tam. G) | M4 | AG02 | a fazer |
| T-208 | VFX de compra e desbloqueio de Núcleo (tam. P) | M4 | AG09 | a fazer |
| T-209 | Balanceamento com Núcleos (simulação do bot) (tam. P) | M4 | AG04 | a fazer |
| T-210 | Validação e fechamento da v0.2.2 (tag) (tam. P) | M4 | AG03 + AG00 | a fazer |
| T-211 | Design dos Módulos: congelamento, escudo e choque; níveis, efeito por nível e custos em Moeda (tam. M) | M5 | AG04 | a fazer |
| T-212 | Módulo de ataque: choque que se espalha entre inimigos (tam. M) | M5 | AG01 | a fazer |
| T-213 | Evolução dos Módulos com Moeda: lógica, save e testes (tam. M) | M5 | AG04 + AG05 | a fazer |
| T-214 | Ícones dos 3 Módulos novos (tam. P) | M5 | AG08 | a fazer |
| T-215 | VFX do congelamento, do escudo e do choque (tam. M) | M5 | AG09 | a fazer |
| T-216 | Tela de Módulos: lista, detalhe e evolução (tam. M) | M5 | AG02 | a fazer |
| T-217 | Seleção de Módulos por slot: equipar, salvar e levar ao `MatchConfig` (tam. M) | M5 | AG02 + AG07 | a fazer |
| T-218 | Mira manual (arrastar) para os Módulos novos que precisarem (tam. P) | M5 | AG01 + AG02 | a fazer |
| T-219 | Balanceamento dos 4 Módulos e bot que usa todos (tam. M) | M5 | AG04 | a fazer |
| T-220 | Validação e fechamento da v0.2.3 (tag) (tam. P) | M5 | AG03 + AG00 | a fazer |
| T-221 | Design das recompensas na partida: quando aparecem, cura × baú, conteúdo do baú (Moeda) (tam. P) | M6 | AG04 | a fazer |
| T-222 | Lógica: escolha entre ondas, cura aplicada, Moeda do baú somada ao resultado (tam. M) | M6 | AG01 | a fazer |
| T-223 | Janela de escolha na partida (pausa, 2 cartões, toque e teclado) (tam. M) | M6 | AG02 | a fazer |
| T-224 | Arte do baú e do cartão de cura + VFX de abrir (tam. M) | M6 | AG08 + AG09 | a fazer |
| T-225 | Validação e fechamento da v0.2.4 (tag) (tam. P) | M6 | AG03 + AG00 | a fazer |
| T-226 | Design dos Componentes: ATK, DEF e híbrido; atributos, níveis, custos de upgrade, taxas de drop (tam. M) | M7 | AG04 | a fazer |
| T-227 | Inventário e equipados: modelo, save e testes (tam. M) | M7 | AG04 + AG05 | a fazer |
| T-228 | Drop de Componentes no fim da partida e no baú (T-222) (tam. M) | M7 | AG04 + AG01 | a fazer |
| T-229 | Partida aplica os atributos dos Componentes equipados (tam. P) | M7 | AG01 | a fazer |
| T-230 | Arte dos 3 Componentes e dos espaços de equipar no Anima (tam. M) | M7 | AG08 | a fazer |
| T-231 | Tela de Componentes: inventário, equipar no Anima, detalhe (tam. G) | M7 | AG02 | a fazer |
| T-232 | Upgrade de Componentes com Moeda (lógica e tela) (tam. M) | M7 | AG04 + AG02 | a fazer |
| T-233 | Resultado e baú mostram os Componentes ganhos (tam. P) | M7 | AG02 | a fazer |
| T-234 | Balanceamento com Componentes (simulação do bot) (tam. P) | M7 | AG04 | a fazer |
| T-235 | Validação e fechamento da v0.2.5 (tag) (tam. P) | M7 | AG03 + AG00 | a fazer |
| T-236 | Mockup da tela de configurações (tam. P) | M8 | AG08 | a fazer |
| T-237 | Configurações no save: volume de música e efeitos, sons ligados, efeitos reduzidos (sai do `debug.cfg`), idioma (tam. P) | M8 | AG05 + AG07 | a fazer |
| T-238 | Barramentos de áudio Música e Efeitos ligados ao volume (tam. P) | M8 | AG11 + AG07 | a fazer |
| T-239 | Tela de configurações (no hangar e na pausa) (tam. M) | M8 | AG02 | a fazer |
| T-240 | Infra de localização: tradução por chaves em todos os textos, só pt-BR por enquanto (os outros idiomas ficam na T-241, M8); toda tela nova do M3 em diante já nasce com chaves (tam. G) | M3 | AG07 + AG02 | a fazer |
| T-241 | Tradução para inglês e espanhol, com glossário dos nomes oficiais (tam. M) | M8 | AG02 | a fazer |
| T-242 | Layout com textos longos (espanhol) e fontes com acentos; teste de corte (tam. P) | M8 | AG02 | a fazer |
| T-243 | Idioma do navegador como padrão (tam. P) | M8 | AG02 | a fazer |
| T-244 | Validação e fechamento da v0.2.6 (tag) (tam. P) | M8 | AG03 + AG00 | a fazer |
| T-245 | Roteiro do onboarding: 4 tutoriais, gatilhos, pular (tam. P) | M9 | AG04 | a fazer |
| T-246 | Sistema de tutorial: passos em dados, destaque, mão apontando, progresso salvo (tam. G) | M9 | AG02 + AG07 | a fazer |
| T-247 | Tutorial do início de jogo (1ª partida: ataque automático, upgrades, foco) (tam. M) | M9 | AG02 + AG01 | a fazer |
| T-248 | Tutoriais de equipar Núcleo, Módulo e Componente (tam. M) | M9 | AG02 | a fazer |
| T-249 | Arte do tutorial: mão, balões, destaque (tam. P) | M9 | AG08 | a fazer |
| T-250 | Textos dos tutoriais em português, inglês e espanhol (tam. P) | M9 | AG02 | a fazer |
| T-251 | Validação com jogador novo e fechamento da v0.2.7 (tag) (tam. P) | M9 | AG03 + AG00 | a fazer |
| T-252 | Design das 5 fases: tipos de fase, inimigos por fase, curva de dificuldade (tam. M) | M10 | AG12 | a fazer |
| T-253 | Novos inimigos (3 a 4 arquétipos) (tam. G) | M10 | AG01 | a fazer |
| T-254 | Arte dos novos inimigos (tam. G) | M10 | AG08 | a fazer |
| T-255 | Chefe 2 (tam. M) | M10 | AG01 | a fazer |
| T-256 | Chefe 3 (tam. M) | M10 | AG01 | a fazer |
| T-257 | Arte dos chefes 2 e 3 (tam. M) | M10 | AG08 | a fazer |
| T-258 | Cenários das fases 2 a 5 (tam. G) | M10 | AG08 | a fazer |
| T-259 | Ondas das 5 fases em dados (tam. M) | M10 | AG12 | a fazer |
| T-260 | Seleção e progressão de fases (mapa, desbloqueio, save) (tam. M) | M10 | AG02 + AG04 + AG05 | a fazer |
| T-261 | Recompensas durante a partida nas fases novas (revisar a T-222) (tam. P) | M10 | AG04 | a fazer |
| T-262 | VFX dos novos inimigos e chefes (tam. M) | M10 | AG09 | a fazer |
| T-263 | Balanceamento das 5 fases (bot e playtest) (tam. M) | M10 | AG12 + AG04 | a fazer |
| T-264 | Polimento de gráficos, efeitos e gameplay (lista do playtest) (tam. G) | M10 | AG01 + AG02 + AG09 | a fazer |
| T-265 | Desempenho no iPhone com o conteúdo novo (tam. M) | M10 | AG01 + AG10 | a fazer |
| T-266 | Validação e fechamento da v0.3.0: tag, branch `beta` e deploy em `beta--projectanimagame.netlify.app` (tam. M) | M10 | AG03 + AG00 + AG10 | a fazer |
| T-267 | Envio de logs: contrato da API, esquema da tabela (`logs`), limites e ADR (decisão 58) (tam. P) | M1 | AG05 | feita (BRF-087) |
| T-268 | Netlify Function `POST /api/log` gravando no Neon: validação, limite de tamanho, chave de cliente, limite por IP, limpeza em 30 dias; testes (tam. M) | M1 | AG05 | feita (BRF-087) |
| T-269 | Botão "Enviar log" no Resultado (só em build de teste): aviso do que é enviado, estados enviando/enviado/falhou, texto por chave de tradução (tam. P) | M1 | AG02 | feita (BRF-088) |
| T-270 | Deploy do envio: variáveis de ambiente no Netlify, CORS, flag de build de teste, `docs/` com a conta Neon (o dono cria a conta e passa a string de conexão) (tam. P) | M1 | AG10 | feita (BRF-089); falta deploy |
| T-271 | Validação do envio no PC e no iPhone (log chega na tabela; falha de rede não trava o jogo) (tam. P) | M1 | AG03 | feita (BRF-097, passa; relatório em docs/qa/qa-T-271.md; falta iPhone real e 429) |
| T-272 | Design da aceleração (x1 e x2): a velocidade não é reduzida sozinha (pausa, hit-stop e Resultado respeitam a escolhida), vale em toda a sessão; definir o escopo da sessão (só a partida ou até fechar o app) e a recompensa por monstros derrotados, não por tempo; deixar o ponto de extensão para travas futuras; registrar em `docs/gameplay.md` (tam. P) | M2 | AG01 | a fazer |
| T-273 | Controlador de velocidade (`Engine.time_scale`): alterna x1/x2, **mantém** a escolha em pausa, hit-stop (restaura para a escolhida) e Resultado; bot/headless em x1; testes GUT (tam. M) | M2 | AG01 | a fazer |
| T-274 | Arte do botão de velocidade: estados x1 e x2 (tam. P) | M2 | AG08 | a fazer |
| T-275 | Botão de velocidade no HUD (toque e tecla no PC via Input Action, sem atrapalhar as skills; mostra a velocidade atual) (tam. M) | M2 | AG02 + AG07 | a fazer |
| T-276 | Medir o x2 no iPhone com a cena de estresse (T-006/T-118) e registrar o fps (tam. P) | M2 | AG01 + AG10 | a fazer |
| T-277 | Fundo holográfico na tela de Resultado: preparar a arte do dono (corte retrato 9:16, peso baixo, sem texto ilegível sob os botões) e aplicar no `result_screen`, com painéis e textos legíveis sobre ele (tam. M) | M1 | AG08 + AG02 | feita (BRF-092, BRF-093); falta ver no iPhone |
| T-278 | Arte do fundo paisagem para PC: preparar as 2 artes do dono (retocar bateria e textos miúdos, peso baixo, 16:9 e telas mais largas/estreitas) (tam. P) | M1 | AG08 | feita (BRF-096); artes guardadas, sem uso |
| T-279 | ~~Fundo paisagem no shell Web~~ | M1 | — | cancelada (decisão 61; shell revertido) |
| T-280 | ~~Jogo avisa o shell qual fundo usar~~ | M1 | — | cancelada (decisão 61: um fundo só) |
| T-281 | Tela inicial: subtítulo vermelho **VERTICAL SLICE** (maiúsculas) entre "ANIMA" e o botão, e remover o link "Último log" (temporário na v0.1.0; tam. P) | M1 | AG02 | feita (BRF-099) |
| T-282 | **(1ª do M2)** Remover o subtítulo "VERTICAL SLICE" da tela inicial (tam. P) | M2 | AG02 | feita (BRF-104) |
| T-283 | **(fim do M2)** Subtítulo vermelho **ALFA** na tela inicial, como o do vertical slice, até o fechamento da v0.2.0 (tam. P) | M2 | AG02 | a fazer |
| T-284 | Deploy por tag: qualquer tag builda e publica num alias do Netlify + GitHub Release (decisão 62) (tam. M) | M1 | AG10 | feita |
| T-285 | Versão exibida `v0.1.0` (tela inicial, pausa e log) e `config/version` no `project.godot` (tam. P) | M1 | AG07 | feita |
| T-286 | Botão "Debug" da pausa só aparece com `?debug` na URL (tam. P) | M1 | AG02 | feita |
| T-148 | Sinais da Arena para VFX (projectile_fired, projectile_hit, enemy_died, particles_gained, skill_cast, boss_telegraph_started, boss_phase_changed) | M1 | AG01 | feita |

## Próximas prontas p/ briefing

> **Decisão 21:** só o usuário libera briefings. A lista abaixo é sugestão; nada começa sem o OK dele.

1. **T-142** (AG08, novo guia + mockups PNG): caminho crítico da arte, dos VFX, da T-144 e da T-145; precisa da aprovação do usuário.
2. **T-143** (AG08, fonte da arte final): gera a decisão 34. Pode ir junto da T-142 no mesmo disparo.
3. **T-125** (AG01 + AG08, meteoro × onda de choque): libera a T-139.
4. **T-133** (AG04, upgrades da partida): libera a T-134 e a T-135.
- Mockup aprovado: **A "Jardim Arcano"** (decisão 36). A HUD deve ter a fileira de upgrades (decisão 35); a T-145 e a T-128 devem considerá-la.
- Também prontas: **T-146** (AG07), **T-140** (AG01), **T-136** (AG02), **T-123** e **T-115** (AG01), **T-107** e **T-006** (AG02).

## Paralelismo e conflitos

- **Feito até aqui:** M0 e o núcleo do M1 (T-101 a T-108, T-111 a T-114, T-121, T-122).
- **Trilhas paralelas do M1 (demo):**
  - Arte: {T-142, T-143} → {T-127, T-128} (AG08, em sequência).
  - Refatorações do novo estilo: T-142 → T-144 (AG01, `src/match/`) e T-142 → T-145 (AG02, `src/ui/`).
  - VFX: T-124 → T-129 → T-130 → T-131 → T-132 (AG09; a T-124 é do AG07).
  - Upgrades: T-133 (AG04) → T-134 (AG01) → T-135 (AG02, HUD).
  - Combate: T-123, T-115, T-139, T-116, T-137 (AG01, em sequência; `skills/` × `enemies/` só em paralelo com duas sessões).
  - UI: T-136 → T-135 → T-138 (AG02, `src/ui/`, em sequência); T-107 e T-006 em outra sessão.
- **Não paralelizar:**
  - T-134 com T-139 ou T-116 (mesmo dono e `src/match/`);
  - T-135, T-136, T-138, T-141 e T-145 (mesma pasta `src/ui/`);
  - T-144 com outras tasks do AG01 em `src/match/`;
  - T-137 com outras tasks do AG01 que mexam nas cenas de `match/`;
  - T-117: as partes do AG01, AG09 e AG02 em briefings separados, cada uma nos seus arquivos.

---

## M0 — Fundação

### T-001 — Layers de colisão nomeadas
- **Marco:** M0 · **Dono:** AG07 · **Status:** feita
- **Depende de:** — · **Desbloqueia:** T-103
- **Arquivos:** `project.godot`
- **Pronto quando:**
  - layers 2D nomeadas: `anima`, `enemies`, `player_projectiles`, `enemy_projectiles`, `skill_areas`, `shield`;
  - tabela de layers e máscaras registrada em `docs/arquitetura.md`;
  - projeto abre sem erros.

### T-002 — Instalar GUT e teste smoke headless
- **Marco:** M0 · **Dono:** AG03 · **Status:** feita
- **Depende de:** — · **Desbloqueia:** T-114, T-120
- **Arquivos:** `addons/gut/`, `.gutconfig.json`, `tests/unit/test_smoke.gd`
- **Pronto quando:**
  - versão do GUT compatível com Godot 4.7.2 instalada;
  - o comando headless do `CLAUDE.md` roda e passa 1 teste smoke;
  - comandos repassados ao AG00 para o `CLAUDE.md`; `project.godot` não é alterado.
- **Briefing:** BRF-004

### T-003 — `docs/ui.md`
- **Marco:** M0 · **Dono:** AG02 · **Status:** feita
- **Depende de:** — · **Desbloqueia:** T-106, T-112, T-113
- **Arquivos:** `docs/ui.md`
- **Pronto quando:** tokens (cores, tipografia, espaçamento), layout em retrato com safe area, posição dos botões de skill e fluxo de telas do M1 documentados.
- **Briefing:** BRF-002

### T-004 — Preset Web + HTML shell mínimo
- **Marco:** M0 · **Dono:** AG02 · **Status:** feita
- **Depende de:** requisitos técnicos do AG07 (Compatibility, sem threads) · **Desbloqueia:** T-005, T-006, T-107
- **Arquivos:** `export_presets.cfg`, `web/`
- **Pronto quando:**
  - preset "Web": Compatibility, Thread Support desligado;
  - shell com meta viewport sem zoom, `touch-action: none` e bloqueio de gestos do Safari;
  - `--export-release "Web"` gera `build/web/index.html` sem erros; tamanho do build medido.
- **Briefing:** BRF-005

### T-005 — Build vazio no Chrome PC e no iPhone
- **Marco:** M0 · **Dono:** AG02 · **Status:** feita (o dono testou o build no iPhone; o jogo já roda lá desde o protótipo)
- **Depende de:** T-004, T-008 · **Desbloqueia:** T-007
- **Situação:** build no ar em dev--projectanimagame.netlify.app e conferido no PC; falta o teste do usuário no iPhone.
- **Arquivos:** `web/`, `docs/setup.md` (seção de deploy de teste, com autorização)
- **Pronto quando:**
  - build abre no Chrome do PC sem erros no console;
  - checklist rodado pelo usuário no iPhone: carrega, toque responde, sem zoom/scroll, retrato ok;
  - procedimento de deploy de teste documentado.

### T-006 — Cena de estresse para confirmar metas
- **Marco:** M0 · **Dono:** AG02 · **Status:** feita no PC; falta medir no iPhone
- **Depende de:** T-004 (T-005 para medir no iPhone) · **Desbloqueia:** T-007, T-118
- **Arquivos:** `tests/perf/` (cena isolada, sem lógica de jogo)
- **Pronto quando:** cena com ~150 sprites móveis e ~300 projéteis em pool roda no build Web; fps medido no PC e no iPhone e registrado.

### T-007 — ADR das metas de desempenho e da exportação single-threaded
- **Marco:** M0 · **Dono:** AG07 · **Status:** a fazer
- **Depende de:** T-002, T-005, T-006 · **Desbloqueia:** fechamento do M0
- **Arquivos:** `docs/adr/`
- **Pronto quando:** ADR com as medições de T-005/T-006, metas de fps e tamanho confirmadas ou ajustadas e recomendação sobre a decisão #4; o AG00 usa a ADR para atualizar `decisoes.md` e a Bíblia.

### T-008 — Deploy automático Web (GitHub Actions → Netlify)
- **Marco:** M0 · **Dono:** AG02 · **Status:** feita
- **Depende de:** T-004 · **Desbloqueia:** T-005
- **Arquivos:** `.github/workflows/deploy-web.yml`
- **Pronto quando:** push em `dev` publica em dev--projectanimagame.netlify.app; push em `main` publica em projectanimagame.netlify.app.
- **Briefing:** BRF-006, BRF-007
- **Obs.:** entregue fora do backlog e registrado depois.

---

## M1 — Demo do combate

### T-101 — `docs/gameplay.md`
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** — · **Desbloqueia:** T-103, T-112
- **Arquivos:** `docs/gameplay.md`
- **Pronto quando:** pilares, loop, parâmetros do Anima e do ataque, 3 skills, 4 arquétipos, chefe, formato dos dados de onda e **lista de sinais expostos à UI** documentados (modelo AG01 §5).
- **Briefing:** BRF-003

### T-102 — Autoload de fluxo de cenas
- **Marco:** M1 · **Dono:** AG07 · **Status:** feita
- **Depende de:** T-001 (mesmo `project.godot`) · **Desbloqueia:** T-113
- **Arquivos:** `src/core/`, `project.godot` (autoload, cena principal)
- **Pronto quando:** autoload troca entre Toque para começar → Partida → Resultado com cenas placeholder; partida recebe config e devolve resultado (sem `meta/` nem `backend/`).

### T-103 — Protótipo cinza: arena, Anima, 1 inimigo
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-001, T-101 · **Desbloqueia:** T-104
- **Arquivos:** `src/match/arena/`, `src/match/anima/`, `src/match/enemies/`, `data/enemies/enemy_runner.tres`
- **Pronto quando:** arena em retrato; Anima fixo no centro; inimigo corredor nasce na borda, anda até o centro e causa dano ao Núcleo; valores vêm de `.tres`.

### T-104 — Ataque automático com pool
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-103 · **Desbloqueia:** T-105
- **Arquivos:** `src/match/anima/`, `src/match/projectiles/`, `data/`
- **Pronto quando:** mira no inimigo mais próximo/prioritário; projéteis reutilizados por pool (sem instanciar por tiro); dano e morte do inimigo funcionam.
- **Decisão:** projéteis inimigos sem ciano.

### T-105 — Ondas por dados, HP do Núcleo, moedas, vitória/derrota
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-104 · **Desbloqueia:** T-108, T-111, T-112, T-114
- **Arquivos:** `src/match/waves/`, `src/match/arena/`, `data/waves/`
- **Pronto quando:** spawner lê ondas de `.tres` (3 ondas de teste); sinais de HP, `Wave X/Y`, moedas e fim de partida emitidos; HP zero = derrota; última onda = vitória.

### T-106 — Tema base e componentes de UI
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** T-003 · **Desbloqueia:** T-112, T-113, T-121
- **Arquivos:** `src/ui/theme/`, `src/ui/components/`
- **Pronto quando:** tema base aplicado; botão, barra de vida e botão de skill com cooldown visual funcionam com toque, mouse e Input Actions; cena de demonstração.
- **Decisão:** fonte Outfit.

### T-107 — Overlay de debug Web
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita (com gravador de logs e botão Logs, BRF-063)
- **Depende de:** T-004 · **Desbloqueia:** T-118
- **Arquivos:** `src/ui/debug/`
- **Pronto quando:** FPS, contagem de nós e últimos logs visíveis na tela; liga/desliga por Input Action; fora dos builds release ou desligado por padrão.

### T-108 — Base de skills + skill de área
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-105 · **Desbloqueia:** T-109 (M2), T-139
- **Arquivos:** `src/match/skills/`, `data/skills/`
- **Pronto quando:** sistema de skill com cooldown acionado por Input Action (slot 1); skill de área causa dano na região; sinais de cooldown para a UI.
- **Decisão:** slots de skill numerados a partir de 1 (1-based).

### T-109 — Skill de controle
- **Marco:** M2 (movida do M1, decisão #28) · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-108 · **Desbloqueia:** T-110
- **Arquivos:** `src/match/skills/`, `data/skills/`
- **Pronto quando:** slot 2 (desbloqueado por nível de conta) aplica lentidão/atordoamento em área; efeito visível e com duração por dados.

### T-110 — Skill de defesa
- **Marco:** M2 (movida do M1, decisão #28) · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-109 · **Desbloqueia:** —
- **Arquivos:** `src/match/skills/`, `data/skills/`
- **Pronto quando:** slot 3 (desbloqueado por nível de conta) protege o Núcleo (escudo ou invulnerabilidade) por tempo definido em dados.

### T-111 — Arquétipos: tanque, atirador, enxame
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-105 · **Desbloqueia:** T-115, T-116
- **Arquivos:** `src/match/enemies/`, `data/enemies/`, `src/match/projectiles/` (projétil inimigo)
- **Pronto quando:** 3 novos arquétipos com comportamento distinto; atirador usa pool de projéteis inimigos; todos por `.tres`.
- **Decisão:** projéteis inimigos sem ciano.

### T-112 — HUD ligado aos sinais
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** T-101, T-105, T-106 (sinais de skill de T-108 podem ser simulados) · **Desbloqueia:** T-117
- **Arquivos:** `src/ui/hud/`
- **Pronto quando:** HP do Núcleo, `Wave X/Y`, moedas, pausa e 3 botões de skill reagem só por sinais; funciona em retrato com safe area.

### T-113 — Telas: toque para começar, pausa, resultado
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** T-102, T-106, T-112 (mesma pasta), T-121, T-122 · **Desbloqueia:** T-120
- **Arquivos:** `src/ui/screens/`
- **Pronto quando:** toque para começar libera o áudio; pausa manual e ao perder o foco da aba; resultado de vitória/derrota com moedas e "Jogar de novo".
- **Nota:** ouvir só um aviso de pausa (evitar pausa duplicada entre a pausa manual e a perda de foco).

### T-114 — Testes GUT de ondas, dano e cooldowns
- **Marco:** M1 · **Dono:** AG03 · **Status:** feita
- **Depende de:** T-002, T-105 (cooldown após T-108) · **Desbloqueia:** T-120
- **Arquivos:** `tests/unit/`, `tests/integration/`
- **Pronto quando:** testes cobrem leitura de ondas, dano/HP do Núcleo, vitória/derrota e cooldown; rodam headless e passam.

### T-115 — Chefe da fase 1
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-111 · **Desbloqueia:** T-116, T-127 (arte do chefe), T-131
- **Arquivos:** `src/match/enemies/boss/`, `data/enemies/boss_*.tres`
- **Pronto quando:** chefe com fases por vida, ao menos 2 padrões de ataque e aviso visual (telegraph) antes de cada padrão; vencível com 1 skill + upgrades da partida.

### T-116 — Fase 1 completa
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-111, T-115, T-134, T-139 · **Desbloqueia:** T-117, T-118, T-120
- **Arquivos:** `data/waves/stage_01*`
- **Pronto quando:** ~10 ondas + chefe; partida de 3–10 min; curva de dificuldade descrita em `docs/gameplay.md`.
- **Nota:** o balanceamento conta com **1 skill (slot 1) + upgrades da partida** (decisões #27 e #28); os valores de upgrade vêm da T-133.

### T-117 — Game feel
- **Marco:** M1 · **Dono:** AG01 + AG09 (com AG02 no HUD) · **Status:** a fazer
- **Depende de:** T-112, T-116, T-130 · **Desbloqueia:** T-120
- **Arquivos:** AG01: `src/match/` · AG09: `src/fx/` · AG02: `src/ui/hud/` (cada parte em briefing próprio, sem paralelo nos mesmos arquivos)
- **Pronto quando:**
  - AG01: tremor de câmera, hit-stop, números de dano e sinais de feedback;
  - AG09: flash de acerto e feedback visual de skill pronta/usada, via pool;
  - sem alocação por frame; nível de demo aprovado pelo usuário.

### T-118 — Desempenho no iPhone
- **Marco:** M1 · **Dono:** AG01 (medição com AG03) · **Status:** pool e modo de estresse feitos; falta medir no iPhone
- **Depende de:** T-006, T-107, T-116, T-132 · **Desbloqueia:** T-120
- **Arquivos:** `src/match/`
- **Pronto quando:** média ≥ 45 fps no iPhone 11 Pro com 150 inimigos vivos (meta revisada na T-007, aprovada pelo dono em 2026-11-06); medições registradas em `docs/perf.md`.
- **Proposta (AG01):** pool de inimigos (reutilizar instâncias em vez de instanciar/liberar por spawn).

### T-119 — Otimização do build Web
- **Marco:** M1 · **Dono:** AG02 · **Status:** a fazer
- **Depende de:** T-113, T-116 · **Desbloqueia:** T-120
- **Arquivos:** `export_presets.cfg`, `web/`
- **Pronto quando:** download inicial ≤ ~15 MB (ou meta revisada); tela de carregamento na estética do jogo; primeiro frame < 5 s em 4G (estimado).

### T-120 — Validação do M1
- **Marco:** M1 · **Dono:** AG03 · **Status:** a fazer
- **Depende de:** T-113, T-114, T-116, T-117, T-118, T-119, T-131, T-132, T-135, T-136, T-137, T-138 · **Desbloqueia:** fechamento do M1
- **Arquivos:** `docs/qa/QA-001_m1.md`
- **Pronto quando:** checklist AG03 §5 executado (partida completa, simulação de 5 min, build medido, checklist do iPhone para o usuário); **qualidade visual de demo** conferida contra `docs/arte.md` e `docs/vfx.md` (arte final em tudo, sem placeholder, efeitos reduzidos funcionando); veredito passa/não passa.

### T-121 — Tema global no `project.godot`
- **Marco:** M1 · **Dono:** AG07 · **Status:** feita
- **Depende de:** T-106 · **Desbloqueia:** T-112, T-113
- **Arquivos:** `project.godot`
- **Pronto quando:** o tema base do AG02 é o tema global do projeto; telas existentes abrem com a fonte Outfit sem erros.

### T-122 — Ligar a arena real ao SceneFlow
- **Marco:** M1 · **Dono:** AG07 · **Status:** feita
- **Depende de:** T-102, T-103 · **Desbloqueia:** T-113
- **Arquivos:** `src/core/`
- **Pronto quando:** o SceneFlow abre a arena real (no lugar do placeholder), chama `setup(config)` e vai para o Resultado ao receber `match_ended`.
- **Notas:** chamar `hud.bind(arena)` antes de a arena entrar na árvore; `DEFAULT_MATCH_SCENE` ainda aponta para o placeholder.
- **Contrato de montagem (`docs/ui.md` §10c):** montar HUD + PauseScreen junto da arena; chamar `bind` antes de a arena entrar na árvore; ligar `restart_requested` → `start_match`.

### T-123 — Seed no `Arena._rng` para testes determinísticos
- **Marco:** M1 · **Dono:** AG01 · **Status:** pronta p/ briefing
- **Depende de:** T-105 · **Desbloqueia:** T-120 (simulação reproduzível)
- **Arquivos:** `src/match/arena/`
- **Pronto quando:** a arena aceita uma seed (por exemplo, via `setup(config)`); com a mesma seed, duas execuções geram os mesmos spawns; os testes do AG03 podem fixá-la.
- **Origem:** sugestão do AG03.

### T-124 — Pasta `src/fx/` em `docs/estrutura.md`
- **Marco:** M1 · **Dono:** AG07 · **Status:** feita
- **Depende de:** — · **Desbloqueia:** T-129
- **Arquivos:** `docs/estrutura.md`, `src/fx/.gitkeep`
- **Pronto quando:** `src/fx/` (efeitos, shaders, pool), `assets/ui/` e `assets/backgrounds/` documentados; regra de dependência definida (`fx/` reage a sinais e não altera o estado de `match/`).

### T-142 — Novo guia de estilo 2D cartoon 3/4 + mockups PNG
- **Marco:** M1 · **Dono:** AG08 · **Status:** feita
- **Depende de:** decisões 31–33 · **Desbloqueia:** T-127, T-128, T-129, T-144, T-145
- **Arquivos:** `docs/arte.md` (reescrever), `assets/backgrounds/` (mockups), `assets/LICENSES.md`
- **Pronto quando:** guia com paleta (clara e saturada, mantendo a regra ciano = jogador), contorno, sombra, proporções, perspectiva 3/4, núcleo-Anima, silhuetas por arquétipo e molduras por raridade; 2 mockups renderizados em **PNG** 720×1280 (arena com HUD); nada copiado de jogos existentes; **aprovado pelo usuário**.

### T-143 — Pipeline e fonte da arte final
- **Marco:** M1 · **Dono:** AG08 · **Status:** feita
- **Depende de:** — · **Desbloqueia:** decisão 34, T-127, T-128
- **Arquivos:** seção em `docs/arte.md`
- **Pronto quando:** comparadas as opções (gerada pelos agentes, pacotes CC0/pagos 2D cartoon, IA de imagem, artista) em qualidade, custo, prazo e licença; formato técnico definido (PNG, resolução, atlas, escala); recomendação para o usuário decidir.

### T-144 — Arena em 3/4
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-142 · **Desbloqueia:** T-137
- **Arquivos:** `src/match/`, `docs/gameplay.md`, testes em `tests/`
- **Pronto quando:** ordenação por Y, sprites ancorados na base, sombra no chão, área de spawn e limites adaptados à perspectiva; colisões no plano do chão; testes passando.

### T-145 — Retema da UI no estilo cartoon
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** T-142 · **Desbloqueia:** T-138
- **Arquivos:** `docs/ui.md`, `src/ui/theme/`, `src/ui/components/`, `assets/fonts/`
- **Pronto quando:** tokens e tema refeitos (botões grandes com contorno e sombra, painéis com moldura, cores por raridade); fonte arredondada OFL avaliada; HUD e telas atuais continuam funcionando.

### T-146 — Remover mockups rejeitados e excluir referências do export Web
- **Marco:** M1 · **Dono:** AG07 · **Status:** feita
- **Depende de:** — · **Desbloqueia:** —
- **Arquivos:** `assets/backgrounds/mockup_arena*.svg`, `assets/LICENSES.md`, `export_presets.cfg`
- **Pronto quando:** mockups A/B removidos; filtro do preset Web exclui mockups e referências; export e testes OK.

### T-149 — Barra de vida sobre os inimigos
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** decisão 38 · **Desbloqueia:** —
- **Pronto quando:** cada inimigo comum mostra uma barra pequena sobre ele (verde ≥ 60%, amarela < 60%, vermelha ≤ 30%), sem alocar por quadro e sem custo relevante com 150 inimigos.

### T-150 — Chefe ogro
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** decisão 39 · **Desbloqueia:** T-131 (VFX do chefe), T-152
- **Pronto quando:** um só ataque corpo a corpo, sem minions; barra de defesa sobre ele como escudo na frente da vida; ao esgotar a defesa ou ao ser atingido pelo meteoro, é lançado para trás em direção à borda; fase 1 continua vencível (~60% no bot).

### T-151 — Arte do chefe ogro
- **Marco:** M1 · **Dono:** AG08 · **Status:** feita
- **Depende de:** decisão 39 · **Desbloqueia:** T-150 (aplicação da arte)

### T-152 — Barra "Boss" no HUD
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** decisão 39 (usa `boss_hp_changed`, já existente) · **Desbloqueia:** —
- **Pronto quando:** barra vermelha grande no topo da tela com o rótulo "Boss", de tamanho próximo ao da barra do Núcleo; aparece só quando o chefe entra.

### T-153 — Arte das pílulas do topo e do botão secundário
- **Marco:** M1 · **Dono:** AG08 · **Status:** pronta p/ briefing
- **Depende de:** — · **Desbloqueia:** aplicação pelo AG02 (parte de T-138)
- **Arquivos:** `assets/ui/`, `assets/LICENSES.md`
- **Pronto quando:** PNGs 2x no estilo do HUD para a pílula "ONDA x/y", a pílula de Partículas (com a estrela) e o botão secundário (branco), em 9-patch com margens documentadas; hoje essas peças são `StyleBoxFlat` por código.

### T-154 — Texto "MAX" na pílula de custo
- **Marco:** M1 · **Dono:** AG08 + AG02 · **Status:** pronta p/ briefing
- **Depende de:** — · **Desbloqueia:** —
- **Arquivos:** `assets/ui/` (AG08), `src/ui/components/upgrade_button.gd` (AG02)
- **Pronto quando:** o README e o PNG de `ui_upgrade_cost_pill_max` ficam de acordo (ou a pílula sem texto, ou com "MAX"); a UI não desenha o texto duas vezes.

### T-155 — Voltar ao título a partir do Resultado
- **Marco:** M1 · **Dono:** AG02 + AG07 · **Status:** feita
- **Depende de:** — (o Resultado hoje só tem "Jogar de novo") · **Desbloqueia:** —
- **Arquivos:** `src/ui/screens/` (AG02), `src/core/scene_flow.gd` (AG07)
- **Pronto quando:** o Resultado oferece também "Voltar ao título" (botão secundário), o fluxo muda para a cena de título sem reiniciar o jogo e sem vazar a partida; testes de fluxo.

### T-156 — Chão sem repetição visível
- **Marco:** M1 · **Dono:** AG08 + AG01 · **Status:** dispensada do M1 (dono, 2026-11-06)
- **Depende de:** T-158 (se o repetir a cada 240 px incomodar) · **Desbloqueia:** —
- **Arquivos:** `assets/backgrounds/` (AG08), `src/match/arena/arena_floor.gd` (AG01)
- **Pronto quando:** as pedrinhas do `floor_tile` deixam de formar padrão visível (tile maior de 8×8 ou pedrinhas espalhadas por código com a semente da arena), sem custo relevante de memória.

### T-157 — Escurecimento do topo
- **Marco:** M1 · **Dono:** AG02 + AG01 · **Status:** depende do teste no iPhone
- **Depende de:** T-158 · **Desbloqueia:** —
- **Arquivos:** `src/ui/hud/` (AG02), `src/match/arena/arena_floor.gd` (AG01)
- **Pronto quando:** o degradê do chão (`floor_top_shade`) e o do HUD (`TOP_SCRIM_ALPHA`) somam um escurecimento que dá leitura sem esconder o chão; um só dono do valor.

### T-158 — Teste no iPhone
- **Marco:** M1 · **Dono:** usuário + AG00 · **Status:** a fazer
- **Depende de:** deploys da dev concluídos · **Desbloqueia:** T-156, T-157, T-118
- **Pronto quando:** testado no iPhone: carregamento (splash em celular, incluindo o corte à direita visto na captura), título, partida, upgrades, meteoro, chefe e Resultado; lista de ajustes entregue ao AG00.

### T-159 — Ícone do meteoro como padrão no HUD
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** — · **Desbloqueia:** —
- **Arquivos:** `src/ui/`
- **Pronto quando:** o ícone do meteoro vem de uma fonte única (hoje por caminho no HUD, ver `Hud.slot_icon_paths`); o `ui_icon_skill_pulse.png` e o `skill_pulse` provisório deixam de aparecer no jogo e nas demos; o número de recarga continua legível sobre o ícone (que ocupa pouco do quadro de 88 px).

### T-160 — Ícone de Partículas verde
- **Marco:** M1 · **Dono:** AG08 · **Status:** feita
- **Depende de:** decisão 40 · **Desbloqueia:** T-161
- **Arquivos:** `assets/ui/`, `assets/LICENSES.md`
- **Pronto quando:** estrela de 4 pontas **verde** em estilo "chipzinho" (contorno escuro, brilho), legível a 24–32 px, **diferente do verde da barra de vida dos inimigos** e sem ciano; paleta de coleta definida para o AG09.

### T-161 — Partículas em verde na UI e nos efeitos
- **Marco:** M1 · **Dono:** AG02 + AG09 · **Status:** feita
- **Depende de:** T-160 · **Desbloqueia:** —
- **Arquivos:** `src/ui/` (AG02), `src/fx/` (AG09)
- **Pronto quando:** o HUD, o Resultado, o custo dos botões de upgrade e o efeito de coleta usam a estrela verde (`UiTokens.PARTICLES` deixa de ser dourado); nenhuma Partícula cai no mapa.

### T-162 — Ícone de Moeda dourada
- **Marco:** M2 · **Dono:** AG08 · **Status:** a fazer
- **Depende de:** decisão 40 · **Desbloqueia:** hangar e economia (M2)

### T-163 — Nomes oficiais nos textos e nos docs
- **Marco:** M2 · **Dono:** AG00 + AG04 + AG02 · **Status:** a fazer
- **Depende de:** T-164 (decisão 41 resolveu a colisão de "Núcleo") · **Desbloqueia:** hangar e telas de meta
- **Pronto quando:** textos e docs usam Módulo, Fragmento, Núcleo (talento) e Moeda onde hoje dizem skill, módulo, talento e Gold; identificadores de código inalterados.

### T-164 — Rótulo "ENERGIA"
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** decisão 41 · **Desbloqueia:** T-163
- **Arquivos:** `src/ui/`, `docs/ui.md`, `tests/` (da UI)
- **Pronto quando:** a barra de vida do Anima mostra "ENERGIA x / y" (e qualquer texto ao jogador que diga "Núcleo" para a vida do Anima); identificadores de código inalterados; testes e demos ajustados.

### T-165 — Build no cabeçalho do log
- **Marco:** M1 · **Dono:** AG07 + AG02 · **Status:** pronta p/ briefing
- **Pronto quando:** o cabeçalho do log mostra a versão e o commit (SHA curto) do build, injetados no deploy (GitHub Actions) ou lidos de um arquivo gerado; localmente aparece "dev local". Hoje "versão" e "build" saem vazios.

### T-166 — Chefe sem defesa
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** decisão 42 · **Pronto quando:** `defense_max = 0` desliga a defesa (código e testes arquivados, documentados em `gameplay.md`); sem barra de defesa sobre o chefe; o meteoro o lança e o atordoa; vida do chefe e dano recalibrados com o bot e com o log real do iPhone.

### T-167 — Passos do chefe
- **Marco:** M1 · **Dono:** AG01 + AG08 · **Status:** feita
- **Pronto quando:** o ogro anda com balanço e passos no ritmo da velocidade (e quadros de caminhada do AG08), sombra acompanhando; não "desliza".

### T-168 — Círculo rúnico menor
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Pronto quando:** o selo do chão (`floor_ring`) fica a ~70% do tamanho atual, mais perto do totem do Anima.

### T-169 — Layout da bandeja e centralização
- **Marco:** M1 · **Dono:** AG02 + AG01 · **Status:** feita
- **Pronto quando:** a bandeja vai até a borda inferior (sem a faixa de cor de fundo), com pouco espaço sob os Módulos e a safe area respeitada; o Anima fica centralizado entre o topo do HUD e a bandeja; sem alteração de tamanho dos botões.

### T-170 — Logo do estúdio antes da splash
- **Marco:** M1 · **Dono:** AG02 (arte recortada pelo próprio agente a partir do arquivo do dono) · **Status:** feita
- **Pronto quando:** `web/shell.html` abre com tela preta e o logo "Anima Games" centralizado por ~1 s (sem atrasar o carregamento do jogo, que começa em paralelo), depois segue a splash atual; logo em `assets/branding/`.

### T-171 — Logo na tela de título
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Pronto quando:** a tela de título mostra o logo horizontal "Anima Games" pequeno, centralizado na parte de baixo (acima da safe area); o crédito "Criado por Marçal Santarem" foi removido.

### T-172 — Canvas até a borda inferior no iPhone
- **Marco:** M1 · **Dono:** AG02 · **Status:** pronta p/ briefing
- **Pronto quando:** no iPhone o canvas cobre a tela até a borda inferior (sem faixa de cor atrás), a safe area inferior não é somada duas vezes (a bandeja deixa pouco espaço sob os Módulos) e o cabeçalho do log traz as medidas de viewport para confirmar.

### T-173 — Meteoro acerta mais
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Evidência (log do iPhone, partida de 3:59):** dos 6 meteoros contra a horda, **2 acertaram 0 inimigos** (1:08 e 3:22, alvo perto do Anima, onde os inimigos já morreram antes do impacto) e 1 acertou 1; os outros acertaram 3, 9 e 9.
- **Pronto quando:** o ponto de impacto é **reavaliado no fim do aviso** (antes da queda) escolhendo o maior grupo no raio; se não houver nenhum inimigo no raio no momento do impacto, o meteoro **não gasta o cooldown** (ou reembolsa a maior parte) ou re-mira para o inimigo mais próximo; teste e bot de simulação confirmando mais acertos por lançamento.

### T-174 — Ícones do app
- **Marco:** M1 · **Dono:** AG08 · **Status:** pronta p/ briefing
- **Pronto quando:** `apple-touch-icon` 180×180, ícones 192 e 512 (comum e maskable) e favicon 32/48, com o núcleo-Anima sobre o roxo do jogo, legíveis em tamanho pequeno.

### T-175 — Manifesto e modo app
- **Marco:** M1 · **Dono:** AG02 · **Status:** pronta p/ briefing
- **Depende de:** T-174 e T-172 (correção do viewport)
- **Pronto quando:** `manifest.webmanifest` (nome, `display: standalone`, retrato, cores), meta tags do iOS (`apple-mobile-web-app-capable`, status bar translúcida, título, ícone), arquivos copiados para o site no deploy (o export do Godot não copia arquivos extras de `web/`), sem service worker que cache versões antigas; no iPhone o jogo abre sem a barra do Safari.

### T-179 — Splash e título no estilo tecnológico
- **Marco:** M1 · **Dono:** AG02 (shell e cena de título) + AG08 (recorte, camadas e elementos de HUD) · **Status:** pronta p/ briefing. Arte limpa: `assets/splash/tech/tech_splash_clean.png`. Referência com texto: `assets/splash/tech/tech_splash_reference_with_text.jpg` (768×1376)
- **Depende de:** decisão 48; imagem do dono **sem o texto e sem a barra**, em resolução maior (≥ 1080×1920, com sobra em cima e embaixo para telas altas)
- **Arquivos:** `web/shell.html` (splash, inline/cópia no deploy), `src/ui/screens/title_screen.gd`, `assets/ui/` ou `assets/splash/`, `assets/LICENSES.md`
- **Pronto quando:** a splash de carregamento usa a arte como fundo (WebP leve, servido pelo deploy), com "PROJECT: ANIMA", a barra e a porcentagem **vivas** (progresso real), cristal com brilho pulsando e linhas de HUD animadas por código; a tela de título usa o mesmo visual, com o botão "Toque para começar" holográfico, o logo do estúdio e a versão; o logo preto do estúdio continua antes; transição suave (fade) do título para a partida cartoon; funciona em 720×1280 a 720×1560 e no modo app do iPhone; licença registrada ("arte do dono gerada no Google Gemini").

### T-180 — Guia "HUD holográfico" dos menus (1ª do M2)
- **Marco:** M2 (primeira tarefa) · **Dono:** AG08 · **Status:** a fazer (início do M2)
- **Depende de:** decisões 48 e 49; T-179 (mesma base visual)
- **Pronto quando:** `docs/arte.md` ganha a seção de menus holográficos (paleta, painéis, botões, molduras por raridade, tipografia, brilhos e animações baratas) e há 2 a 3 mockups em PNG (menu principal, Resultado com recompensa e subida de nível; o hangar fica para o M3), aprovados pelo dono; regras de desempenho no iPhone.

### T-181 — Ícones do app na identidade tecnológica
- **Marco:** M1 · **Dono:** AG08 (arte) + AG02 (deploy) · **Status:** feita
- **Depende de:** decisão 48 e T-179 (arte-base `assets/splash/tech/tech_splash_clean.png`); substitui os ícones da T-174
- **Arquivos:** `assets/app/` (mestre, derivados e gerador), `web/pwa/` (cópia via `web/copy_pwa.sh --sync-icons`), `web/pwa/manifest.webmanifest` (só se mudar cor), `assets/LICENSES.md`
- **Pronto quando:** ícone 1024 mestre e derivados (`apple-touch-icon` 180, 192, 512, maskable 512 e favicons 16/32/48/ico) com o **cristal holográfico ciano sobre o fundo azul-marinho** da arte do Gemini (recortado da arte ou redesenhado no mesmo estilo), legível a 48 px e no favicon; copiados para o deploy; README e licença atualizados; o dono reinstala o atalho para o iOS reler.

### T-182 — Áudio básico (M2)
- **Marco:** M2 · **Dono:** AG02 (música, volume, desbloqueio de áudio na web) + AG01 (som do tiro) · **Status:** a fazer
- **Pronto quando:** uma música toca na entrada (título) em loop e o tiro básico tem um som curto (variação leve de tom, limite de vozes simultâneas para não saturar); áudio só começa após o 1º toque (web/iOS); volume de música e efeitos salvo; sem sons de menu, botões, skills e demais efeitos (ficam para o M16); assets da T-194; assets próprios ou CC0 com licença registrada.

### T-183 — Fechar o M1 como v0.1.0
- **Marco:** M1 · **Dono:** AG00 (PR e tag) + AG02 (deploy) + AG07 (versão) · **Status:** a fazer (no fechamento do M1, quando o dono pedir)
- **Pronto quando:** `DEFAULT_VERSION` = `0.1.0`; PR `dev → main` com título/descrição no chat; tag `v0.1.0`; **sem branch** (decisão 55: a primeira branch fechada é a `alfa`, no M2).

### T-184 — Economia do M2
- **Marco:** M2 · **Dono:** AG04 · **Depende de:** decisões 25 e 40
- **Pronto quando:** `docs/economia.md` com a curva de XP dos níveis 1 a 30 (slots nos níveis 3, 7 e 12), XP e Moeda por partida (vitória, derrota, onda alcançada, chefe), sem gasto de Moeda no M2 (o 1º gasto é no M4); valores em `data/meta/*.tres`, prontos para o Remote Config.

### T-185 — Save local
- **Marco:** M2 · **Dono:** AG05 + AG07 · **Depende de:** —
- **Pronto quando:** autoload `Backend` com interface (carregar, salvar, zerar) e `LocalBackend` em `user://save.json` com campo de versão, migração e cópia de segurança se o arquivo vier corrompido; `PlayerProfile` (nível, XP, Moeda, configurações); persiste no IndexedDB da web após recarregar; ADR em `docs/`; testes GUT.

### T-186 — Lógica pura do meta em `src/meta/`
- **Marco:** M2 · **Dono:** AG04 · **Depende de:** T-184, T-185
- **Pronto quando:** funções puras em `src/meta/` (sem cena nem rede): `MatchResult` → XP e Moeda; aplicar XP com várias subidas de nível; slots liberados por nível; testes GUT dos limites.

### T-187 — Fluxo de cenas com menu
- **Marco:** M2 · **Dono:** AG07 · **Depende de:** T-185, T-186
- **Pronto quando:** o `SceneFlow` vai do Título ao Menu principal; "Jogar" monta o `MatchConfig` a partir do perfil; ao fim, aplica a recompensa, salva e mostra o Resultado; "Voltar" leva ao Menu; a partida continua sem falar com o backend.

### T-188 — Partida monta os slots pelo nível da conta
- **Marco:** M2 · **Dono:** AG01 · **Depende de:** T-187
- **Pronto quando:** `MatchConfig` traz os Módulos liberados; a arena aceita 0 a 3 slots; com 0, só o ataque básico (o 1º Módulo, meteoro, entra no nível 3); testes e simulação do bot atualizados.

### T-189 — Arte do menu holográfico
- **Marco:** M2 · **Dono:** AG08 · **Depende de:** T-180
- **Pronto quando:** sprites e 9-slices do menu na identidade holográfica, em `assets/ui/`, leves para o iPhone, com licença.

### T-190 — Tela do menu principal
- **Marco:** M2 · **Dono:** AG02 · **Depende de:** T-187, T-189, T-162
- **Pronto quando:** menu em retrato com Jogar em destaque, nível e barra de XP, saldo de Moeda e botão de som; funciona de 720×1280 a 720×1560, toque e mouse.

### T-191 — Resultado com recompensa
- **Marco:** M2 · **Dono:** AG02 + AG09 · **Depende de:** T-186, T-187
- **Pronto quando:** o Resultado mostra XP e Moeda ganhos contando, a barra de XP enchendo, a subida de nível com destaque e o aviso "slot liberado"; respeita os efeitos reduzidos.

### T-192 — HUD: slots bloqueados com o nível
- **Marco:** M2 · **Dono:** AG02 · **Depende de:** T-188
- **Pronto quando:** slot bloqueado com cadeado e "Nv 3/7/12"; slot vazio não reage ao toque.

### T-193 — Debug do meta
- **Marco:** M2 · **Dono:** AG02 + AG05 · **Depende de:** T-185
- **Pronto quando:** no overlay de debug: zerar save, +XP, +Moeda e definir nível; o log da partida registra nível, XP e Moeda antes e depois.

### T-194 — Assets de áudio do M2
- **Marco:** M2 · **Dono:** AG08 · **Depende de:** —
- **Pronto quando:** música curta de entrada em loop e 2 a 3 variações de tiro, em `.ogg` leves, com fonte e licença em `assets/LICENSES.md`.

### T-195 — Balanceamento da progressão
- **Marco:** M2 · **Dono:** AG04 · **Depende de:** T-186, T-188
- **Pronto quando:** relatório com as partidas necessárias para os níveis 3, 7 e 12 (alvo a definir com o dono); valores ajustados nos `.tres`.

### T-196 — Validação do M2
- **Marco:** M2 · **Dono:** AG03 · **Depende de:** todas do M2
- **Pronto quando:** veredito do AG03: ciclo jogar → ganhar → voltar sem erro, save sobrevive a recarregar e fechar no iPhone (Safari e modo app), áudio após o 1º toque, testes passando.

### T-197 — Fechar o M2 como v0.2.0
- **Marco:** M2 · **Dono:** AG00 + AG02 + AG07 · **Depende de:** T-196 e aval do dono
- **Pronto quando:** `DEFAULT_VERSION` = `0.2.0`; PR `dev → main` com título e texto no chat; tag `v0.2.0`; branch `alfa` criada da tag; o workflow publica a `alfa` em `alfa--projectanimagame.netlify.app`; nada mais é commitado nela.

### T-148 — Sinais da Arena para VFX
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-129 (lista em `docs/vfx.md`), T-139 (o `skill_cast` do meteoro) · **Desbloqueia:** T-130, T-131
- **Arquivos:** `src/match/`, `docs/gameplay.md`, `tests/` (da arena)
- **Pronto quando:** a Arena emite `projectile_fired(from, dir)`, `projectile_hit(at, target_kind)`, `enemy_died(at, archetype_id, cause)`, `particles_gained(at, amount)`, `skill_cast(slot, at, radius)`, `boss_telegraph_started(pattern_id, duration, at, radius)` e `boss_phase_changed(phase)`, sem custo por quadro; documentados e testados.

### T-147 — Anima com skin trocável
- **Marco:** M2 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-137 · **Desbloqueia:** skins (M4)
- **Arquivos:** `src/match/anima/`, `data/`
- **Pronto quando:** a aparência do Anima (sprite e cor dos projéteis) vem de um Resource; trocar de skin não exige mudar código.

### T-125 — Proposta da skill de área: meteoro × onda de choque
- **Marco:** M1 · **Dono:** AG01 + AG08 · **Status:** decidida pelo dono: meteoro de fogo (decisão 37)
- **Depende de:** — · **Desbloqueia:** T-139, T-128 (ícone), T-131
- **Arquivos:** `docs/gameplay.md` (seção da skill, AG01); esboço visual em `assets/` (AG08)
- **Pronto quando:** as 2 opções descritas (jogabilidade, leitura visual, custo de VFX no iPhone), com recomendação; **o usuário decide via AG00**.

### T-126 — Guia de estilo `docs/arte.md` + mockup da arena
- **Marco:** M1 · **Dono:** AG08 · **Status:** feita, **rejeitada** (substituída pela T-142)
- **Depende de:** — (alinhar com os tokens do `docs/ui.md`) · **Desbloqueia:** T-127, T-128, T-129
- **Arquivos:** `docs/arte.md`, mockup em `assets/backgrounds/`, `assets/LICENSES.md`
- **Pronto quando:** paleta, formas, silhuetas por arquétipo, tamanhos, nomes e checklist de asset documentados; mockup da arena em retrato com Anima, inimigos, projéteis e HUD; **aprovado pelo usuário**.

### T-127 — Arte do Anima, inimigos, chefe, projéteis e fundo
- **Marco:** M1 · **Dono:** AG08 · **Status:** feita
- **Depende de:** T-142, T-143 (o chefe também depende da T-115) · **Desbloqueia:** T-137
- **Arquivos:** `assets/sprites/`, `assets/backgrounds/`, `assets/LICENSES.md`
- **Pronto quando:** Anima, 4 arquétipos, chefe, projéteis (inimigos sem ciano) e fundo seguem o `docs/arte.md`; silhuetas distintas; tamanhos para 720×1280; licenças registradas.

### T-128 — Ícones e arte da UI
- **Marco:** M1 · **Dono:** AG08 · **Status:** feita
- **Depende de:** T-142, T-143, T-125 (ícone da skill), T-133 (ícones dos upgrades) · **Desbloqueia:** T-138
- **Arquivos:** `assets/ui/`
- **Pronto quando:** ícone da skill, cadeado dos slots, ícones dos upgrades, botões, barras e painéis no estilo do guia; legíveis no toque no iPhone.

### T-129 — `docs/vfx.md` + pool de efeitos
- **Marco:** M1 · **Dono:** AG09 · **Status:** feita
- **Depende de:** T-124, T-142 · **Desbloqueia:** T-130, T-131, T-132
- **Nota:** VFX no estilo cartoon (formas sólidas, contorno, cores vivas, poucas partículas).
- **Arquivos:** `docs/vfx.md`, `src/fx/`
- **Pronto quando:** catálogo de efeitos com os sinais de que cada um depende; pool de efeitos reutilizável (sem instanciar por evento), com teste ou cena de demonstração.

### T-130 — VFX do ataque, acertos e mortes
- **Marco:** M1 · **Dono:** AG09 · **Status:** a fazer
- **Depende de:** T-129 · **Desbloqueia:** T-117, T-132
- **Arquivos:** `src/fx/`, `assets/vfx/`
- **Pronto quando:** rastro/brilho do projétil, impacto e morte de inimigo via pool, ligados por sinais; custo medido no build Web.
- **Nota:** se faltar algum sinal em `match/`, pedir ao AG00 (vira task do AG01).

### T-131 — VFX da skill e do chefe
- **Marco:** M1 · **Dono:** AG09 · **Status:** a fazer
- **Depende de:** T-129, T-139, T-115 · **Desbloqueia:** T-132, T-120
- **Arquivos:** `src/fx/`, `assets/vfx/`
- **Pronto quando:** telegraph e impacto da skill escolhida; telegraphs e efeitos dos padrões do chefe; custo medido.

### T-132 — Modo de efeitos reduzidos
- **Marco:** M1 · **Dono:** AG09 · **Status:** a fazer
- **Depende de:** T-130, T-131 · **Desbloqueia:** T-118, T-120
- **Arquivos:** `src/fx/`
- **Pronto quando:** uma configuração reduz partículas, brilho e tremor sem perder a leitura dos telegraphs; ganho de fps medido.

### T-133 — Dados e balanceamento dos upgrades da partida
- **Marco:** M1 · **Dono:** AG04 · **Status:** feita
- **Depende de:** — · **Desbloqueia:** T-134, T-128
- **Arquivos:** `docs/meta.md` (seção de upgrades da partida)
- **Pronto quando:** os 5 upgrades (Atk power, Atk spd, Defesa, Vida máxima, Cooldown) com efeito por nível, nível máximo e curva de custo em Partículas documentados, com valores coerentes com as Partículas ganhas na fase 1 e com tetos que não quebrem o balanceamento (ex.: redução de cooldown).

### T-134 — Lógica dos upgrades em tempo real (5 atributos)
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-133, T-105, T-140 · **Desbloqueia:** T-135, T-116
- **Arquivos:** `src/match/upgrades/`, `data/upgrades/`
- **Pronto quando:** `Arena.buy_upgrade(id)->bool` compra 1 nível durante a partida, sem pausar; desconta Partículas e aplica o efeito até o fim; custo cresce por nível e há nível máximo; sinais `upgrade_changed(id, level, next_cost)` e `can_afford` para a UI; valores em `.tres`; testes GUT da compra e da aplicação.

### T-135 — Fileira de 5 botões de upgrade no HUD
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** T-134, T-141 (os sinais podem ser simulados antes) · **Desbloqueia:** T-138, T-120
- **Arquivos:** `src/ui/hud/`, `src/ui/components/`
- **Pronto quando:** fileira de 5 botões acima da linha de skills (Atk power, Atk spd, Defesa, Vida máxima, Cooldown), cada um com ícone, nível e custo em Partículas; desabilitado quando não há Partículas ou no nível máximo; alvo de toque de 44 px ou mais; funciona com toque, mouse e teclado em retrato; não cobre inimigos nem as skills.

### T-136 — Slots 2 e 3 do HUD bloqueados (cadeado)
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** T-112 · **Desbloqueia:** T-138, T-120
- **Arquivos:** `src/ui/hud/`
- **Pronto quando:** slots 2 e 3 visíveis com cadeado e sem ação (toque e teclas `2`/`3` ignorados); ícone provisório até a T-128.

### T-137 — Trocar placeholders da partida pela arte final
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita (o chefe ogro usa a arte final desde a T-150)
- **Depende de:** T-127, T-144 · **Desbloqueia:** T-120
- **Arquivos:** `src/match/` (cenas)
- **Pronto quando:** Anima, inimigos, chefe, projéteis e fundo usam a arte final; colisões continuam corretas; nenhum placeholder geométrico.

### T-138 — Aplicar a arte da UI no HUD e nas telas
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** T-128, T-135, T-136, T-145 · **Desbloqueia:** T-120
- **Arquivos:** `src/ui/`
- **Pronto quando:** HUD, telas e tela de upgrade usam os ícones e a arte final; legibilidade conferida no iPhone.

### T-139 — Meteoro de fogo como skill de área (decisão 37)
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** decisão 37 (feita) · **Desbloqueia:** T-131, T-128 (troca do ícone)
- **Arquivos:** `src/match/skills/`, `data/skills/`
- **Pronto quando:** a skill do slot 1 é um meteoro de fogo: cai na posição alvo (inimigo mais denso ou mais próximo, regra a documentar), explode com **raio e dano em dados** (`radius`, `damage`, cooldown), pensados para receber upgrades depois; telegraph no chão antes de cair; sinais para VFX e UI; substitui `skill_pulse`; testes.

### T-140 — Moeda da partida vira Partículas: sinais, código e `gameplay.md`
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** decisão #29 · **Desbloqueia:** T-141, T-134
- **Arquivos:** `src/match/`, `data/`, `docs/gameplay.md`, `tests/` (só os testes afetados, com aviso ao AG03)
- **Pronto quando:** sinais, variáveis e dados da moeda da partida usam o nome Partículas; começa em 0 e zera a cada partida; testes GUT passam.
- **Nota:** o identificador em código não deve colidir com nós de partículas do Godot nem com `src/fx/`; o AG07 confirma o nome (decisão do AG00).

### T-141 — Moeda da partida vira Partículas: HUD, telas e `ui.md`
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** T-140 · **Desbloqueia:** T-135, T-138
- **Arquivos:** `src/ui/hud/`, `src/ui/screens/`, `docs/ui.md`
- **Pronto quando:** HUD e Resultado mostram "Partículas"; ligados aos sinais renomeados; nenhuma menção a "moedas" para a moeda da partida.

---

## Pendências a decidir

- **Voltar ao título a partir do Resultado:** hoje "Jogar de novo" vai direto para a partida. Exigiria um sinal novo no ResultScreen (AG02). Decisão do usuário via AG00.

## Depois (M3+)

- **Envio de logs no M1** (2026-11-06, decisão 58): T-267 a T-271.
- **M2 quebrado** (2026-11-05): T-162, T-163, T-180, T-182 e T-184 a T-197. **Aceleração do jogo** (2026-11-06, decisão 59): T-272 a T-276.
- **M3 a M7 quebrados** (2026-11-05, estimativa; o detalhe "pronto quando" é escrito no briefing): M3 T-198 a T-202 e T-240 · M4 T-203 a T-210 · M5 T-109, T-110, T-211 a T-220 · M6 T-221 a T-225 · M7 T-226 a T-235 · M8 T-236 a T-244 (sem a T-240) · M9 T-245 a T-251 · M10 T-252 a T-266. Tamanho: P = até 1 sessão de agente, M = 1 a 2, G = 3 ou mais.
- **Roadmap:** marcos e versões em [docs/roadmap.md](roadmap.md) (decisão 53). Tarefas do M3 em diante são quebradas quando o marco começar.

- **Decisão 37 (meteoro de fogo):** T-139 (AG01) implementa o meteoro com raio de explosão e dano em dados, preparados para upgrades; o ícone (T-128, AG08) e o VFX (T-131, AG09) seguem o meteoro de fogo.
