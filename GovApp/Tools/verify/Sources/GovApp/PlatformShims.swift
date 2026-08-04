#if !canImport(Security)
import Foundation

// Stand-ins for the three Apple-only pieces GovApp touches, so the rest of the
// logic can be compiled and tested on Linux. None of this is ever built into
// the app: on Apple platforms `canImport(Security)` is true and the real
// Keychain.swift and WebAuthPresenter.swift are used instead.

let errSecSuccess: Int32 = 0
let kSecRandomDefault: UnsafeRawPointer? = nil

func SecRandomCopyBytes(
    _ rnd: UnsafeRawPointer?,
    _ count: Int,
    _ bytes: UnsafeMutableRawPointer
) -> Int32 {
    let buffer = bytes.assumingMemoryBound(to: UInt8.self)
    for index in 0..<count {
        buffer[index] = UInt8.random(in: 0...255)
    }
    return errSecSuccess
}

/// The real implementation stores the session token in the Keychain. Tests use
/// `InMemorySecretStore`, so nothing here needs to persist.
enum Keychain {
    static func set(_ value: String, for account: String) {}
    static func string(for account: String) -> String? { nil }
    static func delete(_ account: String) {}
}

@MainActor
final class WebAuthPresenter {
    static let shared = WebAuthPresenter()

    func present(url: URL, callbackScheme: String) async throws -> URL {
        throw AppError.identityUnavailable
    }
}
#endif
