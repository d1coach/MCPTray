import SwiftUI

@main
struct MCPTrayApp: App {
    @State private var store = ProjectStore()
    @State private var scanner = Scanner()

    var body: some Scene {
        MenuBarExtra {
            RootView(store: store, scanner: scanner)
        } label: {
            Image(systemName: menubarSymbol)
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)
    }

    private var menubarSymbol: String {
        let anyDisabled = scanner.scans.contains { $0.disabledCount > 0 }
        return anyDisabled ? "switch.2" : "switch.2"
    }
}
