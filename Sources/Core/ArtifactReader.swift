import Foundation

public struct ArtifactSet: Sendable {
    public let exploreMd: String?
    public let planMd: String?
    public let sprintMd: String?
    public let sbarBriefs: [String]

    public init(exploreMd: String?, planMd: String?, sprintMd: String?, sbarBriefs: [String]) {
        self.exploreMd = exploreMd
        self.planMd = planMd
        self.sprintMd = sprintMd
        self.sbarBriefs = sbarBriefs
    }
}

public func readArtifacts(worktreePath: String) -> ArtifactSet {
    let claudeDir = URL(fileURLWithPath: worktreePath).appendingPathComponent(".claude")
    let fm = FileManager.default

    func read(_ name: String) -> String? {
        let url = claudeDir.appendingPathComponent(name)
        return try? String(contentsOf: url, encoding: .utf8)
    }

    let decisionsDir = claudeDir.appendingPathComponent("decisions")
    var briefs: [String] = []
    if let items = try? fm.contentsOfDirectory(atPath: decisionsDir.path) {
        briefs = items
            .filter { $0.hasSuffix(".md") }
            .compactMap { read("decisions/\($0)") }
    }

    return ArtifactSet(
        exploreMd: read("explore.md"),
        planMd: read("plan.md"),
        sprintMd: read("sprint.md"),
        sbarBriefs: briefs
    )
}
