import SwiftUI

@main
struct GovAppApp: App {
    @State private var sessions = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(sessions)
                .environment(\.services, .live)
        }
    }
}

/// Routes between the three screens. A valid session means chat; otherwise the
/// citizen is in onboarding until they choose to sign in.
struct RootView: View {
    @Environment(SessionStore.self) private var sessions
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSigningIn = false

    var body: some View {
        ZStack {
            Brand.background.ignoresSafeArea()

            if let session = sessions.session, session.isValid() {
                ChatView(session: session)
            } else if isSigningIn {
                SignInView(onCancel: { isSigningIn = false })
            } else {
                OnboardingView(profile: sessions.lastKnownProfile) {
                    isSigningIn = true
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: sessions.session)
        .animation(.easeInOut(duration: 0.25), value: isSigningIn)
        .onChange(of: sessions.session) { _, session in
            if session != nil { isSigningIn = false }
        }
        .onChange(of: scenePhase) { _, phase in
            // A session that aged out while backgrounded must not survive a
            // return to the foreground.
            if phase == .active { sessions.discardIfExpired() }
        }
    }
}

#Preview("Signed out") {
    RootView()
        .environment(SessionStore(secrets: InMemorySecretStore(), defaults: .previewSuite))
        .environment(\.services, .stub)
}
