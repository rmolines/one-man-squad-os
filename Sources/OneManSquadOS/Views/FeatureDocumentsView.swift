import SwiftUI
import Core

/// Shows the artifact documents for a feature. Documents are already loaded in
/// `FeatureNode.info.artifacts` — no disk I/O here.
struct FeatureDocumentsView: View {
    let feature: FeatureNode

    private enum Doc: String, CaseIterable {
        case clarify   = "Clarify"
        case explore   = "Explore"
        case discovery = "Discovery"
        case research  = "Research"
        case plan      = "Plan"
    }

    @State private var selectedDoc: Doc = .clarify

    private var artifacts: ArtifactSet { feature.info.artifacts }

    private var availableDocs: [Doc] {
        Doc.allCases.filter { content(for: $0) != nil }
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
                docContent
            }
        }
        .onAppear { selectDefaultDoc() }
        .onChange(of: feature.id) { selectDefaultDoc() }
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
                Text(feature.phase.label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(feature.phase.color.opacity(0.15))
                    .foregroundStyle(feature.phase.color)
                    .clipShape(Capsule())
                Text(feature.info.status.label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(feature.info.status.color.opacity(0.15))
                    .foregroundStyle(feature.info.status.color)
                    .clipShape(Capsule())
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
}
