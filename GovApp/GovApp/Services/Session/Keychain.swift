import Foundation
import Security

/// Minimal Keychain accessor for the one secret GovApp holds: the session
/// token. Display data (username, gov URL ID, expiry) lives in `UserDefaults`.
enum Keychain {
    /// Device-only and unavailable before first unlock, so the token never
    /// rides along in an iCloud or iTunes backup.
    private static let accessibility = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    static func set(_ value: String, for account: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func string(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
