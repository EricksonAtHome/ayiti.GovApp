# GovApp design reference

Every value here is defined once in `GovApp/DesignSystem/Theme.swift`. Use the
token, never the literal.

## Color

The house palette is five colors. These are exact — the CMYK column is what
print uses, and nudging a hex here breaks that pairing.

| Token | Hex | RGB | CMYK | Use |
| --- | --- | --- | --- | --- |
| `Brand.blue` | `#1E56C8` | 30, 86, 200 | 85, 60, 0, 0 | Logo left stroke, primary actions |
| `Brand.red` | `#E63946` | 230, 57, 70 | 0, 90, 70, 0 | Logo right stroke, errors |
| `Brand.ink` | `#0D1B2A` | 13, 27, 42 | 100, 85, 45, 70 | Headings, body text, dark surfaces |
| `Brand.surface` | `#F3F5F7` | 243, 245, 247 | 4, 2, 1, 0 | Cards, bubbles, avatars |
| `Brand.inkMuted` | `#6B7280` | 107, 114, 128 | 60, 47, 35, 1 | Secondary text and captions |

Everything else is an alias or a derivation, never a sixth color:

| Token | Value | Use |
| --- | --- | --- |
| `Brand.action` | `= blue` | Says "interactive" at the call site |
| `Brand.background` | `#FFFFFF` | Sign-in and chat backgrounds |
| `Brand.onPhoto` | `#FFFFFF` | Anything on an onboarding photo |
| `Brand.line` | `inkMuted` at 20% | Field and card borders |
| `Brand.placeholder` | `inkMuted` at 75% | Empty-field prompts |
| `Brand.photoScrim` | `ink` gradient | Darkens a photo under the headline |

The mark's blue and red are Haitian-flag derived but brighter; do not substitute
`#00209F` / `#D21034`.

`photoScrim` runs from 32% of the height to the bottom, ramping `ink` at
`0 → 0.35 → 0.85`. It starts that high deliberately: the longest headline wraps
to four lines, and a scrim that begins at the midpoint leaves the top line
sitting on bare photo. Tinting with `ink` rather than black cools the photograph
toward the palette's navy instead of flattening it to grey.

Do not introduce a lighter "friendly" blue for buttons. The palette has one
blue, and `#1E56C8` on white is 6.5:1 — it does not need help.

### Contrast

Every pairing the UI uses clears WCAG AA. Two did not, and the fix was to change
the design rather than the palette — if you hit a third, do the same:

- **`red` on white is 4.17:1**, short of the 4.5:1 body text needs. `NoticeBanner`
  therefore sets its message in `ink` and carries the alarm through a red icon,
  rule, and wash. Those are graphics and only need 3:1. Never set error *text*
  in `red` on a light background.
- **`inkMuted` on `surface` is 4.42:1.** Fine for icons and the decorative avatar
  initial, which need 3:1, but not for text. The "ap reflechi" pill uses `ink`.

`placeholder` sits at 80% of `inkMuted` because that is the lightest that still
clears 3:1 on both `background` and `surface`.

## Type

System font (SF Pro) throughout.

| Token | Size / weight | Use |
| --- | --- | --- |
| `Brand.Font.headline` | 36 / bold | Onboarding slide headline |
| `Brand.Font.title` | 28 / bold | "Bonjou, konekte isit la" |
| `Brand.Font.wordmark` | 30 / heavy, tracking −1 | "ayiti.io" lockup |
| `Brand.Font.body` | 17 / regular | Fields, chat messages, swipe hint |
| `Brand.Font.buttonLabel` | 17 / semibold | Button labels |
| `Brand.Font.caption` | 13 / regular | Footer rows |
| `Brand.Font.micro` | 10 / semibold | "GOVTalk AI" and `{gov.url.id}` |

## Metrics

| Token | Value |
| --- | --- |
| `Brand.Metric.gutter` | 24 (screen horizontal inset) |
| `Brand.Metric.fieldHeight` | 56 |
| `Brand.Metric.radius` | 12 (fields, buttons) |
| `Brand.Metric.bubbleRadius` | 20 (citizen message) |
| `Brand.Metric.cardRadius` | 24 (composer card) |
| `Brand.Metric.chipHeight` | 38 (suggestions, message actions) |
| `Brand.Metric.controlButton` | 44 (send, stop) |
| `Brand.Metric.stack` | 12 (gap between stacked fields) |
| `Brand.Metric.section` | 28 (gap between groups) |
| `Brand.Metric.progressTrack` | 3 (onboarding page indicator) |
| `Brand.Metric.barHeight` | 76 (onboarding action bar) |
| `Brand.Metric.pillHeight` | 52 ("Kontinye" pill) |

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

Header: `AyitiLockup` at 28pt, a spacer, a "new chat" `CircleIconButton` that
appears only once the transcript has something in it, and a 38pt avatar that
opens the sign-out dialog.

**Empty state** (`model.isEmpty`) — centred vertically: a 64pt `AyitiMark`, the
greeting in `title` size, then `ChatSuggestion.all` as `BrandChip`s in a
`FlowLayout` so they wrap and centre. Tapping a chip calls the same `submit`
path as typing, so a suggestion is indistinguishable from a typed message.

**Transcript** — `section` spacing between turns.

- Citizen: a `Brand.surface` bubble at `bubbleRadius`, trailing-aligned, with a
  44pt minimum gap on its leading edge so it never spans the full width.
- Assistant: a header row of a 15pt `AyitiMark` plus "Repons" in `sectionLabel`,
  then the reply in `body`, then an action row of `Kopye` / `Reeseye` / `Pataje`
  chips. `Pataje` is a real `ShareLink` wearing `ChipLabel`, not a button that
  imitates one.

Replies are parsed with `AttributedString(markdown:)` using
`.inlineOnlyPreservingWhitespace`, so `**bold**` and `` `code` `` render while
line breaks and list dashes stay exactly as the model sent them. Full block
parsing would collapse them, and SwiftUI's `Text` cannot draw list intents.

While a reply is in flight, a pulsing pill on `Brand.surface` shows
"GOVTalk ap reflechi…".

**Composer** — a white card at `cardRadius` with a `Brand.line` border and a
soft shadow, pinned to the bottom. Inside: the field (1–5 lines), then a
`controlButton` circle in `Brand.action` — an up arrow that sends, replaced by a
stop square while a reply is running. Under that, a `micro` row with the mark,
the live `AppConfig.aiModel`, and `{gov.url.id}`.

There is deliberately **no microphone button**. The references have one, but
GovApp has no dictation, and a control that does nothing is worse than an
absent one. Add the button when the feature exists.

### 3. Onboarding — `Features/Onboarding/OnboardingView.swift`

The signed-out landing screen, and the only one that is not white. Three
full-bleed photographs of Haiti in a `TabView` with `.page(indexDisplayMode:
.never)`, so pages snap. Slides are declared in `OnboardingSlide.all`:

| Photo asset | Headline |
| --- | --- |
| `OnboardingStreet` | Poze yo kesyon |
| `OnboardingTown` | Pale ak gouvènman Ayiti a |
| `OnboardingAvenue` | Mande tout enfòmasyon oswa dokiman ou bezwen |

Each page is the photo `.scaledToFill()` and clipped, then `Brand.photoScrim`,
then the headline in `Brand.Font.headline` / `Brand.onPhoto`, leading-aligned,
with `barHeight + 64` of bottom padding so it clears the action bar.

Two fixed overlays sit above the pager and do not swipe:

- **Top** — a `progressTrack`-tall segmented indicator, one capsule per slide at
  full white for the current page and 35% for the rest, then `AyitiLockup` with
  a `Brand.onPhoto` wordmark.
- **Bottom** — a `barHeight` capsule of `.ultraThinMaterial` with a 25% white
  border, holding a `Brand.ink` pill labelled "Kontinye". Trailing it: "Glise →"
  on the first two slides; on the last, the returning citizen's name and avatar
  if one is known, so "Kontinye" reads as *continue as me*. With neither, the
  pill fills the bar instead of leaving a gap.

"Kontinye" advances, and finishes onboarding on the last slide.

The mark keeps its brand colors on photos — only the wordmark takes a tint.

Photographs live in `Assets.xcassets/Onboarding/`, cropped to the 393:852 phone
ratio so no shipped pixel is cropped at runtime. They are **placeholders**: swap
in licensed photography before release.

## Layout invariants

- Sign-in and chat are white, edge-to-edge, with `gutter` horizontal insets.
  Onboarding is full-bleed photography and ignores the safe area; only its
  overlays respect it.
- Content is top-aligned; a single `Spacer()` separates content from the footer
  or pinned bar. Never center a whole screen vertically.
- Buttons and fields keep 52–76pt height so they stay comfortable one-handed.
- Placeholder text uses `Brand.placeholder`; never rely on SwiftUI's default.
- Text over a photograph always carries a scrim *and* a shadow. One is not
  enough when the image behind it is unknown.
