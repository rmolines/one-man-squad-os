import SwiftUI
import Core

/// Shows the artifact documents (explore, discovery, research, plan) for a feature plan.
/// Documents are already loaded in `FeaturePlanInfo.artifacts` — no disk I/O here.
struct FeatureDocumentsView: View {
    let hypothesis: FeaturePlanInfo

    private enum Doc: String, CaseIterable {
        case explore = "Explore"
        case discovery = "Discovery"
        case research = "Research"
        case plan = "Plan"
    }

    @State private var selectedDoc: Doc = .explore

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
                MarkdownView(text: content(for: selectedDoc) ?? "")
            }
        }
        .frame(minWidth: 640, maxWidth: 640, minHeight: 480, maxHeight: 720)
        .onAppear {
            if let first = availableDocs.first {
                selectedDoc = first
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(hypothesis.title)
                    .font(.headline)
                Text(hypothesis.slug)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusChip(status: hypothesis.status)
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

    private var emptyState: some View {
        ContentUnavailableView(
            "No documents",
            systemImage: "doc.text.slash",
            description: Text("No artifacts found for \(hypothesis.slug)")
        )
    }

    // MARK: - Helpers

    private func content(for doc: Doc) -> String? {
        switch doc {
        case .explore:   return hypothesis.artifacts.exploreMd
        case .discovery: return hypothesis.artifacts.discoveryMd
        case .research:  return hypothesis.artifacts.researchMd
        case .plan:      return hypothesis.artifacts.planMd
        }
    }
}

