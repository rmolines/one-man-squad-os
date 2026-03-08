import Foundation
import Observation
import Core

@Observable @MainActor
final class PortfolioStore {
    var hypotheses: [WorktreeInfo] = []
    var isLoading: Bool = false
    var loadError: String? = nil

    func refresh(repoPath: String) {
        guard !repoPath.isEmpty else { return }
        isLoading = true
        loadError = nil
        do {
            let all = try listWorktrees(repoPath: repoPath)
            hypotheses = all.filter { !$0.isMain }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}
