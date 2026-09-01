import {
  convertToLlm,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import type { Context, Message, Model, Tool } from "@earendil-works/pi-ai";

const WARMING_PROMPT =
  "This is a keep-alive request. Do not perform any work or use tools. Reply with exactly: OK";
const INTERVAL_MS = 4 * 60 * 1000;
const DURATION_MS = 30 * 60 * 1000;
const BUSY_RETRY_MS = 1_000;
const REQUEST_TIMEOUT_MS = 60_000;

type Snapshot = {
  ctx: ExtensionContext;
  model: Model<any>;
  context: Context;
  thinkingLevel: ExtensionContext["thinkingLevel"];
  sessionId: string;
};

type WarmingState = {
  generation: number;
  last: number;
  expires: number;
  snapshot: Snapshot;
};

export default function cacheWarming(pi: ExtensionAPI) {
  let enabled = true;
  let state: WarmingState | undefined;
  let timer: ReturnType<typeof setTimeout> | undefined;
  let request: AbortController | undefined;
  let generation = 0;

  function clearTimer() {
    if (timer) clearTimeout(timer);
    timer = undefined;
  }

  function stop() {
    generation++;
    state = undefined;
    clearTimer();
    request?.abort();
    request = undefined;
  }

  function arm(current: WarmingState, at?: number) {
    clearTimer();
    if (!enabled || state !== current || Date.now() >= current.expires) {
      if (state === current) state = undefined;
      return;
    }

    const due = at ?? Math.min(current.last + INTERVAL_MS, current.expires);
    timer = setTimeout(() => void warm(current), Math.max(0, due - Date.now()));
    timer.unref?.();
  }

  async function warm(current: WarmingState) {
    timer = undefined;
    if (!enabled || state !== current || current.generation !== generation) return;

    const now = Date.now();
    if (now >= current.expires) {
      state = undefined;
      return;
    }

    if (!current.snapshot.ctx.isIdle() || current.snapshot.ctx.hasPendingMessages()) {
      arm(current, Math.min(now + BUSY_RETRY_MS, current.expires));
      return;
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
    timeout.unref?.();
    request = controller;

    try {
      const messages: Message[] = [
        ...current.snapshot.context.messages,
        { role: "user", content: WARMING_PROMPT, timestamp: Date.now() },
      ];
      const reasoning = current.snapshot.thinkingLevel;

      await current.snapshot.ctx.modelRegistry.complete(
        current.snapshot.model,
        { ...current.snapshot.context, messages },
        {
          signal: controller.signal,
          sessionId: current.snapshot.sessionId,
          cacheRetention: "short",
          transport: "auto",
          maxTokens: 16,
          ...(reasoning && reasoning !== "off" ? { reasoning } : {}),
        },
      );
    } catch (error) {
      if (!controller.signal.aborted) {
        const message = error instanceof Error ? error.message : String(error);
        console.warn(`[cache-warming] ${message}`);
      }
    } finally {
      clearTimeout(timeout);
      if (request === controller) request = undefined;
    }

    if (state !== current || current.generation !== generation) return;
    current.last = Date.now();
    arm(current);
  }

  pi.on("context", (event, ctx) => {
    if (!enabled || !ctx.model) return;

    request?.abort();
    request = undefined;

    const allTools = new Map(pi.getAllTools().map((tool) => [tool.name, tool]));
    const tools: Tool[] = pi.getActiveTools().flatMap((name) => {
      const tool = allTools.get(name);
      return tool
        ? [{ name: tool.name, description: tool.description, parameters: tool.parameters }]
        : [];
    });
    const now = Date.now();
    const current: WarmingState = {
      generation: ++generation,
      last: now,
      expires: now + DURATION_MS,
      snapshot: {
        ctx,
        model: ctx.model,
        context: {
          systemPrompt: ctx.getSystemPrompt(),
          messages: structuredClone(convertToLlm(event.messages)),
          tools,
        },
        thinkingLevel: ctx.thinkingLevel,
        sessionId: ctx.sessionManager.getSessionId(),
      },
    };

    state = current;
    arm(current);
  });

  pi.on("session_shutdown", () => stop());

  pi.registerCommand("warming", {
    description: "Control provider prompt-cache warming: on, off, or status",
    handler: async (args, ctx) => {
      const action = args.trim().toLowerCase() || "status";
      if (action === "off") {
        enabled = false;
        stop();
        ctx.ui.notify("Cache warming disabled", "info");
        return;
      }
      if (action === "on") {
        enabled = true;
        ctx.ui.notify("Cache warming enabled; starts after the next model request", "info");
        return;
      }
      if (action !== "status") {
        ctx.ui.notify("Usage: /warming [on|off|status]", "warning");
        return;
      }

      const remaining = state ? Math.max(0, Math.ceil((state.expires - Date.now()) / 60_000)) : 0;
      const detail = state ? `, ${remaining}m remaining` : ", waiting for a model request";
      ctx.ui.notify(`Cache warming ${enabled ? "enabled" : "disabled"}${enabled ? detail : ""}`, "info");
    },
  });
}
