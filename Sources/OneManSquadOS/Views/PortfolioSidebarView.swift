import SwiftUI
import Core

struct PortfolioSidebarView: View {
    let groups: [GroupNode]
    @Binding var selection: String?

    var body: some View {
        List(groups, selection: $selection) { group in
            Label(group.title, systemImage: sidebarIcon(for: group))
                .badge(group.features.count)
        }
        .listStyle(.sidebar)
    }

    private func sidebarIcon(for group: GroupNode) -> String {
        group.milestone == nil ? "magnifyingglass" : "flag.fill"
    }
}
