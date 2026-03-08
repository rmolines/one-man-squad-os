import Foundation

// MARK: - MilestoneInfo

public struct MilestoneInfo: Sendable, Identifiable {
    public let id: String           // e.g. "M4"
    public let title: String        // from sprint.md first # heading
    public let featureSlugs: [String]
    public let sprintMd: String?

    public init(id: String, title: String, featureSlugs: [String], sprintMd: String?) {
        self.id = id
        self.title = title
        self.featureSlugs = featureSlugs
        self.sprintMd = sprintMd
    }
}

// MARK: - Scanner

/// Lists milestone directories (M1, M2, …) from `.claude/feature-plans/` and parses
/// each sprint.md to extract the feature slugs belonging to that milestone.
public func listMilestones(repoPath: String) -> [MilestoneInfo] {
    let featurePlansRoot = URL(fileURLWithPath: repoPath)
        .appendingPathComponent(".claude/feature-plans")
    let fm = FileManager.default

    guard let entries = try? fm.contentsOfDirectory(atPath: featurePlansRoot.path) else {
        return []
    }

    return entries
        .filter { isMilestoneDir($0) }
        .compactMap { id -> MilestoneInfo? in
            let dir = featurePlansRoot.appendingPathComponent(id)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue else {
                return nil
            }
            let sprintMd = try? String(contentsOf: dir.appendingPathComponent("sprint.md"), encoding: .utf8)
            let title = sprintMd.flatMap(parseSprintTitle) ?? id
            let slugs = sprintMd.map(parseFeatureSlugs) ?? []
            return MilestoneInfo(id: id, title: title, featureSlugs: slugs, sprintMd: sprintMd)
        }
        .sorted { $0.id < $1.id }
}

// MARK: - Parsing helpers

/// Extracts the milestone title from the first `# ` heading in sprint.md.
/// Example: "# Sprint M4 — Interface hierárquica" → "Sprint M4 — Interface hierárquica"
private func parseSprintTitle(from content: String) -> String? {
    for line in content.split(separator: "\n", omittingEmptySubsequences: false) {
        let s = String(line)
        if s.hasPrefix("# ") {
            return String(s.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        }
    }
    return nil
}

/// Extracts feature slugs from the sprint.md feature table.
///
/// Expected column layout: `| # | Feature | Slug | Deps | Esforço | Status |`
/// Slug column (index 2) contains backtick-quoted values like `` `my-feature` ``.
private func parseFeatureSlugs(from content: String) -> [String] {
    var slugs: [String] = []
    var inTable = false

    for line in content.split(separator: "\n", omittingEmptySubsequences: false) {
        let s = String(line).trimmingCharacters(in: .whitespaces)
        guard s.hasPrefix("|") else {
            if inTable { break }
            continue
        }
        inTable = true
        // Skip header separator rows (e.g. "|---|---|")
        if s.replacingOccurrences(of: "|", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "").isEmpty {
            continue
        }
        let columns = s.split(separator: "|", omittingEmptySubsequences: false).map { String($0).trimmingCharacters(in: .whitespaces) }
        // columns[0] is empty (before first |), columns[1] = #, columns[2] = Feature, columns[3] = Slug
        guard columns.count > 3 else { continue }
        let slugColumn = columns[3]
        // Extract value from backticks: `slug-name`
        if slugColumn.hasPrefix("`") && slugColumn.hasSuffix("`") && slugColumn.count > 2 {
            let slug = String(slugColumn.dropFirst().dropLast())
            if !slug.isEmpty {
                slugs.append(slug)
            }
        }
    }
    return slugs
}
