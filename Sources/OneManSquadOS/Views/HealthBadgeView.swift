import SwiftUI

struct HealthBadgeView: View {
    let date: Date?

    private var staleness: Staleness {
        guard let date else { return .unknown }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days < 3 { return .fresh }
        if days < 14 { return .aging }
        return .stale
    }

    private var relativeLabel: String {
        guard let date else { return "no artifacts" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(staleness.color)
                .frame(width: 6, height: 6)
            Text(relativeLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private enum Staleness {
        case fresh, aging, stale, unknown
        var color: Color {
            switch self {
            case .fresh:   return .green
            case .aging:   return .yellow
            case .stale:   return .red
            case .unknown: return .secondary
            }
        }
    }
}
