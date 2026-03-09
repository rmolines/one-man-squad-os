import Foundation
import Observation
import Core

@Observable @MainActor
final class PortfolioStore {
    var repoTree: RepoNode?
    var isLoading: Bool = false

    private var featurePlansWatcher: RepoWatcher?
    private var worktreesWatcher: RepoWatcher?
    private var watchedPath: String = ""

    /// Refreshes the project tree and (re)starts FSEvents watchers if the path changed.
    func refresh(repoPath: String) {
        guard !repoPath.isEmpty else { return }

        if repoPath != watchedPath {
            watchedPath = repoPath
            let base = URL(fileURLWithPath: repoPath)
            let featurePlansPath = base.appendingPathComponent(".claude/feature-plans").path
            let worktreesPath = base.appendingPathComponent(".git/worktrees").path
            featurePlansWatcher = RepoWatcher(path: featurePlansPath) { [weak self] in
                Task { @MainActor [weak self] in self?.reload() }
            }
            worktreesWatcher = RepoWatcher(path: worktreesPath) { [weak self] in
                Task { @MainActor [weak self] in self?.reload() }
            }
        }

        reload()
    }

    // MARK: - Private

    private func reload() {
        isLoading = true
        let path = watchedPath
        Task { @MainActor in
            let tree = await Task.detached(priority: .userInitiated) {
                buildProjectTree(repoPath: path)
            }.value
            self.repoTree = tree
            self.isLoading = false
        }
    }
}
