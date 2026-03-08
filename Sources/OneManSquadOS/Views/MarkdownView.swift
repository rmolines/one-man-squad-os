import SwiftUI
import Core

/// Renders a raw markdown string (with optional YAML frontmatter) as styled SwiftUI content.
/// Supports: H1–H3 headings, paragraphs (with inline markdown), bullet lists,
/// fenced code blocks, horizontal dividers, and empty lines.
///
/// Usage:
/// ```swift
/// MarkdownView(text: hypothesis.artifacts.planMd ?? "")
/// ```
struct MarkdownView: View {
    let text: String
    private let blocks: [MarkdownBlock]

    init(text: String) {
        self.text = text
        self.blocks = parseMarkdown(text)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(blocks, id: \.self) { block in
                    blockView(for: block)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            MarkdownHeadingView(level: level, text: text)
                .padding(.top, level == 1 ? 12 : 8)
                .padding(.bottom, 4)

        case .paragraph(let text):
            Text(.init(text))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)

        case .bulletItem(let text):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("•")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Text(.init(text))
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 1)

        case .codeBlock(let lines, let language):
            MarkdownCodeBlockView(lines: lines, language: language)
                .padding(.vertical, 6)

        case .divider:
            Divider()
                .padding(.vertical, 8)

        case .empty:
            Spacer()
                .frame(height: 6)
        }
    }
}

// MARK: - Subviews

private struct MarkdownHeadingView: View {
    let level: Int
    let text: String

    var body: some View {
        Text(text)
            .font(font)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var font: Font {
        switch level {
        case 1: return .title2
        case 2: return .title3
        default: return .headline
        }
    }
}

private struct MarkdownCodeBlockView: View {
    let lines: [String]
    let language: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(lines.joined(separator: "\n"))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .textBackgroundColor).opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Preview

#Preview("plan.md") {
    MarkdownView(text: """
    ---
    feature: markdown-renderer
    status: building
    ---

    # Plan: markdown-renderer

    ## Problema

    O app não tem componente de renderização de markdown.

    ## Deliverables

    ### Deliverable 1 — MarkdownView completo

    Renderiza **headings**, _itálico_, `inline code`, listas e blocos de código.

    - Item um
    - Item dois com **negrito**
    - Item três

    ```swift
    struct MarkdownView: View {
        let text: String
        var body: some View { Text(text) }
    }
    ```

    ---

    ## Rollback

    Deletar worktree e branch.
    """)
    .frame(width: 500, height: 600)
}
