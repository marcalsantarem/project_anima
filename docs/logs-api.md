# API de logs de teste (decisão 58)

Telemetria **só de teste**: o jogador aperta "Enviar log" no Resultado e o log da partida vai para uma tabela no Neon. Não é o backend do jogo (Firebase/Nakama segue em aberto).

## Contrato

`POST /api/log` (redirect para a Netlify Function `netlify/functions/log.mjs`)

- Cabeçalhos: `Content-Type: application/json`, `X-Anima-Key: <chave de cliente>` (não é segredo; só barra robô; valor em `LOG_CLIENT_KEY`).
- Corpo (JSON, máx. 200 KB):
  `version` (texto, ex. `0.1.0`), `build` (texto, hash/data do build), `platform` (texto, ex. `web`), `user_agent` (texto), `result` (`victory` | `defeat` | `quit` | nulo), `wave` (int), `duration_s` (número), `log` (texto do gravador de logs).
- Respostas: `201 {"id": n}` ok · `400` JSON/campo inválido · `401` chave errada · `413` grande demais · `429` limite por IP · `500` falha no banco (sem detalhes).
- Rate limit: 20 envios por hora por IP (guardar só o **hash** do IP com sal, nunca o IP).
- CORS: só a origem do site (`*.netlify.app` do projeto e `localhost`).

## Tabela `logs` (Neon, Postgres)

`id bigserial pk`, `created_at timestamptz default now()`, `version text`, `build text`, `platform text`, `user_agent text`, `result text`, `wave int`, `duration_s real`, `ip_hash text`, `content text`. Índice em `created_at` e em `ip_hash`. Limpeza: apagar linhas com mais de 30 dias.

## Segredos

`DATABASE_URL` (Neon) fica só nas variáveis do Netlify (escopo Functions) e, para testes locais, no `.env` ignorado pelo git. **Nunca** em código, docs, logs, briefings ou commits, nem impresso no terminal.

## Deploy (T-270)

- `netlify.toml` (raiz): funções em `netlify/functions`; `/api/log` → `/.netlify/functions/log` (200). O workflow `deploy-web.yml` instala `netlify/package.json` (se existir) e publica com `--functions=netlify/functions`.
- Variáveis no Netlify (Site settings → Environment variables, escopo **Functions**; vale para todos os contextos de deploy):
  - `DATABASE_URL`: string do Neon (segredo; já cadastrada).
  - `LOG_CLIENT_KEY`: chave de cliente; padrão `anima-teste`. A função e o jogo (AG02) usam o mesmo valor como fallback, então a variável é opcional.
- Local: `npm i -g netlify-cli`, `cd netlify && npm install`, e na raiz `netlify dev` (carrega o `.env` com `DATABASE_URL`; o site precisa estar vinculado com `netlify link`). Teste: `curl -X POST localhost:8888/api/log -H "X-Anima-Key: anima-teste" -H "Content-Type: application/json" -d "{...}"`.
- Passo a passo do dono: (1) confirmar `DATABASE_URL` no Netlify; (2) criar a tabela `logs` no Neon (SQL do AG05); (3) após o merge do AG05, dar push em `dev`; (4) conferir em Deploys > Functions que `log` aparece; (5) testar `POST https://dev--projectanimagame.netlify.app/api/log`.

## Implementação (T-267/T-268)

- Contrato revisado, sem mudanças de rota. Acréscimos: `405` para método não-POST; `OPTIONS` (preflight CORS) responde `204`; limites por campo: `version` 32, `build` 64, `platform` 32, `user_agent` 512 caracteres; `wave` inteiro 0–10000; `duration_s` 0–86400; `log` não vazio, até 200 KB; `content` é `NOT NULL`.
- Variáveis: `DATABASE_URL` e `LOG_CLIENT_KEY` (obrigatórias no Netlify, escopo Functions); `LOG_IP_SALT` (opcional; sem ela, o sal é derivado da `DATABASE_URL`). O mesmo valor de `LOG_CLIENT_KEY` vai no cliente (AG02), em build de teste.
- Código: `netlify/functions/log.mjs` (+ `netlify/lib/validate.mjs`), `netlify/sql/001_logs.sql`, `netlify/run-sql.mjs` (aplica o SQL: `node netlify/run-sql.mjs netlify/sql/001_logs.sql`), testes em `netlify/test` (`cd netlify && npm test`; o e2e usa o `.env` da raiz e apaga a linha que insere).
- O Netlify precisa rodar `npm install` em `netlify/` (o AG10 deve apontar `[functions] directory = "netlify/functions"` no `netlify.toml`; a rota `/api/log` já vem do `config.path` da função).

## ADR: por que Neon + Netlify Function

- **Neon (Postgres free):** SQL de verdade para consultar os logs, sem servidor para manter, driver HTTP serverless (sem pool de conexões em função efêmera). Não define o backend do jogo.
- **Netlify Function, sem Render:** o site já fica no Netlify; a função é do mesmo domínio (sem CORS em produção) e não "dorme" como o plano free do Render, que atrasaria o 1º envio.
- **Limites de segurança (aceitos):** a chave `X-Anima-Key` vai no cliente, então **não é segredo**: só barra robôs ingênuos. A defesa real é o conjunto: validação estrita, 200 KB por envio, 20 envios/h por hash de IP (um atacante com muitos IPs ainda pode encher o banco; o teto é o plano free do Neon, e a limpeza de 30 dias ajuda), mensagens de erro genéricas e conteúdo tratado só como texto (parâmetros do driver, nunca concatenado em SQL). Se houver abuso: trocar a chave e/ou desligar o botão no build. Dados guardados: sem IP, só hash com sal.
