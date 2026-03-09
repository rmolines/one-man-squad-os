import Foundation

public struct ArtifactSet: Sendable {
    public let clarifyMd: String?
    public let exploreMd: String?
    public let discoveryMd: String?
    public let researchMd: String?
    public let planMd: String?
    public let sprintMd: String?
    public let sbarBriefs: [String]
    /// Task items extracted from plan.md at construction time — no per-render parsing.
    public let taskItems: [TaskItem]
    /// Phase inferred from artifact presence at construction time — no per-render logic.
    public let inferredPhase: Phase
    /// Hill Chart position (0.0–1.0) derived from `confiança:` field or phase fallback.
    public let confidenceT: CGFloat

    public init(
        clarifyMd: String?,
        exploreMd: String?,
        discoveryMd: String?,
        researchMd: String?,
        planMd: String?,
        sprintMd: String?,
        sbarBriefs: [String]
    ) {
        self.clarifyMd = clarifyMd
        self.exploreMd = exploreMd
        self.discoveryMd = discoveryMd
        self.researchMd = researchMd
        self.planMd = planMd
        self.sprintMd = sprintMd
        self.sbarBriefs = sbarBriefs
        self.taskItems = planMd.map { parseTaskItems($0) } ?? []

        // Infer phase from artifact presence (stored to avoid recomputation)
        let phase: Phase
        if planMd != nil {
            phase = .delivery
        } else if discoveryMd != nil || researchMd != nil || sprintMd != nil {
            phase = .planning
        } else {
            phase = .discovery
        }
        self.inferredPhase = phase

        // Derive Hill Chart position — prefer confiança field from most advanced artifact
        let taskRatio: CGFloat = self.taskItems.isEmpty
            ? 0
            : CGFloat(self.taskItems.filter(\.completed).count) / CGFloat(self.taskItems.count)

        if let raw = exploreMd.flatMap({ extractConfianca(from: $0) }) {
            self.confidenceT = confidenceToT(raw)
        } else if let raw = clarifyMd.flatMap({ extractConfianca(from: $0) }) {
            self.confidenceT = confidenceToT(raw)
        } else {
            self.confidenceT = phaseToT(phase: phase, taskRatio: taskRatio)
        }
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
        clarifyMd: read("clarify.md"),
        exploreMd: read("explore.md"),
        discoveryMd: read("discovery.md"),
        researchMd: read("research.md"),
        planMd: read("plan.md"),
        sprintMd: read("sprint.md"),
        sbarBriefs: briefs
    )
}
