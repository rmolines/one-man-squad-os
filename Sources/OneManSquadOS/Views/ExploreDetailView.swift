import SwiftUI
import Core

/// Schema-aware rendering of explore.md artifacts.
struct ExploreDetailView: View {
    let raw: String

    private var sections: [SectionBlock] { parseSections(from: raw) }

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

// MARK: - Helpers

private struct SectionBlock: Identifiable {
    let id: String  // title used as stable id
    let title: String
    let body: String
}

private func parseSections(from markdown: String) -> [SectionBlock] {
    var result: [SectionBlock] = []
    var currentTitle: String? = nil
    var currentLines: [String] = []

    func flush() {
        if let title = currentTitle {
            let body = currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !body.isEmpty {
                result.append(SectionBlock(id: title, title: title, body: body))
            }
        }
    }

    for line in markdown.components(separatedBy: .newlines) {
        if line.hasPrefix("## ") {
            flush()
            currentTitle = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            currentLines = []
        } else if currentTitle != nil {
            currentLines.append(line)
        }
    }
    flush()
    return result
}
