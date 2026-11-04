# BRF-048 — AG09 — T-130 VFX do ataque, acertos e mortes
**Objetivo e pronto quando:** ver T-130 em [docs/backlog.md](../backlog.md).
**Contexto:** `docs/vfx.md` e o pool (`FxPool`, `fx_*.tscn`, `src/fx/demo/`) existem (T-129). Os sinais da Arena de que os efeitos dependem estão sendo criados **agora** pelo AG01 (T-148, em `src/match/`): `projectile_fired(from, dir)`, `projectile_hit(at, target_kind)`, `enemy_died(at, archetype_id, cause)`, `particles_gained(at, amount)`, `skill_cast(slot, at, radius)`, `boss_telegraph_started(pattern_id, duration, at, radius)`, `boss_phase_changed(phase)`. Você **não** edita `src/match/`.
**Fazer:**
- `src/fx/fx_director.gd` (nó `FxDirector`): `bind(arena: Node)` conecta (com `has_signal`, tolerando sinais ainda ausentes) os sinais acima ao `FxPool` e dispara os efeitos do catálogo: **muzzle/rastro/brilho do projétil**, **impacto** por tipo de alvo, **morte** por arquétipo (cores do `docs/arte.md`), **coleta de Partícula** (estrela dourada subindo ao HUD não: só brilho no chão, o HUD é do AG02), pulso no Núcleo quando ele leva dano (use o sinal `core_hp_changed` existente). O **rastro do projétil** pode ser um efeito curto ligado ao disparo/no impacto; evite instanciar por quadro.
- Respeite `reduced_effects` e o orçamento de `docs/vfx.md`; sem alocação por quadro; posições em coordenadas de chão (Y-sort e 0,75).
- Testes GUT do `FxDirector` com um emissor falso (um Node com os sinais), conferindo a reação a cada sinal, tolerância a sinal ausente e reuso do pool.
- Cena de demo atualizada para mostrar o fluxo completo (disparo → impacto → morte → coleta) disparando sinais de um emissor falso; renderize e confira.
- Registre em `docs/vfx.md` como ligar (`FxDirector.bind(arena)` + um `FxPool` na cena), e o **pedido ao AG00** para a ligação final na partida (ex.: no `SceneFlow` ou na `arena.tscn`), já que são arquivos fora do seu escopo.
- Meça o custo do pool com ~150 inimigos e ~300 projéteis simulados em tempo de quadro (no desktop, relativo) e registre.
**Arquivos permitidos:** `src/fx/`, `assets/vfx/`, `docs/vfx.md`, `tests/` (do fx). Não toque em `src/match/`, `src/ui/`, `src/core/` nem `project.godot`.
**Validação:** `--import` e GUT; falhas em `tests/unit/match` causadas pelo AG01 trabalhando ao mesmo tempo não são suas: relate.
**Entrega:** no máximo 10 linhas (entregue · validação · suposições · não testado · próximo passo).
