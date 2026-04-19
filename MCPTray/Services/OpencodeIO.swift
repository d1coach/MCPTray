import Foundation

/// Reads/writes `<project>/opencode.json`. opencode supports `enabled: false`
/// per MCP entry natively, so we flip that boolean in place.
enum OpencodeIO {
    static let configRelative = "opencode.json"

    static func scan(project: URL) -> AgentScanResult {
        let url = project.appendingPathComponent(configRelative)
        guard FileManager.default.fileExists(atPath: url.path) else { return .empty }

        let data: Data
        do { data = try Data(contentsOf: url) }
        catch {
            return AgentScanResult(servers: [], error: ScanError(
                agent: .opencode, file: url,
                message: "Could not read: \(error.localizedDescription)"))
        }

        let top: [String: Any]
        do {
            guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return AgentScanResult(servers: [], error: ScanError(
                    agent: .opencode, file: url,
                    message: "Top-level JSON must be an object"))
            }
            top = parsed
        } catch {
            return AgentScanResult(servers: [], error: ScanError(
                agent: .opencode, file: url,
                message: "Invalid JSON: \(error.localizedDescription)"))
        }

        guard let mcp = top["mcp"] as? [String: Any] else { return .empty }

        let list: [MCPServer] = mcp.keys.sorted().map { name in
            let entry = mcp[name] as? [String: Any]
            let enabled = (entry?["enabled"] as? Bool) ?? true
            // command may be a string or an array of strings in opencode
            var cmd: String?
            if let s = entry?["command"] as? String { cmd = s }
            else if let a = entry?["command"] as? [String] { cmd = a.joined(separator: " ") }
            return MCPServer(
                agent: .opencode,
                name: name,
                isEnabled: enabled,
                command: cmd,
                sourceFile: url)
        }
        return AgentScanResult(servers: list, error: nil)
    }

    static func setEnabled(_ enabled: Bool, server: String, project: URL) throws {
        let url = project.appendingPathComponent(configRelative)
        let data = try Data(contentsOf: url)
        guard var top = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OpencodeIOError.invalidConfig
        }
        guard var mcp = top["mcp"] as? [String: Any],
              var entry = mcp[server] as? [String: Any] else {
            throw OpencodeIOError.serverNotFound(server)
        }
        entry["enabled"] = enabled
        mcp[server] = entry
        top["mcp"] = mcp
        let out = try JSONSerialization.data(withJSONObject: top,
                                             options: [.prettyPrinted, .sortedKeys])
        try out.write(to: url, options: .atomic)
    }
}

enum OpencodeIOError: LocalizedError {
    case invalidConfig
    case serverNotFound(String)

    var errorDescription: String? {
        switch self {
        case .invalidConfig: return "opencode.json must be a JSON object at the top level."
        case .serverNotFound(let name): return "MCP server `\(name)` not found in opencode.json."
        }
    }
}
