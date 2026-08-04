import SwiftUI

/// GOVTalk AI — the signed-in conversation screen.
struct ChatView: View {
    let session: Session

    @Environment(\.services) private var services
    @State private var model: ChatViewModel?

    var body: some View {
        ZStack {
            Brand.background.ignoresSafeArea()
            if let model {
                ChatContent(model: model, session: session)
            }
        }
        .task {
            let model = model ?? ChatViewModel(chat: services.chat)
            self.model = model
            model.greet(session.username)
            await model.probeAvailability()
        }
    }
}

private struct ChatContent: View {
    @Bindable var model: ChatViewModel
    let session: Session

    @Environment(SessionStore.self) private var sessions
    @FocusState private var isComposerFocused: Bool
    @State private var isConfirmingSignOut = false

    var body: some View {
        VStack(spacing: 0) {
            header

            transcript

            if model.isOffline {
                NoticeBanner(message: model.notice ?? L10n.Chat.offline)
                    .padding(.horizontal, Brand.Metric.gutter)
                    .padding(.bottom, Brand.Metric.stack)
            }

            composer

            Text(session.govURLID)
                .font(Brand.Font.micro)
                .foregroundStyle(Brand.inkMuted)
                .padding(.top, 6)
        }
        .padding(.horizontal, Brand.Metric.gutter)
        .confirmationDialog(
            L10n.Chat.signOut,
            isPresented: $isConfirmingSignOut,
            titleVisibility: .visible
        ) {
            Button(L10n.Chat.signOut, role: .destructive) { sessions.signOut() }
        }
    }

    private var header: some View {
        HStack {
            AyitiLockup()
            Spacer()
            Text(session.username)
                .font(Brand.Font.body)
                .foregroundStyle(Brand.ink)
            Button {
                isConfirmingSignOut = true
            } label: {
                AvatarCircle(size: 44, initial: session.initial)
            }
            .accessibilityLabel(L10n.Chat.signOut)
        }
        .padding(.top, 8)
        .padding(.bottom, Brand.Metric.section)
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Brand.Metric.section) {
                    ForEach(model.messages) { message in
                        MessageRow(message: message, username: session.username, initial: session.initial)
                            .id(message.id)
                    }
                    if model.isReplying {
                        Text(L10n.Chat.thinking)
                            .font(Brand.Font.caption)
                            .foregroundStyle(Brand.inkMuted)
                            .id(Self.thinkingAnchor)
                    }
                }
                .padding(.bottom, Brand.Metric.section)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: model.messages.count) { _, _ in
                guard let last = model.messages.last else { return }
                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
            }
            .onChange(of: model.isReplying) { _, isReplying in
                guard isReplying else { return }
                withAnimation { proxy.scrollTo(Self.thinkingAnchor, anchor: .bottom) }
            }
        }
    }

    private var composer: some View {
        HStack(spacing: Brand.Metric.stack) {
            TextField(
                "",
                text: $model.draft,
                prompt: Text(L10n.Chat.composerPlaceholder).foregroundColor(Brand.placeholder),
                axis: .vertical
            )
            .lineLimit(1...4)
            .font(Brand.Font.body)
            .foregroundStyle(Brand.ink)
            .focused($isComposerFocused)
            .submitLabel(.send)
            .accessibilityLabel(L10n.Chat.composerPlaceholder)

            Button {
                Task { await model.send(from: sessions) }
            } label: {
                Image(systemName: "paperplane")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(model.canSend ? Brand.ink : Brand.placeholder)
            }
            .disabled(!model.canSend)
            .accessibilityLabel(L10n.Chat.send)
        }
        .padding(.horizontal, 20)
        .frame(minHeight: Brand.Metric.wideButtonHeight)
        .background(
            RoundedRectangle(cornerRadius: Brand.Metric.composerRadius, style: .continuous)
                .fill(Brand.surface)
        )
    }

    private static let thinkingAnchor = "govtalk.thinking"
}

private struct MessageRow: View {
    let message: ChatMessage
    let username: String
    let initial: String

    /// Inset applied to the opposite edge so the two speakers read as columns.
    private let columnInset: CGFloat = 56

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            attribution
            Text(message.text)
                .font(Brand.Font.body)
                .foregroundStyle(Brand.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, message.author == .citizen ? columnInset : 0)
        .padding(.trailing, message.author == .assistant ? columnInset : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var attribution: some View {
        HStack(spacing: 6) {
            Spacer(minLength: 0)
            switch message.author {
            case .assistant:
                Text(L10n.Chat.assistant)
                    .font(Brand.Font.micro)
                    .foregroundStyle(Brand.ink)
                AyitiMark(height: 14)
            case .citizen:
                Text(username)
                    .font(Brand.Font.micro)
                    .foregroundStyle(Brand.inkMuted)
                AvatarCircle(size: 24, initial: initial)
            }
        }
    }
}

#Preview("GOVTalk") {
    ChatView(session: .preview)
        .environment(SessionStore(secrets: InMemorySecretStore(), defaults: .previewSuite))
        .environment(\.services, .stub)
}

#Preview("Offline") {
    ChatView(session: .preview)
        .environment(SessionStore(secrets: InMemorySecretStore(), defaults: .previewSuite))
        .environment(
            \.services,
            Services(
                identity: StubIdentityService(),
                chat: StubChatService(reachable: false)
            )
        )
}
