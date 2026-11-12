# QA M2 — Validação da v0.2.0 Alfa (BRF-141, T-196)

**Veredito: PASSA COM RESSALVAS** (0 bloqueantes, 0 graves).

## Evidência
- **Suíte:** GUT completo 3x: 439/439, 439/439 e 441/441 (a 3ª já com meu arquivo novo), exit 0 nas três, 0 "Parse error", orphans 2 (`test_stress_mode`, conhecido). Isoladas: `tests/unit/match` 178/178 (24 scripts) e `tests/integration` 32/32 (6 scripts), exit 0. Sem instabilidade. Os WARNING/ERROR do log são provocados pelos testes (fx_nope, menu ausente, falha de save, vazamento de saída do GUT). Importação limpa; só 3 avisos "Missing .uid" (ver menores).
- **Ciclo** (`test_scene_flow_meta`, 10 testes, fake de backend): Título → Menu → Partida → Resultado → Menu, vitória com bônus do dia, 2ª vitória sem bônus, vários níveis + slot, teto 30 (XP 0), derrota reduzida sem bônus, falha de save não trava, estresse não paga nem salva. `test_meta_logic`/`test_slots_by_level`/`test_economy_data`: slots 2/5/8, ×0,7, só monstros (decisão 59), recompensa por tipo. **Lacuna fechada:** `tests/integration/test_meta_persistence.gd` (novo, 2 testes, `LocalBackend` real): 3 partidas liquidadas, salvar, reabrir o perfil = mesmos nível/XP/Moeda/data do bônus; 2ª vitória no dia depois de reabrir sem bônus; teto 30 sobrevive à reabertura.
- **Velocidade:** `test_speed_controller` (8: escolha salva e inválida vira x1, restauração após hit-stop/pausa, trava x1 no headless, mesmo `MatchResult` x1/x2 por seed) + `test_projectile_tunnel` (x1 e x2) + `test_hud_speed_button`: verdes. Medição no iPhone (T-276) feita pelo dono.
- **Áudio:** `test_audio_manager`: nada toca antes do gesto, música começa no gesto e para na partida, limite de vozes de SFX, volumes salvos sem apagar `game_speed`. Som real só o dono ouve.
- **Pausa/HUD:** Web (painel): pausa com Continuar, Recomeçar, Voltar ao menu (testado: volta ao menu), interruptores Efeitos reduzidos/Debug; HUD holográfico com slots NV 2/NV 5/NV 8, Anima holográfico sem anel, botão x1→x2 alterna. Sem erro de recurso na importação nem no console.
- **Web:** export release OK (exit 0, sem erro), `copy_pwa.sh` OK, `inject_build.sh` OK (testado com SHA falso). Tamanho: `index.wasm` 39,5 MB cru (10,1 MB gzip -9), `index.pck` 2,9 MB cru (2,7 MB gzip), total ~12,8 MB em gzip (brotli ficará menor; sem `brotli` no ambiente para medir) ≤ 15 MB, mas o `.pck` subiu de 2,0 MB (M1) para 2,9 MB. Chrome do painel: Toque para começar → Menu (NV 1, Moeda 0) → Jogar → partida → pausa → menu; `?debug=1` abre a seção Meta (+100 XP, +1000 XP, +500 Moeda, Nível ±, Zerar save); console sem erros. Log: `LogUploader.MAX_BYTES` 200 KB e corpo do log limitado a 150 KB (`LogReport.UPLOAD_MAX_BYTES`), dentro do contrato (não mudou); `test_match_logs`/`test_log_enriched` verdes. Envio real não feito (sem rede/chave).
- **Docs:** decisões 59, 63 e 64 estão na Bíblia, `CLAUDE.md` (slots 2/5/8, Núcleos 3, Componentes 4, x2 6, fusão 7) e `economia.md` (×0,7, bônus do dia, níveis 1 a 30). Backlog M2: todas as tasks "feitas" têm código/testes correspondentes; só restam T-196 (esta), T-197 (fechamento) e T-283 (abaixo).
- **T-283 (conferida por último):** `TXT_BUILD_TAG := "ALFA"` em `title_screen.gd`, teste `test_build_tag_shows_alfa_in_red` verde (4/4 em `test_title_screen`), capturas `docs/img/titulo-alfa-*.png` mostram "ALFA" vermelho entre o título e o botão, e o Web mostra o mesmo. Obs.: o AG02 ainda tinha `docs/ui.md`, `title_screen.gd` e o teste sem commit ao fechar este relatório.

## Defeitos
- [menor] Versão exibida e `project.godot` `config/version` continuam `0.1.0` (a v0.2.0 depende de T-197). Na captura 375x812 do título o rótulo "v0.1.0 · dev local" encosta/sobrepõe o logo "Anima Games" (`docs/img/titulo-alfa-375x812.png`).
- [menor] Faltam `.uid` versionados: `tests/tools/measure_stress.gd`, `tests/unit/debug/test_log_adjust.gd`, `tests/unit/debug/test_log_enriched.gd` (gerados no import; entram no `git status` como lixo) e vários `docs/img/*.png.import` untracked.
- [menor] A pausa ainda mostra o interruptor "Debug" ao jogador (já registrado no M1).
- [menor] `.pck` +45% desde o M1 (2,0 → 2,9 MB); acompanhar (ADR de desempenho).
- [sugestão] O fake de backend do `test_scene_flow_meta` não exercita o `LocalBackend` dentro do `SceneFlow`; o novo teste cobre só a lógica + backend, não o autoload.

## Não validado
- Partida completa no navegador até o Resultado (o painel do Godot roda a ~0,3 fps com overlay; coberto por `test_scene_flow_meta`/`test_match_flow`); áudio audível; PWA e save em dispositivo; envio real do log; x2 visualmente sem tunelamento (só teste); aval do dono.

## Roteiro do dono no iPhone
- [ ] Abrir no Safari: Toque para começar, ouvir a música só depois do 1º toque (título/menu), silêncio na partida, som do tiro.
- [ ] Jogar 3 partidas seguidas (ganhar ao menos uma, perder ao menos uma): XP/Moeda sobem, barra enche, nível sobe; ×0,7 na derrota e bônus só na 1ª vitória do dia.
- [ ] Fechar o Safari por completo e reabrir: nível, XP e Moeda continuam.
- [ ] Repetir pelo ícone na tela inicial (modo app/PWA): o save é o mesmo ou separado? (anotar; o armazenamento do PWA pode ser outro).
- [ ] Slots: NV 2/5/8 liberam ao subir (usar `?debug=1` → +XP).
- [ ] Botão x2: alterna, a escolha fica ao reabrir, sem perder fps nem tiros atravessando inimigos.
- [ ] Pausa: Continuar, Recomeçar, Voltar ao menu, efeitos reduzidos; pausar ao trocar de aba/app.
- [ ] Enviar log (`?debug=1`) e confirmar que chegou; versão visível sem sobrepor o logo.
