import SwiftUI

/// Geometry of the ayiti.io "A", expressed on a 1024-unit grid.
///
/// These numbers are shared with `Tools/generate-appicon.py`, which renders the
/// app icon from the same coordinates. Change both together.
enum AyitiGeometry {
    static let bounds = CGRect(x: 190, y: 195, width: 648, height: 610)

    static let blueStroke: [CGPoint] = [
        CGPoint(x: 435, y: 195),
        CGPoint(x: 555, y: 195),
        CGPoint(x: 660, y: 355),
        CGPoint(x: 190, y: 805),
    ]

    static let redStroke: [CGPoint] = [
        CGPoint(x: 678, y: 408),
        CGPoint(x: 448, y: 652),
        CGPoint(x: 562, y: 656),
        CGPoint(x: 648, y: 805),
        CGPoint(x: 838, y: 805),
    ]

    static let knockoutCenter = CGPoint(x: 716, y: 735)
    static let knockoutRadius: CGFloat = 62

    static var aspectRatio: CGFloat { bounds.width / bounds.height }
}

/// Maps grid coordinates into a target rect, preserving aspect ratio.
private struct GridProjection {
    let scale: CGFloat
    let origin: CGPoint

    init(target: CGRect) {
        let grid = AyitiGeometry.bounds
        scale = min(target.width / grid.width, target.height / grid.height)
        origin = CGPoint(
            x: target.minX + (target.width - grid.width * scale) / 2 - grid.minX * scale,
            y: target.minY + (target.height - grid.height * scale) / 2 - grid.minY * scale
        )
    }

    func callAsFunction(_ point: CGPoint) -> CGPoint {
        CGPoint(x: origin.x + point.x * scale, y: origin.y + point.y * scale)
    }
}

private struct BlueStrokeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let project = GridProjection(target: rect)
        var path = Path()
        path.addLines(AyitiGeometry.blueStroke.map(project.callAsFunction))
        path.closeSubpath()
        return path
    }
}

/// The red stroke with the circle as a second subpath, so an even-odd fill
/// knocks the circle out to transparent rather than painting it white.
private struct RedStrokeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let project = GridProjection(target: rect)
        var path = Path()
        path.addLines(AyitiGeometry.redStroke.map(project.callAsFunction))
        path.closeSubpath()

        let center = project(AyitiGeometry.knockoutCenter)
        let radius = AyitiGeometry.knockoutRadius * project.scale
        path.addEllipse(
            in: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        )
        return path
    }
}

/// The ayiti.io "A" mark, drawn as vectors so it stays crisp at any size.
struct AyitiMark: View {
    var height: CGFloat = 32

    var body: some View {
        ZStack {
            BlueStrokeShape().fill(Brand.blue)
            RedStrokeShape().fill(Brand.red, style: FillStyle(eoFill: true))
        }
        .frame(width: height * AyitiGeometry.aspectRatio, height: height)
        .accessibilityHidden(true)
    }
}

/// The mark paired with the "ayiti.io" wordmark, used as screen headers.
///
/// The mark keeps its brand colors everywhere; only the wordmark changes, so
/// pass `Brand.onPhoto` when the lockup sits on a photograph.
struct AyitiLockup: View {
    var height: CGFloat = 34
    var wordmark: Color = Brand.ink

    var body: some View {
        HStack(spacing: height * 0.22) {
            AyitiMark(height: height)
            Text(verbatim: "ayiti.io")
                .font(Brand.Font.wordmark(size: height * 0.88))
                .tracking(-1)
                .foregroundStyle(wordmark)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.General.brand)
    }
}

/// The "Repiblik 🇭🇹 Ayiti" endorsement shown in the sign-in footer.
struct RepiblikAyitiWordmark: View {
    var height: CGFloat = 15

    var body: some View {
        HStack(spacing: height * 0.18) {
            Text(L10n.General.repiblik)
            HaitiFlagGlyph(height: height * 0.82)
            Text(L10n.General.ayiti)
        }
        .font(.system(size: height, weight: .bold))
        .foregroundStyle(Brand.ink)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(L10n.General.repiblik) \(L10n.General.ayiti)")
    }
}

private struct HaitiFlagGlyph: View {
    var height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Brand.blue
            Brand.red
        }
        .frame(width: height * 1.5, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 1, style: .continuous))
    }
}

#Preview("Mark") {
    VStack(alignment: .leading, spacing: 32) {
        AyitiMark(height: 96)
        AyitiLockup()
        RepiblikAyitiWordmark()
    }
    .padding(Brand.Metric.gutter)
}
