import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import type { EditorComponent } from "@earendil-works/pi-tui";

// Built-in TUI commands run before extension input hooks. Intercept submission
// in the existing editor instead, preserving its other behavior and shortcuts.
export default function (pi: ExtensionAPI) {
	let pending = false;
	let dispatched = false;
	let installedFactory: ReturnType<ExtensionContext["ui"]["getEditorComponent"]>;
	let previousFactory: typeof installedFactory;

	const dispatch = (ctx: ExtensionContext) => {
		if (!pending || dispatched || !ctx.isIdle()) return;
		dispatched = true;
		// At agent_settled this runs after all settled handlers finish, through
		// command dispatch rather than as a prompt to the model.
		pi.sendUserMessage("/queued-reload", { expandPromptTemplates: true });
	};

	const enqueue = (ctx: ExtensionContext) => {
		if (pending) return;
		pending = true;
		if (!ctx.isIdle() && ctx.hasUI) {
			ctx.ui.notify("Reload queued until the agent finishes.", "info");
		}
		dispatch(ctx);
	};

	pi.registerCommand("queued-reload", {
		description: "Reload resources when the agent is fully idle",
		handler: async (_args, ctx) => {
			dispatched = false;
			if (!ctx.isIdle()) {
				// Recheck: work may have started since the command was dispatched.
				enqueue(ctx);
				return;
			}
			pending = false;
			await ctx.reload();
			return;
		},
	});

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		previousFactory = ctx.ui.getEditorComponent();
		installedFactory = (tui, theme, keybindings) => {
			const editor = previousFactory
				? previousFactory(tui, theme, keybindings)
				: new CustomEditor(tui, theme, keybindings);
			const originalHandleInput = editor.handleInput.bind(editor);
			editor.handleInput = (data: string) => {
				if (
					(keybindings.matches(data, "tui.input.submit") ||
						keybindings.matches(data, "app.message.followUp")) &&
					(editor.getExpandedText?.() ?? editor.getText()).trim() === "/reload"
				) {
					(editor as EditorComponent & { addToHistory?: (text: string) => void })
						.addToHistory?.("/reload");
					editor.setText("");
					enqueue(ctx);
					return;
				}
				originalHandleInput(data);
			};
			return editor;
		};
		ctx.ui.setEditorComponent(installedFactory);
	});

	pi.on("agent_settled", (_event, ctx) => dispatch(ctx));

	pi.on("session_shutdown", (_event, ctx) => {
		pending = false;
		dispatched = false;
		// Do not overwrite a different extension's cleanup or newer editor.
		if (ctx.mode === "tui" && installedFactory && ctx.ui.getEditorComponent() === installedFactory) {
			ctx.ui.setEditorComponent(previousFactory);
		}
	});
}
