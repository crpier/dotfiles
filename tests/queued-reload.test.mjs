import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { stripTypeScriptTypes } from "node:module";
import { test } from "node:test";

// Only the host-provided CustomEditor constructor is replaced. Test the actual
// extension's registrations, editor wrapper, and lifecycle handlers.
const mockHost = `export class CustomEditor {
  text = ''; history = []; forwarded = [];
  getText() { return this.text; }
  setText(text) { this.text = text; }
  addToHistory(text) { this.history.push(text); }
  handleInput(data) { this.forwarded.push(data); }
}`;
const hostURL = `data:text/javascript,${encodeURIComponent(mockHost)}`;
const source = stripTypeScriptTypes(await readFile(new URL("../pi-extensions/queued-reload/index.ts", import.meta.url), "utf8"))
  .replace('"@earendil-works/pi-coding-agent"', JSON.stringify(hostURL));
const { default: extension } = await import(`data:text/javascript,${encodeURIComponent(source)}`);

function harness({ idle = false, mode = "tui", baseFactory } = {}) {
  const events = new Map(), commands = new Map(), sent = [], notices = [];
  let factory = baseFactory, reloads = 0;
  const ctx = {
    mode, hasUI: mode === "tui", isIdle: () => idle,
    ui: {
      getEditorComponent: () => factory,
      setEditorComponent: value => { factory = value; },
      notify: text => notices.push(text),
    },
    reload: async () => { reloads++; },
  };
  extension({
    on: (name, handler) => events.set(name, handler),
    registerCommand: (name, command) => commands.set(name, command),
    sendUserMessage: (text, options) => sent.push({ text, options }),
  });
  const emit = (name, event = {}) => events.get(name)?.(event, ctx);
  emit("session_start");
  const keys = { matches: (data, action) => data === (action === "tui.input.submit" ? "enter" : "followUp") };
  const editor = factory?.({}, {}, keys);
  return {
    ctx, editor, sent, notices, emit,
    idle: value => { idle = value; },
    factory: () => factory,
    replaceFactory: value => { factory = value; },
    reloads: () => reloads,
    command: () => commands.get("queued-reload").handler("", ctx),
    submit: (text = "/reload", key = "enter") => { editor.setText(text); editor.handleInput(key); },
  };
}

test("busy /reload is consumed without interrupting the agent", () => {
  const h = harness(); h.submit();
  assert.equal(h.editor.getText(), "");
  assert.deepEqual(h.editor.history, ["/reload"]);
  assert.deepEqual(h.editor.forwarded, []);
  assert.equal(h.sent.length, 0); assert.equal(h.reloads(), 0);
  assert.match(h.notices[0], /queued/);
});

test("waits for agent_settled, not individual tool turns or agent_end", async () => {
  const h = harness(); h.submit();
  h.emit("turn_end"); h.emit("agent_end");
  assert.equal(h.sent.length, 0);
  h.idle(true); h.emit("agent_settled");
  assert.deepEqual(h.sent, [{ text: "/queued-reload", options: { expandPromptTemplates: true } }]);
  await h.command(); assert.equal(h.reloads(), 1);
});

test("repeated requests and settled notifications dispatch only once", async () => {
  const h = harness(); h.submit(); h.submit(); h.submit();
  h.idle(true); h.emit("agent_settled"); h.emit("agent_settled"); h.submit();
  assert.equal(h.sent.length, 1); assert.equal(h.notices.length, 1);
  await h.command(); assert.equal(h.reloads(), 1);
});

test("idle /reload dispatches immediately", async () => {
  const h = harness({ idle: true }); h.submit("  /reload  ");
  assert.equal(h.sent.length, 1); await h.command(); assert.equal(h.reloads(), 1);
});

test("follow-up shortcut queues reload rather than sending it to the model", () => {
  const h = harness(); h.submit("/reload", "followUp");
  assert.equal(h.notices.length, 1); assert.deepEqual(h.editor.forwarded, []);
});

test("unrelated submissions, arguments, and ordinary keystrokes pass through", () => {
  const h = harness();
  h.submit("hello"); h.submit("/reload-extra"); h.submit("/reload argument"); h.submit("/reload", "x");
  assert.deepEqual(h.editor.forwarded, ["enter", "enter", "enter", "x"]);
  assert.equal(h.notices.length, 0); assert.equal(h.sent.length, 0);
});

test("command requeues if the agent becomes busy before dispatch completes", async () => {
  const h = harness({ idle: true }); h.submit();
  h.idle(false); await h.command(); assert.equal(h.reloads(), 0);
  h.idle(true); h.emit("agent_settled"); assert.equal(h.sent.length, 2);
  await h.command(); assert.equal(h.reloads(), 1);
});

test("aborted runs also drain once fully settled", async () => {
  const h = harness(); h.submit(); h.idle(true); h.emit("agent_settled", { aborted: true });
  await h.command(); assert.equal(h.reloads(), 1);
});

test("direct /queued-reload works in non-TUI modes", async () => {
  const h = harness({ mode: "rpc" });
  assert.equal(h.factory(), undefined); await h.command(); assert.equal(h.sent.length, 0);
  h.idle(true); h.emit("agent_settled"); await h.command(); assert.equal(h.reloads(), 1);
});

test("wraps and restores an existing editor rather than replacing its behavior", () => {
  const base = () => ({ text: "", forwarded: [], getText() { return this.text; }, setText(t) { this.text = t; }, handleInput(d) { this.forwarded.push(d); } });
  const h = harness({ baseFactory: base }); h.submit("hello");
  assert.deepEqual(h.editor.forwarded, ["enter"]);
  h.emit("session_shutdown"); assert.equal(h.factory(), base);
});

test("shutdown cancels pending reload and respects another editor's cleanup", () => {
  const h = harness(); h.submit();
  const other = () => {}; h.replaceFactory(other); h.emit("session_shutdown");
  assert.equal(h.factory(), other);
  h.idle(true); h.emit("agent_settled"); assert.equal(h.sent.length, 0);
});

test("expanded editor text is used when available", () => {
  const h = harness(); h.editor.getExpandedText = () => "/reload";
  h.submit("collapsed display text"); assert.equal(h.notices.length, 1);
});
