import Foundation

/// Reads `<project>/.mcp.json` and toggles disable state via
/// `<project>/.claude/settings.local.json`'s `disabledMcpjsonServers` array.
/// Never mutates `.mcp.json` itself.
enum ClaudeCodeIO {
    static let mcpJsonRelative = ".mcp.json"
    static let settingsLocalRelative = ".claude/settings.local.json"
    static let settingsSharedRelative = ".claude/settings.json"
    static let disabledKey = "disabledMcpjsonServers"

    static func scan(project: URL) -> AgentScanResult {
        let mcpJson = project.appendingPathComponent(mcpJsonRelative)
        guard FileManager.default.fileExists(atPath: mcpJson.path) else {
            return .empty
        }

        let data: Data
        do {
            data = try Data(contentsOf: mcpJson)
        } catch {
            return AgentScanResult(servers: [], error: ScanError(
                agent: .claudeCode, file: mcpJson,
                message: "Could not read: \(error.localizedDescription)"))
        }

        let parsed: Any
        do {
            parsed = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            return AgentScanResult(servers: [], error: ScanError(
                agent: .claudeCode, file: mcpJson,
                message: "Invalid JSON: \(error.localizedDescription)"))
        }

        guard let top = parsed as? [String: Any],
              let servers = top["mcpServers"] as? [String: Any] else {
            return AgentScanResult(servers: [], error: ScanError(
                agent: .claudeCode, file: mcpJson,
                message: "Missing or invalid `mcpServers` object"))
        }

        let disabled = Set(readDisabledList(project: project))

        let list: [MCPServer] = servers.keys.sorted().map { name in
            let entry = servers[name] as? [String: Any]
            let command = (entry?["command"] as? String)
            return MCPServer(
                agent: .claudeCode,
                name: name,
                isEnabled: !disabled.contains(name),
                command: command,
                sourceFile: mcpJson)
        }
        return AgentScanResult(servers: list, error: nil)
    }

    static func setEnabled(_ enabled: Bool, server: String, project: URL) throws {
        let claudeDir = project.appendingPathComponent(".claude", isDirectory: true)
        let settingsURL = claudeDir.appendingPathComponent("settings.local.json")

        if !FileManager.default.fileExists(atPath: claudeDir.path) {
            try FileManager.default.createDirectory(at: claudeDir, withIntermediateDirectories: true)
        }

        var obj: [String: Any] = [:]
        if FileManager.default.fileExists(atPath: settingsURL.path),
           let data = try? Data(contentsOf: settingsURL),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            obj = parsed
        }

        var list = (obj[disabledKey] as? [String]) ?? []
        if enabled {
            list.removeAll { $0 == server }
            if list.isEmpty {
                obj.removeValue(forKey: disabledKey)
            } else {
                obj[disabledKey] = list
            }
        } else {
            if !list.contains(server) { list.append(server) }
            list.sort()
            obj[disabledKey] = list
        }

        let out = try JSONSerialization.data(
            withJSONObject: obj,
            options: [.prettyPrinted, .sortedKeys])
        try out.write(to: settingsURL, options: .atomic)
    }

    private static func readDisabledList(project: URL) -> [String] {
        // settings.local.json wins; fall back to settings.json if present.
        for rel in [settingsLocalRelative, settingsSharedRelative] {
            let url = project.appendingPathComponent(rel)
            guard FileManager.default.fileExists(atPath: url.path),
                  let data = try? Data(contentsOf: url),
                  let top = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let list = top[disabledKey] as? [String]
            else { continue }
            return list
        }
        return []
    }
}
