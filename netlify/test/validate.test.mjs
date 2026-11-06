import test from "node:test";
import assert from "node:assert/strict";
import { validateBody, corsOrigin } from "../lib/validate.mjs";

const ok = { version: "0.1.0", build: "abc", platform: "web", user_agent: "ua", result: "victory", wave: 3, duration_s: 12.5, log: "x" };

test("valido", () => assert.ok(validateBody(ok).value));
test("result nulo", () => assert.equal(validateBody({ ...ok, result: null }).value.result, null));
test("result invalido", () => assert.ok(validateBody({ ...ok, result: "x" }).error));
test("wave nao int", () => assert.ok(validateBody({ ...ok, wave: 1.5 }).error));
test("duration invalida", () => {
  assert.ok(validateBody({ ...ok, duration_s: -1 }).error);
  assert.ok(validateBody({ ...ok, duration_s: "1" }).error);
});
test("log grande/vazio", () => {
  assert.ok(validateBody({ ...ok, log: "a".repeat(200 * 1024 + 1) }).error);
  assert.ok(validateBody({ ...ok, log: "" }).error);
});
test("texto longo", () => assert.ok(validateBody({ ...ok, user_agent: "a".repeat(513) }).error));
test("corpo nao objeto", () => { assert.ok(validateBody(null).error); assert.ok(validateBody([]).error); });
test("cors", () => {
  assert.equal(corsOrigin("http://localhost:8060"), "http://localhost:8060");
  assert.equal(corsOrigin("https://anima.netlify.app"), "https://anima.netlify.app");
  assert.equal(corsOrigin("https://evil.com"), null);
  assert.equal(corsOrigin("http://x.netlify.app"), null);
});
