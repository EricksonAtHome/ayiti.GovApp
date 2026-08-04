import Foundation

/// The only error type screens ever see. Raw `URLError`s and status codes are
/// mapped here so a citizen never reads a system diagnostic.
enum AppError: Error, Equatable {
    case invalidCredentials
    case grantExpired
    case tooManyAttempts
    case identityUnavailable
    case assistantUnavailable
    case network
    case canceled

    var userMessage: String {
        switch self {
        case .invalidCredentials: L10n.Failure.invalidCredentials
        case .grantExpired: L10n.Failure.grantExpired
        case .tooManyAttempts: L10n.Failure.tooManyAttempts
        case .identityUnavailable: L10n.Failure.identityUnavailable
        case .assistantUnavailable: L10n.Failure.assistantUnavailable
        case .network: L10n.Failure.network
        case .canceled: L10n.Failure.canceled
        }
    }

    /// Whether the citizen must be returned to the welcome screen.
    var invalidatesSession: Bool {
        self == .grantExpired
    }
}
