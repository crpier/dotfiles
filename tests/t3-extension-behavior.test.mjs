import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { stripTypeScriptTypes } from "node:module";
import { test } from "node:test";

async function load(path) {
  // Exercise actual extension code with host imports replaced, without starting Pi.
  const source = stripTypeScriptTypes(await readFile(new URL(`../pi-extensions/${path}`, import.meta.url), "utf8"))
    .replace(/^import[\s\S]*?from\s*["'][^"']+["'];\s*/gm, "");
  const host = "const Type = new Proxy({}, { get: () => () => ({}) });\n";
  return (await import(`data:text/javascript,${encodeURIComponent(host + source)}`)).default;
}

function withT3(enabled, fn) {
  const previous = process.env.T3_PI_MCP_EXTENSION_PATH;
  if (enabled) process.env.T3_PI_MCP_EXTENSION_PATH = "/test/t3-extension.ts";
  else delete process.env.T3_PI_MCP_EXTENSION_PATH;
  try { return fn(); }
  finally {
    if (previous === undefined) delete process.env.T3_PI_MCP_EXTENSION_PATH;
    else process.env.T3_PI_MCP_EXTENSION_PATH = previous;
  }
}

for (const path of ["loop/index.ts", "auto-name/index.ts", "full-compact/index.ts", "context-token-footer.ts", "edit-last-agent-message.ts", "turn-bell.ts"]) {
  const extension = await load(path);
  test(`${path}: registers nothing under T3; still registers outside T3`, () => {
    let registrations = 0;
    const sentinel = new Error("first registration");
    const pi = new Proxy({}, { get: () => () => { registrations++; throw sentinel; } });
    withT3(true, () => extension(pi));
    assert.equal(registrations, 0);
    withT3(false, () => assert.throws(() => extension(pi), error => error === sentinel));
    assert.equal(registrations, 1);
  });
}

const statsExtension = await load("turn-stats.ts");
function statsHarness() {
  const handlers = new Map(), entries = [], notices = [];
  statsExtension({
    on: (name, handler) => handlers.set(name, handler),
    registerEntryRenderer: () => {},
    appendEntry: (type, data) => entries.push({ type, data }),
  });
  const ctx = { mode: "rpc", hasUI: true, ui: { notify: (text, level) => notices.push({ text, level }) } };
  const emit = (name, event = {}) => handlers.get(name)?.(event, ctx);
  const run = () => {
    emit("agent_start");
    emit("turn_start", { turnIndex: 0, timestamp: Date.now() });
    emit("message_update", { assistantMessageEvent: { type: "text_delta", delta: "hello" } });
    emit("message_end", { message: { role: "assistant" } });
    emit("turn_end", { turnIndex: 0, message: { role: "assistant", usage: { output: 123, cost: { total: 0.0123 } } } });
    emit("agent_settled");
  };
  return { ctx, entries, notices, emit, run };
}

test("T3 turn stats persist and emit exactly one notice per settled run", () => withT3(true, () => {
  const h = statsHarness();
  h.run(); h.emit("agent_settled");
  assert.equal(h.entries.length, 1);
  assert.equal(h.notices.length, 1);
  assert.equal(h.entries[0].data.outputTokens, 123);
  assert.equal(h.entries[0].data.estimatedCostUsd, 0.0123);
  assert.match(h.notices[0].text, /123 output tokens.*tok\/s avg.*TTFT avg.*\$0\.0123/);
  assert.doesNotMatch(h.notices[0].text, /Turn stats:/);
  assert.equal(h.notices[0].level, "info");
}));

test("standalone RPC still saves stats without a T3 notice", () => withT3(false, () => {
  const h = statsHarness(); h.run();
  assert.equal(h.entries.length, 1);
  assert.equal(h.notices.length, 0);
}));

test("TUI and command-only settlement do not emit T3 stats notices", () => withT3(true, () => {
  const h = statsHarness();
  h.emit("agent_settled");
  assert.equal(h.entries.length, 0);
  h.ctx.mode = "tui"; h.run();
  assert.equal(h.entries.length, 1);
  assert.equal(h.notices.length, 0);
}));
