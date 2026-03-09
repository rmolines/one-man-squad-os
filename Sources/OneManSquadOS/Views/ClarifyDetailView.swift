import SwiftUI
import Core

/// Schema-aware rendering of clarify.md artifacts.
/// Extracts structured sections instead of rendering raw markdown.
struct ClarifyDetailView: View {
    let raw: String

    private let sections: [MarkdownH2Section]

    init(raw: String) {
        self.raw = raw
        self.sections = parseMarkdownH2Sections(from: raw)
    }

    private func body(for title: String) -> String? {
        let v = sections.first(where: { $0.title == title })?.body
        return v?.isEmpty == false ? v : nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Tension headline — primary signal
                if let tension = body(for: "Tensão cristalizada") {
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
                let knownOrder = ["Tensão cristalizada", "Sinal bruto", "Tensões identificadas",
                                  "Próxima ação", "Handoff"]
                ForEach(knownOrder.filter { $0 != "Tensão cristalizada" }, id: \.self) { name in
                    if let sectionBody = body(for: name) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            MarkdownView(text: sectionBody)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}
