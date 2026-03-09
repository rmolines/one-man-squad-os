import SwiftUI
import SwiftData
import SettingsAccess
import Core

struct PortfolioView: View {
    @Query private var settingsList: [CockpitSettings]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openSettings) private var openSettings
    @State private var store = PortfolioStore()
    @State private var isRefreshSpinning = false
    @State private var selectedGroupId: String? = nil
    @State private var selectedFeatureId: String? = nil

    private var settings: CockpitSettings {
        if let existing = settingsList.first { return existing }
        let fresh = CockpitSettings()
        modelContext.insert(fresh)
        return fresh
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 240, maximum: 320), spacing: 12)]
    }

    private var selectedGroup: GroupNode? {
        store.repoTree?.groups.first { $0.id == selectedGroupId }
    }

    private var selectedFeature: FeatureNode? {
        selectedGroup?.features.first { $0.id == selectedFeatureId }
    }

    var body: some View {
        Group {
            if settings.rootRepoPath.isEmpty {
                onboardingView
            } else {
                portfolioContent
            }
        }
        .frame(minWidth: 900, minHeight: 500)
        .onAppear {
            if !settings.rootRepoPath.isEmpty {
                store.refresh(repoPath: settings.rootRepoPath)
            }
        }
        .onChange(of: settings.rootRepoPath) { _, newPath in
            if !newPath.isEmpty {
                store.refresh(repoPath: newPath)
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
            Button("Open Settings…") { openSettings() }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Portfolio

    private var portfolioContent: some View {
        NavigationSplitView {
            PortfolioSidebarView(groups: store.repoTree?.groups ?? [], selection: $selectedGroupId)
                .navigationSplitViewColumnWidth(min: 160, ideal: 220, max: 280)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        refreshButton
                    }
                    ToolbarItem(placement: .automatic) {
                        settingsButton
                    }
                }
        } content: {
            contentColumn
                .navigationSplitViewColumnWidth(min: 280, ideal: 380)
        } detail: {
            detailColumn
        }
        .navigationSplitViewStyle(.prominentDetail)
        .onChange(of: selectedGroupId) { selectedFeatureId = nil }
    }

    // MARK: - Content column (center)

    @ViewBuilder
    private var contentColumn: some View {
        if store.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let group = selectedGroup {
            if group.features.isEmpty {
                ContentUnavailableView(
                    "No features",
                    systemImage: "square.stack.3d.up.slash",
                    description: Text("No feature plans in this group yet.")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(group.features) { feature in
                            HypothesisCardView(feature: feature) {
                                selectedFeatureId = feature.id
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                    .animation(.easeOut(duration: 0.2), value: group.features.map(\.id))
                    .padding(16)
                }
            }
        } else if store.repoTree != nil {
            ContentUnavailableView(
                "Select a group",
                systemImage: "sidebar.left",
                description: Text("Choose a milestone or Discovery from the sidebar.")
            )
        } else {
            ContentUnavailableView(
                "No feature plans found",
                systemImage: "square.stack.3d.up.slash",
                description: Text("No feature plans in \(settings.rootRepoPath)/.claude/feature-plans/")
            )
        }
    }

    // MARK: - Detail column

    @ViewBuilder
    private var detailColumn: some View {
        if let feature = selectedFeature {
            FeatureDocumentsView(
                feature: feature,
                rootRepoPath: settings.rootRepoPath,
                onSave: { store.refresh(repoPath: settings.rootRepoPath) }
            )
        } else {
            ContentUnavailableView(
                "Select a feature",
                systemImage: "doc.text",
                description: Text("Choose a feature plan to view its artifacts.")
            )
        }
    }

    // MARK: - Toolbar items

    private var refreshButton: some View {
        Button {
            store.refresh(repoPath: settings.rootRepoPath)
        } label: {
            Image(systemName: "arrow.clockwise")
                .rotationEffect(.degrees(isRefreshSpinning ? 360 : 0))
                .animation(
                    isRefreshSpinning
                        ? .linear(duration: 0.6).repeatForever(autoreverses: false)
                        : .easeOut(duration: 0.3),
                    value: isRefreshSpinning
                )
                .accessibilityLabel("Refresh")
        }
        .buttonStyle(.borderless)
        .disabled(store.isLoading)
        .keyboardShortcut("r", modifiers: .command)
        .onChange(of: store.isLoading) { _, loading in
            isRefreshSpinning = loading
        }
    }

    private var settingsButton: some View {
        Button {
            openSettings()
        } label: {
            Label("Settings", systemImage: "gear")
        }
        .buttonStyle(.borderless)
    }
}
