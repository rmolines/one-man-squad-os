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
    /// Eagerly loaded at scan time — never triggers disk I/O after construction.
    public let artifacts: ArtifactSet
    public let lastArtifactDate: Date?

    public init(
        slug: String,
        featurePlansPath: String,
        attachedWorktree: WorktreeInfo?,
        artifacts: ArtifactSet,
        lastArtifactDate: Date?
    ) {
        self.slug = slug
        self.featurePlansPath = featurePlansPath
        self.attachedWorktree = attachedWorktree
        self.artifacts = artifacts
        self.lastArtifactDate = lastArtifactDate
    }
}

extension FeaturePlanInfo: HypothesisCard {
    public var id: String { slug }
    public var title: String {
        slug.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }
    public var status: HypothesisStatus { artifacts.inferredStatus }

    public var hasPendingBrief: Bool {
        artifacts.sbarBriefs.contains { parseSBAR(from: $0) != nil }
    }
}

