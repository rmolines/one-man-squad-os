import SwiftUI
import Core

/// Schema-aware rendering of clarify.md artifacts.
/// Extracts structured sections instead of rendering raw markdown.
struct ClarifyDetailView: View {
    let raw: String

    private var sections: ParsedSections { ParsedSections(markdown: raw) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Tension headline — primary signal
                if let tension = sections["Tensão cristalizada"] {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tensão cristalizada")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(tension)
                            .font(.title3)
                            .fontWeight(.medium)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Remaining sections as markdown
                let remaining = ParsedSections.remainingSectionNames.filter { $0 != "Tensão cristalizada" }
                ForEach(remaining, id: \.self) { name in
                    if let body = sections[name] {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            MarkdownView(text: body)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Section parser

/// Splits a markdown document into H2 sections.
private struct ParsedSections {
    private let map: [String: String]

    static let remainingSectionNames: [String] = [
        "Tensão cristalizada", "Sinal bruto", "Tensões identificadas",
        "Próxima ação", "Handoff"
    ]

    init(markdown: String) {
        var result: [String: String] = [:]
        var currentTitle: String? = nil
        var currentLines: [String] = []

        func flush() {
            if let title = currentTitle {
                result[title] = currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
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
        self.map = result
    }

    subscript(name: String) -> String? {
        let v = map[name]
        return v?.isEmpty == false ? v : nil
    }
}
