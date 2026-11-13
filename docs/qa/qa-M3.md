# QA M3 — Validação da v0.2.1 Hangar (BRF-148, T-202)

**Veredito: PASSA COM RESSALVAS** (0 bloqueantes, 0 graves).

## Evidência
- **Suíte:** GUT completo 3x: 463/463, 466/466 e 466/466 (a 2ª e a 3ª já com meu arquivo novo, +3), exit 0 nas três, 0 "Parse error", orphans 2 (`test_stress_mode`, conhecido do M2). Sem instabilidade. WARNING/ERROR do log são provocados pelos testes (fx_nope, menu ausente, falha de save) mais os vazamentos de saída do GUT (RIDs/ObjectDB). Importação headless limpa (0 ERROR/WARNING).
- **Lacuna fechada:** `tests/integration/test_hangar_m3_qa.gd` (novo, 3 testes, hangar real com menu e barra via `SceneFlow`): matriz de bloqueio NV 1/2/3/4/8 (Módulos 2, Núcleos 3, Componentes 4; Jogar e Ajustes livres; toque no bloqueado não navega e mostra o aviso; livre navega e cai no "Em breve"); peças `ui_nav_bar`, `ui_nav_tab_active`/`_pressed`, `ui_nav_lock_chip`, `ui_icon_nav_*` e `ui_icon_*_locked` carregadas como `StyleBoxTexture`/textura, sem fallback; Voltar entre abas, barra acompanha, mesma instância com estado (meta) preservado, aba oculta com `PROCESS_MODE_DISABLED`, Jogar limpa o histórico.
- **Hangar:** ordem Módulos · Componentes · Jogar · Núcleos · Ajustes (`HangarBarLogic.ORDER`, `test_hangar_bar`); cache liberado na partida e volta em Jogar (`test_scene_flow_hangar`); Partida/Resultado → Jogar confirmados no Web. Alvos medidos: 75×76 px em 375×812 e 81×82 px em 1280×720 (≥ 64); barra 110 px com faixa segura.
- **Capturas** (`docs/img/qa-m3-*.png`): `hangar-jogar-nv1`, `hangar-bloqueado-nv1` (aviso "Núcleos libera no NV 3"), `hangar-em-breve` (Ajustes → "Configurações") em 375×812 e 1280×720, e `notch-hangar-em-breve-375x812` (safe area simulada 47/34 pt: Voltar desce abaixo do notch, barra mantém a faixa). Conferem com `hangar-opcao-a-375x812.png` na estrutura, ordem, Jogar central em destaque e selos; diferenças nos menores abaixo.
- **Localização:** varredura de `src/ui/` (sem `demo/`) sem texto visível fixo (só números/símbolos: "%.1f", "—"); `test_localization` 5/5. Cada literal removido no commit da T-240 tem valor idêntico em `data/i18n/strings.csv` (64 chaves, inclusive espaços e "1ª VITÓRIA DO DIA  (+BÔNUS)"); título capturado igual ao `titulo-alfa-375x812.png` no texto; HUD, pausa e Resultado no Web com os mesmos textos da v0.2.0. `strings.pt_BR.translation` está no `index.pck`. Exceção conhecida: `src/debug/log_uploader.gd:25-28` ("Enviar log" e estados).
- **Regressão M2:** suíte do M2 inteira verde (ciclo com save, x1/x2, pausa, áudio só após o gesto). Web: pausa (Esc) → "Voltar ao menu" → hangar em Jogar.
- **Web:** export release "Web" exit 0 sem erro/aviso; `copy_pwa.sh` OK. `index.pck` 2.912.244 → 2.978.364 B (+66 KB, +2,3%; gzip 2,69 → 2,75 MB); `index.wasm` igual (39,5 MB, 10,1 MB gzip). Chrome (Playwright 1.58 + Chrome do sistema, 375×812): Toque para começar → hangar NV 1 → Núcleos bloqueado (aviso) → Ajustes ("Em breve") → Voltar → Jogar → partida → pausa → Voltar ao menu → hangar; e `?debug=1&stress=5,5` → Resultado (60 s) → Voltar → hangar em Jogar. Console: só as 3 linhas de boot do Godot, 0 erros.
- **Docs:** backlog coerente (T-198 a T-201 e T-240 "feitas" têm código e testes; T-202 é esta).

## Defeitos
- [menor] Ícone bloqueado quase invisível: a arte `ui_icon_*_locked` já vem "cinza a 45%" (arte.md §11.9) e o código aplica de novo alfa 0,45 (`src/ui/hangar/hangar_bar.gd:132`). Esperado: como no mockup; obtido: ~20% (capturas `qa-m3-hangar-jogar-nv1-*`).
- [menor] Selo "NV n" escrito por cima do cadeado: `ui_nav_lock_chip` pede `content_margin` 38/12 e 9-slice 38/12/12/12, mas o `StyleBoxTexture` é criado sem margens e o chip tem 36×16 base (`hangar_bar.gd:182-187`, `:309`). Lê-se "ÑV 2". Também `ui_nav_bar` sem 9-slice 48/48/16/8 nem `expand_margin` (`:146-150`): a arte estica (colchetes deformam em 1280×720).
- [menor] O aviso do bloqueado aparece sobre a parte de baixo do botão JOGAR (`hangar_bar.gd:318`; captura `qa-m3-hangar-bloqueado-nv1-*`).
- [menor] `ui_icon_back` não é usado: Voltar é só texto (`coming_soon_screen.gd`); o painel do "Em breve" também não tem o ícone do conceito pedido no §11.9. Ressalva conhecida; cosmético.
- [menor] `docs/ui.md` não descreve o hangar (só "Sem menu/hangar no M1", linha 255). Ressalva conhecida; a spec está em `arte.md` §11.9 e `arquitetura.md`.
- [menor] Doc/comentário dizem que `HangarNav.TABS` é a ordem da barra (`docs/arquitetura.md:61`, `src/core/hangar_nav.gd:11`), mas a barra usa `HangarBarLogic.ORDER`.
- [menor] `config/version` ainda `0.2.0` e o título mostra "v0.2.0" (esperado na T-202, fechamento).
- [menor] Os `docs/img/*.png.import` seguem untracked (lixo de import, já no M2).

## Não validado
- Safe area/notch reais (só simulada), toque real, áudio audível, PWA; partida completa até vitória no navegador (Resultado coberto pelo modo estresse e pelos testes); aval do dono.

## Roteiro do dono no iPhone
- [ ] Barra: alcançar os 5 itens com o polegar (mão única), sem toque errado no vizinho; Jogar central em destaque.
- [ ] Faixa segura: rótulos acima do indicador de home; nada colado na borda; "Voltar" do "Em breve" abaixo do notch/Dynamic Island.
- [ ] Trocar de abas (Ajustes, e no NV ≥ 4 Módulos/Componentes/Núcleos): troca imediata, aba ativa marcada.
- [ ] Voltar (botão) retorna à aba anterior e, por fim, a Jogar.
- [ ] Bloqueios com save novo (NV 1): Módulos, Componentes e Núcleos com selo; tocar só mostra o aviso. Subir de nível com `?debug=1` (+XP) até 2, 3, 4 e conferir cada liberação.
- [ ] Jogar → partida → Resultado → Voltar cai em Jogar, com nível/Moeda atualizados.
- [ ] Ícones bloqueados e selos legíveis ao sol/brilho baixo (ver menores).
