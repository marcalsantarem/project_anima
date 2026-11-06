import { neon } from "@neondatabase/serverless";
import { createHash, timingSafeEqual } from "node:crypto";
import { validateBody, corsOrigin, MAX_BYTES } from "./validate.mjs";

const RATE_LIMIT = 20; // envios por hora por IP

function json(status, body, origin) {
  const headers = { "Content-Type": "application/json" };
  const o = corsOrigin(origin);
  if (o) {
    headers["Access-Control-Allow-Origin"] = o;
    headers["Vary"] = "Origin";
  }
  return new Response(JSON.stringify(body), { status, headers });
}

function keyOk(got) {
  const want = process.env.LOG_CLIENT_KEY;
  if (!want || typeof got !== "string") return false;
  const a = createHash("sha256").update(got).digest();
  const b = createHash("sha256").update(want).digest();
  return timingSafeEqual(a, b);
}

export default async function handler(req, context) {
  const origin = req.headers.get("origin");
  if (req.method === "OPTIONS") {
    const o = corsOrigin(origin);
    if (!o) return new Response(null, { status: 403 });
    return new Response(null, { status: 204, headers: {
      "Access-Control-Allow-Origin": o, "Vary": "Origin",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, X-Anima-Key",
      "Access-Control-Max-Age": "86400" } });
  }
  if (req.method !== "POST") return json(405, { error: "metodo nao permitido" }, origin);
  if (!keyOk(req.headers.get("x-anima-key"))) return json(401, { error: "nao autorizado" }, origin);

  const declared = Number(req.headers.get("content-length") || 0);
  if (declared > MAX_BYTES + 4096) return json(413, { error: "grande demais" }, origin);
  const raw = await req.text();
  if (raw.length > MAX_BYTES + 4096) return json(413, { error: "grande demais" }, origin);
  let body;
  try { body = JSON.parse(raw); } catch { return json(400, { error: "json invalido" }, origin); }
  const v = validateBody(body);
  if (v.error) return json(400, { error: v.error }, origin);
  const d = v.value;

  try {
    const sql = neon(process.env.DATABASE_URL);
    const ip = context?.ip || req.headers.get("x-nf-client-connection-ip") || "unknown";
    const salt = process.env.LOG_IP_SALT || process.env.DATABASE_URL;
    const ipHash = createHash("sha256").update(salt + "|" + ip).digest("hex");

    const [{ n }] = await sql`SELECT count(*)::int AS n FROM logs WHERE ip_hash = ${ipHash} AND created_at > now() - interval '1 hour'`;
    if (n >= RATE_LIMIT) return json(429, { error: "limite atingido" }, origin);

    const [row] = await sql`INSERT INTO logs (version, build, platform, user_agent, result, wave, duration_s, ip_hash, content)
      VALUES (${d.version}, ${d.build}, ${d.platform}, ${d.user_agent}, ${d.result}, ${d.wave}, ${d.duration_s}, ${ipHash}, ${d.log})
      RETURNING id`;
    // limpeza barata (indice em created_at)
    await sql`DELETE FROM logs WHERE created_at < now() - interval '30 days'`;
    return json(201, { id: Number(row.id) }, origin);
  } catch {
    return json(500, { error: "falha no servidor" }, origin);
  }
}

export const config = { path: "/api/log" };
