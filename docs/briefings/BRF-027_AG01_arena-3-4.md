# BRF-027 — AG01 — T-144 Arena em 3/4
**Objetivo e pronto quando:** ver T-144 em [docs/backlog.md](../backlog.md).
**Contexto:** decisões 31–33. Guia visual em [docs/arte.md](../arte.md) (§ perspectiva 3/4: elipse 0,75, âncora na base, sombra, Y-sort) e mockup `assets/backgrounds/mockup_cartoon_a_upgrades.png` (arena de y≈164 a 987 em 720×1280; o núcleo no centro da arena, não da tela; a arena é menor por causa da fileira de upgrades e da bandeja de skills). Hoje a arena é top-down com placeholders geométricos.
**Fazer:** ordenação por Y (Y-sort) para Anima, inimigos e projéteis; âncora dos sprites na base; sombra no chão por entidade (nó simples e barato); área de spawn e limites adaptados à arena do mockup; **colisões e distâncias no plano do chão** (a elipse 0,75 afeta só o desenho, documente a regra); ajustar o centro da arena ao do mockup. Não troque os placeholders pela arte final (T-137). Atualize `docs/gameplay.md` e `docs/arquitetura.md` se a regra mudar.
**Arquivos permitidos:** `src/match/`, `docs/gameplay.md`, `tests/` (só da arena). Não toque em `src/ui/`, `project.godot` nem em `src/core/` sem pedir.
**Validação:** GUT passando (rode `--import` antes), e a partida ainda joga de ponta a ponta nos testes de integração.
**Entrega:** no máximo 10 linhas. Se o HUD precisar de ajuste, informe ao AG00 em vez de editar.
