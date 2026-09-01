import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

interface TurnStats {
	durationMs: number;
	outputTokens: number;
	tokensPerSecond: number;
	endedAt?: number;
}

const ENTRY_TYPE = "turn-stats";
const numberFormat = new Intl.NumberFormat("en-US");
const timeFormat = new Intl.DateTimeFormat(undefined, {
	hour: "2-digit",
	minute: "2-digit",
	second: "2-digit",
	hourCycle: "h23",
});

function formatDuration(durationMs: number): string {
	if (durationMs < 1_000) return `${Math.round(durationMs)}ms`;
	if (durationMs < 10_000) return `${(durationMs / 1_000).toFixed(1)}s`;
	if (durationMs <= 60_000) return `${Math.round(durationMs / 1_000)}s`;

	const totalSeconds = Math.round(durationMs / 1_000);
	const minutes = Math.floor(totalSeconds / 60);
	const seconds = totalSeconds % 60;
	return `${minutes}m ${seconds}s`;
}

export default function (pi: ExtensionAPI) {
	const startedAt = new Map<number, number>();
	const responseEndedAt = new Map<number, number>();
	let currentTurn: number | undefined;
	let totalDurationMs = 0;
	let totalOutputTokens = 0;
	let completedTurns = 0;

	pi.registerEntryRenderer<TurnStats>(ENTRY_TYPE, (entry, _options, theme) => {
		if (!entry.data) return;

		const { durationMs, outputTokens, tokensPerSecond, endedAt } = entry.data;
		const stats = [
			`⏱ ${formatDuration(durationMs)}`,
			`${numberFormat.format(outputTokens)} output tokens`,
			`${tokensPerSecond.toFixed(1)} tok/s avg`,
		];
		if (endedAt !== undefined) stats.push(timeFormat.format(endedAt));
		const text = stats.join(" · ");

		return new Text(theme.fg("dim", text), 1, 0);
	});

	pi.on("agent_start", () => {
		startedAt.clear();
		responseEndedAt.clear();
		currentTurn = undefined;
		totalDurationMs = 0;
		totalOutputTokens = 0;
		completedTurns = 0;
	});

	pi.on("turn_start", (event) => {
		currentTurn = event.turnIndex;
		startedAt.set(event.turnIndex, event.timestamp);
	});

	pi.on("message_end", (event) => {
		if (event.message.role === "assistant" && currentTurn !== undefined) {
			responseEndedAt.set(currentTurn, Date.now());
		}
	});

	pi.on("turn_end", (event) => {
		if (event.message.role !== "assistant") return;

		const start = startedAt.get(event.turnIndex);
		const end = responseEndedAt.get(event.turnIndex) ?? Date.now();
		if (start === undefined) return;

		totalDurationMs += Math.max(1, end - start);
		totalOutputTokens += event.message.usage.output;
		completedTurns++;
		startedAt.delete(event.turnIndex);
		responseEndedAt.delete(event.turnIndex);
	});

	pi.on("agent_settled", () => {
		if (completedTurns === 0) return;

		pi.appendEntry<TurnStats>(ENTRY_TYPE, {
			durationMs: totalDurationMs,
			outputTokens: totalOutputTokens,
			tokensPerSecond: totalOutputTokens / (totalDurationMs / 1_000),
			endedAt: Date.now(),
		});
		completedTurns = 0;
	});
}
