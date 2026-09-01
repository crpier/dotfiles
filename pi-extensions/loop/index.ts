import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const STATE_ENTRY = "loop-state";
const TICK_MESSAGE = "loop-tick";
const STATUS_KEY = "loop";
const MIN_INTERVAL_SECONDS = 10;
const MAX_INTERVAL_SECONDS = 365 * 24 * 60 * 60;
const MAX_TIMER_DELAY_MS = 2_147_000_000;

interface LoopState {
	prompt: string;
	intervalMs: number;
	nextRunAt: number;
}

interface PersistedLoopState {
	version: 1;
	active: boolean;
	prompt?: string;
	intervalMs?: number;
	nextRunAt?: number;
}

function formatDuration(milliseconds: number): string {
	const seconds = Math.max(1, Math.round(milliseconds / 1000));
	if (seconds < 60) return `${seconds}s`;
	const minutes = Math.round(seconds / 60);
	if (minutes < 60) return `${minutes}m`;
	const hours = Math.round(minutes / 60);
	if (hours < 24) return `${hours}h`;
	const days = Math.round(hours / 24);
	return `${days}d`;
}

function isPersistedLoopState(value: unknown): value is PersistedLoopState {
	if (!value || typeof value !== "object") return false;
	const state = value as Partial<PersistedLoopState>;
	if (state.version !== 1 || typeof state.active !== "boolean") return false;
	if (!state.active) return true;
	return (
		typeof state.prompt === "string" &&
		state.prompt.trim().length > 0 &&
		typeof state.intervalMs === "number" &&
		Number.isFinite(state.intervalMs) &&
		state.intervalMs >= MIN_INTERVAL_SECONDS * 1000 &&
		typeof state.nextRunAt === "number" &&
		Number.isFinite(state.nextRunAt)
	);
}

export default function loopExtension(pi: ExtensionAPI) {
	let loop: LoopState | undefined;
	let timer: ReturnType<typeof setTimeout> | undefined;
	let generation = 0;
	let awaitingSettlement: number | undefined;
	let configurationPrompt: string | undefined;

	const clearTimer = () => {
		if (timer !== undefined) clearTimeout(timer);
		timer = undefined;
	};

	const updateStatus = (ctx: ExtensionContext) => {
		if (!loop) {
			ctx.ui.setStatus(STATUS_KEY, undefined);
			return;
		}

		const remaining = Math.max(0, loop.nextRunAt - Date.now());
		const suffix = awaitingSettlement === generation ? "running" : `next ${formatDuration(remaining)}`;
		ctx.ui.setStatus(STATUS_KEY, `loop: ${formatDuration(loop.intervalMs)} · ${suffix}`);
	};

	const persistActiveState = () => {
		if (!loop) return;
		pi.appendEntry<PersistedLoopState>(STATE_ENTRY, {
			version: 1,
			active: true,
			prompt: loop.prompt,
			intervalMs: loop.intervalMs,
			nextRunAt: loop.nextRunAt,
		});
	};

	const schedule = (ctx: ExtensionContext, expectedGeneration: number) => {
		clearTimer();
		if (!loop || generation !== expectedGeneration) return;

		const waitUntilDue = () => {
			if (!loop || generation !== expectedGeneration) return;
			const remaining = loop.nextRunAt - Date.now();
			if (remaining > MAX_TIMER_DELAY_MS) {
				timer = setTimeout(waitUntilDue, MAX_TIMER_DELAY_MS);
				timer.unref?.();
				return;
			}

			timer = setTimeout(() => {
				timer = undefined;
				if (!loop || generation !== expectedGeneration) return;
				awaitingSettlement = expectedGeneration;
				updateStatus(ctx);
				try {
					pi.sendMessage(
						{
							customType: TICK_MESSAGE,
							content: loop.prompt,
							display: true,
						},
						{
							triggerTurn: true,
							deliverAs: ctx.isIdle() ? "steer" : "followUp",
						},
					);
				} catch (error) {
					awaitingSettlement = undefined;
					ctx.ui.notify(`Loop run failed: ${error instanceof Error ? error.message : String(error)}`, "error");
					loop.nextRunAt = Date.now() + loop.intervalMs;
					persistActiveState();
					schedule(ctx, expectedGeneration);
					updateStatus(ctx);
				}
			}, Math.max(0, remaining));
			timer.unref?.();
		};

		waitUntilDue();
		updateStatus(ctx);
	};

	const activateLoop = (prompt: string, intervalSeconds: number, ctx: ExtensionContext) => {
		const intervalMs = Math.round(intervalSeconds * 1000);
		generation += 1;
		awaitingSettlement = undefined;
		loop = {
			prompt,
			intervalMs,
			nextRunAt: Date.now() + intervalMs,
		};
		persistActiveState();
		schedule(ctx, generation);
	};

	const stopLoop = (ctx: ExtensionContext, persist: boolean) => {
		generation += 1;
		clearTimer();
		loop = undefined;
		awaitingSettlement = undefined;
		configurationPrompt = undefined;
		if (persist) {
			pi.appendEntry<PersistedLoopState>(STATE_ENTRY, { version: 1, active: false });
		}
		updateStatus(ctx);
	};

	const restoreLoop = (ctx: ExtensionContext) => {
		stopLoop(ctx, false);
		let restored: PersistedLoopState | undefined;
		for (const entry of ctx.sessionManager.getBranch()) {
			if (entry.type !== "custom" || entry.customType !== STATE_ENTRY) continue;
			if (isPersistedLoopState(entry.data)) restored = entry.data;
		}

		if (!restored?.active) return;
		loop = {
			prompt: restored.prompt!,
			intervalMs: restored.intervalMs!,
			nextRunAt: restored.nextRunAt!,
		};
		generation += 1;
		schedule(ctx, generation);
	};

	pi.registerTool({
		name: "set_loop",
		label: "Set Loop",
		description:
			"Schedule one prompt to run repeatedly in this pi session. Infer the cadence from the user's request. Rewrite prompt as a self-contained instruction for one execution: remove scheduling language and make the requested action clear. Replaces any existing loop. The minimum interval is 10 seconds.",
		promptSnippet: "Schedule a prompt to run repeatedly at an inferred interval",
		parameters: Type.Object({
			prompt: Type.String({
				description: "A self-contained, cadence-free instruction for one execution of the recurring task",
			}),
			interval_seconds: Type.Number({
				description: "Delay between runs, in seconds",
				minimum: MIN_INTERVAL_SECONDS,
				maximum: MAX_INTERVAL_SECONDS,
			}),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const prompt = params.prompt.trim();
			if (!prompt) throw new Error("Loop prompt cannot be empty");
			if (!Number.isFinite(params.interval_seconds)) throw new Error("Loop interval must be finite");

			const intervalSeconds = Math.min(
				MAX_INTERVAL_SECONDS,
				Math.max(MIN_INTERVAL_SECONDS, params.interval_seconds),
			);
			configurationPrompt = undefined;
			activateLoop(prompt, intervalSeconds, ctx);

			return {
				content: [
					{
						type: "text",
						text: `Loop scheduled every ${formatDuration(intervalSeconds * 1000)}. First run in ${formatDuration(intervalSeconds * 1000)}.`,
					},
				],
				details: { prompt, intervalSeconds, nextRunAt: loop!.nextRunAt },
			};
		},
	});

	pi.registerCommand("loop", {
		description: "Repeat a prompt at an LLM-inferred interval; use 'status' or 'stop' to manage it",
		getArgumentCompletions: (prefix) => {
			const items = ["status", "stop"].filter((item) => item.startsWith(prefix));
			return items.length > 0 ? items.map((item) => ({ value: item, label: item })) : null;
		},
		handler: async (args, ctx) => {
			const request = args.trim();
			if (!request) {
				ctx.ui.notify("Usage: /loop <prompt> | /loop status | /loop stop", "warning");
				return;
			}

			if (request === "stop") {
				if (!loop) {
					ctx.ui.notify("No active loop", "info");
					return;
				}
				stopLoop(ctx, true);
				ctx.ui.notify("Loop stopped", "info");
				return;
			}

			if (request === "status") {
				if (!loop) {
					ctx.ui.notify("No active loop", "info");
					return;
				}
				const next = awaitingSettlement === generation
					? "running now"
					: `next run in ${formatDuration(Math.max(0, loop.nextRunAt - Date.now()))}`;
				ctx.ui.notify(`Every ${formatDuration(loop.intervalMs)}; ${next}\nPrompt: ${loop.prompt}`, "info");
				return;
			}

			await ctx.waitForIdle();
			const activeTools = pi.getActiveTools();
			if (!activeTools.includes("set_loop")) {
				pi.setActiveTools([...activeTools, "set_loop"]);
			}
			configurationPrompt = request;
			pi.sendUserMessage(
				[
					"Configure a recurring loop for the request below.",
					"Infer a sensible interval from the wording and task, then call set_loop exactly once.",
					"Rewrite the tool's prompt as a self-contained instruction for one run: remove cadence/scheduling language, preserve the user's intent, and phrase it naturally for repeated execution.",
					"Do not execute the recurring task now.",
					"",
					`Request: ${request}`,
				].join("\n"),
			);
		},
	});

	pi.on("session_start", async (_event, ctx) => restoreLoop(ctx));
	pi.on("session_tree", async (_event, ctx) => restoreLoop(ctx));

	pi.on("context", async (event) => {
		let changed = false;
		const messages = event.messages.map((message) => {
			if (message.role !== "custom" || message.customType !== TICK_MESSAGE) return message;
			changed = true;
			const prompt = typeof message.content === "string"
				? message.content
				: message.content
					.filter((item) => item.type === "text")
					.map((item) => item.text)
					.join("\n");
			return {
				...message,
				content: [
					"Automated loop run. Execute the task exactly once now.",
					"Do not schedule or reconfigure a loop, even if the task mentions a cadence.",
					"",
					prompt,
				].join("\n"),
			};
		});
		if (changed) return { messages };
	});

	pi.on("agent_settled", async (_event, ctx) => {
		if (configurationPrompt !== undefined) {
			configurationPrompt = undefined;
			ctx.ui.notify("The model did not configure the loop", "warning");
		}

		if (!loop || awaitingSettlement !== generation) return;
		awaitingSettlement = undefined;
		let nextRunAt = loop.nextRunAt + loop.intervalMs;
		while (nextRunAt <= Date.now()) nextRunAt += loop.intervalMs;
		loop.nextRunAt = nextRunAt;
		persistActiveState();
		schedule(ctx, generation);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		clearTimer();
		ctx.ui.setStatus(STATUS_KEY, undefined);
	});
}
