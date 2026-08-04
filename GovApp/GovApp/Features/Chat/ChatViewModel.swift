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

    init(chat: any ChatService, messages: [ChatMessage] = []) {
        self.chat = chat
        self.messages = messages
    }

    var canSend: Bool {
        !isReplying && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Seeds the transcript locally so the screen opens with a greeting rather
    /// than an empty scroll view. This never calls the model.
    func greet(_ username: String) {
        guard messages.isEmpty else { return }
        messages.append(ChatMessage(author: .assistant, text: L10n.Chat.greeting(username)))
    }

    func probeAvailability() async {
        isOffline = await !chat.isReachable()
    }

    func send(from sessions: SessionStore) async {
        guard canSend else { return }
        let prompt = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let history = messages

        draft = ""
        notice = nil
        messages.append(ChatMessage(author: .citizen, text: prompt))
        isReplying = true
        defer { isReplying = false }

        do {
            let reply = try await chat.reply(to: prompt, history: history)
            messages.append(ChatMessage(author: .assistant, text: reply))
            isOffline = false
        } catch let error as AppError {
            notice = error.userMessage
            isOffline = error == .assistantUnavailable || error == .network
            if error.invalidatesSession { sessions.signOut() }
        } catch {
            notice = AppError.assistantUnavailable.userMessage
            isOffline = true
        }
    }
}
