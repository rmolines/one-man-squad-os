import SwiftUI
import Core

/// Schema-aware rendering of explore.md artifacts.
struct ExploreDetailView: View {
    let raw: String

    private let sections: [MarkdownH2Section]

    init(raw: String) {
        self.raw = raw
        self.sections = parseMarkdownH2Sections(from: raw)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hypothesis headline — primary signal
                if let hypothesis = sections.first(where: { $0.title == "Hipótese" }) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hipótese")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        MarkdownView(text: hypothesis.body)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Remaining sections
                ForEach(sections.filter { $0.title != "Hipótese" }) { section in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        MarkdownView(text: section.body)
                    }
                }
            }
            .padding(16)
        }
    }
}
