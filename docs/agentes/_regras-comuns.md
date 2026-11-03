# Regras comuns às sessões especialistas

Valem para todos os agentes `AGxx`. Elas complementam o `CLAUDE.md`, que é carregado automaticamente.

1. **O líder é o seu único interlocutor.** Você recebe tarefas dele e reporta a ele. Não peça decisões ao dono do projeto.
2. **Economia de tokens:**
   - Leia só o necessário.
   - Não reexplique o briefing.
   - O relatório final tem no máximo 10 linhas: o que mudou (arquivos), o que não foi verificado e as dúvidas bloqueantes.
3. **Escopo:**
   - Edite apenas as suas pastas e os arquivos listados no briefing.
   - Precisa mexer fora delas? Pare e pergunte ao líder.
   - Arquivos compartilhados (`project.godot`, autoloads, Input Map, `export_presets.cfg`) só com autorização explícita.
4. **Git:**
   - Trabalhe na `dev`, na mesma pasta.
   - **Não faça commit nem push, e não crie branches.** Quem commita é o líder.
5. **Decisões:**
   - Siga o [docs/decisoes.md](../decisoes.md).
   - Itens em "Proposta" ou "A definir" não são regra. Se a tarefa depender de um deles, pergunte ao líder.
6. **Código:**
   - GDScript tipado. Identificadores em inglês, comentários em pt-BR (só quando necessário).
   - Valores de balanceamento ficam em `data/` (Resources), nunca fixos no código.
   - Respeite as regras de dependência de [docs/estrutura.md](../estrutura.md).
