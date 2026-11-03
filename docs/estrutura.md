# Estrutura de pastas (Proposta)

O projeto Godot fica na **raiz do repositório**: quando for criado, o `project.godot` mora aqui. O código é organizado **por domínio**, e cada cena (`.tscn`) fica junto do seu script.

```
addons/          Plugins de terceiros (ex.: framework de testes). Não editar.
assets/          Arquivos de mídia brutos, sem lógica.
  sprites/  audio/  fonts/  vfx/
data/            Resources (.tres) de balanceamento e conteúdo. Nenhuma lógica aqui.
  skills/  cards/  enemies/  waves/  stats/
src/
  core/          Autoloads e infraestrutura: estado global, config, troca de cenas.
  backend/       Interface `Backend` e suas implementações (local primeiro).
  match/         A partida: arena, Anima, ataque automático, skills, inimigos, ondas, projéteis.
  meta/          Lógica pura fora da partida: cards, fusão, atributos, talentos, economia.
  ui/            HUD, menus, hangar e componentes visuais reutilizáveis.
tests/
  unit/          Testes de lógica pura (principalmente src/meta).
  integration/   Testes que instanciam cenas.
web/             HTML shell customizado da exportação Web e scripts JS (bridges).
docs/            GDD, decisões, regras e planejamento.
build/           Saída das exportações (ignorada pelo git).
```

## Regras de dependência

- `match/` não depende de `meta/` nem de `backend/`. Ela recebe a configuração da partida e devolve um resultado.
- `meta/` não depende de cenas nem de rede.
- Somente `backend/` conversa com serviços externos.
- `ui/` pode ler de todos, mas a lógica fica nos módulos de domínio.

As pastas vazias têm um `.gitkeep`. Remova-o quando a pasta ganhar arquivos.
