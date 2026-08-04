# Linux verification package

Compiles GovApp's platform-independent logic and runs its test suite on Linux,
so the app can be checked without a Mac.

```bash
cd GovApp/Tools/verify
swift test
```

Everything under `Sources/GovApp/` and `Tests/GovAppTests/` is a **symlink** to
the real file in the app target, so this cannot drift from what Xcode builds.
The only extra file is `Sources/GovApp/PlatformShims.swift`, which stands in for
the three Apple-only pieces and compiles to nothing on Apple platforms
(`#if !canImport(Security)`):

| Shimmed | Real implementation |
| --- | --- |
| `SecRandomCopyBytes` | Security framework |
| `Keychain` | `Services/Session/Keychain.swift` |
| `WebAuthPresenter` | `Services/Identity/WebAuthPresenter.swift` |

## What this does and does not cover

Covered: `AppConfig`, `HTTPClient`, `AppError`, `GrantToken`, `Session`,
`SessionStore`, the identity and chat services, `PromptBuilder`, and both view
models — 27 tests.

**Not covered:** every SwiftUI view, the design system, `Services.swift`, the
asset catalog, and the Xcode project itself. Those still need
`xcodebuild -project GovApp/GovApp.xcodeproj -scheme GovApp … build test` on
macOS, which remains the authoritative check before shipping.
