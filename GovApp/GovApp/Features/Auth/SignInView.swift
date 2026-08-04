import SwiftUI

struct SignInView: View {
    let onCancel: () -> Void

    @Environment(\.services) private var services
    @State private var model: SignInViewModel?

    var body: some View {
        ZStack {
            Brand.background.ignoresSafeArea()
            if let model {
                SignInForm(model: model, onCancel: onCancel)
            }
        }
        .task {
            let model = model ?? SignInViewModel(identity: services.identity)
            self.model = model
            model.startCountdown()
        }
        .onDisappear { model?.stopCountdown() }
    }
}

private struct SignInForm: View {
    @Bindable var model: SignInViewModel
    let onCancel: () -> Void

    @Environment(SessionStore.self) private var sessions

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Text(L10n.SignIn.title)
                .font(Brand.Font.title)
                .foregroundStyle(Brand.ink)
                .padding(.top, Brand.Metric.section)

            if model.collectsCredentialsInApp {
                credentialFields
            }

            if let notice = model.notice {
                NoticeBanner(message: notice)
                    .padding(.top, Brand.Metric.stack)
            }

            BrandButton(
                title: model.isWorking ? L10n.SignIn.working : L10n.SignIn.submit,
                isEnabled: model.canSubmit
            ) {
                Task { await model.submit(into: sessions) }
            }
            .padding(.top, Brand.Metric.section)

            Spacer(minLength: Brand.Metric.section)

            footer
        }
        .padding(.horizontal, Brand.Metric.gutter)
    }

    private var header: some View {
        HStack {
            AyitiLockup()
            Spacer()
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Brand.inkMuted)
            }
            .accessibilityLabel(L10n.Failure.canceled)
        }
        .padding(.top, 8)
    }

    private var credentialFields: some View {
        VStack(spacing: Brand.Metric.stack) {
            BrandTextField(
                placeholder: L10n.SignIn.hid,
                text: $model.hid,
                textContentType: .username
            )
            BrandTextField(
                placeholder: L10n.SignIn.pin,
                text: $model.pin,
                isSecure: true,
                textContentType: .password,
                keyboardType: .numberPad
            )
        }
        .padding(.top, Brand.Metric.section)
        .disabled(model.isWorking)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            FooterRow(
                label: L10n.SignIn.sessionID,
                value: model.grant.masked,
                valueColor: Brand.action
            )
            FooterRow(label: L10n.SignIn.expiresIn, value: model.countdown)

            HStack(spacing: 6) {
                Text(L10n.SignIn.copyright)
                    .font(Brand.Font.caption)
                    .foregroundStyle(Brand.inkMuted)
                RepiblikAyitiWordmark(height: 14)
                Spacer(minLength: 0)
            }
            .padding(.top, 4)
        }
        .padding(.bottom, Brand.Metric.stack)
    }
}

#Preview("Sign in") {
    SignInView(onCancel: {})
        .environment(SessionStore(secrets: InMemorySecretStore(), defaults: .previewSuite))
        .environment(\.services, .stub)
}

#Preview("Rejected") {
    SignInView(onCancel: {})
        .environment(SessionStore(secrets: InMemorySecretStore(), defaults: .previewSuite))
        .environment(
            \.services,
            Services(
                identity: StubIdentityService(result: .failure(.invalidCredentials)),
                chat: StubChatService()
            )
        )
}
