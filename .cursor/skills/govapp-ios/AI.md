# GOVTalk AI (ElloFive runtime)

GOVTalk is the assistant on GovApp's chat screen. It is served by
[ElloFive](https://github.com/EricksonAtHome/ElloFive) — a local Ollama-based
LLM runtime that exposes an FRC7-style HTTP API.

## Running the model

```bash
git clone https://github.com/EricksonAtHome/ElloFive.git
cd ElloFive
bash scripts/install.sh   # installs Ollama, pulls llama3.2:3b, builds the models
npm install && npm run api  # FRC bridge on http://127.0.0.1:3000
```

Two models ship with the runtime: `ellofive` (the general assistant defined by
`models/Modelfile`) and `models5` (the FRC7-compatible alias). GovApp uses
`AppConfig.aiModel`, default `ellofive`.

## The contract

`EllofiveClient` speaks to `AppConfig.aiBaseURL` (default
`http://127.0.0.1:3000`).

**Send a turn**

```http
POST /run/{model}
Content-Type: application/json

{ "input": "Kilè paspò mwen an ap pare?" }
```

```json
{
  "runtime": "ElloFive",
  "source": "FRC7",
  "model": "ellofive",
  "input": "…",
  "output": "…",
  "latencyMs": 812,
  "status": "success"
}
```

Read `output`; it is already trimmed server-side. `400` means the body was
missing `input`, `502` means the upstream Ollama host is unreachable.

**Health probe**

```http
GET /health  →  { "ok": true, "runtime": "ElloFive", "host": "…", "models": ["…"] }
```

`503` here means Ollama is not running (`ellofive serve`). The chat screen probes
health once on appear and shows a Kreyòl offline notice rather than failing on
the first message.

## What the API does not do

The bridge is **stateless and single-turn** — `POST /run/{model}` takes one
string and forgets it. Conversation memory therefore lives in the app:
`ChatViewModel` keeps the transcript and `PromptBuilder` folds the last
`AppConfig.contextTurns` exchanges into the `input` string it sends. If you need
true multi-turn server state, that is a change to ElloFive's `frc/server.js`
(its `client.js` already has a `chat()` helper that accepts a `messages` array),
not a workaround in the app.

There is also no streaming and no auth on the bridge. Do not send the session
token or any PII from `Session` in the prompt body.

## Talking to it from the simulator

`127.0.0.1` from a simulator resolves to the host Mac, so the default works —
but plaintext HTTP needs an App Transport Security exception. `Info.plist`
already carries `NSAllowsLocalNetworking` for exactly this. Point
`GOVAPP_AI_BASE_URL` at an HTTPS host for anything beyond local development, and
do not widen ATS further.

## Prompting

The runtime's system prompt makes the model self-identify as *ElloFive*, which
is wrong for a citizen-facing government assistant. `PromptBuilder` prepends the
GOVTalk persona (`L10n.Chat.systemPersona`) to each request so replies stay in
character and in Kreyòl. Keep that persona short — it is re-sent every turn and
`num_ctx` is 8192.
