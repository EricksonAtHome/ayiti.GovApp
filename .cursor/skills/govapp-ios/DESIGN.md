# GovApp design reference

Every value here is defined once in `GovApp/DesignSystem/Theme.swift`. Use the
token, never the literal.

## Color

| Token | Hex | Use |
| --- | --- | --- |
| `Brand.blue` | `#1450C8` | Logo left stroke, Repiblik Ayiti wordmark |
| `Brand.red` | `#ED2338` | Logo right stroke |
| `Brand.action` | `#4C8DFF` | Primary buttons, session-ID value, links |
| `Brand.ink` | `#111114` | Headings and body text |
| `Brand.inkMuted` | `#6B7076` | Footer labels, secondary captions |
| `Brand.placeholder` | `#9AA0A6` | Field placeholders, input-bar hint |
| `Brand.line` | `#E3E5E8` | Text-field borders |
| `Brand.surface` | `#F2F3F5` | Chat composer, avatar circles |
| `Brand.background` | `#FFFFFF` | All screen backgrounds |

The mark's blue and red are Haitian-flag derived but brighter; do not substitute
`#00209F` / `#D21034`.

## Type

System font (SF Pro) throughout.

| Token | Size / weight | Use |
| --- | --- | --- |
| `Brand.Font.display` | 40 / bold | Username on the welcome screen |
| `Brand.Font.title` | 28 / bold | "Bonjou, konekte isit la" |
| `Brand.Font.wordmark` | 30 / heavy, tracking −1 | "ayiti.io" lockup |
| `Brand.Font.body` | 17 / regular | Fields, buttons, chat messages |
| `Brand.Font.action` | 20 / regular | Welcome-screen login button |
| `Brand.Font.caption` | 13 / regular | Footer rows |
| `Brand.Font.micro` | 10 / semibold | "GOVTalk AI" and `{gov.url.id}` |

## Metrics

| Token | Value |
| --- | --- |
| `Brand.Metric.gutter` | 24 (screen horizontal inset) |
| `Brand.Metric.fieldHeight` | 56 |
| `Brand.Metric.radius` | 12 (fields, buttons) |
| `Brand.Metric.composerRadius` | 16 |
| `Brand.Metric.stack` | 12 (gap between stacked fields) |
| `Brand.Metric.section` | 28 (gap between groups) |

## The mark

`AyitiMark` draws two filled polygons on a 1024-unit grid, scaled to the
requested size. The circle is a second subpath of the red shape filled with the
even-odd rule, so it knocks through to transparent instead of painting white:

- Blue quad: `(435,195) (555,195) (660,355) (190,805)`
- Red polygon: `(678,408) (448,652) (562,656) (648,805) (838,805)`
- Knockout circle: center `(716,735)`, radius `62`

Those coordinates live in `AyitiGeometry` **and** in
`Tools/generate-appicon.py`, which renders `AppIcon-1024.png` from them. Change
both together or the icon drifts from the in-app mark.

`AyitiLockup` places the mark beside the "ayiti.io" wordmark and is what screens
should use as a header.

## Screens

### 1. Sign-in — `Features/Auth/SignInView.swift`

Top-left `AyitiLockup` (mark 34pt tall). Below it the title
"Bonjou, konekte isit la". Two `BrandTextField`s stacked with `stack` spacing:
"Idantite Ayiti (HID)" then "Kòd sekrè (Pin)" (secure). Then a `BrandButton`
labelled "Konekte", **not** full width — it hugs its label with 40pt horizontal
padding and is left-aligned.

A `Spacer()` pushes the footer down. The footer is three rows at `caption` size:

```
Session ID:                                  ***764d77   ← Brand.action
Expires in:                                      29:50
© 2026 ayiti.io from  [Repiblik Ayiti wordmark]
```

The session ID shows only the last six characters, always masked with `***`.
"Expires in" counts down live from `AppConfig.sessionTTL` (30:00) — see AUTH.md.

### 2. GOVTalk chat — `Features/Chat/ChatView.swift`

Header: `AyitiLockup` left, `{username}` + 44pt avatar circle right.

Messages scroll between header and composer. Each message shows a small
right-aligned attribution row above its text:

- Assistant: "GOVTalk AI" in `micro` + a 14pt `AyitiMark`.
- Citizen: `{username}` in `micro` + a 24pt avatar circle.

Message text is plain — `body` size on the background, no bubble fill. Each row
is inset 56pt on the edge opposite its speaker (citizen rows from the leading
edge, assistant rows from the trailing edge) so the two read as distinct
columns without needing bubbles.

Composer pinned to the bottom: a `Brand.surface` rounded rect at
`composerRadius`, 64pt tall, placeholder "what can i help you", with a
paper-plane send button trailing. Send is disabled while the input is empty or a
reply is in flight. Below it, `{gov.url.id}` centered in `micro`.

### 3. Welcome — `Features/Welcome/WelcomeView.swift`

A 245pt `Brand.surface` circle centered in the upper third, `{username}` in
`display` beneath it, then `{gov.url.id}` in `caption`/muted. `Spacer()`, then a
full-width 64pt `BrandButton` labelled "login" pinned above the safe area.

This is the signed-out landing screen; its button routes to sign-in.

## Layout invariants

- Every screen is white, edge-to-edge, with `gutter` horizontal insets.
- Content is top-aligned; a single `Spacer()` separates content from the footer
  or pinned button. Never center a whole screen vertically.
- Buttons and fields keep 56–64pt height so they stay comfortable one-handed.
- Placeholder text uses `Brand.placeholder`; never rely on SwiftUI's default.
