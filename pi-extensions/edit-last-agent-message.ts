import { spawn } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionContext,
	type KeybindingsManager,
	SettingsManager,
} from "@earendil-works/pi-coding-agent";
import type { EditorComponent, EditorTheme, TUI } from "@earendil-works/pi-tui";

type MarkedEditorFactory = ((tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) => EditorComponent) & {
	__editLastAgentMessageFactory?: true;
	baseFactory?: (tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) => EditorComponent;
};

function getLastAssistantText(ctx: ExtensionContext): string | undefined {
	for (const entry of ctx.sessionManager.getBranch().toReversed()) {
		if (entry.type !== "message" || entry.message.role !== "assistant") continue;

		const text = entry.message.content
			.filter((part): part is { type: "text"; text: string } => part.type === "text")
			.map((part) => part.text)
			.join("")
			.trim();
		return text || undefined;
	}
	return undefined;
}

function runEditor(command: string, file: string): Promise<number | null> {
	const [editor, ...args] = command.split(" ");
	if (!editor) return Promise.resolve(null);

	return new Promise((resolve) => {
		const child = spawn(editor, [...args, file], {
			stdio: "inherit",
			shell: process.platform === "win32",
		});
		child.on("error", () => resolve(null));
		child.on("close", (code) => resolve(code));
	});
}

export default function (pi: ExtensionAPI) {
	let tui: TUI | undefined;
	let running = false;
	let installedBaseFactory: MarkedEditorFactory["baseFactory"];

	pi.registerShortcut("ctrl+space", {
		description: "Edit the latest agent message as the next prompt",
		handler: async (ctx) => {
			if (ctx.mode !== "tui" || !tui) return;
			if (running) {
				ctx.ui.notify("External editor is already open", "warning");
				return;
			}

			const original = getLastAssistantText(ctx);
			if (!original) {
				ctx.ui.notify("No finalized agent message with text", "error");
				return;
			}

			const settings = SettingsManager.create(ctx.cwd, undefined, {
				projectTrusted: ctx.isProjectTrusted(),
			});
			const editorCommand = settings.getExternalEditorCommand();
			if (!editorCommand) {
				ctx.ui.notify("No external editor configured", "error");
				return;
			}

			running = true;
			let directory: string | undefined;
			let tuiStopped = false;

			try {
				directory = await mkdtemp(join(tmpdir(), "pi-edit-agent-message-"));
				const file = join(directory, "agent-message.pi.md");
				await writeFile(file, original, "utf8");
				tui.stop();
				tuiStopped = true;
				process.stdout.write(`Launching external editor: ${editorCommand}\nPi will resume when the editor exits.\n`);

				const status = await runEditor(editorCommand, file);
				if (status === 0) {
					const edited = (await readFile(file, "utf8")).replace(/\n$/, "");
					if (edited !== original) {
						// Image attachments are represented in the editor text, so replacing it
						// also clears any images from the previous draft.
						ctx.ui.setEditorText(edited);
					}
				} else {
					ctx.ui.notify("External editor failed; prompt unchanged", "error");
				}
			} catch (error) {
				ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
			} finally {
				try {
					if (directory) await rm(directory, { recursive: true, force: true });
				} catch {
					// Cleanup failure must not leave the TUI stopped.
				}
				if (tuiStopped) {
					tui.start();
					tui.requestRender(true);
				}
				running = false;
			}
		},
	});

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		const currentFactory = ctx.ui.getEditorComponent() as MarkedEditorFactory | undefined;
		const baseFactory = currentFactory?.__editLastAgentMessageFactory ? currentFactory.baseFactory : currentFactory;
		installedBaseFactory = baseFactory;

		const captureTuiFactory: MarkedEditorFactory = (currentTui, theme, keybindings) => {
			tui = currentTui;
			return baseFactory
				? baseFactory(currentTui, theme, keybindings)
				: new CustomEditor(currentTui, theme, keybindings);
		};
		captureTuiFactory.__editLastAgentMessageFactory = true;
		captureTuiFactory.baseFactory = baseFactory;
		ctx.ui.setEditorComponent(captureTuiFactory);
	});

	pi.on("session_shutdown", (_event, ctx) => {
		tui = undefined;
		if (ctx.mode === "tui") ctx.ui.setEditorComponent(installedBaseFactory);
	});
}
