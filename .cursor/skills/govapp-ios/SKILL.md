---
name: govapp-ios
description: Builds and extends GovApp, the ayiti.io SwiftUI iOS app — brand design system, Kreyòl UI copy, HID/PIN sign-in against the id.ayiti.io identity server, and GOVTalk AI chat backed by the ElloFive local LLM runtime. Use when adding screens, colors, components, auth flows, or AI chat features to GovApp, or when the user mentions ayiti.io, GOVTalk, HID, ElloFive, or the GovApp Xcode project.
---

# GovApp (ayiti.io iOS)

GovApp is the citizen-facing iOS client for the Republic of Haiti's `ayiti.io`
platform. It signs a citizen in with their Ayiti Identity (HID) and secret PIN,
then opens **GOVTalk AI**, a chat assistant served by the
[ElloFive](https://github.com/EricksonAtHome/ElloFive) LLM runtime.

## Project layout

```
GovApp/
├── GovApp.xcodeproj/          Xcode 16 project (synchronized file groups)
├── GovApp/
│   ├── GovAppApp.swift        @main entry + root routing
│   ├── AppConfig.swift        All endpoints/flags, read from Info.plist
│   ├── DesignSystem/          Brand tokens, ayiti.io logo, shared controls
│   ├── Features/Welcome/      Screen 3 — signed-out landing
│   ├── Features/Auth/         Screen 1 — HID + PIN sign-in
│   ├── Features/Chat/         Screen 2 — GOVTalk AI conversation
│   └── Services/              Identity, session, keychain, ElloFive client
└── GovAppTests/
```

Xcode 16 **synchronized root groups** are used, so new files under `GovApp/` are
picked up automatically. Do not hand-edit `project.pbxproj` to add a source file.

## Non-negotiable rules

1. **Never hardcode a URL, port, model name, or scheme in a view or service.**
   Every one lives in `AppConfig` and is overridable from `Info.plist`.
2. **Never log or persist a PIN.** The PIN is passed to `IdentityService` and
   released; only the returned session token is stored, and only in the Keychain.
3. **UI copy is Haitian Creole (Kreyòl).** Add new strings to `L10n` — never
   inline a literal in a view body.
4. **Match the design tokens exactly.** Read `DESIGN.md` before writing a view;
   never invent a color, radius, or spacing value.
5. **The logo is vector code, not a bitmap.** Use `AyitiMark` / `AyitiLockup`
   from the design system so it stays crisp at every size.

## Quick reference

| Need | Read |
| --- | --- |
| Colors, type scale, spacing, per-screen specs | [DESIGN.md](DESIGN.md) |
| HID/PIN sign-in, `id.ayiti.io/id/g/{token}`, sessions | [AUTH.md](AUTH.md) |
| GOVTalk chat, ElloFive `/run/{model}` contract | [AI.md](AI.md) |

## Adding a screen

1. Create `GovApp/Features/<Name>/<Name>View.swift` plus a `@MainActor`
   `<Name>ViewModel` if it does any I/O.
2. Compose from `DesignSystem` primitives (`BrandTextField`, `BrandButton`,
   `AyitiLockup`) — do not restyle raw SwiftUI controls inline.
3. Add a `Route` case in `GovAppApp.swift` and route through `AppRouter`; views
   never construct services themselves, they receive them from the environment.
4. Add copy to `L10n`, and a `#Preview` seeded from `PreviewData`.

## Adding a network call

Services are protocol-first so previews and tests never touch the network:

```swift
protocol ChatService: Sendable {
    func send(_ prompt: String) async throws -> ChatReply
}
```

Ship a `Live<Name>Service` (real `URLSession`) and a `Stub<Name>Service`
(deterministic, used by `#Preview` and tests). Resolve which one to use in
`AppConfig.current`, never at the call site.

Every request goes through `HTTPClient`, which owns timeouts, JSON coding, and
error mapping to `AppError`. Surface failures as an `AppError` with a Kreyòl
`userMessage`; never show a raw `URLError` to a citizen.

## Building and verifying

The project targets **iOS 17+** and requires Xcode 16 on macOS.

```bash
xcodebuild -project GovApp/GovApp.xcodeproj -scheme GovApp \
  -destination 'platform=iOS Simulator,name=iPhone 15' build test
```

Without a Mac, `cd GovApp/Tools/verify && swift test` builds and tests
everything that does not need UIKit. It symlinks the real sources, so keep new
logic files off SwiftUI imports and add them to `Sources/GovApp/` when they
belong there. Views are not covered — never treat a green `swift test` as
proof the app builds.

Two constraints that package imposes on all code it covers:

- Import `Security` and `FoundationNetworking` under `#if canImport(…)`.
- In tests, put `@MainActor` on individual test methods, never on the
  `XCTestCase` class, and make every isolated test `async`. Linux's XCTest
  aborts discovery otherwise.

`GovApp/Tools/preview/` renders the screens in a browser for the README images.
It duplicates the design tokens, so changing `Theme.swift`, `AyitiGeometry`, or
`L10n` means updating `index.html` and re-running `node capture.mjs`.

To exercise GOVTalk against a real model, run ElloFive on the host first — see
[AI.md](AI.md) for the runtime setup and the simulator's ATS requirements.
