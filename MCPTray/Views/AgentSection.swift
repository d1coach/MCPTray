import SwiftUI

struct AgentSection: View {
    let agent: AgentKind
    let result: AgentScanResult
    let onToggle: (MCPServer, Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: agent.symbolName)
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(agent.displayName)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                if !result.servers.isEmpty {
                    Text("\(result.servers.filter { $0.isEnabled }.count)/\(result.servers.count)")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 8)

            if let error = result.error {
                errorBadge(error)
            } else if result.servers.isEmpty {
                Text("Not configured")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .italic()
                    .padding(.horizontal, 8)
                    .padding(.bottom, 2)
            } else {
                VStack(spacing: 2) {
                    ForEach(result.servers) { server in
                        ServerToggleRow(server: server) { newValue in
                            onToggle(server, newValue)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func errorBadge(_ error: ScanError) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.caption)
            Text(error.message)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.orange.opacity(0.12))
        }
        .padding(.horizontal, 8)
    }
}
