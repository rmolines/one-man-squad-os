import SwiftData
import Foundation

@Model
final class BacklogHypothesis {
    @Attribute(.unique) var slug: String
    var worktreePath: String?
    var branch: String?
    var rawStatus: String
    var hasPendingBrief: Bool
    var lastArtifactDate: Date?
    var createdAt: Date

    init(slug: String) {
        self.slug = slug
        self.worktreePath = nil
        self.branch = nil
        self.rawStatus = "idle"
        self.hasPendingBrief = false
        self.lastArtifactDate = nil
        self.createdAt = Date()
    }
}
