import Foundation

/// One full-bleed page of the onboarding carousel.
struct OnboardingSlide: Identifiable, Equatable, Sendable {
    let id: Int
    /// Asset-catalog name under `Assets.xcassets/Onboarding`.
    let imageName: String
    let headline: String

    static let all: [OnboardingSlide] = [
        OnboardingSlide(
            id: 0,
            imageName: "OnboardingStreet",
            headline: L10n.Onboarding.askQuestions
        ),
        OnboardingSlide(
            id: 1,
            imageName: "OnboardingTown",
            headline: L10n.Onboarding.talkToGovernment
        ),
        OnboardingSlide(
            id: 2,
            imageName: "OnboardingAvenue",
            headline: L10n.Onboarding.requestDocuments
        ),
    ]
}
