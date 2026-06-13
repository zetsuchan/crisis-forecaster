# Crisis Forecaster — Demo Recording Guide

Target: a tight **~2 minute** submission video. Lead with Siri (ambient), not the
dashboard. Intercut your screen recordings with the rendered explainer
(`demo/explainer/out/explainer.mp4`, 27s).

## Before you record
- In Xcode, set the scheme to **CrisisForecaster** (not CrisisWidget), then run.
- For a fresh onboarding take: Settings → **Start over**, or delete the app first.
- The first forecast makes two model calls (~15–40s). Either let it breathe as a
  "thinking" beat or cut it.

## What needs a real device vs the simulator
| Beat | Where |
|---|---|
| Siri "what's my crisis risk" with app closed | **Device** (signed) — App Group is cross-process |
| "Siri, show my sickle cell passport" from lock screen | **Device** |
| Lock-screen / Home-screen widget | **Device** |
| Onboarding, Today, Check-in, Passport, on-device triage, Claude forecast | Simulator is fine |

> If device signing fails on WeatherKit/App Groups (free team), tell Claude — we can
> strip WeatherKit for the device build (Demo Mode doesn't use it).

## Shot list (in order)
1. **Explainer — Title + Problem** (~8s): use `explainer.mp4` (0:00–0:09).
2. **Cold open — Siri, app closed** (~10s, device): lock screen → "Hey Siri, what's
   my crisis risk this week?" → spoken answer. Then show the lock-screen widget reading
   "High."
3. **The why** (~25s, sim or device): open the app → Today: the High hero, the
   **Apple Intelligence + Claude Opus 4.8** badges, the on-device triage card, then
   Claude's plain-language explanation. Scroll the 14-day trends + drivers + actions.
4. **Close the loop** (~15s): Check-in tab → log pain 6/10, cold exposure → save →
   "Apple Intelligence read it on-device" → forecast updates.
5. **The moat** (~20s): Passport tab → the staged ER packet (triage summary, critical
   flags, vitals, call buttons). On device: "Siri, show my sickle cell passport" from
   the lock screen.
6. **Explainer — Architecture + Division** (~14s): `explainer.mp4` (0:09–0:23).
7. **Orchestration proof** (~10s): terminal running `./scripts/verify.sh` → green, and
   a glance at `RUBRIC.md`. Nails the Opus-use + Orchestration criteria.
8. **Explainer — Close** (~4s): `explainer.mp4` (0:23–0:27): "Prediction is the
   feature. The Passport is the moat."

## Recording the simulator
- QuickTime → New Movie Recording → select the Simulator window, **or**
  `xcrun simctl io booted recordVideo demo/sim.mov` (Ctrl-C to stop).

## Re-rendering the explainer (if you edit copy/timing)
```sh
cd demo/explainer
npm install
# the bundled browser download is flaky here; point at local Chrome:
npx remotion render Explainer out/explainer.mp4 \
  --browser-executable="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
```
Edit live with `npm run dev` (Remotion Studio).
