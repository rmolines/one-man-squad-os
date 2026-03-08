import Foundation
import Observation
import Core

@Observable @MainActor
final class PortfolioStore {
    var hypotheses: [WorktreeInfo] = []
    var isLoading: Bool = false
    var loadError: String? = nil

    private var watcher: RepoWatcher?
    private var watchedPath: String = ""

    /// Refreshes the worktree list and (re)starts the FSEvents watcher if the path changed.
    func refresh(repoPath: String) {
        guard !repoPath.isEmpty else { return }

        if repoPath != watchedPath {
            watchedPath = repoPath
            watcher = RepoWatcher(path: repoPath) { [weak self] in
                // Callback already arrives on main thread (scheduled on CFRunLoopGetMain).
                self?.reload()
            }
        }

        reload()
    }

    // MARK: - Private

    private func reload() {
        isLoading = true
        loadError = nil
        do {
            let all = try listWorktrees(repoPath: watchedPath)
            hypotheses = all.filter { !$0.isMain }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}
