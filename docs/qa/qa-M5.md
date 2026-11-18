# QA M5 — Validação da v0.2.3 Módulos (BRF-173, T-220)

**Veredito: PASSA COM RESSALVAS** (0 bloqueantes, 1 grave de correção pequena, 5 menores). O grave não perde dado nem quebra a partida, mas contradiz o escopo da T-214 ("ícones aparecem no HUD"); recomendo corrigir antes da tag. Lógica, partida, tela, mira, localização e build Web estão corretos.

## Achados
- **[grave] QA-M5-1: o HUD não mostra o ícone do Módulo equipado.** Só `data/skills/skill_meteor.tres` tem `icon`; `skill_shock/freeze/shield.tres` não têm (os PNG `assets/ui/ui_icon_skill_*.png` existem). Ninguém chama `Hud.set_slot_icon` (só testes) e `Hud.slot_icon_paths` (`src/ui/hud/hud.gd:46`) fixa `[meteoro, "", ""]`. Efeito: o slot 1 mostra o **ícone do meteoro mesmo com Choque, Congelamento ou Escudo equipado**; os slots 2 e 3 mostram o glifo genérico. A tela de Módulos usa mapa próprio (`modules_screen.gd:50`) e está certa. Repro: conta NV 8, slot 1 = Escudo, abrir a partida. Correção: `icon` nos 3 `.tres` e `SceneFlow` chamar `hud.set_slot_icon(slot, skill.icon)` por slot (junto de `_link_slot_levels`). Teste: `test_module_icons_reach_skill_data_and_hud` em `tests/integration/test_modules_m5_qa.gd` fica **pendente** até corrigir (remover o ramo `pending` e acrescentar a asserção do HUD).
- **[menor] QA-M5-2: capturas do AG02 desatualizadas.** `docs/img/modulos-tela-maximo-*.png` mostram Meteoro "Dano: 80"; após a T-219 o Nv 5 é 76 (dados e `meta.md` corretos). Os 4 estados conferem; refazer o número.
- **[menor] QA-M5-3: a lista rola em 1280×720 e mostra só 2 das 4 linhas** (barra de slots + detalhe ocupam a altura; `modulos-tela-maximo-1280x720.png`). Usável (barra de rolagem visível, detalhe fixo), mesma natureza do QA-M4-2. Em 375×812 as 4 linhas cabem sem rolar. Menor (PC é secundário).
- **[menor] QA-M5-4: EVOLUIR sem confirmação.** Toque único gasta de 250 a 2.650 Moedas, sem desfazer. O botão mostra o custo ("EVOLUIR · 250") e o Módulo já está aberto; aceitável no M5. Reavaliar se o dono errar toques no iPhone.
- **[menor] QA-M5-5: `slow_after` (0,5) é a fração de velocidade perdida**, não um tempo; o nome confunde ao lado de `slow_time`. Renomear depois; o comportamento está correto e testado.
- **[menor] QA-M5-6: o briefing cita "choque com 6 saltos"; após a T-219 o máximo é 5** (`levels_shock.tres`). O pior caso é de 5 saltos.

## Evidência
1. **Suíte:** GUT completo 3x, exit 0 nas três: 596/596, 596/596 e 602 passando + 1 pendente = 603 (a 3ª já com meus 7 testes novos). 0 "Parse error", orphans 2 (`test_stress_mode`, conhecido), sem instabilidade. WARNING/ERROR do log são os provocados pelos testes (fx_nope, menu ausente, falha de save) e vazamentos de saída do GUT. Export Web: 0 ERROR/WARNING.
2. **Lógica (`MetaModules`, 17 testes + meus):** Nv 1 grátis ao liberar (meteoro NV 2, choque e congelamento NV 5, escudo NV 8); custos exatos 250/600/1300/2650 (4.800 por Módulo, 19.200 no total); tudo-ou-nada, sem Moeda, nível máximo, bloqueado; equipar, trocar, desequipar, repetido, slot bloqueado, Módulo bloqueado, slot inválido; JSON ida e volta; ids e níveis inválidos saneados; Moeda dos Módulos não volta no respec dos Núcleos. **Novos:** save antigo (sem campos) → slot 1 = meteoro Nv 1 (dano 40), slots 2 e 3 `null`; ids desconhecidos viram vazio e nível 99 limita a 5; NV 1 = nenhum Módulo, 0 slots.
3. **Partida:** testes existentes cobrem congelamento (parado→lento, chefe só lento, mira, sem alvo, fora do alcance sem recarga, sem empilhar), escudo (contato, tiros, golpe do chefe, renova, quebra, expira), choque (1º alvo mais denso, salto ao vizinho, falloff, chefe) e os valores dos Nv 1 a 5 na Arena real. **Novos (Arena real via `SceneFlow.build_match_config`):** slot 1 vazio com slot 2 cheio (1 e 3 não disparam nem aceitam mira; 2 dispara e causa dano); `stat_cooldown` -20% nos 4 (recarga ×0,8); `stat_skill_damage` +50% só em meteoro (40→60) e choque (25→38), congelamento e escudo sem dano. Meteoro Nv 1 sozinho = v0.2.2 (`test_data_nv1` e config padrão verdes).
4. **Tela:** `test_modules_screen` (estados, atual→próximo, EVOLUIR, equipar/trocar/desequipar com persistência, motivos, slots por nível, alvos em 375 px) verde. Capturas do AG02 abertas (liberado, bloqueado, equipado, máximo; 375×812 e 1280×720): QA-M5-2 e QA-M5-3. Barra do hangar: regressão do QA-M4-1 verde.
5. **Mira (T-218):** `test_skill_aim` verde (toque simples, arrastar, voltar ao botão cancela, soltar em área inválida cancela, recarga não mira, mouse, tecla+clique, tecla sem mira dispara ao apertar, troca entre partidas).
6. **VFX/desempenho:** `test_modules_fx` (cristais e degelo, ciclo do escudo, reuso da instância, choque escalonado devolve ao pool, modo reduzido, sem vazamento de nós) verde. Ícones: ver QA-M5-1. fps do pior caso **não medido** (Não testado).
7. **Localização:** `test_localization` verde. Exceção conhecida: "Enviar log" (T-241).
8. **Regressão M2 a M4:** `test_hangar_m3_qa`, `test_nucleos_m4_qa`, `test_scene_flow_*`, `test_meta_persistence`, `test_match_flow`, HUD, pausa e áudio verdes; import e export sem ERROR/WARNING de recurso.
9. **Web:** export release + `copy_pwa.sh` exit 0. `.pck` **3.241.064 B** (v0.2.2: 3.150.636; +90 KB, +2,9%); `.wasm` **39.514.754 B** (idêntico). Chrome do painel: carrega, "Toque para começar", console sem erros. O Chrome real (extensão) roda rAF a ~61 quadros/s, mas não alcança `localhost`/`127.0.0.1` (conexão recusada) e o painel não roda `requestAnimationFrame`: o fluxo hangar → Módulos → evoluir/equipar → partida → Resultado e o fps **não foram testados no navegador**.
10. **Docs:** backlog (T-109, T-110, T-211 a T-219 "feita"; T-220 "a fazer"), `meta.md` (4.800/19.200, tabela de níveis pós-T-219) e `project.godot` 0.2.3 coerentes. T-214 está "feita" mas incompleta (QA-M5-1). Pendências conhecidas: campanha em dias com Módulos não rodada (~37 dias estimados), bot mediano vence ~100% (não discrimina), `docs/img/nucleos-vfx-*.png` ausentes (menor), SFX `sfx_freeze/shield/shock` sem áudio (AG11, futuro), "Enviar log" (T-241).

## Lacuna fechada
`tests/integration/test_modules_m5_qa.gd` (novo, 7 testes, só em `tests/`): save antigo, ids desconhecidos, NV 1, slot 1 vazio com slot 2 cheio, `stat_cooldown` nos 4, `stat_skill_damage` só em meteoro e choque, e o ícone (pendente, QA-M5-1).

## Não testado
Fluxo completo e fps no navegador; medição de quadro do pior caso (choque 5 saltos, 20 congelados); efeitos reduzidos no Web; Safari/iPhone (do dono); campanha em dias; bot com Módulos.

## Roteiro do dono no iPhone (v0.2.3)
1. Toque para começar (som só depois do toque). Conta NV 8 com Moeda (`?debug=1` → Meta ▸ Nível/+Moeda).
2. Hangar → Módulos: evoluir o Meteoro com o polegar. EVOLUIR e as linhas ficam fáceis de acertar? Houve toque acidental (QA-M5-4)?
3. Rolagem da lista: arraste; não deve evoluir nem equipar sem querer.
4. Equipar: toque no Módulo e depois no slot; trocar de slot; esvaziar; fechar a aba do Safari, reabrir e conferir persistência.
5. Slots por nível: NV 2 só slot 1; NV 5 slot 2 (Choque e Congelamento); NV 8 slot 3 (Escudo). Slots bloqueados mostram "NV x".
6. Na partida: **confira o ícone de cada slot (QA-M5-1)**; arraste no botão do Congelamento e do Meteoro (anel muda de cor, voltar ao botão cancela, soltar dispara); Choque e Escudo disparam com um toque; slot vazio não faz nada.
7. Veja o escudo absorvendo, o choque saltando, o congelamento parando e depois retardando (o chefe só retarda).
8. Desempenho com tudo na tela (3 Módulos + muitos inimigos), efeitos reduzidos ligados e desligados; pausa ao trocar de aba; safe area.
9. Dificuldade: com Módulos evoluídos a partida ficou fácil demais? O custo de 250 a 2.650 por nível parece justo?
