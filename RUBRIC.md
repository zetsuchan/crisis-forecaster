# Crisis Forecaster — Output Rubric

This rubric defines what "good" looks like for the two Opus 4.8 agents. It is written
so **Claude can grade a run against it without a human** — feed it a captured
`risk_snapshot.json` + `emergency_passport.json` (see `scripts/verify.sh`, which writes
them to the app's container) and ask Claude to score each criterion pass/fail with a
one-line justification.

## A. Risk forecast (`RiskEngine` → `risk_snapshot.json`)

| # | Criterion | Pass condition |
|---|-----------|----------------|
| A1 | Well-formed | Valid JSON; `risk_level` ∈ {low, guarded, elevated, high}; `score` 0–100; `window_hours` 24–72. |
| A2 | Score scale correct | `score` is on a 0–100 scale (NOT a 0–1 fraction). A high band must read e.g. 78, not 0.78. |
| A3 | Band matches score | `risk_level` is consistent with `score` (low≈0–25, guarded≈25–50, elevated≈50–75, high≈75–100). |
| A4 | Grounded drivers | Each `driver` references a real signal present in the input (RHR, HRV, SpO2, sleep, pressure, humidity, temp). No invented signals. |
| A5 | Driver direction correct | `direction` describes the metric's actual movement (falling SpO2 → "down"), not the risk direction. |
| A6 | Explanation names specifics | `explanation` cites concrete numbers/trends from the data (e.g. "+8 bpm", "SpO2 0.93", "15mb drop"), not generic phrasing. |
| A7 | Companion tone | Warm, plain language; not clinical, not alarmist; respects patient expertise. No diagnosis or prescription. |
| A8 | Actionable self-management | `actions` are concrete and self-management oriented (hydration, warmth, rest, ready the pain plan); ER staging mentioned only at genuinely high risk. |

## B. Emergency Passport (`PassportService` → `emergency_passport.json`)

| # | Criterion | Pass condition |
|---|-----------|----------------|
| B1 | Well-formed | Valid JSON; non-empty `triageSummary`; `criticalFlags` is a 2–5 item array. |
| B2 | Triage is 1–2 sentences | `triageSummary` is 1–2 complete sentences — diagnosis, why now, top priority. No lists, no "Note:", no meta/schema commentary, no stub words ("placeholder"). |
| B3 | Flags are short + separate | Each `criticalFlags` item is a few words; allergies / high-risk history / danger-zone vitals appear here, not buried in the summary. |
| B4 | Faithful to profile | All clinical content traces to the provided `PatientProfile` + risk context. Nothing invented (no fabricated meds, allergies, or history). |
| B5 | Risk context attached | `riskContext` states the band, score/100, and window. |

## C. End-to-end behavior (from `scripts/verify.sh`)

| # | Criterion | Pass condition |
|---|-----------|----------------|
| C1 | Builds | `xcodebuild` succeeds for the iOS 27 simulator. |
| C2 | Runs | App launches on the iOS 27 simulator without crashing. |
| C3 | Two Opus calls succeed | Both the risk and passport requests return HTTP 200 (no refusal). |
| C4 | Persisted artifacts | `risk_snapshot.json` and `emergency_passport.json` are written and pass sections A & B. |

## How to grade (model-runnable)
1. Run `scripts/verify.sh` → it builds, runs, and prints the paths of the two JSON files.
2. Hand the two files + this rubric to Claude: "Grade each criterion pass/fail with a
   one-line reason; report a total." No human judgement required.
