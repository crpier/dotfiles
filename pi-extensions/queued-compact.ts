import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionContext,
	type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import type { EditorComponent, EditorTheme, TUI } from "@earendil-works/pi-tui";

type PendingCompaction = {
	customInstructions?: string;
};

type CompactableEditor = EditorComponent & {
	addToHistory?: (text: string) => void;
	handleInput(data: string): void;
};

function parseCompactCommand(text: string): string | undefined | null {
	const trimmed = text.trim();
	if (trimmed === "/compact") return undefined;
	if (!trimmed.startsWith("/compact ")) return null;
	return trimmed.slice("/compact ".length).trim() || undefined;
}

function notify(ctx: ExtensionContext, message: string, level: "info" | "warning" | "error" = "info") {
	if (ctx.hasUI) ctx.ui.notify(message, level);
}

type MarkedEditorFactory = ((tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) => EditorComponent) & {
	__queuedCompactFactory?: true;
	baseFactory?: (tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) => EditorComponent;
};

function isPreviousQueuedCompactFactory(factory: unknown): factory is MarkedEditorFactory {
	return (
		typeof factory === "function" &&
		((factory as MarkedEditorFactory).__queuedCompactFactory === true ||
			// Handles one reload from the first version of this extension, which did not mark its factory.
			factory.toString().includes("wrapEditor"))
	);
}

export default function (pi: ExtensionAPI) {
	let pending: PendingCompaction | undefined;
	let running = false;
	let drainTimer: ReturnType<typeof setTimeout> | undefined;
	let installedBaseFactory: MarkedEditorFactory["baseFactory"] | undefined;

	const scheduleDrain = (ctx: ExtensionContext) => {
		if (drainTimer || !pending || running) return;
		drainTimer = setTimeout(() => {
			drainTimer = undefined;
			drain(ctx);
		}, 250);
	};

	const drain = (ctx: ExtensionContext) => {
		if (!pending || running) return;
		if (!ctx.isIdle() || ctx.hasPendingMessages()) {
			scheduleDrain(ctx);
			return;
		}

		const item = pending;
		pending = undefined;
		running = true;

		ctx.compact({
			customInstructions: item.customInstructions,
			onComplete: () => {
				running = false;
				notify(ctx, "Queued compaction completed");
				if (pending) scheduleDrain(ctx);
			},
			onError: (error) => {
				running = false;
				notify(ctx, `Queued compaction failed: ${error.message}`, "error");
				if (pending) scheduleDrain(ctx);
			},
		});
	};

	const enqueue = (ctx: ExtensionContext, customInstructions?: string) => {
		const hadPending = pending !== undefined;
		pending = { customInstructions };
		notify(ctx, hadPending ? "Queued compaction updated" : "Compaction queued");
		drain(ctx);
	};

	const wrapEditor = (
		editor: CompactableEditor,
		keybindings: KeybindingsManager,
		ctx: ExtensionContext,
	): CompactableEditor => {
		const originalHandleInput = editor.handleInput.bind(editor);

		editor.handleInput = (data: string) => {
			if (keybindings.matches(data, "tui.input.submit") || keybindings.matches(data, "app.message.followUp")) {
				const text = (editor.getExpandedText?.() ?? editor.getText()).trim();
				const customInstructions = parseCompactCommand(text);
				if (customInstructions !== null) {
					editor.addToHistory?.(text);
					editor.setText("");
					enqueue(ctx, customInstructions);
					return;
				}
			}

			originalHandleInput(data);
		};

		return editor;
	};

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui" || !ctx.hasUI) return;

		const currentFactory = ctx.ui.getEditorComponent();
		const previousFactory = isPreviousQueuedCompactFactory(currentFactory) ? currentFactory.baseFactory : currentFactory;
		installedBaseFactory = previousFactory;

		const queuedCompactFactory: MarkedEditorFactory = (tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) => {
			const editor = previousFactory
				? previousFactory(tui, theme, keybindings)
				: new CustomEditor(tui, theme, keybindings);
			return wrapEditor(editor as CompactableEditor, keybindings, ctx);
		};
		queuedCompactFactory.__queuedCompactFactory = true;
		queuedCompactFactory.baseFactory = previousFactory;
		ctx.ui.setEditorComponent(queuedCompactFactory);
	});

	pi.on("agent_end", (_event, ctx) => {
		drain(ctx);
	});

	pi.on("session_compact", (_event, ctx) => {
		// If an automatic/manual compaction satisfied the request while this one
		// was waiting, do not immediately compact again with no intervening work.
		if (!running && pending) {
			pending = undefined;
			if (drainTimer) {
				clearTimeout(drainTimer);
				drainTimer = undefined;
			}
			notify(ctx, "Queued compaction cleared because context was already compacted");
		}
	});

	pi.on("session_shutdown", (_event, ctx) => {
		if (drainTimer) {
			clearTimeout(drainTimer);
			drainTimer = undefined;
		}
		if (ctx.mode === "tui" && ctx.hasUI) {
			ctx.ui.setEditorComponent(installedBaseFactory);
		}
	});
}
