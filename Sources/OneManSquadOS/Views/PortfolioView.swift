import SwiftUI
import SwiftData
import AppKit

struct PortfolioView: View {
    @Query private var settingsList: [CockpitSettings]
    @Environment(\.modelContext) private var modelContext
    @State private var store = PortfolioStore()

    private var settings: CockpitSettings {
        if let existing = settingsList.first {
            return existing
        }
        let fresh = CockpitSettings()
        modelContext.insert(fresh)
        return fresh
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 240, maximum: 320), spacing: 12)]
    }

    var body: some View {
        Group {
            if settings.rootRepoPath.isEmpty {
                onboardingView
            } else {
                portfolioContent
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            if !settings.rootRepoPath.isEmpty {
                store.refresh(repoPath: settings.rootRepoPath)
            }
        }
    }

    // MARK: - Onboarding

    private var onboardingView: some View {
        ContentUnavailableView {
            Label("No Repo Selected", systemImage: "folder.badge.questionmark")
        } description: {
            Text("Select the root folder of a git repository to scan for feature plans.")
        } actions: {
            Button("Select Folder…") { pickFolder() }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Portfolio

    private var portfolioContent: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            ScrollView {
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                } else if store.hypotheses.isEmpty {
                    ContentUnavailableView(
                        "No feature plans found",
                        systemImage: "square.stack.3d.up.slash",
                        description: Text("No feature plans in \(settings.rootRepoPath)/.claude/feature-plans/")
                    )
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(store.hypotheses) { hypothesis in
                            HypothesisCardView(hypothesis: hypothesis)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private var toolbar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Portfolio")
                    .font(.headline)
                Text(settings.rootRepoPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                pickFolder()
            } label: {
                Label("Change Folder", systemImage: "folder")
            }
            .buttonStyle(.borderless)

            Button {
                store.refresh(repoPath: settings.rootRepoPath)
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(store.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Folder Picker

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.title = "Select Repo Root"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        settings.rootRepoPath = url.path
        store.refresh(repoPath: url.path)
    }
}
