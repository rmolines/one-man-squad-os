import SwiftUI

struct PortfolioView: View {
    var body: some View {
        ContentUnavailableView(
            "Portfolio",
            systemImage: "square.stack.3d.up",
            description: Text("Hypothesis cards — coming in portfolio-view feature.")
        )
    }
}
