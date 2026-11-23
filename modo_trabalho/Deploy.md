# Fechamento do marco: PR, tag e deploy

## Sequência

1. A task de validação do marco passa ([Validacao.md](Validacao.md)).
2. Um agente (o arquiteto) sobe o **número da versão** nos arquivos do projeto e nos testes que conferem a versão.
3. O líder roda a suíte, faz commit e push na `dev`.
4. O líder entrega ao dono, **no chat**, o **título**, a **descrição** e o **link** do PR.
5. O dono abre o PR `dev` → `main` e faz o merge.
6. O dono avisa ("Mesclado", "Feito"). O líder cria a **tag** no commit do merge na `main` e faz push da tag.
7. A tag dispara o build e o deploy num **link de teste** da versão. O dono testa no aparelho alvo.

## Link para abrir o PR

```
https://github.com/<dono>/<repo>/compare/main...dev?expand=1
```

O link vai **sempre** junto do texto, pronto para clicar.

## Texto do PR

Sempre colado na própria mensagem do chat (não só em arquivo), em pt-BR, em blocos de código prontos para copiar.

**Título:** `vX.Y.Z: <nome do marco> (<resumo de poucas palavras>)`

**Descrição:**
```
## O que entra
- <funcionalidade 1, em uma linha>
- <funcionalidade 2>
- Versão X.Y.Z.

## Validação
- Testes: N/N verdes.
- QA (`docs/qa/qa-MN.md`): <veredito>; <grave corrigido, se houve>.
- <medidas relevantes: tamanho do build, desempenho>.

## Pendente para o dono
<o que só o dono consegue validar, ex.: roteiro no aparelho real>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Tag

- Formato `vX.Y.Z`, igual à versão do marco (`v0.2.2`).
- Criada **só depois do merge**, apontando para o commit de merge na `main`:
  ```bash
  git fetch origin
  git tag v0.2.2 origin/main
  git push origin v0.2.2
  ```
- Não se cria branch por versão: a tag é o marco do histórico.

## Deploy

- **Qualquer tag** dispara build e publica num endereço próprio da versão (ex.: `v0-2-2--<site>.netlify.app`), nunca em produção.
- Em projeto com build (ex.: jogo exportado), o build roda no CI (GitHub Actions) disparado pela tag.
- Em **site estático** sem build, a publicação é direta no Netlify a partir do repositório. Não há CI de build.
- Depois de criar a tag, o líder informa o link de teste. Se não conferiu que o deploy terminou, diz isso.
