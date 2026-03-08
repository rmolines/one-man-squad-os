import Foundation
import Observation
import Core

@Observable @MainActor
final class PortfolioStore {
    var hypotheses: [FeaturePlanInfo] = []
    var isLoading: Bool = false

    private var featurePlansWatcher: RepoWatcher?
    private var worktreesWatcher: RepoWatcher?
    private var watchedPath: String = ""

    /// Refreshes the feature-plan list and (re)starts the FSEvents watchers if the path changed.
    func refresh(repoPath: String) {
        guard !repoPath.isEmpty else { return }

        if repoPath != watchedPath {
            watchedPath = repoPath
            let featurePlansPath = repoPath + "/.claude/feature-plans"
            let worktreesPath = repoPath + "/.git/worktrees"
            featurePlansWatcher = RepoWatcher(path: featurePlansPath) { [weak self] in
                self?.reload()
            }
            worktreesWatcher = RepoWatcher(path: worktreesPath) { [weak self] in
                self?.reload()
            }
        }

        reload()
    }

    // MARK: - Private

    private func reload() {
        isLoading = true
        hypotheses = listFeaturePlans(repoPath: watchedPath)
        isLoading = false
    }
}
