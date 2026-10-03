# Full compaction

A Pi 1.0.0 extension that saves a smaller checkpoint before leaving a session:

```text
/full-compact
/full-compact Preserve unresolved tasks, design decisions, and verification commands.
```

The repository's `pi-extensions` directory is already linked to
`~/.pi/agent/extensions`. Run `/reload` in Pi to discover the command.

## Behavior

- Summarizes **all current model-visible conversation history on the active
  branch**, including recent messages that ordinary compaction would retain.
- Incorporates the previous summary using Pi's built-in update-summary prompt.
  It does not reread already-compacted raw history or abandoned branches.
- Uses Pi's exported `compact()` function: the same summarization system prompt,
  summary format, serialization (including tool-output truncation), file lists,
  and error/length checks as ordinary Pi compaction. No prompt is copied here.
- Uses the selected model, configured provider/authentication, thinking level,
  compaction output budget, and retry settings. Summary requests disable cache
  writes, as Pi's ordinary summarizer does.
- Saves a retain-none compaction entry and reopens **the same session file**.
  The next request contains the summary and system/tool checkpoint, but no old
  conversation messages. New messages then accumulate normally.
- Keeps the original transcript, session ID, branches, and summary usage/cost
  accounting in the session file.
- Leaves `/compact` and automatic compaction unchanged. Repeating the command
  with no new context does nothing.

Run it at any time: when the agent is busy or messages are queued, one full
compaction waits until that work finishes, then summarizes the latest context.
Duplicate requests are ignored while one is queued or running. The selected
model and settings are read when summarization starts. Switching sessions or
reloading extensions discards the queued request. Keep Pi running until it finishes.

It requires a saved session; `--no-session` is not supported.
`/full-compact --cancel` cancels a queued request or a running summary. Failed, empty, cancelled, or output-capped
summaries are not saved. Changes to the active branch or session file during
summarization also prevent saving a stale checkpoint.

## Implementation notes

Pi's ordinary compaction can reject short sessions before extension hooks run,
so this command calls the exported summarizer directly. The extension context
exposes only a read-only session manager. To persist through supported APIs,
we open the file with `SessionManager`, append a checkpoint with
`firstKeptEntryId: null` (Pi resolves this to the checkpoint's own ID), and use
`ctx.switchSession()` to rebuild the live session. This also reloads extensions
and their session-scoped state. It does **not** emit the built-in
`session_before_compact` / `session_compact` lifecycle events.

If another extension cancels the session switch, the checkpoint is already saved;
resume the session before continuing. Do not edit the same session concurrently
from another Pi process.

This trades a summarization call and possible loss of detail for fewer uncached
input tokens when resuming. It does not eliminate the cost of processing the
summary, system instructions, or tools. Run it before leaving, rather than after
the cache expires, if you want to avoid resending the large old context later.

## Tests

From the repository root:

```sh
bash tests/test_full_compact.sh
```

The runner installs test-only Pi 1.0.0, TypeScript, and tsx dependencies in a
removed-on-exit temporary directory, typechecks the extension, and runs offline
integration tests with real session persistence and a fake summarization stream.
No paid model calls are made. The initial dependency installation requires npm
registry access.
