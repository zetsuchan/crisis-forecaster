# Crisis Forecaster — Hackathon Submission Brief

**Anthropic Hackathon 2026 · built from a standing start during the event.**
Repo: https://github.com/zetsuchan/crisis-forecaster

> A Siri-native, vaso-occlusive-crisis (VOC) early-warning agent for sickle cell
> disease. It fuses HealthKit vitals + WeatherKit + the patient's own check-ins,
> uses **Claude Opus 4.8** to forecast crisis risk 24–72h out and explain it in
> plain language, and — on elevated risk — auto-drafts an **Emergency Passport**
> (the ER handoff packet) so the handoff is already done before the visit happens.
> An on-device **Apple Foundation Model** triages privately first; **iOS 27 App
> Intents** make it ambient — Siri answers with the app closed.

## The brief

**Problem.** Vaso-occlusive crises are sudden, agonizing, and a leading cause of ER
visits for the ~20M people living with sickle cell disease — but they rarely come
from nowhere. Rising resting heart rate, falling HRV, SpO₂ dips, fragmented sleep,
and weather shifts (barometric pressure drops, low humidity, cold) precede them.
Nobody has fused these into a patient-facing early-warning tool, and every ER visit
starts from zero — the patient re-explaining their variant, meds, allergies, and
pain plan while in crisis.

**Who it's for.** People living with sickle cell disease and their care teams.
Designed from 37 years of lived experience (see `Anthropic Hackathon 2026/04 -
Lived Experience & Founder Insight` in the founder's notes): a *companion, not a
monitor* — not clinical, not alarmist, respecting the expertise patients already have.

**What "done" looks like.**
1. A daily forecast that scores VOC risk 24–72h out and explains *why* in plain
   language, grounded in the patient's real 14-day trend.
2. On elevated risk, an ER-ready Emergency Passport drafted automatically.
3. Ambient delivery: the patient never opens an app — Siri answers "what's my crisis
   risk this week?" and surfaces the passport from the lock screen.
4. Verifiable output quality: a rubric Claude can grade a run against, with no human.

## What was built during the hackathon (100% original)

No prior codebase. Native iOS 27 / Swift 6.4 app. Original contributions:

- **Risk-reasoning agent** — `Services/RiskEngine.swift` + `ClaudeClient.swift`: a
  hand-rolled Anthropic Messages API client (Swift has no official SDK) calling
  `claude-opus-4-8` with **structured outputs**, client-side normalization, and
  defensive `refusal` handling.
- **Emergency Passport agent** — `Services/PassportService.swift`: a second
  structured call producing a triage summary + critical flags, rendered as native
  Liquid Glass cards with one-tap call buttons and a shareable packet.
- **On-device triage** — `Services/OnDeviceTriage.swift`: Apple Foundation Models
  (`SystemLanguageModel`, guided generation) read the patient's check-in privately.
- **Ambient delivery** — `Intents/` (App Intents + `AppShortcutsProvider`) for Siri;
  `Background/DailyScoreTask.swift` (BGTaskScheduler) for the daily run; a WidgetKit
  lock-screen + Home-screen widget.
- **Product** — guided onboarding, 14-day trend charts (Swift Charts), check-in/body
  log, editable profile, Liquid Glass throughout, App-Group persistence, and a
  non-dismissive "not medical advice" disclaimer.

## How Claude Opus 4.8 is used (beyond a basic integration)

Two distinct structured-output agents (forecast + passport), and a **two-tier model
architecture**: Apple's on-device model is the *triage nurse* (private, instant,
offline — normalizes the check-in, scores concern, decides escalation); **Claude Opus
4.8** is the *specialist* (fuses 14 days of vitals + weather + the on-device digest
into the 24–72h forecast and the ER packet). Cheap/private/local pre-digestion →
frontier reasoning. The division — *Claude reasons, Apple triages on-device, iOS 27
delivers* — is surfaced in the UI so it's legible.

## Orchestration — "done" is verifiable by the model

- **`RUBRIC.md`** — pass/fail criteria for the forecast (A1–A8), the passport (B1–B5),
  and end-to-end behavior (C1–C4), written so Claude can grade a captured run with no
  human in the loop.
- **`scripts/verify.sh`** — one command: regenerate the project → build for iOS 27 →
  run headlessly (exercises both Opus calls via launch args) → locate the persisted
  artifacts → assert the rubric. Rerunnable by anyone, tomorrow, on a new input.
- **Session log** — the entire app was built in a single Claude Code session;
  transcript available alongside this submission.

## Impact

Sickle cell is ethically urgent, data-dense, and underserved. Even a modest reduction
in ER visits / inpatient days is worth thousands of dollars per avoided event, and the
pre-crisis trajectory data is something EHRs don't capture. The Passport is the moat:
prediction earns daily use; the staged handoff is the defensible wedge into a
multi-disease bio-AI platform.

## Demo

- **Explainer:** `demo/explainer.mp4` (27s, rendered with Remotion).
- **Recording plan:** `demo/SHOT_LIST.md` — leads with Siri (ambient), maps each beat
  to device vs simulator, and includes the `verify.sh` orchestration beat.

## Safety & compliance

Informational early warning, **not medical advice or a diagnosis** (disclaimer shown
in-app on Today, Passport, and onboarding). It surfaces the patient's *own*
self-management plan and organizes their data for clinicians; it does not diagnose,
prescribe, or replace a care team. All on-device; the only network call is the Claude
forecast. Demo data is synthetic (no real patient data); no third-party code or
copyrighted assets.

## Links
- Code: https://github.com/zetsuchan/crisis-forecaster
- Rubric: `RUBRIC.md` · Verification: `scripts/verify.sh` · Demo: `demo/`
