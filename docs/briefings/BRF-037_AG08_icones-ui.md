# BRF-037 — AG08 — T-128 Ícones e arte da UI
**Objetivo e pronto quando:** ver T-128 em [docs/backlog.md](../backlog.md).
**Contexto:** estilo em [docs/arte.md](../arte.md) e mockup `assets/backgrounds/mockup_cartoon_a_upgrades.png`; método e pasta-fonte iguais aos da T-127 (`assets/sprites/_src/gen_sprites.py` e `README.md`). A T-125 (skill meteoro × onda de choque) ainda não foi decidida: faça o ícone da skill atual `skill_pulse` (explosão/pulso) e deixe-o fácil de trocar.
**Fazer:** PNGs em 2x com fundo transparente em `assets/ui/` (um por arquivo, snake_case) e `assets/ui/README.md` com arquivo, tamanho e uso:
- 5 ícones de upgrade: Atk power (espada), Atk spd (setas duplas), Defesa (escudo hexagonal), Vida máxima (coração com cruz), Cooldown (ampulheta);
- ícone da skill de área, cadeado dos slots, estrela de Partículas, pausa;
- moldura/fundo do botão de upgrade nos 3 estados (normal, apagado, MAX);
- moldura circular das skills (pronta, recarga, bloqueada);
- pílula de barra (trilho e preenchimento);
- painel com moldura (9-patch, margens documentadas);
- botão grande (normal e pressionado).

Legíveis em 44 px. Sem copiar jogos existentes. Registre em `assets/LICENSES.md` com **edição pontual** (outro agente também edita esse arquivo). Não edite cenas, temas nem scripts (T-138 é do AG02).
**Arquivos permitidos:** `assets/ui/`, `assets/LICENSES.md`, `docs/arte.md` (ajustes).
**Validação:** confira cada PNG visualmente (folha de contato) e a legibilidade em tamanho pequeno.
**Entrega:** no máximo 10 linhas.
