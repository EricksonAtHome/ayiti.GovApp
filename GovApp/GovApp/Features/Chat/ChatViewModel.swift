import Foundation
import Observation

@Observable
@MainActor
final class ChatViewModel {
    private(set) var messages: [ChatMessage]
    var draft = ""
    private(set) var isReplying = false
    private(set) var isOffline = false
    private(set) var notice: String?

    @ObservationIgnored private let chat: any ChatService
    /// Handle on the in-flight reply so the citizen can stop it. A local model
    /// can take a while, and waiting with no way out is not acceptable.
    @ObservationIgnored private var pending: Task<Void, Never>?

    init(chat: any ChatService, messages: [ChatMessage] = []) {
        self.chat = chat
        self.messages = messages
    }

    /// Drives the empty state: greeting plus suggestion chips.
    var isEmpty: Bool { messages.isEmpty }

    var canSend: Bool {
        !isReplying && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func probeAvailability() async {
        isOffline = await !chat.isReachable()
    }

    // MARK: - Entry points used by the view

    func startSend(from sessions: SessionStore) {
        start { await self.send(from: sessions) }
    }

    func startSuggestion(_ suggestion: ChatSuggestion, from sessions: SessionStore) {
        start { await self.submit(suggestion.prompt, from: sessions) }
    }

    func startRetry(from sessions: SessionStore) {
        start { await self.retryLast(from: sessions) }
    }

    func stop() {
        pending?.cancel()
        pending = nil
    }

    func startNewChat() {
        stop()
        messages.removeAll()
        draft = ""
        notice = nil
    }

    // MARK: - Awaitable core

    func send(from sessions: SessionStore) async {
        guard canSend else { return }
        let prompt = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        draft = ""
        await submit(prompt, from: sessions)
    }

    /// Shared by the composer and the suggestion chips, so a suggestion is
    /// indistinguishable from something the citizen typed.
    func submit(_ prompt: String, from sessions: SessionStore) async {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isReplying else { return }

        messages.append(ChatMessage(author: .citizen, text: trimmed))
        await answer(trimmed, from: sessions)
    }

    /// Drops the last reply and asks again — for when an answer was unhelpful or
    /// the runtime was briefly unreachable.
    func retryLast(from sessions: SessionStore) async {
        guard !isReplying else { return }
        if messages.last?.author == .assistant { messages.removeLast() }
        guard let prompt = messages.last(where: { $0.author == .citizen })?.text else { return }
        await answer(prompt, from: sessions)
    }

    // MARK: - Private

    private func start(_ work: @escaping @MainActor () async -> Void) {
        pending?.cancel()
        pending = Task { await work() }
    }

    private func answer(_ prompt: String, from sessions: SessionStore) async {
        // History excludes the turn being answered; PromptBuilder adds it back.
        let history = Array(messages.dropLast())

        notice = nil
        isReplying = true
        defer { isReplying = false }

        do {
            let reply = try await chat.reply(to: prompt, history: history)
            messages.append(ChatMessage(author: .assistant, text: reply))
            isOffline = false
        } catch let error as AppError {
            // Stopping is a choice, not a failure — say nothing.
            guard error != .canceled else { return }
            notice = error.userMessage
            isOffline = error == .assistantUnavailable || error == .network
            if error.invalidatesSession { sessions.signOut() }
        } catch {
            notice = AppError.assistantUnavailable.userMessage
            isOffline = true
        }
    }
}
