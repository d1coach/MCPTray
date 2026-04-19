import Foundation
import Observation

@MainActor
@Observable
final class Scanner {
    private(set) var scans: [ProjectScan] = []
    private(set) var lastScanDate: Date?

    /// Re-scans every tracked project on disk.
    func scanAll(_ projects: [TrackedProject]) {
        scans = projects.map { project in
            Self.scan(project: project)
        }
        lastScanDate = Date()
    }

    /// Rescans a single project and replaces its entry in `scans`.
    func rescan(project: TrackedProject) {
        let updated = Self.scan(project: project)
        if let idx = scans.firstIndex(where: { $0.project.id == project.id }) {
            scans[idx] = updated
        } else {
            scans.append(updated)
        }
    }

    static func scan(project: TrackedProject) -> ProjectScan {
        let url = project.path
        let cc = ClaudeCodeIO.scan(project: url)
        let codex = CodexIO.scan(project: url)
        let oc = OpencodeIO.scan(project: url)
        return ProjectScan(
            project: project,
            claudeCode: cc,
            codex: codex,
            opencode: oc)
    }

    func toggle(server: MCPServer, in project: TrackedProject, to enabled: Bool) throws {
        switch server.agent {
        case .claudeCode:
            try ClaudeCodeIO.setEnabled(enabled, server: server.name, project: project.path)
        case .codex:
            try CodexIO.setEnabled(enabled, server: server.name, project: project.path)
        case .opencode:
            try OpencodeIO.setEnabled(enabled, server: server.name, project: project.path)
        }
        rescan(project: project)
    }
}
