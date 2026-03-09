import Foundation

/// Splits a markdown string into H2 (`## `) sections.
struct MarkdownH2Section: Identifiable {
    let id: String   // title as stable id
    let title: String
    let body: String
}

func parseMarkdownH2Sections(from markdown: String) -> [MarkdownH2Section] {
    var result: [MarkdownH2Section] = []
    var currentTitle: String?
    var currentLines: [String] = []

    func flush() {
        guard let title = currentTitle else { return }
        let body = currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if !body.isEmpty {
            result.append(MarkdownH2Section(id: title, title: title, body: body))
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
