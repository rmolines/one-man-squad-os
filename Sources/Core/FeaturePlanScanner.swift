import Foundation

/// Indexes .claude/feature-plans/<slug>/ as source of truth for hypotheses.
/// Attaches worktrees as execution context via naming convention.
public func listFeaturePlans(repoPath: String) -> [FeaturePlanInfo] {
    let featurePlansRoot = URL(fileURLWithPath: repoPath)
        .appendingPathComponent(".claude/feature-plans")
    let fm = FileManager.default

    guard let slugs = try? fm.contentsOfDirectory(atPath: featurePlansRoot.path) else {
        return []
    }

    // Worktrees for JOIN — failures silently produce empty list (git not found, etc.)
    let worktrees = (try? listWorktrees(repoPath: repoPath)) ?? []

    let plans: [FeaturePlanInfo] = slugs
        .filter { !$0.hasPrefix(".") }
        .compactMap { slug -> FeaturePlanInfo? in
            let planPath = featurePlansRoot.appendingPathComponent(slug)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: planPath.path, isDirectory: &isDir), isDir.boolValue else {
                return nil
            }
            // JOIN: worktree path ends with "/<slug>" or branch is "feat/<slug>" or "worktree-<slug>"
            let attached = worktrees.first {
                $0.path.hasSuffix("/\(slug)")
                    || $0.branch == "feat/\(slug)"
                    || $0.branch == "worktree-\(slug)"
            }
            return FeaturePlanInfo(slug: slug, featurePlansPath: planPath.path, attachedWorktree: attached)
        }

    // Sort: pendingDecision first, then building, then by lastArtifactDate desc
    return plans.sorted { a, b in
        let statusOrder: (HypothesisStatus) -> Int = {
            switch $0 {
            case .pendingDecision: return 0
            case .building: return 1
            case .discovered: return 2
            case .exploring: return 3
            case .validating: return 4
            case .idle: return 5
            case .killed: return 6
            }
        }
        let ao = statusOrder(a.status), bo = statusOrder(b.status)
        if ao != bo { return ao < bo }
        switch (a.lastArtifactDate, b.lastArtifactDate) {
        case (let ad?, let bd?): return ad > bd
        case (.some, .none): return true
        case (.none, .some): return false
        case (.none, .none): return a.slug < b.slug
        }
    }
}
