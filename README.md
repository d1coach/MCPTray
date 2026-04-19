# MCPTray

macOS menu bar utility for toggling project-scoped MCP servers across
Claude Code, Codex, and opencode — without hand-editing config files.

Point it at a project folder; it reads the local MCP config and exposes
per-server on/off toggles. Non-destructive: disabling a server never
deletes its command/args/env.

## What it reads/writes

| Agent | Reads | Disables via |
|---|---|---|
| Claude Code | `./.mcp.json` | `disabledMcpjsonServers` array in `./.claude/settings.local.json` |
| Codex | `./.codex/config.toml` | moves `[mcp_servers.<name>]` table to `./.codex/config.disabled.toml` |
| opencode | `./opencode.json` | flips `"enabled": false` on the MCP entry |

Toggle changes take effect on the **next session** of the affected agent
(Claude Code and Codex re-read config on each invocation; opencode on
TUI restart).

## Install

Requires macOS 26 Tahoe, Xcode 26+, and
[xcodegen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
git clone https://github.com/d1coach/MCPTray.git
cd MCPTray && ./build.sh
```

That's it. The app appears in the menu bar (`switch.2` icon); click it,
add a project folder, toggle away.

MCPTray is **unsigned**. Because you built it yourself, Gatekeeper never
blocks it — ad-hoc signing by your own machine is trusted.

## Update

```bash
cd MCPTray && git pull && ./build.sh
```

## Uninstall

```bash
osascript -e 'tell application "MCPTray" to quit'
rm -rf /Applications/MCPTray.app
defaults delete io.github.d1coach.mcptray  # forgets tracked folders
```

## Development

- Source of truth for the Xcode project is `project.yml`; regenerate with
  `xcodegen generate`. The generated `MCPTray.xcodeproj` is gitignored.
- Single SPM dependency: [TOMLKit](https://github.com/LebJe/TOMLKit).
- SwiftUI + `MenuBarExtra(.window)`, macOS 26 minimum.

## Status

Personal tool, v0.1. Explicit non-goals: Launch at Login, FSEvents
auto-refresh, Sparkle updater, add/remove MCP entries, sandbox / MAS,
user-scope MCPs in UI. Happy to accept PRs that add any of these.

## License

MIT (add a LICENSE file before publishing).
