# BRF-064 — AG01 — T-166 chefe sem defesa · T-167 passos do chefe · T-168 círculo menor · T-169 (parte AG01) Anima centralizado
Decisões 42 e 43 em [docs/decisoes.md](../decisoes.md). Faça nesta ordem, na mesma sessão. O AG08 entrega quadros de caminhada do ogro e o AG02 refaz a bandeja do HUD em paralelo; você **não** edita `src/ui/` nem `assets/`.

**Dados do teste real no iPhone (log da partida, derrota no chefe):** o Anima chegou ao chefe com Energia 131/210 e morreu em 38 s; o chefe deu 114 de dano em 6 golpes de ~19 (a cada ~1,5 s) e a vida dele (600) só caiu para 312, porque a defesa de 500 absorvia os tiros; foi lançado 3 vezes pelo meteoro. Upgrades no chefe: atk spd 7, atk power 6, vida 5, defesa 2, cooldown 2. O jogo roda a **30 FPS** (o aparelho estava em Modo de Pouca Energia; não é problema de código).

**T-166 — Chefe sem defesa**
- **Desligue a mecânica de defesa por dados**: `defense_max = 0` em `boss_warden.tres` desliga a barra, o escudo e os sinais `boss_defense_changed`; **não apague o código nem os testes**: deixe-o **arquivado e funcional** para outros chefes (comentário no código e seção "Defesa do chefe (arquivada)" em `docs/gameplay.md` com como ligar). Sem barra sobre o chefe; só a barra "Boss" do HUD (já existe, vida).
- O **meteoro lança o chefe e o atordoa sempre** que o atinge (independente de defesa): lançamento para trás, em direção à borda (mesma regra de hoje, dentro da área visível), ~2 s atordoado (pose `boss_ogre_stunned`, sem atacar), depois volta andando. Dê **imunidade curta a novo lançamento** (~1 s após acordar) só se necessário para evitar loop; documente.
- **Recalibre** (dados primeiro): vida do chefe (sem defesa a vida cai direto: comece em ~900–1200), dano e cadência do golpe, velocidade. **Meta, medida com o bot** (`tests/tools/run_sim.gd`, 100 seeds): 100% chegam ao chefe, **vitória ~60%**, luta de **25 a 45 s**, Energia média restante de quem vence ≥ 25%. Use também o log real como referência: o jogador real tem ~38 de DPS contra o chefe com os upgrades acima; um chefe que mata o Anima em 38 s é duro demais para a demo. Atualize a tabela de balanceamento em `docs/gameplay.md`/`docs/meta.md`.

**T-167 — Passos do chefe (ele está "se arrastando")**
- Animação de caminhada procedural, barata e sem alocar por quadro, no ritmo da velocidade real (passos ≈ distância/comprimento do passo): **balanço vertical** (bob) de ~6–8 px a 1x, **inclinação lateral** alternada (±4–6°), **squash e stretch** no apoio do pé, e a **sombra** (`GroundShadow`) pulsando em sincronia; para quando ele para ou ataca, e respeita o atordoamento e o lançamento. Se existirem `assets/sprites/boss_ogre_walk_1..4.png` (AG08, em paralelo; âncora igual à do `boss_ogre`), alterne os quadros no ritmo dos passos (os dados trazem a lista de texturas; sem os arquivos, use só o procedural). Teste: o ritmo escala com a velocidade, parado não anima.
- Opcional e barato: o mesmo balanço mais suave (±3 px) nos inimigos comuns, **desligável por dado** (`walk_bob`), desde que o desempenho no teste de estresse não piore; informe.

**T-168 — Círculo rúnico menor**
- O selo do chão (`floor_ring`) fica com **~70% do tamanho atual** (escala 0,5 → ~0,35 no nó; ajuste `arena_floor.gd` e a regra do README de sprites), mais perto do totem do Anima. O círculo (elipse 0,75) segue centrado no Anima. Mantenha constante em dado (`RING_SCALE`).

**T-169 (parte AG01) — Anima centralizado na área livre**
- O Anima deve ficar no **centro da área livre entre o topo do HUD e a bandeja**, não no centro da `arena_rect` inteira: `center_y = (top_inset + tray_top) / 2`, com `top_inset = Hud.TOP_INSET` (164, **fixo**: a barra "Boss" não desloca o Anima) e `tray_top = altura da arena` (recalcule no `size_changed`; o AG02 está reduzindo a altura da bandeja e o `SceneFlow` já repassa `hud.tray_height()` por `Arena.set_bottom_inset`). Selo, pilares, spawn e o alvo do meteoro seguem esse centro. Documente em `docs/gameplay.md` (arena em tela cheia) e ajuste os testes.

**Arquivos permitidos:** `src/match/`, `data/`, `docs/gameplay.md`, `docs/meta.md`, `tests/`, `tests/tools/`. **Proibido:** `src/ui/`, `src/fx/`, `src/core/`, `assets/`, `project.godot`.
**Validação:** `--import` e GUT completo passando (2 vezes); tabela do bot antes e depois; renderize a arena (720×1280 e 720×1474) mostrando o círculo menor e o Anima centralizado.
**Entrega:** no máximo 10 linhas por tarefa (entregue · validação · suposições · não testado · próximo passo).
