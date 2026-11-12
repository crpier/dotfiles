# Prompt-cache miss notifications (Pi 1.5.0–1.5.2, RPC only)

Globally installed through the existing symlink:

```text
~/.pi/agent/extensions -> ~/.dotfiles/pi-extensions
                         cache-miss-notify/index.ts
```

No settings, dependencies, slash commands, model-visible tools, injected messages, context rewrites, provider payload changes, timers, or external network calls. In **RPC mode only**, this extension observes usage and calls `ctx.ui.notify(message, "warning")`. TUI, print and JSON modes do not inspect history or emit notifications. This targets T3's RPC integration, but also applies to other Pi RPC clients.

## Activation

New Pi processes discover it automatically. Existing processes require `/reload` **after the current run settles**, or a Pi/provider-session restart. A running process cannot load the newly written extension mid-turn. In T3, use its Pi extension-command/reload support if available; otherwise restart the provider session. Restarting the entire desktop app may not restart an existing server-owned Pi process.

The temporary `/cache-miss-notify` diagnostic command and prefix-busting hook were removed after successful live testing. No slash command is required for normal operation.

After reloading revision `2026-11-10.1`, the session JSONL records a hidden custom entry with `customType: "cache-miss-notify"`, `data.kind: "loaded"` and that revision. This lets us confirm a live process actually loaded the fix before another overnight test. No startup notification is emitted. Significant misses also record hidden entries with baseline/request timestamps, token counts, estimated cost, formatted text, and whether a notice was emitted or suppressed (`episode`, `cooldown`, `no-ui`). These entries contain no prompts or credentials, have no renderer, and are not included in model context. `notified: true` means `ctx.ui.notify` was called, not proof that the client displayed it.

## Detection and noise control

The calculation follows the installed Pi 1.5.0 `dist/core/cache-stats.js` (`detectMiss`, `asPreviousRequest`, `scan`; recovered in `/tmp/pi-1.5.0-strings.txt` around lines 831456–831523):

```text
promptTokens = usage.input + usage.cacheRead + usage.cacheWrite
expectedReusable = min(previousPromptTokens, currentPromptTokens)
missedTokens = expectedReusable - currentCacheRead
significant = missedTokens > 1024
```

Caching must have been reported in the current request or previous same-model history. Thus an unsupported provider reporting zero cache on every request does not produce warnings. A partial hit can still be a significant miss. New input and output/reasoning tokens are not themselves counted as lost prefix tokens.

Uses **Pi-normalized** usage, not raw provider counters. In particular, OpenAI inclusive `prompt_tokens` must not be added directly to its cached-token count. Anthropic input/cache-read/cache-write buckets are separate, and writes count as paid rather than cache hits. Real OpenAI normalization is covered by the loopback integration test; Anthropic accounting is covered with normalized fixtures, not a live Anthropic call.

Additional conservative gates deliberately differ from Pi's TUI's broader accounting:

- First request is a cold start. Tree navigation and compaction skip the next response; persisted genuine model changes, compaction and branch-summary boundaries reset the baseline. Reselecting the same provider/model (including T3 resume/startup) preserves both cached-token evidence and its original timestamp. A startup/default-model selection event alone never suppresses the first real request.
- Only the active branch is scanned, before the response is persisted, avoiding self-comparison and abandoned histories. Cache-warming usage entries refresh that baseline.
- Long-idle misses are not suppressed. At least five minutes between request timestamps adds Pi's `after Xm idle` label, with minutes rounded to the nearest integer. This is a presentation threshold, not an assertion that every provider has a five-minute TTL. Cache-warming entries can refresh the baseline timestamp, as in Pi.
- Error, aborted, pending, deferred, zero-usage and invalid-counter responses are ignored. An error does not establish recovery.
- One notice per consecutive miss episode, rearmed by a healthy/cold response or an idle gap of at least five minutes, with a minimum 60 seconds between notices. A miss at the end of yesterday's run cannot indefinitely suppress today's idle miss. Suppressed misses are not individually replayed. Episode/cooldown state is in memory and resets on reload/session replacement/navigation/compaction; historical misses are never announced on load.
- RPC only: no detection or UI calls in TUI, print or JSON mode.

The notice fires at `message_end`, when final normalized usage is available, before tool execution and settlement. It does **not** claim to know final cache accounting during token streaming. A slow final response may therefore notify only just before settling, whereas a tool-calling response can notify while substantial work remains.

## Notification wording

Matches Pi 1.5.0's TUI `addCacheMissNotice`/`formatTokens` presentation, for example:

```text
Cache miss: 115k tokens re-billed (~$0.22)
```

After an idle interval of at least five minutes, the label becomes `Cache miss after 12m idle: …`, using Pi's elapsed-minute formatting. The interval is measured between request timestamps (or the latest cache-warming entry), not precisely from the user's last keystroke.

Cost is shown to two decimal places only when the reliable estimate is at least $0.01. Token counts use Pi's compact `k`/`M` formatting. Detection and suppression policy are unchanged; matching the wording does not adopt the TUI's separate 20,000-token/$0.10 presentation gate.

## Cost estimate

Uses Pi's same calculation:

```text
paidRate = (usage.cost.input + usage.cost.cacheWrite) / (input + cacheWrite)
readRate = usage.cost.cacheRead / cacheRead
           or model catalog cacheRead / 1,000,000 when no cache tokens were read
estimatedExtra = missedTokens * (paidRate - readRate)
```

The estimate is omitted when pricing is missing/invalid or the differential is not positive (including all-zero subscription/unknown pricing). Output cost is excluded. This is a counterfactual API-price estimate, not an invoice or a claim that an OAuth subscription is charged per request. It assumes unchanged prefix size approximates reusable content; it cannot prove identical prompt bytes. Prompt/tool rewrites, routing and legitimate prefix changes can also produce this signal. Catalog inaccuracies, tiered pricing and mixed cache-write retention can affect the estimate, just as in Pi's detector.

## Verification

Run with Node supporting TypeScript stripping (tested with Node 26):

```sh
node --test ~/.dotfiles/tests/cache-miss-notify*.mjs
```

`PI_TEST_BINARY` optionally overrides the integration test's default Pi 1.5.2 binary path.

- Unit tests exercise thresholds, partial hits, shrink/growth, cold starts, genuine vs redundant model changes, errors, pricing, Anthropic writes, valid/invalid warming, branch resets, episode suppression/recovery/cooldown, separate overnight episodes, reload receipts, and the UI guard. A regression fixture uses the real missed warning's counters/timestamps: it now produces `Cache miss after 2872m idle: 144k tokens re-billed (~$0.27)` despite the redundant same-model selection.
- Integration tests start the actual installed Pi 1.5.2 in RPC mode, isolated from user settings/history, against a loopback-only OpenAI SSE fixture. Scenarios cover ordinary requests, simulated two-day idle, reload plus same-model reselection, and actual process restart/session resume plus same-model reselection. In each, three responses (hit, miss, repeated miss) produce exactly one warning with expected tokens/cost **before the second `agent_settled`**. Idle tests verify `after 2880m idle`, unchanged system prompts/tools, and persisted audit entries. Elapsed time is simulated by aging the first fixture response's timestamp, not by waiting or changing the process clock. No external API calls or credentials are used. This verifies Pi loading/event handling/serialization, not actual provider cache eviction.
- T3 backend path verified in the installed `~/.t3/runtime/versions/0.1.8-nightly.20261107.4340/t3`: recovered source in `/tmp/t3-inspect/apps/server/dist/runtimeLayer-D3snvtXy.mjs`, lines 121646–121680 and 122204. `handleExtensionUiRequest` handles `method === "notify"` immediately when `threadState.activeTurn` exists; it calls `emitSystemNotice`, which emits a completed system node and `turn_item.updated` of type `system_notice`. No settlement wait. It ignores empty/idle notices and does not preserve `notifyType` as warning styling. The relevant source strings were also checked to exist in the installed binary, not only the extracted copy.
- **Manual live verification:** the user ran the real prefix-bust test after reload and confirmed it worked. Their T3 screenshot showed the warning for ~114,956 lost reusable tokens and ~$0.2184 extra cost. That validated the live notification path. The user also confirmed the shorter Pi-TUI-style wording worked after reload. The diagnostic command and context-rewriting hook were then removed; only passive detection remains.

## November 10 review findings

The unannounced ~48-hour miss was preceded by a persisted `model_change` selecting the same `openai/gpt-6.1-sol` model. The old scan discarded the baseline on every such entry; the old live `model_select` handler also skipped a response unconditionally. Both paths are fixed. A separate bug allowed a consecutive-miss episode to suppress a later overnight miss without a healthy response in between; long-idle gaps now rearm it. Invalid warming entries no longer turn an older non-caching request into evidence of cache support.

The screenshot's `Cache miss: 121k tokens re-billed (~$0.23)` was matched to usage at `2026-11-08T22:55:33.238Z`: ~121,220 lost reusable tokens, only ~1.4 minutes since the previous assistant request. Omitting `after Xm idle` there was correct and matches Pi 1.5.2's TUI, which still uses the five-minute threshold. A human-message gap can differ from the gap since the latest model/tool-loop request or cache refresh.

Pi's built-in cache-miss TUI notices remain enabled/unchanged. This extension adds no TUI notifications; terminal usage is unaffected after reload. Disabling built-in notices is separate configuration and does not disable this RPC-only extension.
