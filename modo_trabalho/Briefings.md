# Briefings

O briefing é o pedido escrito do líder para um agente. Cada agente começa sem contexto, então o briefing precisa bastar sozinho, mas ser **curto**.

## Arquivo

- `docs/briefings/BRF-NNN_AGxx_<entrega>.md` (ex.: `BRF-158_AG04_nucleos-nivel-unico.md`).
- Numeração sequencial, nunca reaproveitada. Um briefing por agente por entrega.
- Entra no commit da task.

## Estrutura

```
# BRF-158 — AG04 — T-299 <título curto>
**Leia:** arquivo do agente, docs e código necessários (só o necessário). **Regra:** respostas curtas; sem commit/push/branches.
**Decisão do dono:** <o que foi decidido, se houver>.
**Contrato:** <nomes e formatos combinados com outro agente que trabalha em paralelo>.
**Fazer:** (1) … (2) … (3) … testes e docs a atualizar.
**Permitido:** <pastas/arquivos>. **Proibido:** <pastas/arquivos>.
**Pronto quando:** <critério verificável, ex.: suíte inteira verde>.
**Entrega:** até N linhas: <o que reportar, incluindo o que não foi verificado>.
```

## Boas práticas

- **Permitido / Proibido explícitos.** É o que evita dois agentes editarem o mesmo arquivo.
- **Pronto quando** verificável (testes verdes, captura conferida, número medido).
- Cite as **armadilhas conhecidas** (ex.: teste com erro de sintaxe ignorado em silêncio pelo framework).
- Defeitos conhecidos que o agente pode resolver de passagem entram como item "se couber".
- O QA recebe a lista de pendências conhecidas para **classificar**, não para descobrir de novo.
- Quando o agente volta com algo fora do escopo, o líder decide: novo briefing, mensagem ao mesmo agente, ou correção mínima própria.
- Briefing de versão é de duas linhas (ex.: "subir de 0.2.1 para 0.2.2 em X, Y e Z; suíte verde").
