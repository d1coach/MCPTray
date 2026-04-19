import SwiftUI
import AppKit

struct ProjectRow: View {
    let scan: ProjectScan
    let onToggle: (MCPServer, Bool) -> Void
    let onRemove: () -> Void
    let onOpenInFinder: () -> Void

    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation(.snappy(duration: 0.18)) { isExpanded.toggle() } }) {
                header
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider().opacity(0.4)
                    ForEach(AgentKind.allCases) { agent in
                        AgentSection(agent: agent, result: scan.result(for: agent), onToggle: onToggle)
                        if agent != AgentKind.allCases.last {
                            Divider().opacity(0.3).padding(.horizontal, 8)
                        }
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.thickMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: scan.project.exists ? "folder.fill" : "folder.badge.questionmark")
                .foregroundStyle(scan.project.exists ? Color.accentColor : .orange)
                .font(.body)

            VStack(alignment: .leading, spacing: 1) {
                Text(scan.project.displayName)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                Text(collapsedPath(scan.project.path))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 6)

            summaryPill

            Menu {
                Button("Reveal in Finder", action: onOpenInFinder)
                Divider()
                Button("Stop tracking", role: .destructive, action: onRemove)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()

            Image(systemName: "chevron.right")
                .rotationEffect(isExpanded ? .degrees(90) : .degrees(0))
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var summaryPill: some View {
        let enabled = scan.enabledCount
        let disabled = scan.disabledCount
        let total = enabled + disabled
        return Group {
            if total == 0 {
                Text("no MCPs")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else if disabled == 0 {
                Text("\(enabled) on")
                    .font(.caption2)
                    .foregroundStyle(.green)
            } else {
                HStack(spacing: 4) {
                    Text("\(enabled) on")
                        .foregroundStyle(.green)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("\(disabled) off")
                        .foregroundStyle(.orange)
                }
                .font(.caption2)
                .monospacedDigit()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(.quaternary.opacity(0.6)))
    }

    private func collapsedPath(_ url: URL) -> String {
        let path = url.path
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
