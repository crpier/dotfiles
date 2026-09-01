import { Plugin, type Context } from "@opencode-ai/plugin/tui"
import { spawn } from "node:child_process"
import { mkdtemp, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"

const COMMAND = "latest-response.open-editor"

type Options = {
  auto_open_on_idle?: boolean
  delete_after_close?: boolean
}

export default Plugin.define({
  id: "latest-response-editor",
  setup(context) {
    const config = parseOptions(context.options)
    let lastOpenedMessageID = ""

    const openCurrent = async () => {
      const latest = latestAssistant(context)
      if (!latest) {
        context.ui.toast.show({ variant: "warning", message: "No assistant response found" })
        return
      }

      lastOpenedMessageID = latest.messageID
      try {
        await openInEditor(context, latest.text, config.delete_after_close)
      } catch (error) {
        context.ui.toast.show({ variant: "error", message: error instanceof Error ? error.message : String(error) })
      }
    }

    const unregisterCommand = context.ui.slot({
      append: "app",
      render: () => {
        context.keymap.layer(() => ({
          mode: "global",
          commands: [
            {
              id: COMMAND,
              title: "Open latest agent response in $EDITOR",
              group: "Session",
              palette: true,
              slash: { name: "latest-response" },
              suggested: () => context.ui.router.current().type === "session",
              enabled: () => context.ui.router.current().type === "session",
              run: openCurrent,
            },
          ],
        }))
        return null
      },
    })

    if (!config.auto_open_on_idle) return unregisterCommand

    const stopAutoOpen = context.data.on("session.execution.succeeded", (event) => {
      const route = context.ui.router.current()
      if (route.type !== "session") return
      if (route.sessionID !== event.data.sessionID) return

      void (async () => {
        await context.data.session.message.sync(route.sessionID)
        const latest = latestAssistant(context)
        if (!latest) return
        if (latest.messageID === lastOpenedMessageID) return

        lastOpenedMessageID = latest.messageID
        await openInEditor(context, latest.text, config.delete_after_close)
      })().catch((error) => {
        context.ui.toast.show({ variant: "error", message: error instanceof Error ? error.message : String(error) })
      })
    })

    return () => {
      stopAutoOpen()
      unregisterCommand()
    }
  },
})

function parseOptions(options: Record<string, unknown> | undefined): Options {
  return {
    auto_open_on_idle: options?.auto_open_on_idle === true,
    delete_after_close: options?.delete_after_close !== false,
  }
}

function latestAssistant(context: Context) {
  const route = context.ui.router.current()
  if (route.type !== "session") return

  const message = context.data.session.message
    .list(route.sessionID)
    .toReversed()
    .find((item) => item.type === "assistant")
  if (!message) return

  const text = message.content
    .filter((part) => part.type === "text" && part.text.trim())
    .map((part) => part.text)
    .join("\n\n")
    .trim()
  if (!text) return

  return { messageID: message.id, text }
}

async function openInEditor(context: Context, text: string, deleteAfterClose: boolean) {
  const editor = process.env.VISUAL || process.env.EDITOR
  if (!editor) {
    context.ui.toast.show({ variant: "error", message: "Set $EDITOR or $VISUAL first" })
    return
  }

  const dir = await mkdtemp(join(tmpdir(), "opencode-response-"))
  const file = join(dir, "latest-response.md")
  await writeFile(file, text)

  context.renderer.suspend()
  context.renderer.currentRenderBuffer.clear()

  try {
    await runEditor(editor, file, (context.location ?? context.data.location.default()).directory)
  } finally {
    context.renderer.currentRenderBuffer.clear()
    context.renderer.resume()
    context.renderer.requestRender()
    if (deleteAfterClose) await rm(dir, { recursive: true, force: true })
  }
}

function runEditor(editor: string, file: string, cwd: string) {
  const parts = editor.split(" ").filter(Boolean)
  const command = parts[0]
  if (!command) return Promise.resolve()

  return new Promise<void>((resolve, reject) => {
    const child = spawn(command, [...parts.slice(1), file], {
      cwd,
      shell: process.platform === "win32",
      stdio: "inherit",
    })
    child.on("exit", () => resolve())
    child.on("error", reject)
  })
}
