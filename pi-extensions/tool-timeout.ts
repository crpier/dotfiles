/**
 * tool-timeout.ts — enforce a hard 3-minute timeout on all built-in tools.
 *
 * Rebuilds the built-in tools via createCodingTools(), then registers
 * same-name overrides whose execute() races the original against a timer.
 * On timeout: abort the inner signal (kills bash/powershell child processes,
 * cancels abort-aware work) and return an error tool result.
 *
 * Built-in renderers are inherited automatically (no renderCall/renderResult here).
 */

import {
	createCodingTools,
	type ExtensionAPI,
	type ToolDefinition,
} from "@earendil-works/pi-coding-agent";

const TIMEOUT_MS = 3 * 60 * 1000;

export default function (pi: ExtensionAPI) {
	const tools = createCodingTools(process.cwd());

	for (const tool of tools) {
		if (!tool.execute) continue;
		const originalExecute = tool.execute.bind(tool);
		const name = tool.name;

		pi.registerTool({
			...tool,
			description: `${tool.description} (hard ${TIMEOUT_MS / 60000}-minute timeout)`,
			async execute(
				this: unknown,
				toolCallId: string,
				params: any,
				signal: AbortSignal | undefined,
				onUpdate: any,
			) {
				// Forward user cancels (Esc) to the inner signal, so abort still works.
				const controller = new AbortController();
				const onOuterAbort = () => controller.abort(signal?.reason);
				if (signal) {
					if (signal.aborted) controller.abort(signal.reason);
					else signal.addEventListener("abort", onOuterAbort, { once: true });
				}

				let timedOut = false;

				// Swallow late rejections from the original after we've timed out.
				let timerReject: ((e: Error) => void) | undefined;
				const timeoutPromise = new Promise<never>((_, reject) => {
					timerReject = reject;
				});

				const timer = setTimeout(() => {
					timedOut = true;
					controller.abort(new Error("tool timeout"));
					timerReject?.(new Error("tool timeout"));
				}, TIMEOUT_MS);

				try {
					const result = await Promise.race([
						originalExecute(toolCallId, params, controller.signal, onUpdate),
						timeoutPromise,
					]);
					return result;
				} catch (err: any) {
					if (timedOut) {
						const msg = `Tool "${name}" timed out after 3 minutes and was aborted.`;
						return {
							content: [{ type: "text", text: msg }],
							details: {},
							isError: true,
						} as any;
					}
					throw err;
				} finally {
					clearTimeout(timer);
					signal?.removeEventListener("abort", onOuterAbort);
				}
			},
		} as ToolDefinition);
	}
}
