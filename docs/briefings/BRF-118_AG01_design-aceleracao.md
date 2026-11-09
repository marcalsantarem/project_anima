# BRF-118 — AG01 — T-272 design da aceleração (x1 e x2)
**Leia:** `docs/gameplay.md`, `docs/economia.md` (decisão 59: nada depende do tempo), `docs/roadmap.md` (M2), backlog T-272 a T-276. **Regra:** respostas curtas; sem commit/push/branches; só design em `docs/`, sem código.
**Fazer:** registrar em `docs/gameplay.md` (seção nova "Aceleração") o design do botão de velocidade x1/x2:
1. A velocidade escolhida **não é reduzida sozinha**: pausa, hit-stop e Resultado respeitam a escolhida (restauram para ela).
2. **Escopo da sessão:** decidir e justificar entre "só a partida" e "até fechar o app"; recomende uma e diga o que muda na UI e no save (se salvar algo, só `user://`, sem mexer em `src/meta/`).
3. **Recompensa:** XP/Moeda continuam só por monstros derrotados (nunca por tempo); confirme que x2 não altera o valor por monstro, apenas o ritmo.
4. **Ponto de extensão** para travas futuras (ex.: x2 bloqueado por nível ou por anúncio): descreva a interface (um ponto só, ex.: função/sinal `can_use_speed(level)`), sem implementar.
5. Bot/headless sempre em x1; efeitos de tempo (cooldowns, ondas, VFX) escalam pelo `Engine.time_scale`; registre riscos para o iPhone (T-276).
**Arquivos permitidos:** `docs/gameplay.md`. **Proibido:** `src/`, `assets/`, `project.godot`, `data/`.
**Entrega:** até 5 linhas: escopo recomendado, ponto de extensão, riscos e dúvidas que dependem do dono.
