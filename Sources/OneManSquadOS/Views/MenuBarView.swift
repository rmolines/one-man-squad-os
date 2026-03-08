import SwiftUI
import SettingsAccess

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button("Open Portfolio") {
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "portfolio")
            }
            Button("Settings…") {
                openSettings()
            }
            Divider()
            Button("Quit One Man Squad OS") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(8)
    }
}
