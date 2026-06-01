import { completeSimple, type Message, type ThinkingLevel } from "@earendil-works/pi-ai";
import {
	BorderedLoader,
	buildSessionContext,
	convertToLlm,
	type ExtensionAPI,
	type ExtensionCommandContext,
	type Theme,
} from "@earendil-works/pi-coding-agent";
import type { Component, TUI } from "@earendil-works/pi-tui";
import { matchesKey, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const BTW_SYSTEM_APPEND = `

You are answering a /btw side question inside pi.
This is a one-shot, read-only aside. Answer the user's side question using only the current conversation context and your general knowledge.
No tools are available for this aside. Do not claim you can read files, run commands, inspect the repository, or change anything.
Keep the answer concise. If the answer depends on information that is not in the conversation context, say what is missing.`;

function textFromAssistant(message: Message): string {
	return message.content
		.filter((part): part is { type: "text"; text: string } => part.type === "text")
		.map((part) => part.text)
		.join("\n")
		.trim();
}

function wrapLine(line: string, width: number): string[] {
	if (line === "") return [""];
	const words = line.split(/(\s+)/);
	const out: string[] = [];
	let current = "";

	for (const word of words) {
		if (word === "") continue;
		if (/^\s+$/.test(word)) {
			if (current && !current.endsWith(" ")) current += " ";
			continue;
		}

		const candidate = current ? current + word : word;
		if (visibleWidth(candidate) <= width) {
			current = candidate;
			continue;
		}

		if (current.trimEnd()) out.push(current.trimEnd());
		current = "";

		let remaining = word;
		while (visibleWidth(remaining) > width) {
			out.push(truncateToWidth(remaining, width, ""));
			remaining = remaining.slice(out[out.length - 1]!.length);
		}
		current = remaining;
	}

	if (current.trimEnd()) out.push(current.trimEnd());
	return out.length ? out : [""];
}

function wrapText(text: string, width: number): string[] {
	return text.split("\n").flatMap((line) => wrapLine(line, width));
}

class BtwAnswerOverlay implements Component {
	private scrollOffset = 0;

	constructor(
		private readonly tui: TUI,
		private readonly theme: Theme,
		private readonly question: string,
		private readonly answer: string,
		private readonly done: () => void,
	) {}

	invalidate(): void {}
	dispose(): void {}

	handleInput(data: string): void {
		if (matchesKey(data, "escape") || matchesKey(data, "ctrl+c") || matchesKey(data, "return") || matchesKey(data, "space")) {
			this.done();
			return;
		}
		if (matchesKey(data, "up")) {
			this.scrollOffset = Math.max(0, this.scrollOffset - 1);
			this.tui.requestRender();
			return;
		}
		if (matchesKey(data, "down")) {
			this.scrollOffset += 1;
			this.tui.requestRender();
			return;
		}
		if (matchesKey(data, "pageup")) {
			this.scrollOffset = Math.max(0, this.scrollOffset - 10);
			this.tui.requestRender();
			return;
		}
		if (matchesKey(data, "pagedown")) {
			this.scrollOffset += 10;
			this.tui.requestRender();
		}
	}

	render(width: number): string[] {
		const th = this.theme;
		const innerW = Math.max(20, width - 2);
		const maxBodyLines = 18;
		const border = (s: string) => th.fg("border", s);
		const pad = (s: string) => s + " ".repeat(Math.max(0, innerW - visibleWidth(s)));
		const title = truncateToWidth(" /btw ", innerW);
		const left = "─".repeat(Math.floor((innerW - visibleWidth(title)) / 2));
		const right = "─".repeat(Math.max(0, innerW - visibleWidth(title) - left.length));

		const questionLines = wrapText(`Q: ${this.question}`, innerW - 2);
		const answerLines = wrapText(this.answer || "(no answer)", innerW - 2);
		const body = [
			...questionLines.map((line) => th.fg("muted", line)),
			"",
			...answerLines,
		];

		const maxOffset = Math.max(0, body.length - maxBodyLines);
		this.scrollOffset = Math.min(this.scrollOffset, maxOffset);
		const visible = body.slice(this.scrollOffset, this.scrollOffset + maxBodyLines);
		const canScroll = body.length > maxBodyLines;
		const footer = canScroll
			? `↑/↓ scroll ${this.scrollOffset + 1}-${Math.min(body.length, this.scrollOffset + maxBodyLines)}/${body.length} • Esc/Enter/Space close`
			: "Esc/Enter/Space close";

		const lines = [border("╭" + left) + th.fg("accent", title) + border(right + "╮")];
		for (const line of visible) {
			lines.push(border("│") + pad(truncateToWidth(" " + line, innerW, "...", true)) + border("│"));
		}
		for (let i = visible.length; i < Math.min(maxBodyLines, body.length); i++) {
			lines.push(border("│") + " ".repeat(innerW) + border("│"));
		}
		lines.push(border("├" + "─".repeat(innerW) + "┤"));
		lines.push(border("│") + pad(truncateToWidth(" " + th.fg("dim", footer), innerW, "...", true)) + border("│"));
		lines.push(border("╰" + "─".repeat(innerW) + "╯"));
		return lines;
	}
}

async function askBtw(
	question: string,
	ctx: ExtensionCommandContext,
	pi: ExtensionAPI,
	signal?: AbortSignal,
): Promise<string | null> {
	const model = ctx.model;
	if (!model) throw new Error("No model selected");

	const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
	if (!auth.ok || !auth.apiKey) {
		throw new Error(auth.ok ? `No API key for ${model.provider}` : auth.error);
	}

	const sessionContext = buildSessionContext(ctx.sessionManager.getBranch(), ctx.sessionManager.getLeafId());
	const messages = convertToLlm(sessionContext.messages);
	messages.push({
		role: "user",
		content: [{ type: "text", text: question }],
		timestamp: Date.now(),
	});

	const thinkingLevel = pi.getThinkingLevel();
	const response = await completeSimple(
		model,
		{ systemPrompt: ctx.getSystemPrompt() + BTW_SYSTEM_APPEND, messages },
		{
			apiKey: auth.apiKey,
			headers: auth.headers,
			signal,
			sessionId: ctx.sessionManager.getSessionId(),
			reasoning: thinkingLevel === "off" ? undefined : (thinkingLevel as ThinkingLevel),
		},
	);

	if (response.stopReason === "aborted") return null;
	if (response.stopReason === "error") throw new Error(response.errorMessage || "Model request failed");
	return textFromAssistant(response) || "(no text response)";
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("btw", {
		description: "Ask a one-shot side question without adding it to LLM context",
		handler: async (args: string, ctx: ExtensionCommandContext) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("/btw requires interactive mode", "error");
				return;
			}
			if (!ctx.isIdle()) {
				ctx.ui.notify("/btw is only available while pi is idle", "warning");
				return;
			}

			let question = args.trim();
			if (!question) {
				const edited = await ctx.ui.editor("/btw side question", "");
				question = edited?.trim() ?? "";
			}
			if (!question) {
				ctx.ui.notify("/btw cancelled", "info");
				return;
			}

			const answer = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
				const loader = new BorderedLoader(tui, theme, `Asking /btw using ${ctx.model?.id ?? "current model"}...`);
				loader.onAbort = () => done(null);

				askBtw(question, ctx, pi, loader.signal)
					.then(done)
					.catch((err) => {
						const message = err instanceof Error ? err.message : String(err);
						done(`Error: ${message}`);
					});

				return loader;
			});

			if (answer === null) {
				ctx.ui.notify("/btw cancelled", "info");
				return;
			}

			pi.appendEntry("btw", {
				question,
				answer,
				model: ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined,
				thinkingLevel: pi.getThinkingLevel(),
			});

			await ctx.ui.custom<void>((tui, theme, _kb, done) => new BtwAnswerOverlay(tui, theme, question, answer, done), {
				overlay: true,
				overlayOptions: { anchor: "center", width: 88, maxHeight: 24 },
			});
		},
	});
}
