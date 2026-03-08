import Foundation

// MARK: - HypothesisStatus

public enum HypothesisStatus: String, Sendable, CaseIterable {
    case idle
    case exploring
    case discovered
    case building
    case validating
    case pendingDecision
    case killed
}

// MARK: - HypothesisCard

public protocol HypothesisCard: Identifiable, Sendable {
    var id: String { get }           // worktree path
    var title: String { get }        // branch name
    var status: HypothesisStatus { get }
    var hasPendingBrief: Bool { get }
    var lastArtifactDate: Date? { get }
}

// MARK: - FeaturePlanInfo

public struct FeaturePlanInfo: Sendable {
    public let slug: String
    public let featurePlansPath: String
    public let attachedWorktree: WorktreeInfo?

    public init(slug: String, featurePlansPath: String, attachedWorktree: WorktreeInfo?) {
        self.slug = slug
        self.featurePlansPath = featurePlansPath
        self.attachedWorktree = attachedWorktree
    }
}

extension FeaturePlanInfo: HypothesisCard {
    public var id: String { slug }
    public var title: String { slug }
    public var status: HypothesisStatus { readArtifacts(featurePlansPath: featurePlansPath).inferredStatus }

    public var hasPendingBrief: Bool {
        readArtifacts(featurePlansPath: featurePlansPath)
            .sbarBriefs.contains { parseSBAR(from: $0) != nil }
    }

    public var lastArtifactDate: Date? {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(
            at: URL(fileURLWithPath: featurePlansPath),
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return nil }
        return items
            .filter { $0.pathExtension == "md" }
            .compactMap { try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate }
            .max()
    }
}

// MARK: - WorktreeInfo + HypothesisCard

extension WorktreeInfo: HypothesisCard {
    public var id: String { path }
    public var title: String { branch ?? URL(fileURLWithPath: path).lastPathComponent }
    public var status: HypothesisStatus { readArtifacts(worktreePath: path).inferredStatus }

    public var hasPendingBrief: Bool {
        let artifacts = readArtifacts(worktreePath: path)
        return artifacts.sbarBriefs.contains { parseSBAR(from: $0) != nil }
    }

    public var lastArtifactDate: Date? {
        let decisionsURL = URL(fileURLWithPath: path).appendingPathComponent(".claude/decisions")
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(
            at: decisionsURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return nil }
        return items
            .filter { $0.pathExtension == "md" }
            .compactMap { try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate }
            .max()
    }
}
