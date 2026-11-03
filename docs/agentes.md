# Divisão do trabalho em agentes (Proposta)

Esta é uma divisão de responsabilidades em alto nível. O escopo detalhado de cada agente ainda será definido.

## Imprescindíveis

| Agente | Responsabilidade | Pastas principais |
|---|---|---|
| **Gameplay / Combate** | Arena, Anima, ataque automático, skills e cooldowns, inimigos, ondas e chefe, projéteis e colisões | `src/match`, `data/skills`, `data/enemies`, `data/waves` |
| **Meta-jogo / Dados** | Cards, raridades, fusão, atributos, talentos e economia (lógica pura) | `src/meta`, `data/cards`, `data/stats` |
| **Backend** | Interface `Backend`, save local e, depois, o provedor escolhido (auth, banco, regras, lógica no servidor, config remota, hosting) | `src/backend`, `web/` |
| **UI / Plataforma Web** | HUD, menus e hangar, retrato e responsividade, toque/mouse/teclado, exportação Web e desempenho no Safari do iOS | `src/ui`, `web/` |
| **QA / Revisor** | Testes automatizados, revisão entre domínios e verificação dos builds no PC e no iPhone | `tests/` |

## Opcionais (mais adiante)

| Agente | Responsabilidade | Observação |
|---|---|---|
| **Balanceamento** | Curvas de dificuldade, taxas de drop, custos | Pode começar dentro do Meta-jogo |
| **VFX / Arte técnica** | Shaders, partículas, efeitos por raridade e skin | A arte em si vem de fora |
| **Monetização** | Ads, compras, loja | Só depois que o loop principal estiver divertido |
| **DevOps** | Deploy automático de previews | Pode ficar com o Backend no início |
