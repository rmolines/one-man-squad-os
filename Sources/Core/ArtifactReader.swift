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
    /// Artifacts whose upstream dependency was modified more recently than themselves.
    /// Keys are filenames (e.g. `"research.md"`, `"plan.md"`).
    /// Computed at construction time from filesystem mtimes — no per-render I/O.
    public let outdatedArtifacts: Set<String>

    public init(
        clarifyMd: String?,
        exploreMd: String?,
        discoveryMd: String?,
        researchMd: String?,
        planMd: String?,
        sprintMd: String?,
        sbarBriefs: [String],
        outdatedArtifacts: Set<String> = []
    ) {
        self.clarifyMd = clarifyMd
        self.exploreMd = exploreMd
        self.discoveryMd = discoveryMd
        self.researchMd = researchMd
        self.planMd = planMd
        self.sprintMd = sprintMd
        self.sbarBriefs = sbarBriefs
        self.outdatedArtifacts = outdatedArtifacts
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

    // Batch-read mtimes for all md files in one syscall (avoids 5 individual resourceValues calls).
    let mtimes: [String: Date] = {
        guard let items = try? fm.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return [:] }
        var dict: [String: Date] = [:]
        for item in items where item.pathExtension == "md" {
            if let date = try? item.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
                dict[item.lastPathComponent] = date
            }
        }
        return dict
    }()

    let decisionsDir = root.appendingPathComponent("decisions")
    var briefs: [String] = []
    if let items = try? fm.contentsOfDirectory(atPath: decisionsDir.path) {
        briefs = items
            .filter { $0.hasSuffix(".md") }
            .compactMap { read("decisions/\($0)") }
    }

    // Compute outdated artifacts by comparing mtimes along the dependency chain.
    // Chain order: clarify → explore → discovery → research → plan
    // An artifact is outdated if any upstream artifact has a newer mtime.
    let chain: [(String, Date?)] = [
        ("clarify.md",   mtimes["clarify.md"]),
        ("explore.md",   mtimes["explore.md"]),
        ("discovery.md", mtimes["discovery.md"]),
        ("research.md",  mtimes["research.md"]),
        ("plan.md",      mtimes["plan.md"]),
    ]
    var outdated: Set<String> = []
    for i in 0..<chain.count {
        let (_, upDate) = chain[i]
        guard let up = upDate else { continue }
        for j in (i + 1)..<chain.count {
            let (downName, downDate) = chain[j]
            guard let down = downDate else { continue }
            if up > down { outdated.insert(downName) }
        }
    }

    return ArtifactSet(
        clarifyMd: read("clarify.md"),
        exploreMd: read("explore.md"),
        discoveryMd: read("discovery.md"),
        researchMd: read("research.md"),
        planMd: read("plan.md"),
        sprintMd: read("sprint.md"),
        sbarBriefs: briefs,
        outdatedArtifacts: outdated
    )
}
