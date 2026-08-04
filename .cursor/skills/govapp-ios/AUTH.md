# GovApp identity and sessions

Identity is issued by **`https://id.ayiti.io`** (GovID SSO). GovApp never mints
credentials itself and never stores a PIN.

## The `/id/g/{token}` grant

A sign-in attempt is scoped to a short-lived **grant token**. The app mints one
locally, and everything that follows is addressed to
`{identityBaseURL}/id/g/{token}`:

```
https://id.ayiti.io/id/g/2f0b9c4ea1d64c8e9b3a7c15b0e2764d77
                          └──────────── grant token ────────────┘
```

The last six characters of that token are what the sign-in footer surfaces as
`***764d77`. The grant is valid for `AppConfig.sessionTTL` (30 minutes), which
is what the "Expires in" countdown shows; when it hits zero the app discards the
grant, mints a new one, and clears the form.

## Two ways in

`IdentityService` exposes one API and two implementations, chosen by
`AppConfig.identityMode`.

### `.direct` — native form (default)

The HID and PIN typed on screen 1 are posted to the grant URL:

```http
POST /id/g/{token} HTTP/1.1
Host: id.ayiti.io
Content-Type: application/json
Accept: application/json

{ "hid": "…", "pin": "…" }
```

Expected `200`:

```json
{
  "session": "…",
  "expiresIn": 1800,
  "username": "Jean Baptiste",
  "govUrlId": "gov.ayiti.io/jbaptiste"
}
```

`401` means bad HID/PIN, `410` means the grant expired, `429` means too many
attempts. Anything non-JSON is treated as `AppError.identityUnavailable` —
`id.ayiti.io` currently answers unknown paths with the SPA's HTML shell, so a
`text/html` response must **never** be parsed as success.

> **Unconfirmed.** The request and response shapes above are the app's working
> contract, not a published spec. They are declared in one place —
> `Services/Identity/IdentityDTO.swift`. If the server disagrees, change those
> DTOs and nothing else.

### `.hosted` — web grant fallback

`https://id.ayiti.io/id/g/{token}` also renders the hosted GovID login page, so
`HostedIdentityService` opens it in `ASWebAuthenticationSession` and waits for a
redirect to `{callbackScheme}://auth/callback?session=…`. Use this when the
native form is rejected, or for any flow the hosted page owns (recovery, MFA,
first-time enrolment). It needs no changes to the login screen — the router
presents it instead of the form.

## Session storage

`SessionStore` is the only thing that touches persistence:

- The session token goes to the **Keychain** under
  `io.ayiti.govapp.session`, with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- Username, gov URL ID, and expiry go to `UserDefaults` — they are display data,
  not secrets.
- `signOut()` clears both, then routes back to the welcome screen.

Never write the PIN, the grant token, or a full session token to `os_log`,
`print`, or an analytics event. `Session.description` is deliberately redacted;
keep it that way.

## Expiry

`SessionStore.isValid` compares `expiresAt` against `Date()` with a 30-second
skew allowance. Any `401`/`410` from a downstream call (including GOVTalk) must
call `signOut()` so the citizen lands on the welcome screen rather than a broken
chat.
