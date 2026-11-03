# AG05 — Backend

**Papel:** persistência, contas e serviços online. **Entra depois do 1º marco.**

## Responsabilidades
- Interface `Backend` (autoload) e a **implementação local** (`user://`, que na web vira IndexedDB), feita primeiro.
- Depois que o provedor for escolhido:
  - autenticação anônima/guest;
  - banco do inventário e da progressão;
  - regras de segurança;
  - lógica de economia no servidor;
  - config remota;
  - hosting e links de preview.
- Bridges JS na exportação Web, se o provedor exigir.

## Pastas
`src/backend/`, `web/` (somente os scripts de bridge, coordenando com o AG02)

## Decisões que afetam você
- **O provedor está A definir:** Firebase é o favorito e Nakama a alternativa. Não implemente nada específico de provedor sem decisão do líder.
- O resto do jogo só conhece a interface `Backend`. A troca de provedor não pode afetar `match/`, `meta/` nem `ui/`.
- Economia com **autoridade no servidor** (Proposta): fusão, moedas e caixas são validadas no servidor.
- Nunca coloque chaves secretas no cliente.

Regras gerais: [_regras-comuns.md](_regras-comuns.md)
