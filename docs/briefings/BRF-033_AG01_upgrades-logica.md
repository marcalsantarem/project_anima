# BRF-033 — AG01 — T-134 Lógica dos upgrades em tempo real
**Objetivo e pronto quando:** ver T-134 em [docs/backlog.md](../backlog.md). Depois, na mesma sessão, faça o BRF-034 (T-115).
**Contexto:** decisão 35. Valores, curva de custo e mapeamento de stats estão em [docs/meta.md](../meta.md) (5 upgrades, nível máximo 10, custo `ceil(5×1,4^(N−1))`, formato sugerido do `UpgradeData`). Partículas já existem na arena (`Arena.particles`, `particles_changed`).
**Contrato com a UI (o AG02 constrói a fileira de botões em paralelo; documente-o em `docs/gameplay.md` logo no início):**
- IDs, nesta ordem: `upgrade_atk_power`, `upgrade_atk_spd`, `upgrade_defense`, `upgrade_max_hp`, `upgrade_cooldown` (`Arena.UPGRADE_IDS`).
- `Arena.buy_upgrade(id: StringName) -> bool`: compra 1 nível se houver Partículas e nível < máximo; não pausa a partida.
- sinal `Arena.upgrade_changed(id: StringName, level: int, max_level: int, next_cost: int)`: emitido para os 5 no início da partida e após cada compra; `next_cost = -1` quando MAX.
- Dados em `data/upgrades/*.tres` (um `UpgradeData` por upgrade); efeitos aplicados em `src/match/upgrades/`, sem hardcode.
**Fazer:** implementar a lógica (dano, cadência, dano recebido pelo Núcleo antes do escudo, HP máximo +10 também no HP atual, cooldown de todas as skills a partir do próximo uso), reset a cada partida, sinais acima, testes GUT da compra, do custo crescente, do teto e da aplicação de cada efeito.
**Arquivos permitidos:** `src/match/` (inclusive `upgrades/`), `data/upgrades/`, `docs/gameplay.md`, `tests/` (da arena). Não toque em `src/ui/`.
**Validação:** `--import` e GUT completo passando.
**Entrega:** no máximo 10 linhas por tarefa.
