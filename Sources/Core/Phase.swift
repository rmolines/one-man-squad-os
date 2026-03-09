import Foundation

/// Represents where in the cognitive process a feature idea currently sits.
/// Orthogonal to `HypothesisStatus` (which encodes urgency/attention).
public enum Phase: String, Sendable, CaseIterable {
    /// Only clarify.md / explore.md present — still figuring out the problem.
    case discovery
    /// discovery.md, research.md, or sprint.md present — committed to build, planning HOW.
    case planning
    /// plan.md present — actively building.
    case delivery
}
