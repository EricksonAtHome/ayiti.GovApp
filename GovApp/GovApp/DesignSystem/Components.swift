import SwiftUI
import UIKit

/// The bordered text field used across sign-in.
struct BrandTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var textContentType: UITextContentType?
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        Group {
            if isSecure {
                SecureField("", text: $text, prompt: prompt)
            } else {
                TextField("", text: $text, prompt: prompt)
            }
        }
        .font(Brand.Font.body)
        .foregroundStyle(Brand.ink)
        .textContentType(textContentType)
        .keyboardType(keyboardType)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding(.horizontal, 16)
        .frame(height: Brand.Metric.fieldHeight)
        .background(
            RoundedRectangle(cornerRadius: Brand.Metric.radius, style: .continuous)
                .strokeBorder(Brand.line, lineWidth: 1)
        )
        .accessibilityLabel(placeholder)
    }

    private var prompt: Text {
        Text(placeholder).foregroundColor(Brand.placeholder)
    }
}

/// Primary action button. Sizes to its label rather than filling the width.
struct BrandButton: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Brand.Font.buttonLabel)
                .foregroundStyle(.white)
                .padding(.horizontal, 40)
                .frame(minHeight: Brand.Metric.fieldHeight)
                .background(
                    RoundedRectangle(cornerRadius: Brand.Metric.radius, style: .continuous)
                        .fill(Brand.action)
                )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

/// The outlined pill shape used for chat suggestions and message actions.
///
/// Split from `BrandChip` so non-button controls — `ShareLink`, for one — can
/// wear the same shape without faking a button.
struct ChipLabel: View {
    let title: String
    var systemImage: String?
    var tint: Color = Brand.ink

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Brand.action)
            }
            Text(title)
                .font(Brand.Font.chip)
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 14)
        .frame(height: Brand.Metric.chipHeight)
        .background(
            Capsule()
                .fill(Brand.background)
                .overlay(Capsule().strokeBorder(Brand.line))
        )
    }
}

struct BrandChip: View {
    let title: String
    var systemImage: String?
    var tint: Color = Brand.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ChipLabel(title: title, systemImage: systemImage, tint: tint)
        }
        .buttonStyle(.plain)
    }
}

/// Circular icon button: send, mic, new chat.
struct CircleIconButton: View {
    let systemImage: String
    var filled = false
    var size: CGFloat = Brand.Metric.controlButton
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(filled ? Brand.background : Brand.inkMuted)
                .frame(width: size, height: size)
                .background(
                    Circle().fill(filled ? Brand.action : Brand.surface)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}

/// Placeholder avatar. Renders the citizen's initial once a session exists.
struct AvatarCircle: View {
    var size: CGFloat = 44
    var initial: String?

    var body: some View {
        Circle()
            .fill(Brand.surface)
            .frame(width: size, height: size)
            .overlay {
                if let initial, !initial.isEmpty {
                    Text(initial)
                        .font(.system(size: size * 0.42, weight: .semibold))
                        .foregroundStyle(Brand.inkMuted)
                }
            }
            .accessibilityHidden(true)
    }
}

/// A footer row with a leading label and a trailing value, as used by the
/// session block on the sign-in screen.
struct FooterRow: View {
    let label: String
    let value: String
    var valueColor: Color = Brand.ink

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(Brand.inkMuted)
            Spacer(minLength: Brand.Metric.stack)
            Text(value)
                .foregroundStyle(valueColor)
                .monospacedDigit()
        }
        .font(Brand.Font.caption)
    }
}

/// Inline error banner. Nothing in the app shows a raw system error string to a
/// citizen.
///
/// The message is `ink`, not `red`: `#E63946` on white is 4.17:1, short of the
/// 4.5:1 body text needs. Red carries the signal through the icon, the rule, and
/// the wash — all graphics, which only need 3:1.
struct NoticeBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Brand.red)
            Text(message)
                .font(Brand.Font.caption)
                .foregroundStyle(Brand.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Brand.Metric.radius, style: .continuous)
                .fill(Brand.red.opacity(0.08))
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Brand.red)
                .frame(width: 3)
                .clipShape(
                    RoundedRectangle(cornerRadius: Brand.Metric.radius, style: .continuous)
                )
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Components") {
    VStack(alignment: .leading, spacing: Brand.Metric.stack) {
        BrandTextField(placeholder: L10n.SignIn.hid, text: .constant(""))
        BrandTextField(placeholder: L10n.SignIn.pin, text: .constant(""), isSecure: true)
        BrandButton(title: L10n.SignIn.submit) {}
        NoticeBanner(message: L10n.Failure.invalidCredentials)
        FooterRow(label: L10n.SignIn.sessionID, value: "***764d77", valueColor: Brand.action)
    }
    .padding(Brand.Metric.gutter)
}
