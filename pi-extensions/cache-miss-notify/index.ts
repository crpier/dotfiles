import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { COOLDOWN_MS, IDLE_LABEL_THRESHOLD_MS, detectMiss, formatMiss, scanPrevious, type Previous } from "./detection.ts";

// Hidden custom entries let us verify reload/notification decisions without changing
// model context, registering commands, or emitting noisy startup notifications.
export const REVISION = "2026-11-10.1";
const AUDIT_TYPE = "cache-miss-notify";

export default function (pi: ExtensionAPI) {
	let previous: Previous | undefined;
	let inEpisode = false;
	let lastNotice = -Infinity;
	let observing = false;
	let skipNext = false;
	const reset = () => {
		previous = undefined;
		inEpisode = false;
		lastNotice = -Infinity;
		observing = false;
		skipNext = false;
	};
	pi.on("session_start", (event, ctx) => {
		reset();
		if (ctx.mode === "rpc") pi.appendEntry(AUDIT_TYPE, { kind: "loaded", revision: REVISION, reason: event.reason });
	});
	const coldStart = () => { reset(); skipNext = true; };
	pi.on("session_tree", coldStart);
	pi.on("session_compact", coldStart);
	// Do not blindly skip model_select: a host may reselect the same model (or
	// restore it from a different startup default). Persisted model identity changes
	// and response keys already distinguish true switches from resume/reselection.
	pi.on("agent_settled", () => { observing = false; });

	pi.on("turn_start", (_event, ctx) => {
		if (ctx.mode !== "rpc") return;
		// Snapshot BEFORE the response is persisted. Only active-branch history counts.
		// This includes cache-warming usage entries, and works after resume or /reload.
		previous = skipNext ? undefined : scanPrevious(ctx.sessionManager.getBranch());
		skipNext = false;
		observing = true;
	});
	pi.on("message_end", (event, ctx) => {
		if (ctx.mode !== "rpc" || !observing || event.message.role !== "assistant") return;
		observing = false;
		const message = event.message;
		const model = ctx.modelRegistry.find(message.provider, message.model);
		const miss = detectMiss(previous, message, model?.cost.cacheRead);
		if (!miss) {
			// Errors do not represent recovery; retain episode suppression across retries.
			if (!["error", "aborted", "pending", "deferred"].includes(message.stopReason)) inEpisode = false;
			return;
		}
		// A later idle request is a new episode, even if the previous run ended
		// with a miss and there was no intervening healthy request.
		if (miss.idleMs >= IDLE_LABEL_THRESHOLD_MS) inEpisode = false;
		const suppressed = !ctx.hasUI ? "no-ui" : inEpisode ? "episode"
			: Date.now() - lastNotice < COOLDOWN_MS ? "cooldown" : undefined;
		const text = formatMiss(miss);
		if (!suppressed) {
			ctx.ui.notify(text, "warning");
			lastNotice = Date.now();
		}
		pi.appendEntry(AUDIT_TYPE, {
			kind: "miss", revision: REVISION, provider: message.provider, model: message.model,
			requestTimestamp: message.timestamp, previousTimestamp: previous?.timestamp,
			...miss, notified: !suppressed, suppressed, text,
		});
		inEpisode = true;
	});
}
