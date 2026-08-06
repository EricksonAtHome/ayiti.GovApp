import SwiftUI

/// The signed-out landing experience: full-bleed photographs of Haiti that snap
/// from page to page, each carrying one line about what GovApp is for.
struct OnboardingView: View {
    let profile: SessionStore.Profile?
    let onFinish: () -> Void

    @State private var index = 0

    private let slides = OnboardingSlide.all

    var body: some View {
        TabView(selection: $index) {
            ForEach(slides) { slide in
                SlidePage(slide: slide).tag(slide.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .background(Brand.ink)
        .overlay(alignment: .top) { header }
        .overlay(alignment: .bottom) { actionBar }
        .animation(.easeInOut(duration: 0.28), value: index)
    }

    private var isLastSlide: Bool { index == slides.count - 1 }

    private func advance() {
        if isLastSlide {
            onFinish()
        } else {
            index += 1
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Brand.Metric.stack + 6) {
            PageProgress(count: slides.count, current: index)
            AyitiLockup(wordmark: Brand.onPhoto)
                .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
        }
        .padding(.horizontal, Brand.Metric.gutter)
        .padding(.top, Brand.Metric.stack)
    }

    /// On the last slide with nobody to name, the pill fills the bar rather than
    /// leaving a gap where the swipe hint used to be.
    private var pillFillsBar: Bool { isLastSlide && !hasKnownCitizen }

    private var hasKnownCitizen: Bool {
        !(profile?.username ?? "").isEmpty
    }

    private var actionBar: some View {
        HStack(spacing: Brand.Metric.stack) {
            Button(action: advance) {
                Text(L10n.Onboarding.advance)
                    .font(Brand.Font.buttonLabel)
                    .foregroundStyle(Brand.onPhoto)
                    .padding(.horizontal, 28)
                    .frame(maxWidth: pillFillsBar ? .infinity : nil)
                    .frame(height: Brand.Metric.pillHeight)
                    .background(Capsule().fill(Brand.ink))
            }

            if !pillFillsBar {
                Spacer(minLength: 0)
                trailingAffordance
                    .padding(.trailing, Brand.Metric.stack)
            }
        }
        .padding(.leading, Brand.Metric.stack)
        .frame(height: Brand.Metric.barHeight)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().strokeBorder(Brand.onPhoto.opacity(0.25)))
        }
        .padding(.horizontal, Brand.Metric.gutter)
        .padding(.bottom, Brand.Metric.stack)
    }

    /// A swipe hint until the last page, where the returning citizen is named
    /// so "Kontinye" reads as "continue as me".
    @ViewBuilder
    private var trailingAffordance: some View {
        if !isLastSlide {
            Button(action: advance) {
                HStack(spacing: 8) {
                    Text(L10n.Onboarding.slideHint)
                    Image(systemName: "arrow.right")
                }
                .font(Brand.Font.body)
                .foregroundStyle(Brand.onPhoto)
            }
        } else if let profile, hasKnownCitizen {
            HStack(spacing: 8) {
                Text(profile.username)
                    .font(Brand.Font.body)
                    .foregroundStyle(Brand.onPhoto)
                    .lineLimit(1)
                AvatarCircle(
                    size: 36,
                    initial: profile.username.first.map { String($0).uppercased() }
                )
            }
            .accessibilityLabel(profile.username)
        }
    }
}

private struct SlidePage: View {
    let slide: OnboardingSlide

    var body: some View {
        GeometryReader { proxy in
            Image(slide.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .overlay { Brand.photoScrim }
                .overlay(alignment: .bottomLeading) {
                    Text(slide.headline)
                        .font(Brand.Font.headline)
                        .foregroundStyle(Brand.onPhoto)
                        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Brand.Metric.gutter)
                        // Clears the floating action bar and the home indicator.
                        .padding(.bottom, Brand.Metric.barHeight + 64)
                }
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(slide.headline)
    }
}

/// The segmented page indicator across the top.
private struct PageProgress: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(Brand.onPhoto.opacity(index == current ? 1 : 0.35))
                    .frame(height: Brand.Metric.progressTrack)
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 4, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.Onboarding.page(current + 1, of: count))
    }
}

#Preview("Onboarding") {
    OnboardingView(profile: nil) {}
}

#Preview("Returning citizen") {
    OnboardingView(
        profile: SessionStore.Profile(
            username: Session.preview.username,
            govURLID: Session.preview.govURLID
        )
    ) {}
}
