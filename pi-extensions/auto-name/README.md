# Auto-name

A Pi 1.0.0 command that names the current session using the selected model and
full active context, with best-effort prompt-cache reuse.

```text
/auto-name
/auto-name Emphasize the feature being implemented rather than the debugging.
/auto-name --cancel
```

This directory is already linked into `~/.pi/agent/extensions`. Run `/reload` in
Pi to load the command, then use `/auto-name` after the agent finishes working.

## Behavior

- Makes one separate request with the current model, configured provider/auth,
  session ID, thinking level, thinking budgets, transport, and provider retry
  settings. Virtual models use Pi's normal direct-request routing.
- Sends structured messages: system instructions and tool declarations, user
  and assistant messages, tool results, images (unless blocked in settings),
  shell output, custom context, and compaction/branch summaries. It does not
  flatten history into a summary prompt or truncate it.
- Observes `context_with_system` during normal chat. After the agent settles,
  it saves that observed transcript plus finalized messages after the request.
  If the session/branch/prompt/tool set still matches, naming reuses this
  snapshot, including request-local context transformations observed by this
  extension. Otherwise, including immediately after `/reload` or `/resume`,
  it reconstructs context from Pi's active-branch projection.
- Appends a title-only user instruction **only to the separate request**.
- Saves a valid response with `pi.setSessionName()`. The naming prompt and
  response are never persisted as messages, rendered in chat, or added to
  `/tree`. Only the ordinary session-name metadata is saved.
- Refuses to start while the agent is busy or messages are queued. Duplicate
  commands are ignored. Cancellation, agent startup, session shutdown, tree
  navigation, or compaction cancels an in-flight request. Session changes or
  a manual rename during the request prevent saving a stale title.
- Never executes tools. A tool call, provider error, truncated output, empty
  title, multiline title, or title over 100 characters leaves the old name
  unchanged.

## Cache and cost

Caching means the provider recognizes an unchanged request prefix; it does not
let an extension retrieve cached conversation tokens or submit only a cache ID.
The whole context is still sent. Existing system messages, tool declarations,
message structure, and opaque signatures are preserved. Default cache retention,
output budget, and tool choice are left alone, because changing these can affect
cache reuse (especially Anthropic thinking budgets/tool choice).

Cache hits are **not guaranteed**. Expiry, provider behavior, model changes,
context edits, request-local transformations, or request settings can cause a
miss. The appended instruction and latest response may be uncached. A miss can
bill the entire active context at normal input rates. The ordinary thinking
level also applies to title generation, so a high thinking level can be costly.

The completion notification reports cached-input, uncached-input, cache-write
tokens, and the provider's calculated cost. This standalone command's usage is
**not included in Pi's `/session` totals**: the public extension API has no
usage-only append method. No raw session-file writes or session reloads are
used to work around that limitation.

## Differences from a regular chat turn

This is a standalone `ctx.modelRegistry.streamSimple()` request, not a hidden
agent turn. It does not run tools, add history, change the selected model, run
automatic compaction, retry through the agent-level recovery loop, or restart
Pi's cache warmer.

It also does not redispatch `input`, `before_agent_start`, `context`,
`context_with_system`, or agent provider-payload/header/response hooks. The
snapshot observes context at this extension's handler position; transformations
registered after it are not necessarily captured. Reconstruction after reload
uses persisted context, not ephemeral transformations or unsent prompt/tool
updates. Thus it aims to match a normal chat request's cached prefix, rather
than promising byte-identical behavior for every other extension. Provider
configuration and authentication still flow through Pi's model registry.

## Tests

From the dotfiles repository root:

```sh
bash tests/test_auto_name.sh
```

Installs test-only Pi 1.0.0/TypeScript/tsx dependencies in a temporary directory,
typechecks the extension and tests, then runs offline tests using real Pi session
projection and fake model responses. No paid API calls are made. The dependency
installation needs npm registry access.
