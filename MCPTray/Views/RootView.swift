import SwiftUI
import AppKit

struct RootView: View {
    @Bindable var store: ProjectStore
    @Bindable var scanner: Scanner
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.5)
            content
            Divider().opacity(0.5)
            footer
        }
        .frame(width: 420, height: 560)
        .background(.regularMaterial)
        .onAppear {
            scanner.scanAll(store.projects)
        }
        .alert("Couldn't update config", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "switch.2")
                .foregroundStyle(Color.accentColor)
                .font(.title3)
            Text("MCP Toggles")
                .font(.system(.headline, design: .rounded, weight: .semibold))
            Spacer()
            Button(action: addFolder) {
                Image(systemName: "plus")
            }
            .help("Add a project folder")
            .buttonStyle(.borderless)

            Button(action: { scanner.scanAll(store.projects) }) {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh all projects")
            .buttonStyle(.borderless)

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "power")
            }
            .help("Quit MCPTray")
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if store.projects.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(currentScans) { scan in
                        ProjectRow(
                            scan: scan,
                            onToggle: { server, value in toggle(server, in: scan.project, to: value) },
                            onRemove: { store.remove(scan.project); scanner.scanAll(store.projects) },
                            onOpenInFinder: { NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: scan.project.path.path) }
                        )
                    }
                }
                .padding(10)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(.secondary)
            Text("No projects yet")
                .font(.system(.title3, design: .rounded, weight: .semibold))
            Text("Add a project folder to see and toggle its\nClaude Code, Codex, and opencode MCP servers.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: addFolder) {
                Label("Add folder…", systemImage: "plus")
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 6) {
            if let last = scanner.lastScanDate {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("Scanned \(last, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Text("\(store.projects.count) project\(store.projects.count == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private var currentScans: [ProjectScan] {
        // Preserve order based on store.projects
        let byId = Dictionary(uniqueKeysWithValues: scanner.scans.map { ($0.project.id, $0) })
        return store.projects.compactMap { byId[$0.id] ?? Scanner.scan(project: $0) }
    }

    private func addFolder() {
        // Activate the app so NSOpenPanel's sidebar favourites render properly —
        // without this, an .accessory (LSUIElement) app gets a panel with all
        // sidebar items greyed out. We deliberately do NOT toggle activation
        // policy: doing so leaves the MenuBarExtra popover unable to become key
        // on subsequent opens.
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Add"
        panel.message = "Pick a project folder"
        panel.level = .modalPanel

        panel.begin { [self] response in
            guard response == .OK, let url = panel.url else { return }
            store.add(url)
            scanner.scanAll(store.projects)
        }
    }

    private func toggle(_ server: MCPServer, in project: TrackedProject, to enabled: Bool) {
        do {
            try scanner.toggle(server: server, in: project, to: enabled)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
