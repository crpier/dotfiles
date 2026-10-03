import assert from "node:assert/strict";
import { test } from "node:test";
import {
	type ExtensionAPI,
	type ExtensionCommandContext,
	type RegisteredCommand,
	SessionManager,
} from "@earendil-works/pi-coding-agent";
import extension, { parseTitle } from "../pi-extensions/auto-name/index.ts";

const usage = { input: 15, output: 5, cacheRead: 5000, cacheWrite: 0, totalTokens: 5020,
	cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0.01 } };
const response = {
	role: "assistant" as const, content: [{ type: "text" as const, text: "Cache-Friendly Session Naming" }],
	api: "openai-responses" as const, provider: "test", model: "test", usage,
	stopReason: "stop" as "stop" | "error" | "length" | "toolUse", timestamp: 2,
};
const model = { id: "test", name: "test", api: "openai-responses", provider: "test", baseUrl: "https://example.invalid",
	reasoning: true, input: ["text"], cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
	contextWindow: 128000, maxTokens: 8192 } as ExtensionCommandContext["model"];

function harness(complete = async () => response) {
	const manager = SessionManager.inMemory("/tmp");
	manager.appendMessage({ role: "system", content: "Original system prompt", timestamp: 0,
		toolsAdded: [{ name: "read", description: "Read", parameters: { type: "object" } as never }] });
	manager.appendMessage({ role: "user", content: "Implement session naming", timestamp: 1 });
	manager.appendMessage({ ...response, content: [{ type: "text", text: "Final chat response" }] });
	const events = new Map<string, (event: never, ctx: ExtensionCommandContext) => void>();
	let command: RegisteredCommand | undefined;
	const notices: string[] = [];
	const calls: { model: unknown; context: { messages: unknown[] }; options: Record<string, unknown> }[] = [];
	let idle = true;
	let currentName: string | undefined;
	const api = {
		on(name: string, handler: (event: never, ctx: ExtensionCommandContext) => void) { events.set(name, handler); },
		registerCommand(name: string, value: RegisteredCommand) { assert.equal(name, "auto-name"); command = value; },
		getActiveTools: () => ["read"], getAllTools: () => [],
		getSettings: () => ({ thinkingBudgets: { high: 9000 }, transport: "sse" }),
		getSessionName: () => currentName,
		setSessionName(name: string) { currentName = name; manager.appendSessionInfo(name); },
	} as unknown as ExtensionAPI;
	extension(api);
	const ctx = {
		sessionManager: manager, model, thinkingLevel: "high", hasUI: true,
		getSystemPrompt: () => "Original system prompt", isIdle: () => idle, hasPendingMessages: () => false,
		ui: { notify: (message: string) => notices.push(message) },
		modelRegistry: { streamSimple(selected: unknown, context: { messages: unknown[] }, options: Record<string, unknown>) {
			calls.push({ model: selected, context, options });
			return { result: complete };
		} },
	} as unknown as ExtensionCommandContext;
	return { manager, ctx, calls, notices, name: () => currentName, busy: () => { idle = false; },
		emit: (name: string, event: unknown = {}) => events.get(name)?.(event as never, ctx),
		run: (args = "") => command!.handler(args, ctx) };
}

test("uses full structured history/current model/session identity without adding messages", async () => {
	const h = harness();
	const original = h.manager.getBranch();
	await h.run("Emphasize caching");
	assert.equal(h.name(), "Cache-Friendly Session Naming");
	assert.equal(h.calls[0].model, model);
	assert.equal(h.calls[0].options.sessionId, h.manager.getSessionId());
	assert.equal(h.calls[0].options.reasoning, "high");
	assert.deepEqual(h.calls[0].options.thinkingBudgets, { high: 9000 });
	assert.equal(h.calls[0].options.transport, "sse");
	assert.equal("maxTokens" in h.calls[0].options, false);
	assert.equal("toolChoice" in h.calls[0].options, false);
	assert.deepEqual(h.calls[0].context.messages.slice(0, -1), original.map((entry) => entry.type === "message" ? entry.message : undefined));
	assert.match(JSON.stringify(h.calls[0].context.messages.at(-1)), /Emphasize caching/);
	assert.deepEqual(h.manager.getBranch().slice(0, -1), original);
	assert.equal(h.manager.getBranch().at(-1)?.type, "session_info");
	assert.deepEqual(h.manager.buildSessionProjection().messages, original.map((entry) => entry.type === "message" ? entry.message : undefined));
	assert.match(h.notices.at(-1)!, /Cache read: 5,000/);
});

test("reuses observed request-local context and includes finalized last response", async () => {
	const h = harness();
	const anchor = h.manager.getLeafId();
	const messages = h.manager.buildSessionProjection().messages;
	h.emit("context_with_system", { messages: [...messages, { role: "user", content: "Request-local extension context", timestamp: 3 }] });
	h.manager.appendMessage({ ...response, timestamp: 4, content: [{ type: "text", text: "Latest final answer" }] });
	h.emit("agent_settled");
	assert.notEqual(h.manager.getLeafId(), anchor);
	await h.run();
	const sent = JSON.stringify(h.calls[0].context);
	assert.match(sent, /Request-local extension context/);
	assert.match(sent, /Latest final answer/);
	assert.equal(h.calls[0].context.messages.length, messages.length + 3);
});

test("honors compaction and context edits instead of resending raw history", async () => {
	const h = harness();
	const last = h.manager.getLeafId()!;
	h.manager.appendCompaction("Only summarized history remains", null, 1000);
	const latest = h.manager.appendMessage({ role: "user", content: "Original recent request", timestamp: 5 });
	h.manager.appendContextEdit(latest, { content: "Edited recent request" });
	await h.run();
	const sent = JSON.stringify(h.calls[0].context);
	assert.match(sent, /Only summarized history remains/);
	assert.match(sent, /Edited recent request/);
	assert.doesNotMatch(sent, /Original recent request|Implement session naming|Final chat response/);
	assert.ok(h.manager.getEntry(last));
});

test("busy agent is refused without making a paid request", async () => {
	const h = harness(); h.busy(); await h.run();
	assert.equal(h.calls.length, 0); assert.equal(h.name(), undefined);
});

test("context changes during the call discard the title", async () => {
	const h = harness(async () => {
		h.manager.appendMessage({ role: "user", content: "New task", timestamp: 5 });
		return response;
	});
	await h.run(); assert.equal(h.name(), undefined);
	assert.match(h.notices.at(-1)!, /Session changed/);
});

test("cancel and duplicate requests do not save a name", async () => {
	let resolve!: (value: typeof response) => void;
	const h = harness(() => new Promise((done) => { resolve = done; }));
	const running = h.run();
	await h.run(); assert.equal(h.calls.length, 1);
	await h.run("--cancel");
	assert.equal((h.calls[0].options.signal as AbortSignal).aborted, true);
	resolve(response); await running;
	assert.equal(h.name(), undefined); assert.match(h.notices.at(-1)!, /cancelled/);
});

for (const stopReason of ["error", "length", "toolUse"] as const) {
	test(`rejects ${stopReason} responses without touching the name`, async () => {
		const h = harness(async () => ({ ...response, stopReason }));
		const before = h.manager.getBranch();
		await h.run(); assert.equal(h.name(), undefined);
		assert.deepEqual(h.manager.getBranch(), before);
	});
}

test("validates titles", () => {
	assert.equal(parseTitle(' "Session Naming" '), "Session Naming");
	for (const text of ["", "First\nSecond", "x".repeat(101), "Bad\x1bTitle"]) assert.throws(() => parseTitle(text));
});
