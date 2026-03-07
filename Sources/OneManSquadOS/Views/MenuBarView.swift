import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button("Open Portfolio") {
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "portfolio")
            }
            Divider()
            Button("Quit One Man Squad OS") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(8)
    }
}
