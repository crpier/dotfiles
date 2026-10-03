import {
	buildSessionContext,
	convertToLlm,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";

type Messages = ReturnType<typeof buildSessionContext>["messages"];
type Snapshot = {
	messages: Messages;
	sessionId: string;
	leaf: string | null;
	prompt: string;
	tools: string;
};

function notify(ctx: ExtensionContext, text: string, level: "info" | "warning" | "error" = "info") {
	if (ctx.hasUI) ctx.ui.notify(text, level);
}

/** Reject prose/multiple lines rather than silently naming a session after an explanation. */
export function parseTitle(text: string): string {
	const title = text.trim().replace(/^(?:"([\s\S]*)"|'([\s\S]*)'|`([\s\S]*)`)$/, "$1$2$3").trim();
	if (!title || /[\r\n\x00-\x1f\x7f]/.test(title) || [...title].length > 100) {
		throw new Error("Model did not return a single title of at most 100 characters");
	}
	return title;
}

export default function (pi: ExtensionAPI) {
	let request: Snapshot | undefined;
	let snapshot: Snapshot | undefined;
	let controller: AbortController | undefined;
	const toolsKey = () => JSON.stringify(pi.getActiveTools());
	const reset = () => {
		controller?.abort();
		request = undefined;
		snapshot = undefined;
	};

	pi.on("session_shutdown", reset);
	pi.on("session_start", reset);
	pi.on("session_compact", reset);
	pi.on("session_tree", reset);
	pi.on("agent_start", () => controller?.abort());

	// Prefer the actual request transcript, including request-local context transforms.
	// Observe without modifying the normal conversation or its cache.
	pi.on("context_with_system", (event, ctx) => {
		request = {
			messages: structuredClone(event.messages),
			sessionId: ctx.sessionManager.getSessionId(),
			leaf: ctx.sessionManager.getLeafId(),
			prompt: ctx.getSystemPrompt(),
			tools: toolsKey(),
		};
		snapshot = undefined;
	});
	pi.on("agent_settled", (_event, ctx) => {
		if (!request || request.sessionId !== ctx.sessionManager.getSessionId()) return;
		const projection = ctx.sessionManager.buildSessionProjection();
		const anchor = projection.entries.findIndex((entry) => entry.sourceEntry.id === request!.leaf);
		if (anchor < 0) return;
		// Include the finalized response and any trailing tool results, using persisted
		// messages after message_end handlers have finished, not partial stream objects.
		snapshot = {
			...request,
			messages: [...request.messages, ...structuredClone(projection.entries.slice(anchor + 1).flatMap((entry) => entry.messages))],
			leaf: ctx.sessionManager.getLeafId(),
		};
		request = undefined;
	});

	pi.registerCommand("auto-name", {
		description: "Name this session with the current model and full context (/auto-name [guidance] or --cancel)",
		handler: async (args, ctx) => {
			if (args.trim() === "--cancel") {
				controller?.abort();
				return;
			}
			if (controller) {
				notify(ctx, "Session naming is already running; use /auto-name --cancel to cancel", "warning");
				return;
			}
			if (!ctx.isIdle() || ctx.hasPendingMessages()) {
				notify(ctx, "Wait for the agent and queued messages to finish, then run /auto-name", "warning");
				return;
			}
			const model = ctx.model;
			if (!model) {
				notify(ctx, "Select a model first", "warning");
				return;
			}
			const sessionId = ctx.sessionManager.getSessionId();
			const leaf = ctx.sessionManager.getLeafId();
			const prompt = ctx.getSystemPrompt();
			const tools = toolsKey();
			const previousName = pi.getSessionName();
			const settings = pi.getSettings();
			const matches = snapshot?.sessionId === sessionId && snapshot.leaf === leaf &&
				snapshot.prompt === prompt && snapshot.tools === tools;
			let history = structuredClone(matches ? snapshot!.messages : buildSessionContext(ctx.sessionManager.getBranch()).messages);
			if (!history.some((message) => message.role !== "system")) {
				notify(ctx, "No conversation to name yet", "warning");
				return;
			}
			// Older sessions may have no recorded system prompt/tool checkpoint yet.
			if (history[0]?.role !== "system") {
				const active = new Set(pi.getActiveTools());
				history = [{ role: "system", content: prompt, timestamp: Date.now(),
					toolsAdded: pi.getAllTools().filter((tool) => active.has(tool.name))
						.map(({ name, description, parameters }) => ({ name, description, parameters })) }, ...history];
			}
			const messages = convertToLlm(history).map((message) => {
				if (settings.images?.blockImages && (message.role === "user" || message.role === "toolResult") && Array.isArray(message.content)) {
					return { ...message, content: message.content.map((part) => part.type === "image"
						? { type: "text" as const, text: "Image reading is disabled." } : part) };
				}
				return message;
			});
			messages.push({ role: "user", timestamp: Date.now(), content: [
				"Name this session based on the entire conversation above.",
				"Return ONLY a very short title: aim for 2–3 words, never more than 4 words, and at most 40 characters.",
				"Name only the main topic. Prefer brevity over completeness; omit secondary details, filler words, and generic terms like session, discussion, implementation, or extension unless essential.",
				"Use sentence case, not title case: capitalize only the first word and proper nouns or acronyms (such as Pi, TypeScript, or API). Do not capitalize every word.",
				"Example: Pi session naming. Prefer this over Cache-friendly Pi session naming extension.",
				"No explanation, markdown, quotes, or tool calls. Do not carry out any other task.",
				args.trim() ? `Additional naming guidance: ${args.trim()}` : "",
			].filter(Boolean).join("\n") });

			controller = new AbortController();
			const signal = controller.signal;
			try {
				notify(ctx, `Naming session with ${model.id} (full context; cache reuse is best-effort)...`);
				const retry = settings.retry?.provider;
				const idleTimeout = settings.httpIdleTimeoutMs ?? 300_000;
				const response = await ctx.modelRegistry.streamSimple(model, { messages }, {
					sessionId, signal,
					reasoning: ctx.thinkingLevel === "off" ? undefined : ctx.thinkingLevel,
					thinkingBudgets: settings.thinkingBudgets,
					transport: settings.transport ?? "auto",
					timeoutMs: retry?.timeoutMs ?? (idleTimeout === 0 ? 2_147_483_647 : idleTimeout),
					websocketConnectTimeoutMs: settings.websocketConnectTimeoutMs ?? 15_000,
					maxRetries: retry?.maxRetries ?? 0,
					maxRetryDelayMs: retry?.maxRetryDelayMs ?? 60_000,
					// Keep default maxTokens, tool choice, and cache retention, just like
					// a chat request. Changing them can invalidate Anthropic's cache.
				}).result();
				signal.throwIfAborted();
				if (response.stopReason !== "stop" || response.content.some((part) => part.type === "toolCall")) {
					throw new Error(response.errorMessage || `Naming request ended with ${response.stopReason}; no tools were executed`);
				}
				const title = parseTitle(response.content.filter((part) => part.type === "text").map((part) => part.text).join(""));
				if (!ctx.isIdle() || ctx.hasPendingMessages() || ctx.sessionManager.getSessionId() !== sessionId ||
					ctx.sessionManager.getLeafId() !== leaf || ctx.getSystemPrompt() !== prompt || toolsKey() !== tools ||
					ctx.model?.id !== model.id || ctx.model?.provider !== model.provider || pi.getSessionName() !== previousName) {
					throw new Error("Session changed during naming; the generated title was not saved");
				}
				pi.setSessionName(title);
				// The naming exchange stays out of the transcript, including /tree.
				// Nested command usage isn't included in Pi's session totals; report it here.
				const { usage } = response;
				notify(ctx, `Session named: ${title}\nCache read: ${usage.cacheRead.toLocaleString()} tokens; uncached input: ${usage.input.toLocaleString()}; cache write: ${usage.cacheWrite.toLocaleString()}; cost: $${usage.cost.total.toFixed(4)}`);
			} catch (error) {
				notify(ctx, signal.aborted ? "Session naming cancelled; name unchanged" :
					`Session naming failed; name unchanged: ${error instanceof Error ? error.message : String(error)}`, signal.aborted ? "info" : "error");
			} finally {
				controller = undefined;
			}
		},
	});
}
