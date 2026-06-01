import { spawn } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

type EditorResult =
	| { status: "saved"; changed: boolean; text: string }
	| { status: "failed"; code: number | null }
	| { status: "error"; message: string };

type OpenEditorOptions = {
	/** Warn if edits were made but not applied anywhere. */
	warnOnDiscardedEdits?: boolean;
	/** If the file changed, put the edited text into Pi's prompt textbox. */
	putChangedTextInPrompt?: boolean;
};

function runEditor(editorCmd: string, file: string): Promise<number | null> {
	const [editor, ...editorArgs] = editorCmd.split(" ").filter(Boolean);
	return new Promise((resolve, reject) => {
		const child = spawn(editor, [...editorArgs, file], {
			stdio: "inherit",
			shell: process.platform === "win32",
		});
		child.on("error", reject);
		child.on("close", resolve);
	});
}

async function openInExternalEditor(
	ctx: ExtensionContext,
	content: string,
	fileName: string,
	description: string,
	options: OpenEditorOptions = {},
): Promise<void> {
	const editorCmd = process.env.VISUAL || process.env.EDITOR;
	if (!editorCmd) {
		ctx.ui.notify(`Set $VISUAL or $EDITOR to open the ${description}.`, "error");
		return;
	}

	const result = await ctx.ui.custom<EditorResult>((tui, _theme, _kb, done) => {
		const dir = mkdtempSync(join(tmpdir(), "pi-editor-"));
		const file = join(dir, fileName);
		writeFileSync(file, content, "utf8");

		void (async () => {
			let result: EditorResult;
			try {
				tui.stop();
				process.stdout.write(`Launching external editor: ${editorCmd}\nPi will resume when the editor exits.\n`);

				const original = readFileSync(file, "utf8").replace(/\n$/, "");
				const code = await runEditor(editorCmd, file);
				if (code === 0) {
					const edited = readFileSync(file, "utf8").replace(/\n$/, "");
					result = { status: "saved", changed: edited !== original, text: edited };
				} else {
					result = { status: "failed", code };
				}
			} catch (error) {
				result = {
					status: "error",
					message: error instanceof Error ? error.message : String(error),
				};
			} finally {
				rmSync(dir, { recursive: true, force: true });
				tui.start();
				tui.requestRender(true);
			}

			done(result);
		})();

		return new Text(`Opening ${editorCmd}...`, 1, 1);
	}, { overlay: true });

	if (result.status === "saved") {
		if (result.changed && options.putChangedTextInPrompt) {
			ctx.ui.setEditorText(result.text);
		} else if (result.changed && options.warnOnDiscardedEdits) {
			ctx.ui.notify(`${description} viewer is read-only; edited text was not applied.`, "warning");
		}
		return;
	}

	if (result.status === "failed") {
		ctx.ui.notify(`Editor exited with status ${result.code ?? "unknown"}.`, "error");
		return;
	}

	ctx.ui.notify(`Could not launch editor: ${result.message}`, "error");
}

function getLatestAssistantText(ctx: ExtensionContext): string | undefined {
	const latestAssistant = ctx.sessionManager
		.getBranch()
		.slice()
		.reverse()
		.find((entry) => {
			if (entry.type !== "message" || entry.message.role !== "assistant") return false;
			if (entry.message.stopReason === "aborted" && entry.message.content.length === 0) return false;
			return true;
		});

	if (!latestAssistant || latestAssistant.type !== "message" || latestAssistant.message.role !== "assistant") {
		return undefined;
	}

	const text = latestAssistant.message.content
		.filter((content) => content.type === "text")
		.map((content) => content.text)
		.join("")
		.trim();

	return text || undefined;
}

async function openSystemPrompt(ctx: ExtensionContext): Promise<void> {
	await openInExternalEditor(ctx, ctx.getSystemPrompt(), "system-prompt.md", "system prompt", {
		warnOnDiscardedEdits: true,
	});
}

async function openLatestResponse(ctx: ExtensionContext): Promise<void> {
	const text = getLatestAssistantText(ctx);
	if (!text) {
		ctx.ui.notify("No assistant response to open yet.", "error");
		return;
	}

	await openInExternalEditor(ctx, text, "latest-response.md", "latest response", {
		putChangedTextInPrompt: true,
	});
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("system-prompt", {
		description: "Open the current effective system prompt in $VISUAL/$EDITOR",
		handler: async (_args, ctx) => {
			await openSystemPrompt(ctx);
		},
	});

	pi.registerCommand("latest-response", {
		description: "Open the latest assistant response in $VISUAL/$EDITOR",
		handler: async (_args, ctx) => {
			await openLatestResponse(ctx);
		},
	});

	pi.registerShortcut("ctrl+space", {
		description: "Open the latest assistant response in $VISUAL/$EDITOR",
		handler: async (ctx) => {
			await openLatestResponse(ctx);
		},
	});
}
