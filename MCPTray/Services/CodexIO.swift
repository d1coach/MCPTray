import Foundation
import TOMLKit

/// Reads `<project>/.codex/config.toml` for enabled MCP servers and
/// `<project>/.codex/config.disabled.toml` for parked (disabled) ones.
/// Toggle = move the `[mcp_servers.<name>]` table between the two files.
enum CodexIO {
    static let activeRelative = ".codex/config.toml"
    static let disabledRelative = ".codex/config.disabled.toml"
    static let serversTable = "mcp_servers"

    static func scan(project: URL) -> AgentScanResult {
        let active = project.appendingPathComponent(activeRelative)
        let disabled = project.appendingPathComponent(disabledRelative)

        let fm = FileManager.default
        let hasActive = fm.fileExists(atPath: active.path)
        let hasDisabled = fm.fileExists(atPath: disabled.path)

        if !hasActive && !hasDisabled { return .empty }

        var servers: [MCPServer] = []
        var firstError: ScanError?

        if hasActive {
            let (entries, err) = readServers(file: active, enabled: true)
            servers.append(contentsOf: entries)
            if firstError == nil { firstError = err }
        }
        if hasDisabled {
            let (entries, err) = readServers(file: disabled, enabled: false)
            servers.append(contentsOf: entries)
            if firstError == nil { firstError = err }
        }

        servers.sort { $0.name < $1.name }
        return AgentScanResult(servers: servers, error: firstError)
    }

    static func setEnabled(_ enabled: Bool, server: String, project: URL) throws {
        let active = project.appendingPathComponent(activeRelative)
        let disabled = project.appendingPathComponent(disabledRelative)
        let codexDir = project.appendingPathComponent(".codex", isDirectory: true)
        if !FileManager.default.fileExists(atPath: codexDir.path) {
            try FileManager.default.createDirectory(at: codexDir, withIntermediateDirectories: true)
        }

        let source = enabled ? disabled : active
        let target = enabled ? active : disabled

        let sourceDoc = try loadDoc(at: source)
        let targetDoc = try loadDoc(at: target)

        guard let sourceServers = sourceDoc[serversTable]?.table,
              let tableToMove = sourceServers[server]?.table else {
            throw CodexIOError.serverNotFound(server)
        }

        // Remove from source
        sourceServers[server] = nil
        if sourceServers.isEmpty {
            sourceDoc[serversTable] = nil
        }

        // Insert into target
        let targetServers: TOMLTable
        if let existing = targetDoc[serversTable]?.table {
            targetServers = existing
        } else {
            targetServers = TOMLTable()
            targetDoc[serversTable] = targetServers
        }
        targetServers[server] = tableToMove

        try writeDoc(sourceDoc, to: source, deleteIfEmpty: true)
        try writeDoc(targetDoc, to: target, deleteIfEmpty: false)
    }

    // MARK: - Helpers

    private static func readServers(file: URL, enabled: Bool) -> ([MCPServer], ScanError?) {
        do {
            let raw = try String(contentsOf: file, encoding: .utf8)
            let doc = try TOMLTable(string: raw)
            guard let servers = doc[serversTable]?.table else { return ([], nil) }
            let entries: [MCPServer] = servers.keys.sorted().map { name in
                let t = servers[name]?.table
                let cmd = t?["command"]?.string
                return MCPServer(
                    agent: .codex,
                    name: name,
                    isEnabled: enabled,
                    command: cmd,
                    sourceFile: file)
            }
            return (entries, nil)
        } catch {
            return ([], ScanError(agent: .codex, file: file,
                                  message: "TOML parse failed: \(error.localizedDescription)"))
        }
    }

    private static func loadDoc(at url: URL) throws -> TOMLTable {
        if !FileManager.default.fileExists(atPath: url.path) { return TOMLTable() }
        let raw = try String(contentsOf: url, encoding: .utf8)
        if raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return TOMLTable() }
        return try TOMLTable(string: raw)
    }

    private static func writeDoc(_ doc: TOMLTable, to url: URL, deleteIfEmpty: Bool) throws {
        if deleteIfEmpty && doc.isEmpty {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            return
        }
        let text = doc.convert()
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}

enum CodexIOError: LocalizedError {
    case serverNotFound(String)

    var errorDescription: String? {
        switch self {
        case .serverNotFound(let name):
            return "MCP server `\(name)` not found in Codex config."
        }
    }
}
