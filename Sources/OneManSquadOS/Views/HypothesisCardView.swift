import SwiftUI
import Core

struct HypothesisCardView: View {
    let feature: FeatureNode
    var onSelect: () -> Void = {}
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(feature.info.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                HealthBadgeView(date: feature.info.lastArtifactDate)
            }

            HStack(spacing: 6) {
                PhaseChip(phase: feature.phase)
                StatusChip(status: feature.info.status)
            }

            if !feature.gate.canAdvance {
                GateIndicatorView(gate: feature.gate)
            }

            if !feature.info.artifacts.taskItems.isEmpty {
                TaskSummaryView(tasks: feature.info.artifacts.taskItems)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHovered ? Color(nsColor: .selectedControlColor).opacity(0.12) : Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isHovered ? Color.accentColor.opacity(0.3) : Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }
}

// MARK: - PhaseChip

struct PhaseChip: View {
    let phase: Phase

    var body: some View {
        Text(phase.label)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(phase.color.opacity(0.15))
            .foregroundStyle(phase.color)
            .clipShape(Capsule())
    }
}

// MARK: - StatusChip

struct StatusChip: View {
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

// MARK: - TaskSummaryView

private struct TaskSummaryView: View {
    let tasks: [TaskItem]
    private let maxVisible = 3

    private var doneCount: Int { tasks.filter(\.completed).count }
    private var visible: [TaskItem] { Array(tasks.prefix(maxVisible)) }
    private var overflow: Int { max(0, tasks.count - maxVisible) }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "checklist")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(doneCount)/\(tasks.count) done")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            ForEach(visible) { task in
                TaskRowView(task: task)
            }
            if overflow > 0 {
                Text("+\(overflow) more")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 16)
            }
        }
        .padding(.top, 2)
    }
}

private struct TaskRowView: View {
    let task: TaskItem

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                .font(.caption2)
                .foregroundStyle(task.completed ? Color.green : Color.secondary)
            Text(task.title)
                .font(.caption2)
                .foregroundStyle(task.completed ? Color.secondary : Color.primary)
                .lineLimit(1)
                .strikethrough(task.completed, color: .secondary)
        }
    }
}
