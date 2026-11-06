# QA M1 — Validação do vertical slice v0.1.0 (BRF-100, T-120)

**Veredito: PASSA COM RESSALVAS** (0 bloqueantes, 0 graves).

## Evidência
- **Suíte:** GUT completo 3x seguidas: 305/305, exit 0 (orphans: 2, de `test_stress_mode`, inofensivos).
- **Teste instável** `test_skills.gd::test_input_action_triggers_slot`: não reproduzido (3 suítes + 18 execuções do arquivo sob carga: 0 falhas nele). Causa provável: `Input.parse_input_event` + espera fixa de 2 quadros de física (o despacho atrasa sob carga) e ação `skill_1` nunca solta. Conserto (só teste): `Input.flush_buffered_events()`, `wait_until` pelo sinal (máx. 2 s) e soltura da ação com evento novo. 3/3 verdes após o conserto. Obs.: rodar GUT em paralelo falha em `test_files_saved_and_rotated` e `test_settings_persist_overlay_state` por dividirem `user://` (artefato do paralelismo, não defeito).
- **Simulação** (bot, 8 seeds, fase 1): 10 ondas + chefe, 100% chegam ao chefe e vencem; chefe aos ~200 s; partida de 216 a 226 s (média 222 s, dentro de 3–10 min); 33 upgrades/partida (MAX alcançável); ~487 Partículas.
- **Web** (export release + copy_pwa, Chrome do painel, localhost): carrega; tela inicial com `VERTICAL SLICE` e sem "Último log"; Toque para começar → partida (ONDA 1/10, Partículas 0, 5 upgrades, slot 1 meteoro, slots 2 e 3 com cadeado NV 7/NV 12); tecla `1` aciona; pausa funciona (Continuar, Recomeçar, Efeitos reduzidos, Debug); versão `v0.1.0-demo · dev local` visível; console sem erros. Build: index.wasm 37,7 MB + pck 2,0 MB (cru); ~8,9 MB brotli (perf.md) ≤ 15 MB.
- **Desempenho:** iPhone 11 Pro 46,9 fps médio (mín 43,2) no pior caso de 150 inimigos (perf.md, medido pelo dono; abaixo do alvo 50 do overlay, acima do critério ≥ 45 do M1).

## Defeitos
- [menor] Versão exibida é `0.1.0-demo` (default de `build_info.gd`; `project.godot` sem `application/config/version`). README diz 0.1.0.
- [menor] A pausa mostra o botão "Debug: desligado" ao jogador (texto de debug na UI de jogo); decidir se sai do build público.
- [menor] Lixo no git: `docs/img/titulo-vs-375x616.png.import` e `docs/img/titulo-vs-375x812.png.import` (untracked, gerados pelo import do Godot). Fora do meu escopo.
- [menor] 1ª visita em 4G: ~9 MB de .wasm; meta de 1º frame < 5 s em risco (já registrado em perf.md).
- [sugestão] CLAUDE.md não cita a versão 0.1.0.

## Não validado
- Partida completa no navegador até o Resultado e "Jogar de novo" (só sim e testes de integração `test_match_flow`/`test_stage_01_sim`); pausa por perda de foco real (só o botão testado); efeitos reduzidos visualmente; Resultado com fundo holográfico (não visto); iPhone/Safari além do fps medido pelo dono; qualidade visual de demo e aval do usuário; revisão item a item das decisões 31–60; docs sobre Partículas não auditados a fundo.

## Checklist M1 (para o AG00 atualizar marcos.md)
- Arena/Anima/ataque com pool: OK (testes)
- Skill slot 1 meteoro com cooldown por toque/mouse/tecla 1: OK (tecla 1 vista no Web; toque/mouse por testes)
- Slots 2 e 3 com cadeado e nível (NV 7, NV 12): OK
- 5 upgrades com Partículas, MAX alcançável: OK (sim: 33 compras)
- Partículas em HUD/sinais: OK; nos docs: não auditado
- 4 arquétipos + chefe com fases: OK (testes archetypes/boss; chefe vencido na sim)
- Fase 1 de ~10 ondas + chefe, 3–10 min: OK (222 s)
- HUD por sinais; fluxo Toque→Partida→Resultado→Jogar de novo; tema/fonte: OK (testes + Web parcial)
- Guia de estilo/mockup aprovados e arte final sem placeholders: dependem do dono; nenhum placeholder visto nas telas abertas
- VFX com efeitos reduzidos: OK em código/testes; visual não visto
- Game feel: testes OK; sensação não avaliada
- GUT headless: OK (305)
- ≥ 45 fps no iPhone 11 Pro: OK (46,9, dono); build ≤ 15 MB: OK (8,9 MB brotli)
- Enviar log: OK (qa-T-271)
- Veredito AG03: passa com ressalvas; aval do usuário pendente
