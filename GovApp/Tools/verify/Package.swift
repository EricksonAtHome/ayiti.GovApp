// swift-tools-version: 5.9
import PackageDescription

// Compiles GovApp's platform-independent logic on Linux and runs its tests, so
// the parts of the app that do not need UIKit can be verified without a Mac.
//
//     cd GovApp/Tools/verify && swift test
//
// Everything under Sources/GovApp and Tests/GovAppTests is a symlink to the
// real file in the app target — nothing is copied, so this cannot drift. The
// only additions are Shims/PlatformShims.swift, which stands in for the three
// Apple-only pieces (Keychain, WebAuthPresenter, SecRandomCopyBytes) and
// compiles to nothing on Apple platforms.
//
// SwiftUI views, the design system, and the Xcode project itself are NOT
// covered here and still require `xcodebuild` on macOS.
let package = Package(
    name: "GovAppVerify",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "GovApp"),
        .testTarget(name: "GovAppTests", dependencies: ["GovApp"]),
    ]
)
