// Ponta a ponta contra o Neon (usa DATABASE_URL do .env da raiz; pula se ausente).
import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

try {
  for (const l of readFileSync(new URL("../../.env", import.meta.url), "utf8").split(/\r?\n/)) {
    const m = l.match(/^([A-Z_]+)=(.*)$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].replace(/^['"]|['"]$/g, "");
  }
} catch { /* sem .env */ }

test("insere e apaga via handler", { skip: !process.env.DATABASE_URL }, async () => {
  process.env.LOG_CLIENT_KEY = "chave-de-teste";
  const { default: handler } = await import("../functions/log.mjs");
  const { neon } = await import("@neondatabase/serverless");
  const mk = (key, body) => new Request("http://x/api/log", { method: "POST",
    headers: { "content-type": "application/json", "x-anima-key": key, origin: "http://localhost:8060" },
    body: JSON.stringify(body) });
  const body = { version: "0.0.0", build: "e2e-test", platform: "test", user_agent: "node", result: "quit", wave: 1, duration_s: 1, log: "e2e" };
  assert.equal((await handler(mk("errada", body), { ip: "203.0.113.9" })).status, 401);
  assert.equal((await handler(mk("chave-de-teste", { ...body, wave: "x" }), { ip: "203.0.113.9" })).status, 400);
  const res = await handler(mk("chave-de-teste", body), { ip: "203.0.113.9" });
  assert.equal(res.status, 201);
  assert.equal(res.headers.get("access-control-allow-origin"), "http://localhost:8060");
  const { id } = await res.json();
  const sql = neon(process.env.DATABASE_URL);
  const rows = await sql`DELETE FROM logs WHERE id = ${id} AND build = 'e2e-test' RETURNING id`;
  assert.equal(rows.length, 1);
});
