import Foundation

/// Extracts the `confiança:` field from a markdown body (line scan — not YAML frontmatter).
/// The field appears as a bare line: `confiança: cristalizada`
public func extractConfianca(from markdown: String) -> String? {
    for line in markdown.components(separatedBy: .newlines) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("confiança:") {
            return String(trimmed.dropFirst("confiança:".count))
                .trimmingCharacters(in: .whitespaces)
        }
    }
    return nil
}

/// Maps a `confiança` string value to a Hill Chart t parameter (0.0 = far left, 1.0 = far right).
/// Values left of 0.5 are on the upslope (figuring it out); right of 0.5 are on the downslope (making it happen).
public func confidenceToT(_ value: String) -> CGFloat {
    switch value.lowercased() {
    case "draft":          return 0.05
    case "emergente":      return 0.25
    case "validated":      return 0.50
    case "cristalizada":   return 0.70
    case "comprehensive":  return 0.85
    default:               return 0.05
    }
}

/// Derives a Hill Chart t from phase + task completion ratio when no `confiança` field is present.
public func phaseToT(phase: Phase, taskRatio: CGFloat) -> CGFloat {
    switch phase {
    case .discovery: return 0.15
    case .planning:  return 0.55
    case .delivery:  return 0.75 + taskRatio * 0.20
    }
}
