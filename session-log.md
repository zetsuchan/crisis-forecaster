# Session / Build Log — Crisis Forecaster

A chronological account of how this iOS 27 app was built end-to-end in a single
Claude Code session (Opus 4.8), from a standing start. Companion to the brief
(`SUBMISSION.md`), the rubric (`RUBRIC.md`), and the verification script
(`scripts/verify.sh`).

> For the full verbatim transcript, `/export session-log.md` from Claude Code can
> replace this file; this is the orchestration narrative.

## How Claude was directed
- **Brief-first.** Started by reading iOS 27 / Foundation Models / App Intents notes
  and the founder's lived-experience notes, then locked decisions (direct Anthropic
  API from the app, WeatherKit, demo + live data, Opus 4.8) before building.
- **Plan → build → verify loop.** Each feature was built, compiled against the
  iOS 27 simulator, run headlessly via launch arguments (`-autorunForecast`,
  `-openPassport`), and screenshotted to confirm behavior.
- **Model-gradable "done."** `RUBRIC.md` defines pass/fail criteria; `scripts/verify.sh`
  regenerates the project, builds, runs, and asserts the rubric — rerunnable by anyone.
- **Tooling.** XcodeGen (`project.yml`) for a reproducible project; raw `URLSession`
  Anthropic client (no official Swift SDK); ImageMagick for the icon; Remotion for the
  explainer; ffmpeg for the demo assembly.

## Build timeline
1. **Scaffold.** XcodeGen project, entitlements (HealthKit/WeatherKit/App Group/BG),
   models, `SharedStore`, demo dataset, `ClaudeClient` (URLSession), `RiskEngine`,
   `PassportService`, dashboard. Verified build on iOS 27 simulator.
2. **Model.** Targeted `claude-fable-5`, switched to `claude-opus-4-8` (org access);
   structured-output risk JSON; client-side score normalization; `refusal` handling.
3. **Product depth.** Guided onboarding, 14-day trend charts (Swift Charts), check-in /
   body log, editable profile, ambient auto-run, App-Group persistence.
4. **Dual-model.** Added Apple Foundation Models (`SystemLanguageModel`) on-device
   triage of the check-in; Opus 4.8 does the deep forecast. Surfaced both in the UI.
5. **Passport.** Reworked from a markdown blob to structured output → native cards
   (triage summary, critical flags, vitals, one-tap call buttons, shareable packet).
6. **Compliance.** Non-dismissive "not medical advice" disclaimer; `RUBRIC.md`;
   `scripts/verify.sh`; public repo.
7. **Polish.** Liquid Glass (iOS 26+ `glassEffect`), lock-screen + Home-Screen
   WidgetKit widget, device signing, app icon.
8. **Interactivity.** Animated risk ring, tap-to-expand driver cards (per-signal
   "why it matters"), checkable actions, scrubbable charts, Today→Check-in CTA.
9. **Personalization.** Parsed the founder's real Apple Health export (resting HR ~55,
   HRV ~63 over 2,000+ days) to ground the sample data and onboarding baselines.
10. **Demo.** Remotion explainer (rendered to mp4), device screen-clip assembly with
    ffmpeg, founder voiceover mixed in.

## Key files
- `SUBMISSION.md` — problem / who / what "done" looks like
- `RUBRIC.md` — model-gradable success criteria
- `scripts/verify.sh` — build → run → assert, repeatable
- `project.yml` — reproducible Xcode project (XcodeGen)
- `CrisisForecaster/Services/{ClaudeClient,RiskEngine,PassportService,OnDeviceTriage}.swift`
- `CrisisForecaster/Intents/` — App Intents + AppShortcuts (Siri)
- `CrisisWidget/` — lock-screen / Home-Screen widget
- `demo/` — explainer (Remotion) + final demo video
