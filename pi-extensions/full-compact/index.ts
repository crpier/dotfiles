import { addAbortListener } from "node:events";
import { stat } from "node:fs/promises";
import { setTimeout as delay } from "node:timers/promises";
import {
	compact,
	type ExtensionAPI,
	type ExtensionContext,
	SessionManager,
	SettingsManager,
} from "@earendil-works/pi-coding-agent";
import { prepareFullCompaction } from "./preparation.ts";

function notify(ctx: ExtensionContext, message: string, level: "info" | "warning" | "error" = "info") {
	if (ctx.hasUI) ctx.ui.notify(message, level);
}

export default function (pi: ExtensionAPI) {
	let running = false;
	let controller: AbortController | undefined;

	pi.on("session_shutdown", () => controller?.abort());

	pi.registerCommand("full-compact", {
		description: "Summarize all active context for later resumption; retain no old messages (optional focus instructions)",
		handler: async (args, ctx) => {
			if (args.trim() === "--cancel") {
				controller?.abort();
				return;
			}
			if (running) {
				notify(ctx, "Full compaction is already queued or running; use /full-compact --cancel to cancel it", "warning");
				return;
			}
			const file = ctx.sessionManager.getSessionFile();
			const sessionId = ctx.sessionManager.getSessionId();
			if (!file || !ctx.model) {
				notify(ctx, "Full compaction requires a saved session and a selected model", "warning");
				return;
			}

			running = true;
			controller = new AbortController();
			const signal = controller.signal;
			let saved = false;
			let switching = false;
			try {
				if (!ctx.isIdle() || ctx.hasPendingMessages()) {
					notify(ctx, "Full compaction queued; waiting for the agent and queued messages to finish.");
					while (!ctx.isIdle() || ctx.hasPendingMessages()) {
						// Cancellation must release the command even if Pi never becomes idle.
						let listener: ReturnType<typeof addAbortListener> | undefined;
						try {
							await Promise.race([
								ctx.waitForIdle(),
								new Promise<never>((_, reject) => {
									listener = addAbortListener(signal, () => reject(new Error("Full compaction cancelled")));
								}),
							]);
						} finally {
							listener?.[Symbol.dispose]();
						}
						signal.throwIfAborted();
						// Pending work can briefly exist between otherwise idle runs.
						if (ctx.hasPendingMessages()) await delay(25, undefined, { signal });
					}
				}
				signal.throwIfAborted();
				if (ctx.sessionManager.getSessionFile() !== file || ctx.sessionManager.getSessionId() !== sessionId) {
					throw new Error("Session changed while waiting; queued full compaction discarded");
				}
				// Select runtime settings only after all queued work has completed.
				const model = ctx.model;
				if (!model) throw new Error("Full compaction requires a selected model");
				const leaf = ctx.sessionManager.getLeafId();
				const before = await stat(file);
				const settings = SettingsManager.create(ctx.cwd, undefined, { projectTrusted: ctx.isProjectTrusted() });
				const preparation = prepareFullCompaction(ctx.sessionManager.getBranch(), settings.getCompactionSettings(model));
				if (!preparation) {
					notify(ctx, "Nothing new to compact", "info");
					return;
				}
				notify(ctx, `Summarizing all ${preparation.messagesToSummarize.length} active messages with ${model.id}...`);
				const result = await compact(
					preparation,
					model,
					undefined,
					undefined,
					args.trim() || undefined,
					controller.signal,
					ctx.thinkingLevel,
					async (selectedModel, context, options) => {
						const stream = ctx.modelRegistry.streamSimple(selectedModel, context, options);
						const response = await stream.result();
						// Validate before compact() appends file lists: those must not
						// turn an empty model response into a seemingly valid summary.
						if (response.stopReason !== "error" && response.stopReason !== "length" &&
							!response.content.some((part) => part.type === "text" && part.text.trim())) {
							throw new Error("Summarizer returned an empty checkpoint");
						}
						return stream;
					},
					undefined,
					settings.getRetrySettings(),
				);
				controller.signal.throwIfAborted();
				if (!result.summary.trim()) throw new Error("Summarizer returned an empty checkpoint");

				const after = await stat(file);
				if (!ctx.isIdle() || ctx.hasPendingMessages() || ctx.sessionManager.getLeafId() !== leaf ||
					before.size !== after.size || before.mtimeMs !== after.mtimeMs) {
					throw new Error("Session changed during summarization; checkpoint was not saved. Run /full-compact again.");
				}
				// The extension context deliberately exposes a read-only manager. Open
				// the saved session via the SDK and reopen it afterward, rather than
				// casting away that contract or mutating Pi's internal agent state.
				const manager = SessionManager.open(file, ctx.sessionManager.getSessionDir());
				if (!leaf) throw new Error("Session has no active branch");
				manager.branch(leaf);
				manager.appendCompaction(result.summary, null, result.tokensBefore,
					{ ...result.details as object, fullCompact: true }, true, result.usage);
				saved = true;

				// switchSession invalidates ctx; only use the fresh callback context.
				switching = true;
				const switched = await ctx.switchSession(file, {
					withSession: async (fresh) => notify(fresh, "Full compaction saved. Only the summary remains in conversation context."),
				});
				if (switched.cancelled) {
					switching = false;
					notify(ctx, "Checkpoint saved, but session reload was cancelled. Resume this session before continuing.", "warning");
				}
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				// A failed replacement may have invalidated the old context already.
				if (switching) throw new Error(`Checkpoint saved, but reopening the session failed: ${message}`);
				notify(ctx, saved ? `Checkpoint saved; resume the session: ${message}` : `Full compaction failed; session unchanged: ${message}`, "error");
			} finally {
				running = false;
				controller = undefined;
			}
		},
	});
}
