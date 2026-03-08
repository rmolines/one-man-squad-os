import Foundation

// MARK: - HypothesisStatus

public enum HypothesisStatus: String, Sendable, CaseIterable {
    case idle
    case exploring
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

// MARK: - WorktreeInfo + HypothesisCard

extension WorktreeInfo: HypothesisCard {
    public var id: String { path }
    public var title: String { branch ?? URL(fileURLWithPath: path).lastPathComponent }
    public var status: HypothesisStatus { .idle }
    public var hasPendingBrief: Bool { false }
    public var lastArtifactDate: Date? { nil }
}
