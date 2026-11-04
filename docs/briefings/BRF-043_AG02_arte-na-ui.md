# BRF-043 — AG02 — T-138 Aplicar a arte da UI no HUD e nas telas
**Objetivo e pronto quando:** ver T-138 em [docs/backlog.md](../backlog.md).
**Contexto:** a arte da UI está pronta (T-128) em `assets/ui/` (24 PNGs em 2x, `scale = 0.5`; leia `assets/ui/README.md`: tamanhos, usos, margens 9-patch e posições internas). Alvo visual: `assets/backgrounds/mockup_cartoon_a_upgrades.png`. Hoje o HUD e as telas usam `StyleBoxFlat` e ícones provisórios desenhados por código (T-145, T-135, T-136, T-141).
**Fazer:** trocar pelo uso da arte final, sem mudar comportamento nem contrato:
- `UpgradeButton`: moldura do botão nos 3 estados (normal, apagado, MAX), ícones dos 5 upgrades (`icon_texture`), pílula de custo e estrela de Partículas; estado sem Partículas = ícone com `modulate.a ≈ 0,55`.
- `SkillButton`: molduras circulares (pronta, recarga, bloqueada), ícone da skill de área (`skill_pulse`), cadeado, véu de recarga; badge da tecla como está.
- `UiBar`: trilho, preenchimento (branco, tingido por cor) e brilho; pílulas do topo; botão de pausa; estrela de Partículas no HUD e no Resultado.
- Painéis (`ScreenKit.card`, pausa, resultado, título) e botão grande (normal/pressionado) com os 9-patch e as margens documentadas no README.
Use `StyleBoxTexture` / `TextureRect` com filtro Linear e sem mipmaps. Mantenha `StyleBoxFlat` como fallback só se for útil para testes. Sem tooltips (já removidos). Sem alocação por frame. Verifique alvos de toque ≥ 44 px e que nada cobre inimigos. Atualize `docs/ui.md` (arte usada) e as cenas de demo.
**Arquivos permitidos:** `src/ui/`, `docs/ui.md`, `tests/` (da UI), arquivos `.import` gerados em `assets/ui/`. Não edite os PNG de `assets/ui/` (se precisar de ajuste na arte, registre na entrega para o AG08). Não toque em `src/match/` nem em `project.godot`.
**Validação:** `--import` e GUT completo passando; renderize `hud_demo`, `ui_demo`, título, pausa e Resultado (largura 720, alturas 1280 e 1560) e compare com o mockup; confira que o 9-patch não distorce e o texto continua legível.
**Entrega:** no máximo 10 linhas (entregue · validação · suposições · não testado · próximo passo), incluindo o que ficou diferente do mockup.
