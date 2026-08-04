import Foundation

struct ChatMessage: Identifiable, Sendable, Equatable {
    enum Author: Sendable, Equatable {
        case citizen
        case assistant
    }

    let id: UUID
    let author: Author
    let text: String
    let sentAt: Date

    init(id: UUID = UUID(), author: Author, text: String, sentAt: Date = .now) {
        self.id = id
        self.author = author
        self.text = text
        self.sentAt = sentAt
    }
}
