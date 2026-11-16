# Validação

## O líder confere toda entrega

- O relatório do agente **não é prova**. Antes de commitar, o líder:
  - roda a suíte de testes inteira ele mesmo;
  - confere a **contagem** de testes (se caiu ou não subiu como esperado, algum arquivo pode ter sido ignorado);
  - procura erros de carregamento (ex.: no GUT, script com "Parse error" é pulado em silêncio e o total "passa");
  - confere o `git status` (arquivos fora do escopo do briefing).
- Se dois agentes trabalharam em paralelo, a suíte é rodada **depois que os dois terminam**.
- Falha causada pela mudança de outro agente (ex.: teste antigo com um preço velho) o líder resolve ou devolve, e registra.

## Validação do marco (QA)

A última task de cada marco é do **AG03 (QA)** com o líder. O QA:

- roda a suíte 3 vezes (estabilidade);
- testa as regras novas, a tela nova e a integração com o resto;
- verifica regressão dos marcos anteriores;
- faz o build de release e testa no navegador real, medindo tamanho;
- tira capturas nos tamanhos de tela alvo;
- classifica as pendências conhecidas;
- escreve `docs/qa/qa-MN.md` com o **veredito**: passa / passa com ressalvas / não passa, com bloqueantes, graves e menores, cada um com arquivo:linha e passo a passo;
- termina com um **roteiro curto para o dono** testar no aparelho real.

O QA **não corrige**: reporta. Pode escrever testes novos que provam o defeito.

## Depois do veredito

- **Não passa / graves:** vira uma task de ressalvas no mesmo marco, com briefing para o agente dono; o líder confere e acrescenta um "Reteste" no relatório do QA.
- **Passa com ressalvas:** as menores podem ir para o backlog; o líder lista o que ficou.
- Em seguida: versão, commit, PR e tag ([Deploy.md](Deploy.md)).
