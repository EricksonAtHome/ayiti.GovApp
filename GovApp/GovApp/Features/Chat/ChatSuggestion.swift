import Foundation

/// A starter chip on the chat empty state. Tapping one sends `prompt` as if the
/// citizen had typed it, so there is no separate code path for suggestions.
///
/// These cover the services citizens ask about most. The wording is a first
/// draft — it is the only place to edit it.
struct ChatSuggestion: Identifiable, Equatable, Sendable {
    let id: Int
    let label: String
    let systemImage: String
    let prompt: String

    static let all: [ChatSuggestion] = [
        ChatSuggestion(
            id: 0,
            label: "Paspò",
            systemImage: "airplane",
            prompt: "Kijan pou m fè oswa renouvle paspò mwen?"
        ),
        ChatSuggestion(
            id: 1,
            label: "Kat idantite",
            systemImage: "person.text.rectangle",
            prompt: "Kijan pou m jwenn kat idantifikasyon nasyonal mwen?"
        ),
        ChatSuggestion(
            id: 2,
            label: "Batistè",
            systemImage: "doc.text",
            prompt: "Kijan pou m mande yon kopi batistè mwen?"
        ),
        ChatSuggestion(
            id: 3,
            label: "Taks",
            systemImage: "percent",
            prompt: "Ki taks mwen dwe peye epi ki lè?"
        ),
        ChatSuggestion(
            id: 4,
            label: "Jwenn yon biwo",
            systemImage: "mappin.and.ellipse",
            prompt: "Ki biwo leta ki pi pre m epi ki lè li louvri?"
        ),
    ]
}
