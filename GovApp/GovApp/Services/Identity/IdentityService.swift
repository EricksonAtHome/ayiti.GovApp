import Foundation

/// Exchanges a citizen's credentials for a `Session`.
protocol IdentityService: Sendable {
    /// `false` when the hosted GovID page collects the HID and PIN itself, in
    /// which case the sign-in screen hides its fields.
    var collectsCredentialsInApp: Bool { get }

    func signIn(_ credentials: Credentials, grant: GrantToken) async throws -> Session
}

extension IdentityService {
    var collectsCredentialsInApp: Bool { true }
}

/// Posts the HID and PIN to `POST {identityBaseURL}/id/g/{token}`.
struct LiveIdentityService: IdentityService {
    let config: AppConfig
    let http: HTTPClient

    init(config: AppConfig = .current, http: HTTPClient = HTTPClient()) {
        self.config = config
        self.http = http
    }

    func signIn(_ credentials: Credentials, grant: GrantToken) async throws -> Session {
        guard !grant.hasExpired() else { throw AppError.grantExpired }

        do {
            let response: IdentityResponse = try await http.post(
                config.grantURL(for: grant),
                body: IdentityRequest(hid: credentials.hid, pin: credentials.pin)
            )
            return Session(response: response, grant: grant)
        } catch let failure as HTTPFailure {
            throw Self.appError(for: failure)
        }
    }

    static func appError(for failure: HTTPFailure) -> AppError {
        switch failure {
        case .status(401), .status(403):
            .invalidCredentials
        case .status(410), .status(419):
            .grantExpired
        case .status(429):
            .tooManyAttempts
        case .status:
            .identityUnavailable
        // A `text/html` body means the request reached the SPA shell rather
        // than an API route — the endpoint is not there, not the credentials.
        case .notJSON, .decoding:
            .identityUnavailable
        case .transport:
            .network
        case .canceled:
            .canceled
        }
    }
}

/// Opens the hosted GovID page at `/id/g/{token}` and waits for it to redirect
/// back to `govapp://auth/callback`.
///
/// `credentials` is ignored — the hosted page collects them itself.
struct HostedIdentityService: IdentityService {
    let config: AppConfig

    init(config: AppConfig = .current) {
        self.config = config
    }

    var collectsCredentialsInApp: Bool { false }

    func signIn(_ credentials: Credentials, grant: GrantToken) async throws -> Session {
        guard !grant.hasExpired() else { throw AppError.grantExpired }

        let callback = try await WebAuthPresenter.shared.present(
            url: config.grantURL(for: grant),
            callbackScheme: config.callbackScheme
        )
        guard let session = Session(callbackURL: callback, grant: grant) else {
            throw AppError.identityUnavailable
        }
        return session
    }
}

/// Deterministic double for previews and tests. Never reaches the network.
struct StubIdentityService: IdentityService {
    var result: Result<Session, AppError> = .success(.preview)
    var delay: Duration = .milliseconds(300)

    func signIn(_ credentials: Credentials, grant: GrantToken) async throws -> Session {
        try? await Task.sleep(for: delay)
        return try result.get()
    }
}
