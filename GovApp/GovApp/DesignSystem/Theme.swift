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
}

extension Brand {
    enum Font {
        static let display = SwiftUI.Font.system(size: 40, weight: .bold)
        static let title = SwiftUI.Font.system(size: 28, weight: .bold)
        static let body = SwiftUI.Font.system(size: 17, weight: .regular)
        static let action = SwiftUI.Font.system(size: 20, weight: .regular)
        static let buttonLabel = SwiftUI.Font.system(size: 17, weight: .semibold)
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
        static let wideButtonHeight: CGFloat = 64
        static let radius: CGFloat = 12
        static let composerRadius: CGFloat = 16
        /// Gap between stacked controls in the same group.
        static let stack: CGFloat = 12
        /// Gap between distinct groups.
        static let section: CGFloat = 28
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
