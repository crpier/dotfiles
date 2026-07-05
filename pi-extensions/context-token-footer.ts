import { isAbsolute, relative, resolve, sep } from "node:path";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

function formatTokens(count: number): string {
	if (!Number.isFinite(count) || count < 0) return "?";
	if (count < 1000) return count.toString();
	if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
	if (count < 1000000) return `${Math.round(count / 1000)}k`;
	if (count < 10000000) return `${(count / 1000000).toFixed(1)}M`;
	return `${Math.round(count / 1000000)}M`;
}

function formatCwd(cwd: string, home: string | undefined): string {
	if (!home) return cwd;
	const resolvedCwd = resolve(cwd);
	const resolvedHome = resolve(home);
	const relativeToHome = relative(resolvedHome, resolvedCwd);
	const isInsideHome =
		relativeToHome === "" ||
		(relativeToHome !== ".." && !relativeToHome.startsWith(`..${sep}`) && !isAbsolute(relativeToHome));
	return isInsideHome ? (relativeToHome === "" ? "~" : `~${sep}${relativeToHome}`) : cwd;
}

function sanitizeStatusText(text: string): string {
	return text.replace(/[\r\n\t]/g, " ").replace(/ +/g, " ").trim();
}

function installFooter(pi: ExtensionAPI, ctx: ExtensionContext) {
	if (!ctx.hasUI) return;

	ctx.ui.setFooter((tui, theme, footerData) => {
		const unsubscribeBranch = footerData.onBranchChange(() => tui.requestRender());

		return {
			dispose: unsubscribeBranch,
			invalidate() {},
			render(width: number): string[] {
				let totalInput = 0;
				let totalOutput = 0;
				let totalCacheRead = 0;
				let totalCacheWrite = 0;
				let totalCost = 0;

				for (const entry of ctx.sessionManager.getEntries()) {
					if (entry.type === "message" && entry.message.role === "assistant") {
						const usage = (entry.message as AssistantMessage).usage;
						if (!usage) continue;
						totalInput += usage.input ?? 0;
						totalOutput += usage.output ?? 0;
						totalCacheRead += usage.cacheRead ?? 0;
						totalCacheWrite += usage.cacheWrite ?? 0;
						totalCost += usage.cost?.total ?? 0;
					}
				}

				let pwd = formatCwd(ctx.sessionManager.getCwd(), process.env.HOME || process.env.USERPROFILE);
				const branch = footerData.getGitBranch();
				if (branch) pwd += ` (${branch})`;
				const sessionName = ctx.sessionManager.getSessionName();
				if (sessionName) pwd += ` • ${sessionName}`;

				const extensionStatuses = footerData.getExtensionStatuses();
				if (extensionStatuses.size > 0) {
					const statusText = Array.from(extensionStatuses.entries())
						.sort(([a], [b]) => a.localeCompare(b))
						.map(([, text]) => sanitizeStatusText(text))
						.join(" ");
					pwd += ` • ${statusText}`;
				}

				const statsParts: string[] = [];
				if (totalInput) statsParts.push(`↑${formatTokens(totalInput)}`);
				if (totalOutput) statsParts.push(`↓${formatTokens(totalOutput)}`);
				if (totalCacheRead) statsParts.push(`R${formatTokens(totalCacheRead)}`);
				if (totalCacheWrite) statsParts.push(`W${formatTokens(totalCacheWrite)}`);

				const model = ctx.model;
				const usingSubscription = model ? ctx.modelRegistry.isUsingOAuth(model) : false;
				if (totalCost || usingSubscription) {
					statsParts.push(`$${totalCost.toFixed(3)}${usingSubscription ? " (sub)" : ""}`);
				}

				const contextUsage = ctx.getContextUsage();
				const contextWindow = contextUsage?.contextWindow ?? model?.contextWindow ?? 0;
				const contextTokens = contextUsage?.tokens == null ? "?" : formatTokens(contextUsage.tokens);
				statsParts.push(`ctx ${contextTokens}/${formatTokens(contextWindow)}`);

				let statsLeft = statsParts.join(" ");
				let statsLeftWidth = visibleWidth(statsLeft);
				if (statsLeftWidth > width) {
					statsLeft = truncateToWidth(statsLeft, width, "...");
					statsLeftWidth = visibleWidth(statsLeft);
				}

				const modelName = model?.id || "no-model";
				let rightSide = modelName;
				if (model?.reasoning) {
					const thinkingLevel = pi.getThinkingLevel();
					rightSide = thinkingLevel === "off" ? `${modelName} • thinking off` : `${modelName} • ${thinkingLevel}`;
				}

				const minPadding = 2;
				const rightSideWidth = visibleWidth(rightSide);
				let statsLine: string;
				if (statsLeftWidth + minPadding + rightSideWidth <= width) {
					statsLine = statsLeft + " ".repeat(width - statsLeftWidth - rightSideWidth) + rightSide;
				} else {
					const availableForRight = width - statsLeftWidth - minPadding;
					if (availableForRight > 0) {
						const truncatedRight = truncateToWidth(rightSide, availableForRight, "");
						statsLine = statsLeft + " ".repeat(Math.max(0, width - statsLeftWidth - visibleWidth(truncatedRight))) + truncatedRight;
					} else {
						statsLine = statsLeft;
					}
				}

				const lines = [
					truncateToWidth(theme.fg("dim", pwd), width, theme.fg("dim", "...")),
					theme.fg("dim", statsLine),
				];

				return lines;
			},
		};
	});
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		installFooter(pi, ctx);
	});
}
