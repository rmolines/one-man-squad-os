import SwiftUI
import Core

struct HypothesisCardView: View {
    let hypothesis: WorktreeInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(hypothesis.title)
                .font(.headline)
                .lineLimit(1)

            Text(hypothesis.path)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack {
                StatusChip(status: hypothesis.status)
                Spacer()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }
}

private struct StatusChip: View {
    let status: HypothesisStatus

    var body: some View {
        Text(status.label)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.15))
            .foregroundStyle(status.color)
            .clipShape(Capsule())
    }
}

private extension HypothesisStatus {
    var label: String {
        switch self {
        case .idle:            return "Idle"
        case .exploring:       return "Exploring"
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
        case .building:        return .orange
        case .validating:      return .purple
        case .pendingDecision: return .red
        case .killed:          return Color(nsColor: .disabledControlTextColor)
        }
    }
}
