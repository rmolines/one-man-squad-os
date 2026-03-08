import SwiftUI
import SwiftData
import SettingsAccess

@main
struct CockpitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("One Man Squad OS", systemImage: "square.stack.3d.up") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)

        WindowGroup("Portfolio", id: "portfolio") {
            PortfolioView()
        }
        .modelContainer(CockpitSchema.container)
        .defaultSize(width: 900, height: 600)

        Settings {
            SettingsView()
                .openSettingsAccess()
        }
        .modelContainer(CockpitSchema.container)
    }
}
