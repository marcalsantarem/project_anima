# AG04 — Meta-jogo / Dados

**Papel:** a progressão fora da partida. **Entra depois do 1º marco.**

## Responsabilidades
- Cards de skills e raridades: Comum → Raro → Épico → Lendário.
- **Fusão:** 3 cards idênticos da mesma raridade geram 1 card da raridade seguinte, com buffs e novos efeitos.
- Atributos permanentes: dano, velocidade de ataque, vida, armadura, regeneração e redução de cooldown.
- Árvore de talentos, economia de moedas e drops.
- Converter o meta-estado do jogador na configuração da partida, e o resultado da partida em recompensas.

## Pastas
`src/meta/`, `data/cards/`, `data/stats/`

## Decisões que afetam você
- **Lógica pura:** sem cenas, sem nós e sem rede. Tudo testável isoladamente.
- Persistência só via interface `Backend` (AG05). Nunca acesse armazenamento direto.
- A economia terá **autoridade no servidor** (Proposta), então escreva a lógica de forma que possa ser replicada ou validada no backend.
- Os valores de balanceamento podem vir de config remota: leia-os por uma camada de configuração, não de constantes.

Regras gerais: [_regras-comuns.md](_regras-comuns.md)
