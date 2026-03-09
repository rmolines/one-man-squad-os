import Foundation

/// What's needed before a feature can advance to its next phase.
public struct Gate: Sendable {
    /// Artifact names missing before the feature can advance.
    public let missing: [String]
    /// The phase this feature would advance to (nil if already in delivery).
    public let nextPhase: Phase?
    public var canAdvance: Bool { missing.isEmpty }

    public init(missing: [String], nextPhase: Phase?) {
        self.missing = missing
        self.nextPhase = nextPhase
    }
}

/// Evaluates what's blocking a feature from advancing to the next phase.
/// Pure function — no I/O. All data comes from the already-loaded FeaturePlanInfo.
public func evaluateGate(for info: FeaturePlanInfo, phase: Phase) -> Gate {
    switch phase {
    case .discovery:
        var missing: [String] = []
        if info.artifacts.clarifyMd == nil { missing.append("clarify.md") }
        if info.artifacts.exploreMd == nil { missing.append("explore.md") }
        return Gate(missing: missing, nextPhase: .planning)

    case .planning:
        var missing: [String] = []
        if info.artifacts.discoveryMd == nil { missing.append("discovery.md") }
        if info.artifacts.planMd == nil { missing.append("plan.md") }
        return Gate(missing: missing, nextPhase: .delivery)

    case .delivery:
        return Gate(missing: [], nextPhase: nil)
    }
}
