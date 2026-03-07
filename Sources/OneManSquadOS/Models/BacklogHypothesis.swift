import SwiftData
import Foundation

@Model
final class BacklogHypothesis {
    var worktreePath: String
    var branch: String
    var rawStatus: String
    var hasPendingBrief: Bool
    var lastArtifactDate: Date?
    var createdAt: Date

    init(worktreePath: String, branch: String) {
        self.worktreePath = worktreePath
        self.branch = branch
        self.rawStatus = "idle"
        self.hasPendingBrief = false
        self.lastArtifactDate = nil
        self.createdAt = Date()
    }
}
