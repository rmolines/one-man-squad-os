import Foundation

// MarkdownRenderer — line-level parsing of markdown artifacts.
// Exposes `parseMarkdown(_:)` for use by SwiftUI views in the App target.
// `stripFrontmatter` is defined in SBARParser.swift (public) and used here.

// MARK: - Block types

public enum MarkdownBlock: Sendable, Hashable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case bulletItem(String)
    case codeBlock(lines: [String], language: String?)
    case divider
    case empty
}

// MARK: - Parser

/// Parses a raw markdown string (may have frontmatter) into an ordered list of blocks.
public func parseMarkdown(_ raw: String) -> [MarkdownBlock] {
    let body = stripFrontmatter(raw)
    let lines = body.components(separatedBy: "\n")
    var blocks: [MarkdownBlock] = []
    var codeLines: [String] = []
    var codeLang: String? = nil
    var inCode = false

    for line in lines {
        // Code block fence
        if line.hasPrefix("```") {
            if inCode {
                blocks.append(.codeBlock(lines: codeLines, language: codeLang))
                codeLines = []
                codeLang = nil
                inCode = false
            } else {
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                codeLang = lang.isEmpty ? nil : lang
                inCode = true
            }
            continue
        }

        if inCode {
            codeLines.append(line)
            continue
        }

        // Headings
        if line.hasPrefix("### ") {
            blocks.append(.heading(level: 3, text: String(line.dropFirst(4))))
        } else if line.hasPrefix("## ") {
            blocks.append(.heading(level: 2, text: String(line.dropFirst(3))))
        } else if line.hasPrefix("# ") {
            blocks.append(.heading(level: 1, text: String(line.dropFirst(2))))
        // Bullet list
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            blocks.append(.bulletItem(String(line.dropFirst(2))))
        // Divider
        } else if line.trimmingCharacters(in: .whitespaces) == "---" {
            blocks.append(.divider)
        // Empty line
        } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
            blocks.append(.empty)
        // Paragraph
        } else {
            blocks.append(.paragraph(line))
        }
    }

    // Unclosed code block
    if inCode && !codeLines.isEmpty {
        blocks.append(.codeBlock(lines: codeLines, language: codeLang))
    }

    return blocks
}

// MARK: - Task items

public struct TaskItem: Sendable, Identifiable {
    public let id: Int
    public let title: String
    public let completed: Bool

    public init(id: Int, title: String, completed: Bool) {
        self.id = id
        self.title = title
        self.completed = completed
    }
}

/// Extracts checkbox task items (`- [ ]` / `- [x]`) from a raw markdown string.
public func parseTaskItems(_ raw: String) -> [TaskItem] {
    let body = stripFrontmatter(raw)
    var items: [TaskItem] = []
    var index = 0
    for line in body.components(separatedBy: "\n") {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
            items.append(TaskItem(id: index, title: String(trimmed.dropFirst(6)), completed: true))
            index += 1
        } else if trimmed.hasPrefix("- [ ] ") {
            items.append(TaskItem(id: index, title: String(trimmed.dropFirst(6)), completed: false))
            index += 1
        }
    }
    return items
}
