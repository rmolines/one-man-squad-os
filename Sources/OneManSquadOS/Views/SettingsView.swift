import SwiftUI
import SwiftData
import AppKit

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gear") }
        }
        .frame(width: 460)
        .fixedSize()
    }
}

// MARK: - General Tab

private struct GeneralSettingsTab: View {
    @Query private var settingsList: [CockpitSettings]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            if let settings = settingsList.first {
                Section {
                    HStack(spacing: 8) {
                        TextField(
                            "Repo Root Path",
                            text: Binding(
                                get: { settings.rootRepoPath },
                                set: { settings.rootRepoPath = $0 }
                            )
                        )
                        .textFieldStyle(.roundedBorder)

                        Button("Browse…") { pickFolder(settings: settings) }
                    }

                    if !settings.rootRepoPath.isEmpty {
                        Text(settings.rootRepoPath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.head)
                    }
                } header: {
                    Text("Repository")
                } footer: {
                    Text("Root folder of the git repository to scan for feature plans in `.claude/feature-plans/`.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
        .onAppear {
            guard settingsList.first == nil else { return }
            modelContext.insert(CockpitSettings())
        }
    }

    private func pickFolder(settings: CockpitSettings) {
        let panel = NSOpenPanel()
        panel.title = "Select Repo Root"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        settings.rootRepoPath = url.path
    }
}
