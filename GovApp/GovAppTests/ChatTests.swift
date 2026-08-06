import XCTest

@testable import GovApp

final class PromptBuilderTests: XCTestCase {
    func testPersonaLeadsEveryPrompt() {
        let builder = PromptBuilder(contextTurns: 6, persona: "PERSONA")
        let prompt = builder.build(prompt: "Bonjou", history: [])

        XCTAssertTrue(prompt.hasPrefix("PERSONA"))
        XCTAssertTrue(prompt.contains("Sitwayen: Bonjou"))
        XCTAssertTrue(prompt.hasSuffix("GOVTalk:"), "the model is cued to answer next")
    }

    func testHistoryIsCappedToTheConfiguredTurns() {
        let history = (0..<20).map { index in
            ChatMessage(author: index.isMultiple(of: 2) ? .citizen : .assistant, text: "m\(index)")
        }
        let prompt = PromptBuilder(contextTurns: 2, persona: "P")
            .build(prompt: "kounye a", history: history)

        XCTAssertTrue(prompt.contains("m16"))
        XCTAssertFalse(prompt.contains("m15"), "only the last 2 turns (4 messages) are replayed")
    }

    func testZeroContextTurnsSendsOnlyTheNewPrompt() {
        let prompt = PromptBuilder(contextTurns: 0, persona: "P")
            .build(prompt: "sèl", history: [ChatMessage(author: .citizen, text: "ansyen")])

        XCTAssertFalse(prompt.contains("ansyen"))
        XCTAssertTrue(prompt.contains("sèl"))
    }
}

final class ChatErrorMappingTests: XCTestCase {
    func testBridgeFailuresReadAsAnUnavailableAssistant() {
        XCTAssertEqual(EllofiveClient.appError(for: .status(502)), .assistantUnavailable)
        XCTAssertEqual(EllofiveClient.appError(for: .status(400)), .assistantUnavailable)
        XCTAssertEqual(EllofiveClient.appError(for: .decoding), .assistantUnavailable)
        XCTAssertEqual(EllofiveClient.appError(for: .transport), .network)
    }
}

// These tests drive `@MainActor` types. The isolation is applied per test, and
// every isolated test is `async`, because Linux's corelibs-xctest cannot cast a
// class-isolated or synchronously-isolated XCTestCase method during discovery
// and aborts the whole run. Behaviour under Xcode is unchanged.
final class ChatViewModelTests: XCTestCase {
    @MainActor
    private func makeSessions() -> SessionStore {
        SessionStore(secrets: InMemorySecretStore(), defaults: freshDefaults())
    }

    @MainActor
    func testSendAppendsBothTurnsAndClearsTheDraft() async {
        let model = ChatViewModel(chat: StubChatService(canned: "Repons lan", delay: .zero))
        model.draft = "  Bonjou  "

        await model.send(from: makeSessions())

        XCTAssertEqual(model.messages.count, 2)
        XCTAssertEqual(model.messages.first?.text, "Bonjou", "the draft is trimmed")
        XCTAssertEqual(model.messages.first?.author, .citizen)
        XCTAssertEqual(model.messages.last?.text, "Repons lan")
        XCTAssertTrue(model.draft.isEmpty)
        XCTAssertNil(model.notice)
    }

    @MainActor
    func testBlankDraftIsNotSent() async {
        let model = ChatViewModel(chat: StubChatService(delay: .zero))
        model.draft = "   "

        XCTAssertFalse(model.canSend)
        await model.send(from: makeSessions())
        XCTAssertTrue(model.messages.isEmpty)
    }

    @MainActor
    func testUnreachableRuntimeSurfacesAnOfflineNotice() async {
        let model = ChatViewModel(chat: StubChatService(delay: .zero, reachable: false))
        model.draft = "Bonjou"

        await model.send(from: makeSessions())

        XCTAssertTrue(model.isOffline)
        XCTAssertEqual(model.notice, L10n.Failure.assistantUnavailable)
        XCTAssertEqual(model.messages.count, 1, "only the citizen's turn was recorded")
    }

    @MainActor
    func testANewModelIsEmptySoTheGreetingStateShows() async {
        XCTAssertTrue(ChatViewModel(chat: StubChatService()).isEmpty)
    }

    @MainActor
    func testASuggestionIsSentLikeATypedMessage() async {
        let model = ChatViewModel(chat: StubChatService(canned: "Repons", delay: .zero))
        let suggestion = ChatSuggestion.all[0]

        await model.submit(suggestion.prompt, from: makeSessions())

        XCTAssertEqual(model.messages.count, 2)
        XCTAssertEqual(model.messages.first?.text, suggestion.prompt)
        XCTAssertEqual(model.messages.first?.author, .citizen)
        XCTAssertFalse(model.isEmpty)
    }

    @MainActor
    func testRetryReplacesTheLastAnswerWithoutRepeatingTheQuestion() async {
        let model = ChatViewModel(chat: StubChatService(canned: "Premye", delay: .zero))
        let sessions = makeSessions()
        model.draft = "Bonjou"
        await model.send(from: sessions)

        await model.retryLast(from: sessions)

        XCTAssertEqual(model.messages.count, 2, "the question is asked once, not twice")
        XCTAssertEqual(model.messages.first?.text, "Bonjou")
        XCTAssertEqual(model.messages.last?.author, .assistant)
    }

    @MainActor
    func testRetryOnAnEmptyTranscriptDoesNothing() async {
        let model = ChatViewModel(chat: StubChatService(delay: .zero))

        await model.retryLast(from: makeSessions())

        XCTAssertTrue(model.messages.isEmpty)
    }

    @MainActor
    func testNewChatClearsTheTranscriptAndTheDraft() async {
        let model = ChatViewModel(chat: StubChatService(delay: .zero))
        model.draft = "Bonjou"
        await model.send(from: makeSessions())
        model.draft = "yon lòt bagay"

        model.startNewChat()

        XCTAssertTrue(model.isEmpty)
        XCTAssertTrue(model.draft.isEmpty)
        XCTAssertNil(model.notice)
    }

    /// Stopping is the citizen's choice, so it must not look like a failure.
    @MainActor
    func testACanceledReplyLeavesNoErrorBehind() async {
        let model = ChatViewModel(
            chat: StubChatService(delay: .zero, failure: .canceled)
        )
        model.draft = "Bonjou"

        await model.send(from: makeSessions())

        XCTAssertNil(model.notice)
        XCTAssertFalse(model.isOffline)
        XCTAssertEqual(model.messages.count, 1, "only the citizen's turn was recorded")
    }
}
