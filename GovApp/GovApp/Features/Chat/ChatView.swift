import SwiftUI
import UIKit

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

            if model.isEmpty {
                emptyState
            } else {
                transcript
            }

            if let notice = model.notice {
                NoticeBanner(message: notice)
                    .padding(.bottom, Brand.Metric.stack)
            }

            composer
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

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Brand.Metric.stack) {
            AyitiLockup(height: 28)
            Spacer(minLength: 0)

            if !model.isEmpty {
                CircleIconButton(systemImage: "square.and.pencil", size: 38) {
                    model.startNewChat()
                }
                .accessibilityLabel(L10n.Chat.newChat)
            }

            Button {
                isConfirmingSignOut = true
            } label: {
                AvatarCircle(size: 38, initial: session.initial)
            }
            .accessibilityLabel(L10n.Chat.signOut)
        }
        .padding(.top, 8)
        .padding(.bottom, Brand.Metric.stack)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            AyitiMark(height: 64)

            Text(L10n.Chat.greeting(session.username))
                .font(Brand.Font.title)
                .foregroundStyle(Brand.ink)
                .multilineTextAlignment(.center)
                .padding(.top, Brand.Metric.section)

            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(ChatSuggestion.all) { suggestion in
                    BrandChip(title: suggestion.label, systemImage: suggestion.systemImage) {
                        model.startSuggestion(suggestion, from: sessions)
                    }
                }
            }
            .padding(.top, Brand.Metric.section)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Transcript

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Brand.Metric.section) {
                    ForEach(model.messages) { message in
                        MessageView(message: message) {
                            model.startRetry(from: sessions)
                        }
                        .id(message.id)
                    }

                    if model.isReplying {
                        GeneratingPill().id(Self.thinkingAnchor)
                    }
                }
                .padding(.vertical, Brand.Metric.stack)
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

    // MARK: - Composer

    private var composer: some View {
        VStack(spacing: Brand.Metric.stack) {
            HStack(alignment: .bottom, spacing: Brand.Metric.stack) {
                TextField(
                    "",
                    text: $model.draft,
                    prompt: Text(L10n.Chat.composerPlaceholder)
                        .foregroundColor(Brand.placeholder),
                    axis: .vertical
                )
                .lineLimit(1...5)
                .font(Brand.Font.body)
                .foregroundStyle(Brand.ink)
                .focused($isComposerFocused)
                .accessibilityLabel(L10n.Chat.composerPlaceholder)

                if model.isReplying {
                    CircleIconButton(systemImage: "stop.fill", filled: true) {
                        model.stop()
                    }
                    .accessibilityLabel(L10n.General.stop)
                } else {
                    CircleIconButton(
                        systemImage: "arrow.up",
                        filled: true,
                        isEnabled: model.canSend
                    ) {
                        model.startSend(from: sessions)
                    }
                    .accessibilityLabel(L10n.Chat.send)
                }
            }

            HStack(spacing: 6) {
                AyitiMark(height: 12)
                Text(L10n.Chat.model(AppConfig.current.aiModel))
                    .font(Brand.Font.micro)
                    .foregroundStyle(Brand.inkMuted)
                Spacer(minLength: 0)
                Text(session.govURLID)
                    .font(Brand.Font.micro)
                    .foregroundStyle(Brand.inkMuted)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Brand.Metric.cardRadius, style: .continuous)
                .fill(Brand.background)
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.Metric.cardRadius, style: .continuous)
                        .strokeBorder(Brand.line)
                )
                .shadow(color: .black.opacity(0.05), radius: 16, y: 4)
        )
        .padding(.bottom, Brand.Metric.stack)
    }

    private static let thinkingAnchor = "govtalk.thinking"
}

// MARK: - Messages

private struct MessageView: View {
    let message: ChatMessage
    let onRetry: () -> Void

    var body: some View {
        switch message.author {
        case .citizen: citizenBubble
        case .assistant: assistantAnswer
        }
    }

    private var citizenBubble: some View {
        HStack {
            Spacer(minLength: 44)
            Text(message.text)
                .font(Brand.Font.body)
                .foregroundStyle(Brand.ink)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: Brand.Metric.bubbleRadius, style: .continuous)
                        .fill(Brand.surface)
                )
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var assistantAnswer: some View {
        VStack(alignment: .leading, spacing: Brand.Metric.stack) {
            HStack(spacing: 7) {
                AyitiMark(height: 15)
                Text(L10n.Chat.answer)
                    .font(Brand.Font.sectionLabel)
                    .foregroundStyle(Brand.ink)
            }

            Text(formatted)
                .font(Brand.Font.body)
                .foregroundStyle(Brand.ink)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)

            actions
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actions: some View {
        HStack(spacing: 8) {
            BrandChip(title: L10n.Chat.copy, systemImage: "doc.on.doc") {
                UIPasteboard.general.string = message.text
            }
            BrandChip(title: L10n.Chat.retry, systemImage: "arrow.clockwise", action: onRetry)
            ShareLink(item: message.text) {
                ChipLabel(title: L10n.Chat.share, systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
    }

    /// The model replies in markdown. Inline-only parsing keeps bold and code
    /// spans while leaving line breaks and list dashes exactly as sent — full
    /// block parsing would collapse them, since SwiftUI's `Text` cannot render
    /// list presentation intents anyway.
    private var formatted: AttributedString {
        (try? AttributedString(
            markdown: message.text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        )) ?? AttributedString(message.text)
    }
}

private struct GeneratingPill: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            AyitiMark(height: 14)
            // `ink`, not `inkMuted`: 15pt medium is not "large text", and
            // inkMuted on surface is 4.42:1 — just short of 4.5:1.
            Text(L10n.Chat.thinking)
                .font(Brand.Font.chip)
                .foregroundStyle(Brand.ink)
        }
        .padding(.horizontal, 14)
        .frame(height: Brand.Metric.chipHeight)
        .background(
            Capsule()
                .fill(Brand.surface)
        )
        .opacity(pulse ? 0.55 : 1)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}

#Preview("Empty") {
    ChatView(session: .preview)
        .environment(SessionStore(secrets: InMemorySecretStore(), defaults: .previewSuite))
        .environment(\.services, .stub)
}

#Preview("Conversation") {
    ChatView(session: .preview)
        .environment(SessionStore(secrets: InMemorySecretStore(), defaults: .previewSuite))
        .environment(
            \.services,
            Services(identity: StubIdentityService(), chat: StubChatService())
        )
}
