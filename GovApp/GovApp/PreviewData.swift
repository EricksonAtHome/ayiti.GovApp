import Foundation

/// Fixtures for `#Preview` and tests. The design mockups use `{username}` and
/// `{gov.url.id}` placeholders; these are their concrete stand-ins.
extension Session {
    static let preview = Session(
        token: "preview-token",
        username: "Jean Baptiste",
        govURLID: "gov.ayiti.io/jbaptiste",
        expiresAt: .now.addingTimeInterval(1800)
    )
}

extension ChatMessage {
    static let previewTranscript: [ChatMessage] = [
        ChatMessage(
            author: .assistant,
            text: "Bonjou Jean, paspò ou an pare pou l pati."
        ),
        ChatMessage(
            author: .citizen,
            text: "Mèsi Gov Ayiti, èske ou gen yon adrès?"
        ),
    ]
}
