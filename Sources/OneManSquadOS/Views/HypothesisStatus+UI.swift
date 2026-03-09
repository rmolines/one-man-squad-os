import SwiftUI
import Core

// MARK: - Phase UI

extension Phase {
    var label: String {
        switch self {
        case .discovery: return "Discovery"
        case .planning:  return "Planning"
        case .delivery:  return "Delivery"
        }
    }

    var color: Color {
        switch self {
        case .discovery: return .blue
        case .planning:  return .orange
        case .delivery:  return .green
        }
    }
}

// MARK: - HypothesisStatus UI

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
