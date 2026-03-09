import SwiftUI
import Core

struct GateIndicatorView: View {
    let gate: Gate

    var body: some View {
        if !gate.canAdvance {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text("Missing: \(gate.missing.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .lineLimit(1)
            }
        }
    }
}
