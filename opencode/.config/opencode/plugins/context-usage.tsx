/** @jsxImportSource @opentui/solid */

import { Plugin, type Context } from "@opencode-ai/plugin/tui"

export default Plugin.define({
  id: "context-usage",
  setup(context) {
    const location = context.location ?? context.data.location.default()
    void context.data.location.model.sync(location).catch(() => undefined)

    return context.ui.slot({
      replace: "prompt.footer",
      render: ({ sessionID }) => {
        if (!sessionID) return null

        const session = context.data.session.get(sessionID)
        const modelRef = session?.model ?? latestModel(context, sessionID)
        if (!modelRef) return null

        const models = context.data.location.model.list(session?.location ?? location)
        const model = models?.find((item) => item.id === modelRef.id && item.providerID === modelRef.providerID)
        if (!model) return null

        const latest = context.data.session.message
          .list(sessionID)
          .toReversed()
          .find((item) => item.type === "assistant" && item.tokens)
        const tokens = latest?.type === "assistant" ? latest.tokens : undefined
        const used = tokens
          ? tokens.input + tokens.cache.read + tokens.cache.write + tokens.output
          : 0

        const commands = context.keymap.shortcuts("command.palette.show")[0]

        return (
          <box flexDirection="row" justifyContent="flex-end" gap={2} width="100%">
            <text>{`${formatTokens(used)} / ${formatTokens(model.limit.context)}`}</text>
            {commands ? <text>{`${commands} commands`}</text> : null}
          </box>
        )
      },
    })
  },
})

function latestModel(context: Context, sessionID: string) {
  const message = context.data.session.message
    .list(sessionID)
    .toReversed()
    .find((item) => item.type === "assistant")
  return message?.type === "assistant" ? message.model : undefined
}

function formatTokens(tokens: number) {
  if (tokens < 1_000) return String(Math.round(tokens))

  const divisor = tokens >= 1_000_000 ? 1_000_000 : 1_000
  const suffix = divisor === 1_000_000 ? "M" : "K"
  const value = tokens / divisor
  const formatted = value < 100 ? value.toFixed(1).replace(/\.0$/, "") : Math.round(value).toString()
  return `${formatted}${suffix}`
}
