import SwiftUI

struct ServerToggleRow: View {
    let server: MCPServer
    let onToggle: (Bool) -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(server.name)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(server.isEnabled ? .primary : .secondary)
                if let cmd = server.command, !cmd.isEmpty {
                    Text(cmd)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer(minLength: 8)
            Toggle("", isOn: Binding(
                get: { server.isEnabled },
                set: { onToggle($0) }))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background {
            if isHovered {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.quaternary.opacity(0.5))
            }
        }
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}
