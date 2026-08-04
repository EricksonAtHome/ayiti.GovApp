import SwiftUI

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

/// Primary action button.
///
/// `.hugging` sizes to its label (sign-in), `.wide` fills the width (welcome).
struct BrandButton: View {
    enum Width {
        case hugging
        case wide
    }

    let title: String
    var width: Width = .hugging
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(width == .wide ? Brand.Font.action : Brand.Font.buttonLabel)
                .foregroundStyle(.white)
                .padding(.horizontal, width == .wide ? 0 : 40)
                .frame(
                    maxWidth: width == .wide ? .infinity : nil,
                    minHeight: width == .wide
                        ? Brand.Metric.wideButtonHeight
                        : Brand.Metric.fieldHeight
                )
                .background(
                    RoundedRectangle(cornerRadius: Brand.Metric.radius, style: .continuous)
                        .fill(Brand.action)
                )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
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

/// Inline, dismissable error banner. Nothing in the app shows a raw system
/// error string to a citizen.
struct NoticeBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(Brand.Font.caption)
            .foregroundStyle(Brand.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: Brand.Metric.radius, style: .continuous)
                    .fill(Brand.red.opacity(0.08))
            )
            .accessibilityAddTraits(.isStaticText)
    }
}

#Preview("Components") {
    VStack(alignment: .leading, spacing: Brand.Metric.stack) {
        BrandTextField(placeholder: L10n.SignIn.hid, text: .constant(""))
        BrandTextField(placeholder: L10n.SignIn.pin, text: .constant(""), isSecure: true)
        BrandButton(title: L10n.SignIn.submit) {}
        BrandButton(title: L10n.Welcome.signIn, width: .wide) {}
        NoticeBanner(message: L10n.Failure.invalidCredentials)
        FooterRow(label: L10n.SignIn.sessionID, value: "***764d77", valueColor: Brand.action)
    }
    .padding(Brand.Metric.gutter)
}
