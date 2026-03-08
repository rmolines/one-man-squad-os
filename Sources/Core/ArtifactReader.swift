import Foundation

public struct ArtifactSet: Sendable {
    public let exploreMd: String?
    public let discoveryMd: String?
    public let researchMd: String?
    public let planMd: String?
    public let sprintMd: String?
    public let sbarBriefs: [String]
    /// Task items extracted from plan.md at construction time — no per-render parsing.
    public let taskItems: [TaskItem]

    public init(
        exploreMd: String?,
        discoveryMd: String?,
        researchMd: String?,
        planMd: String?,
        sprintMd: String?,
        sbarBriefs: [String]
    ) {
        self.exploreMd = exploreMd
        self.discoveryMd = discoveryMd
        self.researchMd = researchMd
        self.planMd = planMd
        self.sprintMd = sprintMd
        self.sbarBriefs = sbarBriefs
        self.taskItems = planMd.map { parseTaskItems($0) } ?? []
    }

    /// Priority: pendingDecision > building > discovered > exploring > idle
    public var inferredStatus: HypothesisStatus {
        if sbarBriefs.contains(where: { parseSBAR(from: $0) != nil }) { return .pendingDecision }
        if sprintMd != nil || planMd != nil { return .building }
        if discoveryMd != nil || researchMd != nil { return .discovered }
        if exploreMd != nil { return .exploring }
        return .idle
    }
}

/// Reads artifacts from .claude/feature-plans/<slug>/ in the main repo.
public func readArtifacts(featurePlansPath: String) -> ArtifactSet {
    let root = URL(fileURLWithPath: featurePlansPath)
    let fm = FileManager.default

    func read(_ name: String) -> String? {
        try? String(contentsOf: root.appendingPathComponent(name), encoding: .utf8)
    }

    let decisionsDir = root.appendingPathComponent("decisions")
    var briefs: [String] = []
    if let items = try? fm.contentsOfDirectory(atPath: decisionsDir.path) {
        briefs = items
            .filter { $0.hasSuffix(".md") }
            .compactMap { read("decisions/\($0)") }
    }

    return ArtifactSet(
        exploreMd: read("explore.md"),
        discoveryMd: read("discovery.md"),
        researchMd: read("research.md"),
        planMd: read("plan.md"),
        sprintMd: read("sprint.md"),
        sbarBriefs: briefs
    )
}
