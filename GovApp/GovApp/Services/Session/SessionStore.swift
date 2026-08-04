import Foundation
import Observation

/// Where the session token is kept. Swapped for an in-memory double in tests.
protocol SecretStore: Sendable {
    func set(_ value: String, for account: String)
    func string(for account: String) -> String?
    func delete(_ account: String)
}

struct KeychainSecretStore: SecretStore {
    func set(_ value: String, for account: String) { Keychain.set(value, for: account) }
    func string(for account: String) -> String? { Keychain.string(for: account) }
    func delete(_ account: String) { Keychain.delete(account) }
}

/// The single owner of "is somebody signed in".
///
/// The token goes to the Keychain; username, gov URL ID, and expiry are display
/// data and go to `UserDefaults`. Nothing else in the app persists either.
@Observable
@MainActor
final class SessionStore {
    /// Display identity, kept after sign-out so the welcome screen can greet a
    /// returning citizen by name. Contains no credential.
    struct Profile: Sendable, Equatable {
        let username: String
        let govURLID: String
    }

    private enum Key {
        static let token = "io.ayiti.govapp.session"
        static let username = "govapp.username"
        static let govURLID = "govapp.govURLID"
        static let expiresAt = "govapp.expiresAt"
    }

    private(set) var session: Session?
    private(set) var lastKnownProfile: Profile?

    @ObservationIgnored private let secrets: SecretStore
    @ObservationIgnored private let defaults: UserDefaults

    init(secrets: SecretStore = KeychainSecretStore(), defaults: UserDefaults = .standard) {
        self.secrets = secrets
        self.defaults = defaults
        lastKnownProfile = loadProfile()
        session = loadPersisted()
    }

    var isSignedIn: Bool { session?.isValid() == true }

    func save(_ session: Session) {
        self.session = session
        lastKnownProfile = Profile(username: session.username, govURLID: session.govURLID)
        secrets.set(session.token, for: Key.token)
        defaults.set(session.username, forKey: Key.username)
        defaults.set(session.govURLID, forKey: Key.govURLID)
        defaults.set(session.expiresAt.timeIntervalSince1970, forKey: Key.expiresAt)
    }

    /// Ends the session but remembers who the citizen is.
    func signOut() {
        session = nil
        secrets.delete(Key.token)
        defaults.removeObject(forKey: Key.expiresAt)
    }

    /// Ends the session and forgets the citizen entirely.
    func forget() {
        signOut()
        lastKnownProfile = nil
        defaults.removeObject(forKey: Key.username)
        defaults.removeObject(forKey: Key.govURLID)
    }

    /// Drops the session if it has aged out since the app was last foregrounded.
    func discardIfExpired(at now: Date = .now) {
        guard let session, !session.isValid(at: now) else { return }
        signOut()
    }

    private func loadProfile() -> Profile? {
        guard let username = defaults.string(forKey: Key.username) else { return nil }
        return Profile(
            username: username,
            govURLID: defaults.string(forKey: Key.govURLID) ?? ""
        )
    }

    private func loadPersisted() -> Session? {
        guard let token = secrets.string(for: Key.token) else { return nil }
        let expiry = defaults.double(forKey: Key.expiresAt)
        guard expiry > 0 else { return nil }

        let restored = Session(
            token: token,
            username: lastKnownProfile?.username ?? "",
            govURLID: lastKnownProfile?.govURLID ?? "",
            expiresAt: Date(timeIntervalSince1970: expiry)
        )
        guard restored.isValid() else {
            secrets.delete(Key.token)
            return nil
        }
        return restored
    }
}
