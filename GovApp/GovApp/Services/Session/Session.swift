import Foundation

/// A signed-in citizen. The token is a bearer credential — treat it like one.
struct Session: Sendable, Equatable, Codable {
    let token: String
    let username: String
    let govURLID: String
    let expiresAt: Date

    /// Clock skew allowed before a session is considered expired.
    private static let skew: TimeInterval = 30

    func isValid(at now: Date = .now) -> Bool {
        expiresAt.timeIntervalSince(now) > Self.skew
    }

    var initial: String {
        username.first.map { String($0).uppercased() } ?? ""
    }
}

extension Session: CustomStringConvertible {
    /// Deliberately redacted so a session can be interpolated into a log line
    /// without leaking the token. Keep it that way.
    var description: String {
        "Session(user: \(username), token: <redacted>, expires: \(expiresAt))"
    }
}

extension Session {
    /// Builds a session from a successful `POST /id/g/{token}` response,
    /// falling back to the grant's own TTL when the server omits `expiresIn`.
    init(response: IdentityResponse, grant: GrantToken, now: Date = .now) {
        self.init(
            token: response.session,
            username: response.username ?? "",
            govURLID: response.govUrlId ?? "",
            expiresAt: now.addingTimeInterval(response.expiresIn ?? grant.ttl)
        )
    }
}
