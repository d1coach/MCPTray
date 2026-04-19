# MCPTray

macOS menu bar utility for toggling project-scoped MCP servers across Claude Code, Codex, and opencode — without hand-editing config files.

Point it at a project folder; it reads the local MCP config and exposes per-server on/off toggles. Non-destructive: disabling a server never deletes its command/args/env.

## What it reads/writes

| Agent | Reads | Disables via |
|---|---|---|
| Claude Code | `./.mcp.json` | `disabledMcpjsonServers` array in `./.claude/settings.local.json` |
| Codex | `./.codex/config.toml` | moves `[mcp_servers.<name>]` table to `./.codex/config.disabled.toml` |
| opencode | `./opencode.json` | flips `"enabled": false` on the MCP entry |

Toggle changes take effect on the **next session** of the affected agent (Claude Code / Codex re-read config on each invocation; opencode on TUI restart).

## Requirements

- macOS 26 Tahoe
- Xcode 26+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build & run

```bash
cd MCPTray
xcodegen generate
open MCPTray.xcodeproj
# Build & Run (⌘R) in Xcode
```

Or from the CLI:

```bash
xcodebuild -project MCPTray.xcodeproj -scheme MCPTray -configuration Debug build
cp -R ~/Library/Developer/Xcode/DerivedData/MCPTray-*/Build/Products/Debug/MCPTray.app /Applications/
open /Applications/MCPTray.app
```

The app appears in the macOS menu bar (`switch.2` icon). Unsigned local build; Gatekeeper does not intervene for locally built apps.

## Status

Personal tool, v0.1. Non-goals for now: Launch at Login, FSEvents auto-refresh, Sparkle updater, add/remove MCP entries, sandbox / MAS, user-scope MCPs in UI.
