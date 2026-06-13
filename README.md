# Crisis Forecaster

**A Siri-native, vaso-occlusive-crisis (VOC) early-warning agent for sickle cell disease.**
Built at the **Anthropic Hackathon 2026** on the iOS 27 dev beta.

Vaso-occlusive crises rarely come from nowhere — they're preceded by signals: rising
resting heart rate, falling HRV, SpO2 dips, sleep fragmentation, and weather shifts
(barometric pressure drops, low humidity, cold). Crisis Forecaster fuses HealthKit
vitals + WeatherKit and asks **Claude Opus 4.8** to score crisis risk 24–72h out, explain
*why* in plain language, and — on elevated risk — auto-draft an **Emergency Passport**
(the ER handoff packet) so the handoff is already done before the visit happens.

> **Not medical advice.** Crisis Forecaster is an informational early-warning and
> ER-handoff aid. It surfaces the patient's *own* self-management plan and organizes
> their data for clinicians — it does not diagnose, prescribe, or replace a care team.
> In an emergency, call 911 or your hematologist.

## What this is (and is not)

- **It is:** a predictive agent + an ambient Siri delivery layer + a document-staging
  tool (the Passport). The headline feature is **prediction**; the **Passport is the moat.**
- **It is not:** a chatbot, a medical-advice bot, or a dashboard. The dashboard is one
  optional surface — the agent runs daily in the background and answers from Siri with
  the app closed.

## Built during the hackathon (100% original)

Everything in this repo was written from a standing start during the event. There is no
prior codebase. Original contributions:

- **Risk-reasoning agent** — `Services/RiskEngine.swift` + `Services/ClaudeClient.swift`:
  a hand-rolled Anthropic Messages API client (Swift has no official SDK) calling
  `claude-opus-4-8` with **structured outputs** (JSON-schema-constrained risk object),
  client-side score normalization, and defensive `refusal` handling.
- **Emergency Passport agent** — `Services/PassportService.swift`: a second structured
  Opus 4.8 call producing a triage summary + critical flags, rendered as native cards
  (`Views/PassportView.swift`) with one-tap call buttons and a shareable text packet.
- **Ambient delivery** — `Intents/` App Intents (`CrisisRiskIntent`, `ShowPassportIntent`)
  + `AppShortcutsProvider` so Siri answers "What's my crisis risk this week?" and
  "Show my sickle cell passport" with the app closed; `Background/DailyScoreTask.swift`
  runs the forecast daily via `BGTaskScheduler`.
- **Data layer** — Demo/Live seam (`{Demo,Live}HealthSource`, `{Demo,WeatherKit}…`),
  14-day trend charts (Swift Charts), App-Group-backed `SharedStore`, guided onboarding.

No third-party code, scraped data, or copyrighted assets. The demo dataset
(`Resources/demo_decline_14d.json`) is synthetic, authored for this project.

## Requirements
- Xcode 27, iOS 27 SDK, Swift 6.4
- [XcodeGen](https://github.com/yonyz/XcodeGen) (`brew install xcodegen`) — the
  `.xcodeproj` is generated from `project.yml` and is gitignored
- An Anthropic API key (the app calls `claude-opus-4-8`)
- For live HealthKit / WeatherKit: a paid Apple Developer account, a real device, and
  WeatherKit enabled on the App ID

## Setup
```sh
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
# edit Config/Secrets.xcconfig and paste your real ANTHROPIC_API_KEY (gitignored)
xcodegen generate
open CrisisForecaster.xcodeproj
```

## Run the demo (no device, no entitlements)
1. Launch on the iOS 27 simulator.
2. First launch shows **onboarding** → tap through 4 steps → it runs the first forecast.
3. **Demo Mode** (default) replays a scripted 14-day decline and calls Opus 4.8 — you get
   an elevated risk with a plain-language explanation, the 14-day trends, and a staged
   Emergency Passport.

Switch off Demo Mode in Settings for live HealthKit + WeatherKit (device required).

### Automation / CI hook
`-autorunForecast` (skip onboarding + force a fresh score) and `-openPassport` (open the
Passport tab) launch arguments drive headless demo capture — see `scripts/verify.sh`.

## How it does the reasoning
- `ClaudeClient` → `POST /v1/messages`, `claude-opus-4-8`, `output_config.format` with a
  JSON schema, `effort: medium`. No `thinking`/`temperature` (4.8 surface); structured
  output instead of prefill; `refusal` stop-reason handled.
- `RiskEngine` builds the SCD-trigger system prompt + schema and parses a `RiskSnapshot`.
- `PassportService` makes a second structured call for the triage summary + flags.

## Repeatable verification
See `RUBRIC.md` (what "good" output looks like — gradable by Claude) and
`scripts/verify.sh` (build → run on iOS 27 sim → exercise both Opus calls → assert the
persisted forecast + passport are well-formed).
