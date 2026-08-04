import XCTest

@testable import GovApp

final class GrantTokenTests: XCTestCase {
    func testMaskExposesOnlyTheLastSixCharacters() {
        let grant = GrantToken(
            value: "2f0b9c4ea1d64c8e9b3a7c15b0e2764d77",
            issuedAt: .now,
            ttl: 1800
        )
        XCTAssertEqual(grant.masked, "***764d77")
        XCTAssertFalse(grant.description.contains(grant.value))
    }

    func testCountdownFormatsAsMinutesAndSeconds() {
        let issuedAt = Date(timeIntervalSince1970: 0)
        let grant = GrantToken(value: "abc", issuedAt: issuedAt, ttl: 1800)

        XCTAssertEqual(grant.countdown(at: issuedAt.addingTimeInterval(10)), "29:50")
        XCTAssertEqual(grant.countdown(at: issuedAt.addingTimeInterval(1800)), "00:00")
    }

    func testCountdownDoesNotGoNegativePastExpiry() {
        let issuedAt = Date(timeIntervalSince1970: 0)
        let grant = GrantToken(value: "abc", issuedAt: issuedAt, ttl: 60)

        XCTAssertTrue(grant.hasExpired(at: issuedAt.addingTimeInterval(61)))
        XCTAssertEqual(grant.countdown(at: issuedAt.addingTimeInterval(600)), "00:00")
    }

    func testIssuedTokensAreDistinct() {
        let tokens = Set((0..<64).map { _ in GrantToken.issue(ttl: 60).value })
        XCTAssertEqual(tokens.count, 64)
    }
}

final class IdentityErrorMappingTests: XCTestCase {
    func testCredentialFailuresAreDistinguishedFromOutages() {
        XCTAssertEqual(LiveIdentityService.appError(for: .status(401)), .invalidCredentials)
        XCTAssertEqual(LiveIdentityService.appError(for: .status(403)), .invalidCredentials)
        XCTAssertEqual(LiveIdentityService.appError(for: .status(410)), .grantExpired)
        XCTAssertEqual(LiveIdentityService.appError(for: .status(429)), .tooManyAttempts)
        XCTAssertEqual(LiveIdentityService.appError(for: .status(500)), .identityUnavailable)
        XCTAssertEqual(LiveIdentityService.appError(for: .transport), .network)
        XCTAssertEqual(LiveIdentityService.appError(for: .canceled), .canceled)
    }

    /// `id.ayiti.io` answers unknown paths with its SPA shell. An HTML body must
    /// never be read as a rejected credential — it means the route is missing.
    func testHTMLResponseIsAnOutageNotABadPIN() {
        let failure = HTTPFailure.notJSON(contentType: "text/html; charset=utf-8")
        XCTAssertEqual(LiveIdentityService.appError(for: failure), .identityUnavailable)
    }
}

final class SessionCallbackTests: XCTestCase {
    private let grant = GrantToken(value: "abc123", issuedAt: .now, ttl: 1800)

    func testParsesHostedCallback() throws {
        let url = try XCTUnwrap(
            URL(
                string: "govapp://auth/callback?session=tok-1&expires_in=600"
                    + "&username=Jean&gov_url_id=gov.ayiti.io/jean"
            )
        )
        let session = try XCTUnwrap(Session(callbackURL: url, grant: grant))

        XCTAssertEqual(session.token, "tok-1")
        XCTAssertEqual(session.username, "Jean")
        XCTAssertEqual(session.govURLID, "gov.ayiti.io/jean")
        XCTAssertEqual(session.expiresAt.timeIntervalSinceNow, 600, accuracy: 2)
    }

    func testCallbackWithoutSessionIsRejected() throws {
        let url = try XCTUnwrap(URL(string: "govapp://auth/callback?error=denied"))
        XCTAssertNil(Session(callbackURL: url, grant: grant))
    }

    func testSessionDescriptionRedactsTheToken() {
        XCTAssertFalse(Session.preview.description.contains(Session.preview.token))
    }

    func testSessionHonoursClockSkew() {
        let session = Session(
            token: "t",
            username: "Jean",
            govURLID: "",
            expiresAt: .now.addingTimeInterval(10)
        )
        XCTAssertFalse(session.isValid(), "10s of validity is inside the 30s skew window")
    }
}
