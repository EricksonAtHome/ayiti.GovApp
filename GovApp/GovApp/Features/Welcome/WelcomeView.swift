import SwiftUI

/// Signed-out landing screen: a large avatar, the returning citizen's name and
/// gov URL ID, and a full-width button into sign-in.
struct WelcomeView: View {
    let profile: SessionStore.Profile?
    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            AvatarCircle(size: 245, initial: profile?.username.first.map { String($0) })
                .accessibilityHidden(true)

            Text(title)
                .font(Brand.Font.display)
                .foregroundStyle(Brand.ink)
                .padding(.top, Brand.Metric.section)

            Text(subtitle)
                .font(Brand.Font.caption)
                .foregroundStyle(Brand.inkMuted)
                .padding(.top, 2)

            Spacer()

            BrandButton(title: L10n.Welcome.signIn, width: .wide, action: onSignIn)
                .padding(.bottom, Brand.Metric.stack)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Brand.Metric.gutter)
        .background(Brand.background)
    }

    private var title: String {
        let name = profile?.username ?? ""
        return name.isEmpty ? L10n.General.brand : name
    }

    private var subtitle: String {
        let id = profile?.govURLID ?? ""
        return id.isEmpty ? AppConfig.current.identityBaseURL.host() ?? "" : id
    }
}

#Preview("Returning citizen") {
    WelcomeView(
        profile: SessionStore.Profile(
            username: Session.preview.username,
            govURLID: Session.preview.govURLID
        )
    ) {}
}

#Preview("First run") {
    WelcomeView(profile: nil) {}
}
