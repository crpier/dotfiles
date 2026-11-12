import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  // T3 owns completion notifications.
  if (process.env.T3_PI_MCP_EXTENSION_PATH) return;

  // Notify only once Pi has finished retries and queued follow-ups.
  pi.on("agent_settled", async (event, ctx) => {
    if (ctx.mode !== "tui" || event.aborted) return;

    const result = await pi.exec("/usr/bin/notify-send", [
      "--app-name=pi",
      "--icon=utilities-terminal",
      "--expire-time=10000",
      "Pi",
      "Ready for input",
    ], { timeout: 5000 });
    if (result.code !== 0) {
      ctx.ui.notify(`Desktop notification failed: ${result.stderr || `exit code ${result.code}`}`, "warning");
    }
  });
}
