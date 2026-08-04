import Foundation

/// Fixtures for `#Preview` and tests. The design mockups use `{username}` and
/// `{gov.url.id}` placeholders; these are their concrete stand-ins.
extension Session {
    static let preview = Session(
        token: "preview-token",
        username: "Jean Baptiste",
        govURLID: "gov.ayiti.io/jbaptiste",
        expiresAt: .now.addingTimeInterval(1800)
    )
}

/// Keeps previews and tests off the Keychain.
final class InMemorySecretStore: SecretStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: String] = [:]

    func set(_ value: String, for account: String) {
        lock.withLock { storage[account] = value }
    }

    func string(for account: String) -> String? {
        lock.withLock { storage[account] }
    }

    func delete(_ account: String) {
        _ = lock.withLock { storage.removeValue(forKey: account) }
    }
}

extension UserDefaults {
    /// A throwaway suite so previews and tests never disturb real state.
    static let previewSuite = UserDefaults(suiteName: "io.ayiti.govapp.previews") ?? .standard
}

extension ChatMessage {
    static let previewTranscript: [ChatMessage] = [
        ChatMessage(
            author: .assistant,
            text: "Bonjou Jean, paspò ou an pare pou l pati."
        ),
        ChatMessage(
            author: .citizen,
            text: "Mèsi Gov Ayiti, èske ou gen yon adrès?"
        ),
    ]
}
