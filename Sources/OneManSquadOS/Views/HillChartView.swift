import SwiftUI
import Core

/// A Hill Chart showing where features are in the thinking process.
/// Items on the left upslope are "figuring it out"; right downslope are "making it happen".
struct HillChartView: View {
    let items: [HillItem]

    var body: some View {
        Canvas { context, size in
            let W = size.width
            let H = size.height

            // Control points for the hill arc: endpoints at bottom, peak near top-center
            let p0 = CGPoint(x: 0, y: H)
            let p1 = CGPoint(x: W * 0.25, y: H * 0.05)
            let p2 = CGPoint(x: W * 0.75, y: H * 0.05)
            let p3 = CGPoint(x: W, y: H)

            // Draw hill curve
            var hillPath = Path()
            hillPath.move(to: p0)
            hillPath.addCurve(to: p3, control1: p1, control2: p2)
            context.stroke(hillPath, with: .color(.secondary.opacity(0.35)), lineWidth: 2)

            // Draw center divider
            var divider = Path()
            divider.move(to: CGPoint(x: W * 0.5, y: 0))
            divider.addLine(to: CGPoint(x: W * 0.5, y: H))
            context.stroke(divider, with: .color(.secondary.opacity(0.2)),
                           style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            // Draw phase labels
            context.draw(
                Text("Figuring it out").font(.system(size: 9)).foregroundStyle(.secondary),
                at: CGPoint(x: W * 0.25, y: H - 4),
                anchor: .bottom
            )
            context.draw(
                Text("Making it happen").font(.system(size: 9)).foregroundStyle(.secondary),
                at: CGPoint(x: W * 0.75, y: H - 4),
                anchor: .bottom
            )

            // Draw items positioned on the curve
            for item in items {
                let t = max(0.02, min(0.98, item.t))
                let pt = cubicBezierPoint(p0: p0, p1: p1, p2: p2, p3: p3, t: t)

                let dotSize: CGFloat = 8
                let dotRect = CGRect(
                    x: pt.x - dotSize / 2,
                    y: pt.y - dotSize - 2,
                    width: dotSize,
                    height: dotSize
                )
                context.fill(Path(ellipseIn: dotRect), with: .color(item.color))

                // Label above dot
                context.draw(
                    Text(item.label).font(.system(size: 8)).foregroundStyle(.primary),
                    at: CGPoint(x: pt.x, y: pt.y - dotSize - 5),
                    anchor: .bottom
                )
            }
        }
        .frame(height: 110)
    }
}

// MARK: - HillItem

struct HillItem: Identifiable {
    let id: String
    let label: String
    /// Position on the hill: 0.0 = far left (early discovery), 1.0 = far right (delivered).
    let t: CGFloat
    let color: Color
}

// MARK: - Bezier math

private func cubicBezierPoint(
    p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, t: CGFloat
) -> CGPoint {
    let mt = 1.0 - t
    let x = mt*mt*mt*p0.x + 3*mt*mt*t*p1.x + 3*mt*t*t*p2.x + t*t*t*p3.x
    let y = mt*mt*mt*p0.y + 3*mt*mt*t*p1.y + 3*mt*t*t*p2.y + t*t*t*p3.y
    return CGPoint(x: x, y: y)
}
