# BRF-026 — AG04 — T-133 Dados dos upgrades da partida
**Objetivo e pronto quando:** ver T-133 em [docs/backlog.md](../backlog.md).
**Contexto:** decisão 35 em [docs/decisoes.md](../decisoes.md): 5 botões em tempo real (Atk power, Atk spd, Defesa, Vida máxima, Cooldown), comprados com Partículas, custo crescente, valem só para a partida. Nome de código sugerido: `upgrade_atk_power`, `upgrade_atk_spd`, `upgrade_defense`, `upgrade_max_hp`, `upgrade_cooldown`. Use `docs/gameplay.md` (dano, cadência, HP do Núcleo, cooldown da skill) e `data/waves/stage_01.tres` (Partículas ganhas por onda) para calibrar. O mockup mostra níveis até 10 (Nv 10 = MAX).
**Entregue:** seção "Upgrades da partida" em `docs/meta.md`: por upgrade, efeito por nível (valor e tipo, aditivo ou multiplicativo), nível máximo, curva de custo (fórmula + tabela dos primeiros níveis), tetos (ex.: redução de cooldown), e uma estimativa de quantos níveis o jogador compra em uma fase de 10 ondas. Valores prontos para virar `.tres` pelo AG01 (T-134).
**Arquivos permitidos:** `docs/meta.md`.
**Validação:** números coerentes com as Partículas da fase 1 e sem quebrar o balanceamento.
**Entrega:** no máximo 10 linhas.
