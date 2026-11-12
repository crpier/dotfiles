// Pi 1.5.0 dist/core/cache-stats.js semantics, with conservative notification gates.
// Usage is Pi-normalized: input EXCLUDES cacheRead/cacheWrite for all providers.
export interface Request {
	provider: string;
	model: string;
	api?: string;
	timestamp: number;
	stopReason?: string;
	usage: {
		input: number;
		cacheRead: number;
		cacheWrite: number;
		cost?: { input: number; cacheWrite: number; cacheRead: number };
	};
}
export interface Previous {
	promptTokens: number;
	key: string;
	timestamp: number;
	reportedCache: boolean;
}
export const IDLE_LABEL_THRESHOLD_MS = 5 * 60_000;
export const COOLDOWN_MS = 60_000;
const key = (m: Request) => JSON.stringify([m.provider, m.model]);
const valid = (n: number) => Number.isFinite(n) && n >= 0;

export function previousRequest(m: Request, prev?: Previous): Previous | undefined {
	const u = m.usage;
	if ([u.input, u.cacheRead, u.cacheWrite, m.timestamp].some(n => !valid(n)) ||
		["error", "aborted", "pending", "deferred"].includes(m.stopReason ?? "")) return prev;
	const promptTokens = u.input + u.cacheRead + u.cacheWrite;
	if (promptTokens <= 0) return prev;
	return { promptTokens, key: key(m), timestamp: m.timestamp,
		reportedCache: (prev?.key === key(m) && prev.reportedCache) || u.cacheRead + u.cacheWrite > 0 };
}

// Structural entries keep this module independent of Pi's host-only imports.
export function scanPrevious(entries: readonly any[]): Previous | undefined {
	let prev: Previous | undefined;
	for (const entry of entries) {
		if (entry.type === "compaction" || entry.type === "branch_summary") prev = undefined;
		else if (entry.type === "model_change") {
			// T3/Pi can reselect the current model on resume. That is not a cold start.
			if (prev?.key !== JSON.stringify([entry.provider, entry.modelId])) prev = undefined;
		} else if (entry.type === "usage" && entry.kind === "cache_warm") {
			const warm = previousRequest({ ...entry, timestamp: Date.parse(entry.timestamp) });
			if (warm) prev = { ...warm, reportedCache: true };
		} else if (entry.type === "message" && entry.message.role === "assistant") {
			prev = previousRequest(entry.message, prev);
		}
	}
	return prev;
}

export function detectMiss(prev: Previous | undefined, m: Request, cacheReadRate?: number) {
	const current = previousRequest(m);
	if (!prev || !current || prev.key !== current.key) return;
	const idleMs = m.timestamp - prev.timestamp;
	// Long idle periods can expire the cache; report them rather than suppressing them.
	if (idleMs < 0) return;
	const u = m.usage;
	if (u.cacheRead + u.cacheWrite === 0 && !prev.reportedCache) return;
	const expectedTokens = Math.min(prev.promptTokens, current.promptTokens);
	const missedTokens = expectedTokens - u.cacheRead;
	if (missedTokens <= 1024) return; // Pi's exact strict noise-floor comparison.
	const paidTokens = u.input + u.cacheWrite;
	const cost = u.cost;
	const readPerToken = u.cacheRead > 0 && cost ? cost.cacheRead / u.cacheRead :
		cacheReadRate === undefined ? undefined : cacheReadRate / 1e6;
	let extraCost: number | undefined;
	if (cost && paidTokens > 0 && [cost.input, cost.cacheWrite].every(valid) &&
		readPerToken !== undefined && valid(readPerToken)) {
		const paidPerToken = (cost.input + cost.cacheWrite) / paidTokens;
		// All-zero pricing (subscriptions/unknown catalog) is not a reliable dollar estimate.
		if (paidPerToken > readPerToken) extraCost = missedTokens * (paidPerToken - readPerToken);
	}
	return { missedTokens, expectedTokens, cacheRead: u.cacheRead, extraCost, idleMs };
}

// Match Pi 1.5.0's TUI formatTokens/addCacheMissNotice presentation.
export function formatMiss(miss: NonNullable<ReturnType<typeof detectMiss>>) {
	const count = miss.missedTokens;
	const tokens = count < 1000 ? count.toString()
		: count < 10_000 ? `${(count / 1000).toFixed(1)}k`
		: count < 1_000_000 ? `${Math.round(count / 1000)}k`
		: count < 10_000_000 ? `${(count / 1_000_000).toFixed(1)}M`
		: `${Math.round(count / 1_000_000)}M`;
	const cost = miss.extraCost !== undefined && miss.extraCost >= 0.01
		? ` (~$${miss.extraCost.toFixed(2)})` : "";
	const label = miss.idleMs >= IDLE_LABEL_THRESHOLD_MS
		? `Cache miss after ${Math.round(miss.idleMs / 60_000)}m idle` : "Cache miss";
	return `${label}: ${tokens} tokens re-billed${cost}`;
}
