# Arquitetura técnica

> Dono: AG07. As seções são adicionadas conforme as tasks.

## Camadas de colisão 2D (T-001)

Configuradas em `project.godot` → `[layer_names]`. A tabela segue a proposta do AG01 em [gameplay.md](gameplay.md).

| Bit | Nome | Mask (detecta) |
|---|---|---|
| 1 | `anima` | `enemies`, `enemy_projectiles` |
| 2 | `enemies` | `anima`, `player_projectiles`, `skill_areas` |
| 3 | `player_projectiles` | `enemies` |
| 4 | `enemy_projectiles` | `anima`, `shield` |
| 5 | `skill_areas` | `enemies` |
| 6 | `shield` | `enemy_projectiles`, `enemies` |

Regras:
- No Godot, um nó detecta outro quando a **mask dele** contém a **layer do outro**. Basta configurar o lado que reage. A tabela lista os dois lados como referência.
- Cada nó ocupa **uma** layer. A mask pode ter várias.
- No código, use constantes, nunca números soltos. Quando surgir a necessidade, elas ficam em `src/core/`.
- Layers novas (por exemplo `pickups`) só entram com uma task do AG07.
