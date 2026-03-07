import Foundation

public enum HypothesisStatus: String, Sendable, CaseIterable {
    case idle
    case exploring
    case building
    case validating
    case pendingDecision
    case killed
}

public protocol HypothesisCard: Identifiable, Sendable {
    var id: String { get }           // worktree path
    var title: String { get }        // branch name
    var status: HypothesisStatus { get }
    var hasPendingBrief: Bool { get }
    var lastArtifactDate: Date? { get }
}
