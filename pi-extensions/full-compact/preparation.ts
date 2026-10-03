import {
	buildSessionProjection,
	compact,
	estimateTokens,
	prepareBranchEntries,
	type SessionEntry,
} from "@earendil-works/pi-coding-agent";

type Preparation = Parameters<typeof compact>[0];

/** Use the finalized active context, not raw history or abandoned branches. */
export function prepareFullCompaction(branch: SessionEntry[], settings: Preparation["settings"]): Preparation | undefined {
	const projection = buildSessionProjection(branch);
	const previous = projection.entries.find((entry) => entry.sourceEntry.type === "compaction");
	const previousCompaction = previous?.sourceEntry.type === "compaction" ? previous.sourceEntry : undefined;
	const visibleEntries: SessionEntry[] = [];
	for (const { sourceEntry, messages } of projection.entries) {
		if (sourceEntry.type === "compaction" || messages.length === 0) continue;
		if (sourceEntry.type === "message") {
			const message = messages[0];
			if (message.role !== "system") visibleEntries.push({ ...sourceEntry, message: message as typeof sourceEntry.message });
		} else if (sourceEntry.type === "custom_message" && messages[0].role === "custom") {
			visibleEntries.push({ ...sourceEntry, content: messages[0].content });
		} else {
			visibleEntries.push(sourceEntry);
		}
	}
	const messages = projection.entries
		.filter((entry) => entry.sourceEntry.type !== "compaction")
		.flatMap((entry) => entry.messages)
		.filter((message) => message.role !== "system");
	if (messages.length === 0) return undefined;
	// Reuse Pi's exported file tracker for assistant calls and branch summaries.
	// Its branch helper skips tool results, so keep the actual projected messages
	// for compaction and collect their nested file operations separately.
	const prepared = prepareBranchEntries(visibleEntries, 0);
	for (const message of messages) {
		if (message.role !== "toolResult") continue;
		for (const call of message.nestedCalls?.calls ?? []) {
			const path = call.arguments?.path;
			if (typeof path !== "string" || !path) continue;
			if (call.name === "read") prepared.fileOps.read.add(path);
			if (call.name === "write") prepared.fileOps.written.add(path);
			if (call.name === "edit") prepared.fileOps.edited.add(path);
		}
	}

	// Carry Pi-generated lists and our own lists across repeated checkpoints.
	if (previousCompaction && (!previousCompaction.fromHook || isFullCompactionDetails(previousCompaction.details))) {
		const details = previousCompaction.details as { readFiles?: unknown; modifiedFiles?: unknown } | undefined;
		if (Array.isArray(details?.readFiles)) {
			for (const path of details.readFiles) if (typeof path === "string") prepared.fileOps.read.add(path);
		}
		if (Array.isArray(details?.modifiedFiles)) {
			for (const path of details.modifiedFiles) if (typeof path === "string") prepared.fileOps.edited.add(path);
		}
	}

	return {
		// compact() requires a real ID. Persistence replaces it with null, which
		// SessionManager resolves to the new checkpoint's own ID (retain none).
		firstKeptEntryId: branch[branch.length - 1].id,
		messagesToSummarize: messages,
		turnPrefixMessages: [],
		isSplitTurn: false,
		previousSummary: previousCompaction?.summary,
		tokensBefore: projection.messages.reduce((sum, message) => sum + estimateTokens(message), 0),
		fileOps: prepared.fileOps,
		settings,
	};
}

function isFullCompactionDetails(details: unknown): boolean {
	return typeof details === "object" && details !== null && "fullCompact" in details && details.fullCompact === true;
}
