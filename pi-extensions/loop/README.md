# `/loop` extension

Runs a recurring task in the current pi session. The model infers the interval, rewrites the request into a cadence-free instruction for one execution, and calls the extension's `set_loop` tool.

```text
/loop check every 30 minutes if the logs have errors
/loop status
/loop stop
```

The first run occurs after one interval. Later runs stay on the original cadence; missed/overlapping ticks are skipped rather than queued repeatedly. The loop survives `/reload`, tree navigation, and reopening the same session. If a run becomes due while pi is closed, one run starts when that session is reopened.

Loop instructions are injected at the message tail rather than by changing the system prompt, preserving the provider's stable prompt prefix and cache eligibility. New loop turns still add uncached tokens normally.

For example, `tell me a short funny joke every 10 seconds` becomes a repeated prompt like `Tell me one short, funny joke.`

Only one loop can be active per session. Setting another replaces it. Minimum interval: 10 seconds. Each run is a normal user turn and can use tools, modify files, and incur model/API costs. Stop it with `/loop stop` before leaving an autonomous task unattended.
