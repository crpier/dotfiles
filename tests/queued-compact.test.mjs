import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { stripTypeScriptTypes } from "node:module";
import { test } from "node:test";

const host = `export class CustomEditor {}`;
const source = stripTypeScriptTypes(await readFile(new URL("../pi-extensions/queued-compact.ts", import.meta.url), "utf8"))
  .replace('"@earendil-works/pi-coding-agent"', JSON.stringify(`data:text/javascript,${encodeURIComponent(host)}`));
const { default: extension } = await import(`data:text/javascript,${encodeURIComponent(source)}`);

function harness() {
  let idle = false, pendingMessages = false;
  const handlers = new Map(), commands = new Map(), notices = [], compactions = [];
  const ctx = {
    mode: "rpc", hasUI: true,
    isIdle: () => idle,
    hasPendingMessages: () => pendingMessages,
    ui: { notify: text => notices.push(text) },
    compact: options => compactions.push(options),
  };
  extension({ on: (name, fn) => handlers.set(name, fn), registerCommand: (name, definition) => commands.set(name, definition) });
  return {
    notices, compactions,
    idle: value => { idle = value; },
    pendingMessages: value => { pendingMessages = value; },
    emit: name => handlers.get(name)?.({}, ctx),
    command: (args = "") => commands.get("queued-compact").handler(args, ctx),
  };
}

// Fake timers exercise the existing drain queue without real waits or leaked timers.
test("RPC command waits through tool turns and agent_end until fully settled", async t => {
  t.mock.timers.enable({ apis: ["setTimeout"] });
  const h = harness(); h.emit("session_start");
  await h.command("  Keep the test findings  ");
  h.emit("turn_end"); h.emit("agent_end"); t.mock.timers.tick(250);
  assert.equal(h.compactions.length, 0);
  h.idle(true); h.emit("agent_settled");
  assert.equal(h.compactions.length, 1);
  assert.equal(h.compactions[0].customInstructions, "Keep the test findings");
  h.compactions[0].onComplete();
  t.mock.timers.tick(250); h.emit("agent_settled");
  assert.equal(h.compactions.length, 1);
  assert.ok(h.notices.includes("Queued compaction completed"));
});

test("idle command starts compaction and surfaces failure", async () => {
  const h = harness(); h.idle(true); await h.command();
  assert.equal(h.compactions.length, 1);
  assert.equal(h.compactions[0].customInstructions, undefined);
  h.compactions[0].onError(new Error("test failure"));
  assert.ok(h.notices.includes("Queued compaction failed: test failure"));
});

test("repeated busy requests coalesce and wait for pending messages", async t => {
  t.mock.timers.enable({ apis: ["setTimeout"] });
  const h = harness(); await h.command("old"); await h.command("latest");
  h.idle(true); h.pendingMessages(true); h.emit("agent_settled");
  t.mock.timers.tick(250); assert.equal(h.compactions.length, 0);
  h.pendingMessages(false); h.emit("agent_settled");
  assert.equal(h.compactions.length, 1);
  assert.equal(h.compactions[0].customInstructions, "latest");
});

for (const event of ["session_compact", "session_shutdown"]) {
  test(`${event} clears queued work`, async t => {
    t.mock.timers.enable({ apis: ["setTimeout"] });
    const h = harness(); await h.command(); h.emit(event);
    h.idle(true); h.emit("agent_settled"); t.mock.timers.tick(1000);
    assert.equal(h.compactions.length, 0);
  });
}
