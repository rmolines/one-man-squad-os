import SwiftUI
import SwiftData
import SettingsAccess

private enum ViewMode: String {
    case grid, kanban
}

struct PortfolioView: View {
    @Query private var settingsList: [CockpitSettings]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openSettings) private var openSettings
    @State private var store = PortfolioStore()
    @State private var isRefreshSpinning = false
    @State private var selectedHypothesis: FeaturePlanInfo? = nil
    @AppStorage("portfolioViewMode") private var viewMode: ViewMode = .grid

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
        ZStack {
            VStack(spacing: 0) {
                toolbar
                Divider()
                Group {
                    if store.isLoading {
                        ScrollView {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(40)
                        }
                    } else if store.hypotheses.isEmpty {
                        ScrollView {
                            ContentUnavailableView(
                                "No feature plans found",
                                systemImage: "square.stack.3d.up.slash",
                                description: Text("No feature plans in \(settings.rootRepoPath)/.claude/feature-plans/")
                            )
                        }
                    } else if viewMode == .kanban {
                        MilestoneKanbanView(store: store)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(store.hypotheses) { hypothesis in
                                    HypothesisCardView(hypothesis: hypothesis) {
                                        selectedHypothesis = hypothesis
                                    }
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                }
                            }
                            .animation(.easeOut(duration: 0.2), value: store.hypotheses.map(\.id))
                            .padding(16)
                        }
                    }
                }
            }

            if let hypothesis = selectedHypothesis {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture { selectedHypothesis = nil }

                FeatureDocumentsView(hypothesis: hypothesis)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 24, x: 0, y: 8)
                    .padding(40)
                    .onTapGesture {} // absorb taps so they don't reach the backdrop
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .animation(.easeOut(duration: 0.18), value: selectedHypothesis?.id)
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

            Picker("", selection: $viewMode) {
                Label("Grid", systemImage: "square.grid.2x2").tag(ViewMode.grid)
                Label("Kanban", systemImage: "rectangle.split.3x1").tag(ViewMode.kanban)
            }
            .pickerStyle(.segmented)
            .frame(width: 100)

            Button {
                openSettings()
            } label: {
                Label("Settings", systemImage: "gear")
            }
            .buttonStyle(.borderless)

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
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

}
