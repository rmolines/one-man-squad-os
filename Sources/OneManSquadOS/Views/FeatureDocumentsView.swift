import SwiftUI
import Core

/// Shows the artifact documents for a feature. Documents are already loaded in
/// `FeatureNode.info.artifacts` — no disk I/O here.
struct FeatureDocumentsView: View {
    let feature: FeatureNode
    let rootRepoPath: String
    let onSave: () -> Void

    private enum Doc: String, CaseIterable {
        case clarify   = "Clarify"
        case explore   = "Explore"
        case discovery = "Discovery"
        case research  = "Research"
        case plan      = "Plan"
    }

    @State private var selectedDoc: Doc = .clarify
    @State private var isEditing = false
    @State private var editingText = ""
    @State private var showSaveConfirm = false
    @State private var saveError: String? = nil

    private var artifacts: ArtifactSet { feature.info.artifacts }

    private var availableDocs: [Doc] {
        Doc.allCases.filter { content(for: $0) != nil }
    }

    /// Docs that support inline editing (those rendered via MarkdownView).
    private var isEditableDoc: Bool {
        selectedDoc != .clarify && selectedDoc != .explore
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if availableDocs.isEmpty {
                emptyState
            } else {
                docPicker
                Divider()
                if isEditing {
                    editorContent
                } else {
                    docContent
                }
            }
        }
        .onAppear { selectDefaultDoc() }
        .onChange(of: feature.id) { _, _ in
            isEditing = false
            selectDefaultDoc()
        }
        .onChange(of: selectedDoc) { _, _ in
            isEditing = false
        }
        .alert("Save changes?", isPresented: $showSaveConfirm) {
            Button("Save", role: .destructive) { performSave() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will overwrite \(filename(for: selectedDoc)) on disk.")
        }
        .alert("Save failed", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.info.title)
                    .font(.headline)
                Text(feature.info.slug)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 6) {
                if isEditing {
                    Button("Cancel") {
                        isEditing = false
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)

                    Button("Save") {
                        showSaveConfirm = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else {
                    if isEditableDoc && content(for: selectedDoc) != nil {
                        Button {
                            editingText = content(for: selectedDoc) ?? ""
                            isEditing = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                        .controlSize(.small)
                    }
                    PhaseChip(phase: feature.phase)
                    StatusChip(status: feature.info.status)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var docPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(availableDocs, id: \.self) { doc in
                    Button {
                        selectedDoc = doc
                    } label: {
                        Text(doc.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedDoc == doc ? .semibold : .regular)
                            .foregroundStyle(selectedDoc == doc ? Color.accentColor : .secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .bottom) {
                        if selectedDoc == doc {
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(height: 2)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var docContent: some View {
        switch selectedDoc {
        case .clarify:
            ClarifyDetailView(raw: artifacts.clarifyMd ?? "")
        case .explore:
            ExploreDetailView(raw: artifacts.exploreMd ?? "")
        default:
            ScrollView {
                MarkdownView(text: content(for: selectedDoc) ?? "")
                    .padding(16)
            }
        }
    }

    private var editorContent: some View {
        TextEditor(text: $editingText)
            .font(.system(.body, design: .monospaced))
            .padding(12)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No documents",
            systemImage: "doc.text.slash",
            description: Text("No artifacts found for \(feature.info.slug)")
        )
    }

    // MARK: - Helpers

    private func content(for doc: Doc) -> String? {
        switch doc {
        case .clarify:   return artifacts.clarifyMd
        case .explore:   return artifacts.exploreMd
        case .discovery: return artifacts.discoveryMd
        case .research:  return artifacts.researchMd
        case .plan:      return artifacts.planMd
        }
    }

    private func filename(for doc: Doc) -> String {
        switch doc {
        case .clarify:   return "clarify.md"
        case .explore:   return "explore.md"
        case .discovery: return "discovery.md"
        case .research:  return "research.md"
        case .plan:      return "plan.md"
        }
    }

    private func selectDefaultDoc() {
        // For Discovery phase, prefer clarify; otherwise prefer the most advanced artifact
        switch feature.phase {
        case .discovery:
            selectedDoc = availableDocs.first { $0 == .clarify || $0 == .explore } ?? availableDocs.first ?? .clarify
        case .planning:
            selectedDoc = availableDocs.first { $0 == .discovery || $0 == .research } ?? availableDocs.first ?? .discovery
        case .delivery:
            selectedDoc = availableDocs.first { $0 == .plan } ?? availableDocs.first ?? .plan
        }
    }

    private func performSave() {
        let slug = feature.info.slug
        let relativePath = "\(slug)/\(filename(for: selectedDoc))"

        let result = previewWrite(content: editingText, to: relativePath, rootRepoPath: rootRepoPath)
        switch result {
        case .success(let preview):
            do {
                try commitWrite(preview)
                isEditing = false
                onSave()
            } catch {
                saveError = error.localizedDescription
            }
        case .failure(let error):
            switch error {
            case .pathTraversal(let path):
                saveError = "Path traversal rejected: \(path)"
            case .outsideFeaturePlans(let path):
                saveError = "Path outside feature-plans: \(path)"
            case .ioError(let underlying):
                saveError = underlying.localizedDescription
            }
        }
    }
}
