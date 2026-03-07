import SwiftData
import Foundation

@Model
final class CockpitSettings {
    var rootRepoPath: String

    init(rootRepoPath: String = "") {
        self.rootRepoPath = rootRepoPath
    }
}
