import assert from "node:assert/strict";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test, type TestContext } from "node:test";
import {
	DEFAULT_COMPACTION_SETTINGS,
	type ExtensionAPI,
	type ExtensionCommandContext,
	type RegisteredCommand,
	SessionManager,
} from "@earendil-works/pi-coding-agent";
import extension from "../pi-extensions/full-compact/index.ts";
import { prepareFullCompaction } from "../pi-extensions/full-compact/preparation.ts";

const usage = { input: 10, output: 10, cacheRead: 0, cacheWrite: 0, totalTokens: 20,
	cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 } };
const response = {
	role: "assistant" as const,
	content: [{ type: "text" as const, text: "## Goal\nContinue the task" }],
	api: "openai-responses" as const, provider: "test", model: "test", usage,
	stopReason: "stop" as "stop" | "error" | "length", timestamp: Date.now(),
};
const model = {
	id: "test", name: "test", api: "openai-responses", provider: "test", baseUrl: "https://example.invalid",
	reasoning: false, input: ["text"], cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
	contextWindow: 128000, maxTokens: 8192,
} as ExtensionCommandContext["model"];

function user(manager: SessionManager, text: string) {
	return manager.appendMessage({ role: "user", content: text, timestamp: Date.now() });
}

function harness(manager: SessionManager, complete = async () => response) {
	let command: RegisteredCommand | undefined;
	const notices: string[] = [];
	const calls: { context: unknown; options: unknown }[] = [];
	let shutdown: (() => void) | undefined;
	let switchedTo: string | undefined;
	const api = {
		registerCommand(name: string, registered: RegisteredCommand) {
			assert.equal(name, "full-compact"); command = registered;
		},
		on(event: string, handler: () => void) { if (event === "session_shutdown") shutdown = handler; },
	} as unknown as ExtensionAPI;
	extension(api);
	const ctx = {
		cwd: manager.getCwd(), sessionManager: manager, model, thinkingLevel: "off", hasUI: true,
		ui: { notify: (message: string) => notices.push(message) },
		isIdle: () => true, hasPendingMessages: () => false, isProjectTrusted: () => false,
	waitForIdle: async () => {},
		modelRegistry: {
			streamSimple(_model: unknown, context: unknown, options: unknown) {
				calls.push({ context, options });
				const result = complete();
				return { result: () => result };
			},
		},
		switchSession: async (file: string, options: { withSession: (fresh: unknown) => Promise<void> }) => {
			switchedTo = file;
			const fresh = { ...ctx, sessionManager: SessionManager.open(file) };
			await options.withSession(fresh);
			return { cancelled: false };
		},
	} as unknown as ExtensionCommandContext;
	return { ctx, notices, calls, run: (args = "") => command!.handler(args, ctx), switchedTo: () => switchedTo, shutdown: () => shutdown?.() };
}

async function savedSession(t: TestContext) {
	const directory = await mkdtemp(join(tmpdir(), "full-compact-test-"));
	t.after(() => rm(directory, { recursive: true, force: true }));
	const manager = SessionManager.create(directory, directory);
	user(manager, "old request");
	manager.appendMessage(response);
	return manager;
}

test("short sessions include the final message and use the built-in prompt", async (t) => {
	const manager = await savedSession(t);
	user(manager, "most recent request");
	const h = harness(manager);
	const originalId = manager.getSessionId();
	const oldEntries = manager.getEntries().length;
	await h.run("Preserve verification commands");
	assert.equal(h.calls.length, 1);
	const prompt = JSON.stringify(h.calls[0].context);
	assert.match(prompt, /structured context checkpoint summary/);
	assert.match(prompt, /most recent request/);
	assert.match(prompt, /old request/);
	assert.match(prompt, /Additional focus: Preserve verification commands/);
	assert.equal((h.calls[0].options as { cacheRetention: string }).cacheRetention, "none");
	assert.equal(h.switchedTo(), manager.getSessionFile());
	const resumed = SessionManager.open(manager.getSessionFile()!);
	assert.equal(resumed.getSessionId(), originalId);
	assert.equal(resumed.getEntries().length, oldEntries + 1);
	const checkpoint = resumed.getLeafEntry();
	assert.equal(checkpoint?.type, "compaction");
	if (checkpoint?.type !== "compaction") throw new Error("Missing checkpoint");
	assert.equal(checkpoint.firstKeptEntryId, checkpoint.id);
	assert.deepEqual(checkpoint.usage, usage);
	assert.deepEqual(resumed.buildSessionProjection().messages.map((m) => m.role), ["compactionSummary"]);
});

test("projection honors branch selection, omissions, replacements, and previous summaries", () => {
	const manager = SessionManager.inMemory();
	const first = user(manager, "original request");
	manager.appendMessage(response);
	user(manager, "abandoned branch");
	manager.branch(first);
	manager.appendMessage(response);
	const retained = user(manager, "retained request");
	manager.appendCompaction("previous checkpoint", retained, 100,
		{ readFiles: ["earlier.ts"], modifiedFiles: ["changed.ts"] });
	const omitted = user(manager, "omit me");
	const replaced = user(manager, "replace me");
	manager.appendContextEdit(omitted, null);
	manager.appendContextEdit(replaced, { content: "replacement request" });
	const preparation = prepareFullCompaction(manager.getBranch(), DEFAULT_COMPACTION_SETTINGS)!;
	assert.equal(preparation.previousSummary, "previous checkpoint");
	const text = JSON.stringify(preparation.messagesToSummarize);
	assert.match(text, /retained request/);
	assert.match(text, /replacement request/);
	assert.doesNotMatch(text, /abandoned branch|omit me|replace me|original request|previous checkpoint/);
	assert.deepEqual([...preparation.fileOps.read], ["earlier.ts"]);
	assert.deepEqual([...preparation.fileOps.edited], ["changed.ts"]);
});

test("repeated full checkpoints use Pi's update prompt and carry file tracking", async (t) => {
	const manager = await savedSession(t);
	manager.appendCompaction("prior full summary", null, 100,
		{ fullCompact: true, readFiles: ["read.ts"], modifiedFiles: ["edited.ts"] }, true);
	assert.equal(prepareFullCompaction(manager.getBranch(), DEFAULT_COMPACTION_SETTINGS), undefined);
	user(manager, "new work");
	const h = harness(manager);
	await h.run();
	assert.match(JSON.stringify(h.calls[0].context), /Update the existing structured summary/);
	assert.match(JSON.stringify(h.calls[0].context), /prior full summary/);
	const resumed = SessionManager.open(manager.getSessionFile()!);
	const checkpoint = resumed.getLeafEntry();
	assert.equal(checkpoint?.type, "compaction");
	if (checkpoint?.type !== "compaction") throw new Error("Missing checkpoint");
	assert.match(checkpoint.summary, /<read-files>\nread.ts/);
	assert.match(checkpoint.summary, /<modified-files>\nedited.ts/);
});

for (const stopReason of ["error", "length"] as const) {
	test(`${stopReason} response leaves session untouched`, async (t) => {
		const manager = await savedSession(t);
		const file = manager.getSessionFile()!;
		const before = await readFile(file, "utf8");
		const h = harness(manager, async () => ({ ...response, stopReason, errorMessage: "test error" }));
		await h.run();
		assert.equal(await readFile(file, "utf8"), before);
		assert.equal(h.switchedTo(), undefined);
		assert.match(h.notices.at(-1)!, /session unchanged/);
	});
}

test("empty summaries leave session untouched", async (t) => {
	const manager = await savedSession(t);
	const file = manager.getSessionFile()!;
	const before = await readFile(file, "utf8");
	const h = harness(manager, async () => ({ ...response, content: [] }));
	await h.run();
	assert.equal(await readFile(file, "utf8"), before);
	assert.match(h.notices.at(-1)!, /empty checkpoint/);
});

test("changes during summarization prevent a stale checkpoint", async (t) => {
	const manager = await savedSession(t);
	const h = harness(manager, async () => { user(manager, "concurrent work"); return response; });
	await h.run();
	assert.equal(h.switchedTo(), undefined);
	assert.match(h.notices.at(-1)!, /Session changed/);
	assert.equal(SessionManager.open(manager.getSessionFile()!).getLeafEntry()?.type, "message");
});

test("ephemeral sessions make no model calls", async () => {
	const manager = SessionManager.inMemory();
	user(manager, "request");
	const h = harness(manager);
	await h.run();
	assert.equal(h.calls.length, 0);
	assert.match(h.notices.at(-1)!, /saved session/);

});

test("checkpoint preserves system/tool state while discarding old conversation", async (t) => {
	const manager = await savedSession(t);
	manager.appendMessage({ role: "system", content: "System instructions", toolsAdded: [], timestamp: Date.now() });
	manager.appendMessage({ ...response, content: [{ type: "toolCall", id: "read-call", name: "read", arguments: { path: "recent.ts" } }], stopReason: "toolUse" });
	manager.appendMessage({ role: "toolResult", toolCallId: "read-call", toolName: "read", content: [{ type: "text", text: "recent contents" }], isError: false, timestamp: Date.now() });
	const h = harness(manager);
	await h.run();
	assert.match(JSON.stringify(h.calls[0].context), /recent contents/);
	assert.doesNotMatch(JSON.stringify(h.calls[0].context), /System instructions/);
	const resumed = SessionManager.open(manager.getSessionFile()!);
	assert.deepEqual(resumed.buildSessionProjection().messages.map((m) => m.role), ["system", "compactionSummary"]);
	assert.match(JSON.stringify(resumed.buildSessionProjection().messages), /System instructions/);
	const checkpoint = resumed.getLeafEntry();
	if (checkpoint?.type !== "compaction") throw new Error("Missing checkpoint");
	assert.match(checkpoint.summary, /<read-files>\nrecent.ts/);
});

test("empty responses cannot become file-list-only checkpoints", async (t) => {
	const manager = await savedSession(t);
	manager.appendCompaction("previous", null, 100, { readFiles: ["file.ts"], modifiedFiles: [] });
	user(manager, "new work");
	const before = await readFile(manager.getSessionFile()!, "utf8");
	const h = harness(manager, async () => ({ ...response, content: [] }));
	await h.run();
	assert.equal(await readFile(manager.getSessionFile()!, "utf8"), before);
	assert.match(h.notices.at(-1)!, /empty checkpoint/);
});

test("explicit cancellation does not persist a checkpoint", async (t) => {
	const manager = await savedSession(t);
	const before = await readFile(manager.getSessionFile()!, "utf8");
	let finish!: (value: typeof response) => void;
	const h = harness(manager, () => new Promise((resolve) => { finish = resolve; }));
	const pending = h.run();
	while (!finish) await new Promise((resolve) => setTimeout(resolve, 1));
	await h.run("--cancel");
	finish(response);
	await pending;
	assert.equal(await readFile(manager.getSessionFile()!, "utf8"), before);
	assert.equal(h.switchedTo(), undefined);
});

function deferred() {
	let resolve!: () => void;
	const promise = new Promise<void>((done) => { resolve = done; });
	return { promise, resolve };
}

test("busy requests queue once and summarize work completed while waiting", async (t) => {
	const manager = await savedSession(t);
	const h = harness(manager);
	const idle = deferred();
	let busy = true;
	h.ctx.isIdle = () => !busy;
	h.ctx.waitForIdle = () => idle.promise;
	const pending = h.run("Preserve queued work");
	assert.equal(h.calls.length, 0);
	assert.match(h.notices.at(-1)!, /queued; waiting/);
	await h.run();
	assert.match(h.notices.at(-1)!, /already queued or running/);
	user(manager, "completed queued work");
	busy = false;
	idle.resolve();
	await pending;
	assert.equal(h.calls.length, 1);
	assert.match(JSON.stringify(h.calls[0].context), /completed queued work/);
	assert.match(JSON.stringify(h.calls[0].context), /Additional focus: Preserve queued work/);
});

test("pending messages delay full compaction even between idle runs", async (t) => {
	const manager = await savedSession(t);
	const h = harness(manager);
	let queued = true;
	h.ctx.hasPendingMessages = () => queued;
	const pending = h.run();
	await new Promise((resolve) => setTimeout(resolve, 5));
	assert.equal(h.calls.length, 0);
	user(manager, "last queued message");
	queued = false;
	await pending;
	assert.equal(h.calls.length, 1);
	assert.match(JSON.stringify(h.calls[0].context), /last queued message/);
});

for (const action of ["cancel", "shutdown", "session change"] as const) {
	test(`${action} discards a queued full compaction`, async (t) => {
		const manager = await savedSession(t);
		const before = await readFile(manager.getSessionFile()!, "utf8");
		const h = harness(manager);
		const idle = deferred();
		h.ctx.isIdle = () => false;
		h.ctx.waitForIdle = () => idle.promise;
		const pending = h.run();
		if (action === "cancel") await h.run("--cancel");
		else if (action === "shutdown") h.shutdown();
		else {
			h.ctx.sessionManager = SessionManager.inMemory();
			h.ctx.isIdle = () => true;
			idle.resolve();
		}
		// Cancellation and shutdown must finish without resolving waitForIdle.
		await pending;
		assert.equal(h.calls.length, 0);
		assert.equal(h.switchedTo(), undefined);
		assert.equal(await readFile(manager.getSessionFile()!, "utf8"), before);
		assert.match(h.notices.at(-1)!, /session unchanged/);
		idle.resolve();
		if (action === "cancel") {
			h.ctx.isIdle = () => true;
			await h.run();
			assert.equal(h.calls.length, 1);
		}
	});
}
