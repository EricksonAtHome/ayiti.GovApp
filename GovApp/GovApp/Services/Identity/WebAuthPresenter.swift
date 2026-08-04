import AuthenticationServices
import UIKit

/// Presents the hosted GovID page in an `ASWebAuthenticationSession` and
/// resolves when it redirects to the app's callback scheme.
@MainActor
final class WebAuthPresenter: NSObject {
    static let shared = WebAuthPresenter()

    /// The session must stay alive for as long as the sheet is on screen.
    private var current: ASWebAuthenticationSession?

    func present(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callback, error in
                Task { @MainActor in WebAuthPresenter.shared.finish() }

                if let callback {
                    continuation.resume(returning: callback)
                } else if let error = error as? ASWebAuthenticationSessionError,
                          error.code == .canceledLogin {
                    continuation.resume(throwing: AppError.canceled)
                } else {
                    continuation.resume(throwing: AppError.identityUnavailable)
                }
            }

            session.presentationContextProvider = self
            // Government credentials: never leave a cookie behind in Safari.
            session.prefersEphemeralWebBrowserSession = true

            current = session
            guard session.start() else {
                current = nil
                continuation.resume(throwing: AppError.identityUnavailable)
                return
            }
        }
    }

    private func finish() {
        current = nil
    }
}

extension WebAuthPresenter: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(
        for session: ASWebAuthenticationSession
    ) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
            return scene?.keyWindow ?? ASPresentationAnchor()
        }
    }
}