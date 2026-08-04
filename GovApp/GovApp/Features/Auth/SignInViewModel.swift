import Foundation
import Observation

@Observable
@MainActor
final class SignInViewModel {
    var hid = ""
    var pin = ""

    private(set) var grant: GrantToken
    private(set) var countdown: String
    private(set) var isWorking = false
    private(set) var notice: String?

    @ObservationIgnored private let identity: any IdentityService
    @ObservationIgnored private let ttl: TimeInterval
    @ObservationIgnored private var ticker: Task<Void, Never>?

    init(identity: any IdentityService, ttl: TimeInterval = AppConfig.current.sessionTTL) {
        self.identity = identity
        self.ttl = ttl
        let grant = GrantToken.issue(ttl: ttl)
        self.grant = grant
        countdown = grant.countdown()
    }

    var collectsCredentialsInApp: Bool { identity.collectsCredentialsInApp }

    var canSubmit: Bool {
        guard !isWorking else { return false }
        guard collectsCredentialsInApp else { return true }
        return Credentials(hid: hid, pin: pin).isComplete
    }

    func startCountdown() {
        guard ticker == nil else { return }
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.tick()
            }
        }
    }

    func stopCountdown() {
        ticker?.cancel()
        ticker = nil
    }

    func submit(into sessions: SessionStore) async {
        guard canSubmit else { return }
        let credentials = Credentials(hid: hid, pin: pin)

        isWorking = true
        notice = nil
        defer { isWorking = false }

        do {
            let session = try await identity.signIn(credentials, grant: grant)
            pin = ""
            sessions.save(session)
        } catch let error as AppError {
            fail(with: error)
        } catch {
            fail(with: .identityUnavailable)
        }
    }

    private func fail(with error: AppError) {
        // The PIN is cleared on every failure so a shoulder-surfer never gets a
        // second look at a partially entered code.
        pin = ""
        notice = error.userMessage
        if error == .grantExpired { renewGrant() }
    }

    private func tick() {
        countdown = grant.countdown()
        guard grant.hasExpired() else { return }
        renewGrant()
        notice = AppError.grantExpired.userMessage
    }

    private func renewGrant() {
        grant = GrantToken.issue(ttl: ttl)
        countdown = grant.countdown()
        pin = ""
    }
}
