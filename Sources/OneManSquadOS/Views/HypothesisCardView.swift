import SwiftUI
import Core

struct HypothesisCardView: View {
    let hypothesis: FeaturePlanInfo
    var onSelect: () -> Void = {}
    @State private var showingDetail = false
    @State private var isHovered = false

    private var pendingBrief: SBARBrief? {
        hypothesis.artifacts.sbarBriefs.compactMap { parseSBAR(from: $0) }.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(hypothesis.title)
                .font(.headline)
                .lineLimit(1)

            Text(hypothesis.featurePlansPath)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack {
                StatusChip(status: hypothesis.status)
                Spacer()
                if let brief = pendingBrief {
                    PendingBriefBadge(showingDetail: $showingDetail, brief: brief)
                }
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

private struct PendingBriefBadge: View {
    @Binding var showingDetail: Bool
    let brief: SBARBrief

    var body: some View {
        Button {
            showingDetail.toggle()
        } label: {
            Label("Brief", systemImage: "exclamationmark.circle.fill")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.red)
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.plain)
        .help("Pending decision brief — click to read")
        .popover(isPresented: $showingDetail, arrowEdge: .bottom) {
            SBARDetailView(brief: brief)
        }
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

