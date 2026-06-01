import type { TuiPlugin, TuiPluginApi } from "@opencode-ai/plugin/tui"
import { spawn } from "node:child_process"
import { mkdtemp, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"

const COMMAND = "latest-response.open-editor"

type Options = {
  auto_open_on_idle?: boolean
  delete_after_close?: boolean
}

const tui: TuiPlugin = async (api, options) => {
  const config = parseOptions(options)
  let lastOpenedMessageID = ""

  const openCurrent = async () => {
    const latest = latestAssistant(api)
    if (!latest) {
      api.ui.toast({ variant: "warning", message: "No assistant response found" })
      return
    }

    lastOpenedMessageID = latest.messageID
    try {
      await openInEditor(api, latest.text, config.delete_after_close)
    } catch (error) {
      api.ui.toast({ variant: "error", message: error instanceof Error ? error.message : String(error) })
    }
  }

  api.keymap.registerLayer({
    commands: [
      {
        name: COMMAND,
        title: "Open latest agent response in $EDITOR",
        category: "Session",
        namespace: "palette",
        slashName: "latest-response",
        suggested: () => api.route.current.name === "session",
        enabled: () => api.route.current.name === "session",
        run() {
          void openCurrent()
        },
      },
    ],
  })

  if (!config.auto_open_on_idle) return

  api.event.on("session.idle", (event) => {
    if (api.route.current.name !== "session") return
    if (api.route.current.params.sessionID !== event.properties.sessionID) return

    const latest = latestAssistant(api)
    if (!latest) return
    if (latest.messageID === lastOpenedMessageID) return

    lastOpenedMessageID = latest.messageID
    void openInEditor(api, latest.text, config.delete_after_close).catch((error) => {
      api.ui.toast({ variant: "error", message: error instanceof Error ? error.message : String(error) })
    })
  })
}

function parseOptions(options: Record<string, unknown> | undefined): Options {
  return {
    auto_open_on_idle: options?.auto_open_on_idle === true,
    delete_after_close: options?.delete_after_close !== false,
  }
}

function latestAssistant(api: TuiPluginApi) {
  if (api.route.current.name !== "session") return

  const message = api.state.session
    .messages(api.route.current.params.sessionID)
    .toReversed()
    .find((item) => item.role === "assistant")
  if (!message) return

  const text = api.state
    .part(message.id)
    .filter((part) => part.type === "text" && part.text.trim())
    .map((part) => part.text)
    .join("\n\n")
    .trim()
  if (!text) return

  return { messageID: message.id, text }
}

async function openInEditor(api: TuiPluginApi, text: string, deleteAfterClose: boolean) {
  const editor = process.env.VISUAL || process.env.EDITOR
  if (!editor) {
    api.ui.toast({ variant: "error", message: "Set $EDITOR or $VISUAL first" })
    return
  }

  const dir = await mkdtemp(join(tmpdir(), "opencode-response-"))
  const file = join(dir, "latest-response.md")
  await writeFile(file, text)

  api.renderer.suspend()
  api.renderer.currentRenderBuffer.clear()

  try {
    await runEditor(editor, file, api.state.path.directory)
  } finally {
    api.renderer.currentRenderBuffer.clear()
    api.renderer.resume()
    api.renderer.requestRender()
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

export default { id: "latest-response-editor", tui }
