import XCTest

@testable import GovApp

/// A throwaway `UserDefaults` suite so tests never touch real app state.
func freshDefaults(function: String = #function) -> UserDefaults {
    let name = "io.ayiti.govapp.tests.\(function).\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: name) else {
        return .standard
    }
    defaults.removePersistentDomain(forName: name)
    return defaults
}

// These tests drive `@MainActor` types. The isolation is applied per test, and
// every isolated test is `async`, because Linux's corelibs-xctest cannot cast a
// class-isolated or synchronously-isolated XCTestCase method during discovery
// and aborts the whole run. Behaviour under Xcode is unchanged.
final class SessionStoreTests: XCTestCase {
    @MainActor
    func testSavedSessionIsRestoredByANewStore() async {
        let secrets = InMemorySecretStore()
        let defaults = freshDefaults()

        SessionStore(secrets: secrets, defaults: defaults).save(.preview)
        let restored = SessionStore(secrets: secrets, defaults: defaults)

        XCTAssertTrue(restored.isSignedIn)
        XCTAssertEqual(restored.session?.username, Session.preview.username)
        XCTAssertEqual(restored.session?.token, Session.preview.token)
    }

    @MainActor
    func testSignOutClearsTheTokenButRemembersTheCitizen() async {
        let secrets = InMemorySecretStore()
        let store = SessionStore(secrets: secrets, defaults: freshDefaults())
        store.save(.preview)

        store.signOut()

        XCTAssertFalse(store.isSignedIn)
        XCTAssertNil(secrets.string(for: "io.ayiti.govapp.session"))
        XCTAssertEqual(store.lastKnownProfile?.username, Session.preview.username)
    }

    @MainActor
    func testForgetClearsTheProfileToo() async {
        let store = SessionStore(secrets: InMemorySecretStore(), defaults: freshDefaults())
        store.save(.preview)

        store.forget()

        XCTAssertNil(store.lastKnownProfile)
        XCTAssertNil(store.session)
    }

    @MainActor
    func testExpiredSessionIsNotRestored() async {
        let secrets = InMemorySecretStore()
        let defaults = freshDefaults()
        let stale = Session(
            token: "stale",
            username: "Jean",
            govURLID: "",
            expiresAt: .now.addingTimeInterval(-1)
        )

        SessionStore(secrets: secrets, defaults: defaults).save(stale)
        let restored = SessionStore(secrets: secrets, defaults: defaults)

        XCTAssertNil(restored.session)
        XCTAssertNil(secrets.string(for: "io.ayiti.govapp.session"), "the stale token is purged")
    }

    @MainActor
    func testDiscardIfExpiredEndsAnAgedOutSession() async {
        let store = SessionStore(secrets: InMemorySecretStore(), defaults: freshDefaults())
        store.save(.preview)

        store.discardIfExpired(at: .now.addingTimeInterval(3600))

        XCTAssertNil(store.session)
    }
}

final class SignInViewModelTests: XCTestCase {
    @MainActor
    func testSubmitStoresTheSessionOnSuccess() async {
        let sessions = SessionStore(secrets: InMemorySecretStore(), defaults: freshDefaults())
        let model = SignInViewModel(
            identity: StubIdentityService(delay: .zero),
            ttl: 1800
        )
        model.hid = "HID-1"
        model.pin = "1234"

        await model.submit(into: sessions)

        XCTAssertTrue(sessions.isSignedIn)
        XCTAssertTrue(model.pin.isEmpty, "the PIN is released as soon as it is used")
        XCTAssertNil(model.notice)
    }

    @MainActor
    func testRejectedCredentialsClearThePINAndExplainWhy() async {
        let sessions = SessionStore(secrets: InMemorySecretStore(), defaults: freshDefaults())
        let model = SignInViewModel(
            identity: StubIdentityService(result: .failure(.invalidCredentials), delay: .zero),
            ttl: 1800
        )
        model.hid = "HID-1"
        model.pin = "0000"

        await model.submit(into: sessions)

        XCTAssertFalse(sessions.isSignedIn)
        XCTAssertTrue(model.pin.isEmpty)
        XCTAssertEqual(model.notice, L10n.Failure.invalidCredentials)
    }

    @MainActor
    func testIncompleteCredentialsBlockSubmission() async {
        let model = SignInViewModel(identity: StubIdentityService(), ttl: 1800)
        XCTAssertFalse(model.canSubmit)

        model.hid = "HID-1"
        XCTAssertFalse(model.canSubmit, "a HID alone is not enough")

        model.pin = "1234"
        XCTAssertTrue(model.canSubmit)
    }

    @MainActor
    func testHostedFlowDoesNotRequireTypedCredentials() async {
        let model = SignInViewModel(identity: HostedIdentityService(), ttl: 1800)

        XCTAssertFalse(model.collectsCredentialsInApp)
        XCTAssertTrue(model.canSubmit, "the hosted page collects the HID and PIN itself")
    }
}
