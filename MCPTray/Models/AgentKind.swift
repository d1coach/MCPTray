import Foundation

enum AgentKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case claudeCode
    case codex
    case opencode

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code"
        case .codex: return "Codex"
        case .opencode: return "opencode"
        }
    }

    /// SF Symbol name used next to the section header.
    var symbolName: String {
        switch self {
        case .claudeCode: return "c.square"
        case .codex: return "chevron.left.forwardslash.chevron.right"
        case .opencode: return "shippingbox"
        }
    }
}
