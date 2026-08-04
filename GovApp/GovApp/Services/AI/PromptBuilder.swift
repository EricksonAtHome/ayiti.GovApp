import Foundation

/// The ElloFive bridge is stateless — `POST /run/{model}` takes one string and
/// forgets it. Conversation memory therefore lives in the app, and this type is
/// what folds it back into a single `input`.
struct PromptBuilder: Sendable {
    /// How many prior exchanges to replay. Bounded because the runtime's
    /// context window is 8192 tokens.
    let contextTurns: Int
    let persona: String

    init(contextTurns: Int, persona: String = L10n.Chat.systemPersona) {
        self.contextTurns = max(0, contextTurns)
        self.persona = persona
    }

    func build(prompt: String, history: [ChatMessage]) -> String {
        var lines = [persona, ""]

        let replayed = history.suffix(contextTurns * 2)
        if !replayed.isEmpty {
            lines.append("Konvèsasyon anvan:")
            for message in replayed {
                lines.append("\(label(for: message.author)) \(message.text)")
            }
            lines.append("")
        }

        lines.append("\(label(for: .citizen)) \(prompt)")
        lines.append(label(for: .assistant))
        return lines.joined(separator: "\n")
    }

    private func label(for author: ChatMessage.Author) -> String {
        switch author {
        case .citizen: "Sitwayen:"
        case .assistant: "GOVTalk:"
        }
    }
}
