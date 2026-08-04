import Foundation

/// Every endpoint, scheme, and tunable the app uses.
///
/// Values come from `Supporting/Info.plist` so a build can be repointed at a
/// staging identity server or a remote ElloFive host without a code change.
/// Nothing outside this type may hardcode a URL, port, or model name.
struct AppConfig: Sendable {
    enum IdentityMode: String, Sendable {
        /// Post the HID and PIN typed on the sign-in screen to the grant URL.
        case direct
        /// Hand off to the hosted GovID page in a web authentication session.
        case hosted
    }

    let identityBaseURL: URL
    let identityMode: IdentityMode
    let callbackScheme: String
    /// How long a grant, and the session it produces, stays valid.
    let sessionTTL: TimeInterval
    let aiBaseURL: URL
    let aiModel: String
    /// Number of prior exchanges replayed to the stateless ElloFive bridge.
    let contextTurns: Int

    init(bundle: Bundle) {
        let read = { (key: String) -> String? in
            (bundle.object(forInfoDictionaryKey: key) as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nilWhenEmpty
        }

        identityBaseURL = read("GOVAPP_IDENTITY_BASE_URL")
            .flatMap(URL.init(string:)) ?? Fallback.identityBaseURL
        identityMode = read("GOVAPP_IDENTITY_MODE")
            .flatMap(IdentityMode.init(rawValue:)) ?? .direct
        callbackScheme = read("GOVAPP_CALLBACK_SCHEME") ?? "govapp"
        sessionTTL = read("GOVAPP_SESSION_TTL_SECONDS")
            .flatMap(TimeInterval.init) ?? 1800
        aiBaseURL = read("GOVAPP_AI_BASE_URL")
            .flatMap(URL.init(string:)) ?? Fallback.aiBaseURL
        aiModel = read("GOVAPP_AI_MODEL") ?? "ellofive"
        contextTurns = read("GOVAPP_AI_CONTEXT_TURNS").flatMap(Int.init) ?? 6
    }

    /// Used only when Info.plist is missing a key — a misconfigured build should
    /// still launch and fail with a readable message rather than trap.
    private enum Fallback {
        // swiftlint:disable force_unwrapping
        static let identityBaseURL = URL(string: "https://id.ayiti.io")!
        static let aiBaseURL = URL(string: "http://127.0.0.1:3000")!
        // swiftlint:enable force_unwrapping
    }
}

extension AppConfig {
    static let current = AppConfig(bundle: .main)

    /// The grant URL a sign-in attempt is scoped to: `/id/g/{token}`.
    func grantURL(for token: GrantToken) -> URL {
        identityBaseURL
            .appending(path: "id")
            .appending(path: "g")
            .appending(path: token.value)
    }

    /// The ElloFive FRC bridge endpoint for a single turn.
    var runURL: URL {
        aiBaseURL.appending(path: "run").appending(path: aiModel)
    }

    var healthURL: URL {
        aiBaseURL.appending(path: "health")
    }

    var callbackURL: String {
        "\(callbackScheme)://auth/callback"
    }
}

private extension String {
    var nilWhenEmpty: String? { isEmpty ? nil : self }
}
