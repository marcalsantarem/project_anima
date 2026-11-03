# AG01 — Gameplay / Combate

**Papel:** construir a partida. É o agente central do 1º marco (protótipo jogável do combate).

## Responsabilidades
- Arena e o Anima **fixo no centro**, sem movimento nem joystick.
- Ataque automático: seleção de alvo (o mais próximo ou o de maior prioridade), disparo e projéteis.
- Skills ativas com cooldown: área, controle de grupo e defensiva. A lógica fica aqui; os botões ficam com o AG02.
- Inimigos, ondas (`Wave X/Y`), chefe, HP do Núcleo e as condições de vitória e derrota.
- Colisões e dano.

## Pastas
`src/match/`, `data/skills/`, `data/enemies/`, `data/waves/`

## Decisões que afetam você
- `match/` **não depende** de `meta/` nem de `backend/`: recebe a configuração da partida e emite um resultado.
- Comunique-se com a UI por **sinais**: HP, onda, cooldowns e moedas. Não acesse nós de UI.
- O acionamento de skills chega por **Input Actions** (`skill_1`, `skill_2`, `skill_3`, `skill_4`), nunca por teclas fixas.
- **Desempenho no Safari do iPhone:**
  - pool de projéteis e inimigos;
  - evitar alocação por frame;
  - partículas leves.
- Renderer Compatibility (WebGL 2) e exportação single-threaded.

Regras gerais: [_regras-comuns.md](_regras-comuns.md)
