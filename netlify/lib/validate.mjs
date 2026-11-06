export const MAX_BYTES = 200 * 1024;
const RESULTS = ["victory", "defeat", "quit"];
const TEXT_LIMITS = { version: 32, build: 64, platform: 32, user_agent: 512 };

export function validateBody(b) {
  if (b === null || typeof b !== "object" || Array.isArray(b)) return { error: "corpo invalido" };
  const out = {};
  for (const [k, max] of Object.entries(TEXT_LIMITS)) {
    const v = b[k];
    if (typeof v !== "string" || v.length > max) return { error: `campo invalido: ${k}` };
    out[k] = v;
  }
  if (b.result !== null && b.result !== undefined && !RESULTS.includes(b.result)) return { error: "campo invalido: result" };
  out.result = b.result ?? null;
  if (!Number.isInteger(b.wave) || b.wave < 0 || b.wave > 10000) return { error: "campo invalido: wave" };
  out.wave = b.wave;
  if (typeof b.duration_s !== "number" || !Number.isFinite(b.duration_s) || b.duration_s < 0 || b.duration_s > 86400) return { error: "campo invalido: duration_s" };
  out.duration_s = b.duration_s;
  if (typeof b.log !== "string" || b.log.length === 0 || b.log.length > MAX_BYTES) return { error: "campo invalido: log" };
  out.log = b.log;
  return { value: out };
}

export function corsOrigin(origin) {
  if (!origin) return null;
  try {
    const u = new URL(origin);
    if (u.hostname === "localhost" || u.hostname === "127.0.0.1") return origin;
    if (u.protocol === "https:" && u.hostname.endsWith(".netlify.app")) return origin;
  } catch { /* ignora */ }
  return null;
}
