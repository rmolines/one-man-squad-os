import SwiftUI
import Core

extension HypothesisStatus {
    var label: String {
        switch self {
        case .idle:            return "Idle"
        case .exploring:       return "Exploring"
        case .discovered:      return "Discovered"
        case .building:        return "Building"
        case .validating:      return "Validating"
        case .pendingDecision: return "Decision"
        case .killed:          return "Killed"
        }
    }

    var color: Color {
        switch self {
        case .idle:            return .secondary
        case .exploring:       return .blue
        case .discovered:      return .teal
        case .building:        return .orange
        case .validating:      return .purple
        case .pendingDecision: return .red
        case .killed:          return Color(nsColor: .disabledControlTextColor)
        }
    }
}
