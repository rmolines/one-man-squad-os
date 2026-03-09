import Foundation

// MARK: - RepoNode

/// Root of the project tree — represents the scanned git repository.
public struct RepoNode: Sendable {
    public let repoPath: String
    public var groups: [GroupNode]

    public init(repoPath: String, groups: [GroupNode]) {
        self.repoPath = repoPath
        self.groups = groups
    }
}

// MARK: - GroupNode

/// A logical grouping of features: either the "Discovery" virtual group or a named Milestone.
public struct GroupNode: Identifiable, Sendable {
    /// "discovery" for the virtual group; milestone id (e.g. "M4") for milestone groups.
    public let id: String
    public let title: String
    public let milestone: MilestoneInfo?
    public var features: [FeatureNode]

    public init(id: String, title: String, milestone: MilestoneInfo?, features: [FeatureNode]) {
        self.id = id
        self.title = title
        self.milestone = milestone
        self.features = features
    }
}

// MARK: - FeatureNode

/// A single feature hypothesis — leaf of the project tree.
public struct FeatureNode: Identifiable, Sendable {
    public let id: String           // slug
    public let info: FeaturePlanInfo
    public let phase: Phase
    public let confidenceT: CGFloat // Hill Chart position 0.0–1.0
    public let gate: Gate

    public init(id: String, info: FeaturePlanInfo, phase: Phase, confidenceT: CGFloat, gate: Gate) {
        self.id = id
        self.info = info
        self.phase = phase
        self.confidenceT = confidenceT
        self.gate = gate
    }
}
