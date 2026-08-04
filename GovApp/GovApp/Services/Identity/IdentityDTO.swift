import Foundation

/// What the citizen types on the sign-in screen. Held only for the duration of
/// one request — never stored, never logged.
struct Credentials: Sendable {
    let hid: String
    let pin: String

    var isComplete: Bool {
        !hid.trimmingCharacters(in: .whitespaces).isEmpty && !pin.isEmpty
    }
}

extension Credentials: CustomStringConvertible {
    var description: String { "Credentials(hid: <redacted>, pin: <redacted>)" }
}

/// Body posted to `POST /id/g/{token}`.
struct IdentityRequest: Encodable {
    let hid: String
    let pin: String
}

/// Expected `200` body from `POST /id/g/{token}`.
///
/// This shape is the app's working contract with GovID, not a published spec.
/// If the server disagrees, change this type — and only this type.
struct IdentityResponse: Decodable {
    let session: String
    let expiresIn: TimeInterval?
    let username: String?
    let govUrlId: String?
}
