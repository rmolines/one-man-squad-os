import SwiftUI
import Core

struct SBARDetailView: View {
    let brief: SBARBrief

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SBARSection(title: "Situation", content: brief.situation)
                SBARSection(title: "Background", content: brief.background)
                SBARSection(title: "Assessment", content: brief.assessment)
                SBARSection(title: "Recommendation", content: brief.recommendation, isHighlighted: true)
            }
            .padding(16)
        }
        .frame(minWidth: 380, maxWidth: 380, minHeight: 200, maxHeight: 560)
    }
}

private struct SBARSection: View {
    let title: String
    let content: String
    var isHighlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(isHighlighted ? Color.accentColor : .primary)

            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHighlighted ? Color.accentColor.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isHighlighted ? Color.accentColor.opacity(0.3) : Color(nsColor: .separatorColor),
                    lineWidth: 1
                )
        )
    }
}
