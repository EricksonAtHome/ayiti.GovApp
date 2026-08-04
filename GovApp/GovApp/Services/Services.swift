import SwiftUI

/// Everything a view might need to talk to the outside world.
///
/// Views receive this from the environment and never construct a service
/// themselves, so a preview or a test can swap in stubs wholesale.
struct Services: Sendable {
    let identity: any IdentityService
    let chat: any ChatService

    static var live: Services {
        let config = AppConfig.current
        return Services(
            identity: config.identityMode == .hosted
                ? HostedIdentityService(config: config)
                : LiveIdentityService(config: config),
            chat: EllofiveClient(config: config)
        )
    }

    static let stub = Services(identity: StubIdentityService(), chat: StubChatService())
}

/// Defaults to stubs so a `#Preview` can never reach the network by accident.
/// `GovAppApp` injects `.live` at the root.
private struct ServicesKey: EnvironmentKey {
    static let defaultValue = Services.stub
}

extension EnvironmentValues {
    var services: Services {
        get { self[ServicesKey.self] }
        set { self[ServicesKey.self] = newValue }
    }
}
