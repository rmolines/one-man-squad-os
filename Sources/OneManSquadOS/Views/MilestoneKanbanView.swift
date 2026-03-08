import SwiftUI
import Core

struct MilestoneKanbanView: View {
    let store: PortfolioStore

    // Columns skip .idle — features without any artifact don't appear in active kanban view.
    private let columns: [HypothesisStatus] = [
        .exploring, .discovered, .building, .validating, .pendingDecision, .killed
    ]

    // Computed var (not let) so @Observable tracking in body sees store.milestones / store.hypotheses
    // and re-renders when PortfolioStore reloads after FSEvents. buildRows is pure in-memory — no disk I/O.
    private var rows: [KanbanRow] {
        Self.buildRows(milestones: store.milestones, hypotheses: store.hypotheses)
    }

    var body: some View {
        ScrollView([.vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                Divider()
                ForEach(rows) { row in
                    MilestoneRowView(row: row, columns: columns)
                    Divider()
                }
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("Milestone")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 180, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            ForEach(columns, id: \.self) { status in
                Text(status.label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(status.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Data builder

    private static func buildRows(
        milestones: [MilestoneInfo],
        hypotheses: [FeaturePlanInfo]
    ) -> [KanbanRow] {
        let hypothesisBySlug: [String: FeaturePlanInfo] = Dictionary(
            uniqueKeysWithValues: hypotheses.map { ($0.slug, $0) }
        )

        var assignedSlugs: Set<String> = []

        var rows: [KanbanRow] = milestones.map { milestone in
            let features = milestone.featureSlugs.compactMap { slug -> FeaturePlanInfo? in
                guard let info = hypothesisBySlug[slug] else { return nil }
                assignedSlugs.insert(slug)
                return info
            }
            return KanbanRow(id: milestone.id, title: milestone.title, features: features)
        }

        // Features not assigned to any milestone go to an "Others" section.
        let unassigned = hypotheses.filter { !assignedSlugs.contains($0.slug) }
        if !unassigned.isEmpty {
            rows.append(KanbanRow(id: "__others__", title: "Outros", features: unassigned))
        }

        return rows
    }
}

// MARK: - Row

private struct KanbanRow: Identifiable {
    let id: String
    let title: String
    let features: [FeaturePlanInfo]
}

private struct MilestoneRowView: View {
    let row: KanbanRow
    let columns: [HypothesisStatus]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(row.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(width: 180, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

            ForEach(columns, id: \.self) { status in
                let cards = row.features.filter { $0.status == status }
                KanbanColumnCell(cards: cards)
            }
        }
        .frame(minHeight: 48)
    }
}

// MARK: - Cell

private struct KanbanColumnCell: View {
    let cards: [FeaturePlanInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(cards, id: \.slug) { card in
                KanbanFeatureChip(feature: card)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}

// MARK: - Chip

private struct KanbanFeatureChip: View {
    let feature: FeaturePlanInfo
    @State private var isHovered = false

    var body: some View {
        Text(feature.title)
            .font(.caption2)
            .lineLimit(2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isHovered
                    ? feature.status.color.opacity(0.18)
                    : feature.status.color.opacity(0.08)
            )
            .foregroundStyle(feature.status.color)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(feature.status.color.opacity(isHovered ? 0.4 : 0.2), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.12), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

