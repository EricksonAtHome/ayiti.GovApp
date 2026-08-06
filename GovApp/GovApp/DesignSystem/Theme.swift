import SwiftUI

/// Design tokens for the ayiti.io brand.
///
/// Views must never spell out a color, size, or radius literal — every value a
/// screen needs lives here. See `.cursor/skills/govapp-ios/DESIGN.md`.
enum Brand {
    /// Logo left stroke and the Repiblik Ayiti wordmark.
    static let blue = Color(hex: 0x1450C8)
    /// Logo right stroke.
    static let red = Color(hex: 0xED2338)
    /// Primary buttons, links, and the session-ID value.
    static let action = Color(hex: 0x4C8DFF)

    static let ink = Color(hex: 0x111114)
    static let inkMuted = Color(hex: 0x6B7076)
    static let placeholder = Color(hex: 0x9AA0A6)
    static let line = Color(hex: 0xE3E5E8)
    static let surface = Color(hex: 0xF2F3F5)
    static let background = Color.white

    /// Text and controls sitting on a photograph.
    static let onPhoto = Color.white
    /// Darkens the lower part of an onboarding photo so a headline stays legible
    /// whatever the image behind it. It starts high enough to cover the
    /// four-line headline on the last slide, not just a one-liner.
    static let photoScrim = LinearGradient(
        stops: [
            .init(color: .black.opacity(0), location: 0),
            .init(color: .black.opacity(0.30), location: 0.45),
            .init(color: .black.opacity(0.80), location: 1),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0.32),
        endPoint: .bottom
    )
}

extension Brand {
    enum Font {
        /// Onboarding headline. Sized so the longest slide copy still clears the
        /// action bar at four lines.
        static let headline = SwiftUI.Font.system(size: 36, weight: .bold)
        static let title = SwiftUI.Font.system(size: 28, weight: .bold)
        static let body = SwiftUI.Font.system(size: 17, weight: .regular)
        static let buttonLabel = SwiftUI.Font.system(size: 17, weight: .semibold)
        /// Suggestion chips and message action buttons.
        static let chip = SwiftUI.Font.system(size: 15, weight: .medium)
        /// Section headers inside the transcript, e.g. "Repons".
        static let sectionLabel = SwiftUI.Font.system(size: 15, weight: .semibold)
        static let caption = SwiftUI.Font.system(size: 13, weight: .regular)
        static let micro = SwiftUI.Font.system(size: 10, weight: .semibold)

        static func wordmark(size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .heavy)
        }
    }

    enum Metric {
        /// Horizontal inset applied to every screen.
        static let gutter: CGFloat = 24
        static let fieldHeight: CGFloat = 56
        static let radius: CGFloat = 12
        /// Citizen message bubbles.
        static let bubbleRadius: CGFloat = 20
        static let cardRadius: CGFloat = 24
        static let chipHeight: CGFloat = 38
        /// Circular controls: send, mic, new chat.
        static let controlButton: CGFloat = 44
        /// Gap between stacked controls in the same group.
        static let stack: CGFloat = 12
        /// Gap between distinct groups.
        static let section: CGFloat = 28

        // Onboarding
        /// Height of one segment in the page-progress track.
        static let progressTrack: CGFloat = 3
        /// The floating bar that holds the advance button.
        static let barHeight: CGFloat = 76
        static let pillHeight: CGFloat = 52
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
