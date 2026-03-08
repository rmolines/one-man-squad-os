import Foundation

public struct SBARBrief: Sendable {
    public let situation: String
    public let background: String
    public let assessment: String
    public let recommendation: String

    public init(situation: String, background: String, assessment: String, recommendation: String) {
        self.situation = situation
        self.background = background
        self.assessment = assessment
        self.recommendation = recommendation
    }
}

/// Parses SBAR sections from markdown using regex.
/// Sections must be H2: ## Situation, ## Background, ## Assessment, ## Recommendation
public func parseSBAR(from markdown: String) -> SBARBrief? {
    let body = stripFrontmatter(markdown)
    let pattern = #"(?m)^## (.+?)\n([\s\S]+?)(?=^## |\z)"#

    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
        return nil
    }

    let range = NSRange(body.startIndex..., in: body)
    let matches = regex.matches(in: body, range: range)

    var sections: [String: String] = [:]
    for match in matches {
        if let titleRange = Range(match.range(at: 1), in: body),
           let contentRange = Range(match.range(at: 2), in: body) {
            let title = String(body[titleRange]).trimmingCharacters(in: .whitespaces)
            let content = String(body[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            sections[title] = content
        }
    }

    guard let situation = sections["Situation"],
          let background = sections["Background"],
          let assessment = sections["Assessment"],
          let recommendation = sections["Recommendation"] else {
        return nil
    }

    return SBARBrief(
        situation: situation,
        background: background,
        assessment: assessment,
        recommendation: recommendation
    )
}

public func stripFrontmatter(_ markdown: String) -> String {
    guard markdown.hasPrefix("---") else { return markdown }
    let lines = markdown.components(separatedBy: "\n")
    var closingIndex: Int?
    for (i, line) in lines.enumerated().dropFirst() {
        if line.trimmingCharacters(in: .whitespaces) == "---" {
            closingIndex = i
            break
        }
    }
    guard let idx = closingIndex else { return markdown }
    return lines.dropFirst(idx + 1).joined(separator: "\n")
}
