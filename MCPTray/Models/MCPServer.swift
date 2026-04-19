import Foundation

struct MCPServer: Identifiable, Hashable {
    let agent: AgentKind
    let name: String
    var isEnabled: Bool
    var command: String?
    var sourceFile: URL

    var id: String { "\(agent.rawValue).\(name)" }
}

struct ScanError: Identifiable, Hashable {
    let id = UUID()
    let agent: AgentKind
    let file: URL
    let message: String
}

struct AgentScanResult: Hashable {
    var servers: [MCPServer]
    var error: ScanError?

    static let empty = AgentScanResult(servers: [], error: nil)
}

struct ProjectScan: Identifiable, Hashable {
    var project: TrackedProject
    var claudeCode: AgentScanResult
    var codex: AgentScanResult
    var opencode: AgentScanResult

    var id: UUID { project.id }

    func result(for agent: AgentKind) -> AgentScanResult {
        switch agent {
        case .claudeCode: return claudeCode
        case .codex: return codex
        case .opencode: return opencode
        }
    }

    var allServers: [MCPServer] {
        claudeCode.servers + codex.servers + opencode.servers
    }

    var enabledCount: Int { allServers.filter { $0.isEnabled }.count }
    var disabledCount: Int { allServers.filter { !$0.isEnabled }.count }
}
