import Foundation
#if canImport(Security)
import Security
#endif

/// A short-lived, single-attempt handle that scopes one sign-in to the URL
/// `https://id.ayiti.io/id/g/{token}`.
///
/// The sign-in footer shows only `masked`; the full value is never displayed,
/// logged, or persisted.
struct GrantToken: Sendable, Equatable {
    let value: String
    let issuedAt: Date
    let ttl: TimeInterval

    var expiresAt: Date { issuedAt.addingTimeInterval(ttl) }

    /// What the footer renders, e.g. `***764d77`.
    var masked: String { "***" + String(value.suffix(6)) }

    static func issue(ttl: TimeInterval, now: Date = .now) -> GrantToken {
        GrantToken(value: randomHex(byteCount: 16), issuedAt: now, ttl: ttl)
    }

    func remaining(at now: Date = .now) -> TimeInterval {
        max(0, expiresAt.timeIntervalSince(now))
    }

    func hasExpired(at now: Date = .now) -> Bool {
        remaining(at: now) <= 0
    }

    /// `mm:ss` countdown shown next to "Expires in:".
    func countdown(at now: Date = .now) -> String {
        let seconds = Int(remaining(at: now).rounded())
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private static func randomHex(byteCount: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
        guard status == errSecSuccess else {
            // The system CSPRNG is the only acceptable source for a credential;
            // there is no safe weaker fallback.
            preconditionFailure("SecRandomCopyBytes failed with status \(status)")
        }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
}

extension GrantToken: CustomStringConvertible {
    var description: String { "GrantToken(\(masked))" }
}
