// Uso: node netlify/run-sql.mjs netlify/sql/001_logs.sql  (le DATABASE_URL de ../.env ou do ambiente)
import { readFileSync } from "node:fs";
import { neon } from "@neondatabase/serverless";
try {
  for (const l of readFileSync(new URL("../.env", import.meta.url), "utf8").split(/\r?\n/)) {
    const m = l.match(/^([A-Z_]+)=(.*)$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].replace(/^['"]|['"]$/g, "");
  }
} catch { /* sem .env */ }
const sql = neon(process.env.DATABASE_URL);
const stmts = readFileSync(process.argv[2], "utf8").split(";").map((s) => s.trim()).filter(Boolean);
for (const s of stmts) await sql.query(s);
console.log("ok:", stmts.length, "comandos");
