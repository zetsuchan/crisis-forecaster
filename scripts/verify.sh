#!/usr/bin/env bash
#
# Repeatable end-to-end verification for Crisis Forecaster.
# Builds for the iOS 27 simulator, runs the app headlessly (forcing a fresh
# Opus 4.8 forecast + passport), then asserts the persisted artifacts are
# well-formed per RUBRIC.md sections A & B. Exits non-zero on any failure.
#
# Usage:  ./scripts/verify.sh
# Requires: Xcode 27, xcodegen, an ANTHROPIC_API_KEY in Config/Secrets.xcconfig.

set -euo pipefail
cd "$(dirname "$0")/.."

BUNDLE_ID="com.crisisforecaster.app"
SCHEME="CrisisForecaster"
OS="27.0"

echo "▸ Generating project"
xcodegen generate >/dev/null

echo "▸ Resolving an iOS ${OS} simulator"
UDID=$(xcrun simctl list devices --json | python3 -c "
import json,sys
d=json.load(sys.stdin)['devices']
for rt,devs in d.items():
    if 'iOS-27' in rt:
        for x in devs:
            if x.get('isAvailable') and 'iPhone' in x['name']:
                print(x['udid']); sys.exit(0)
sys.exit('no iOS 27 simulator found')
")
echo "  $UDID"

echo "▸ Building (C1)"
xcodebuild build -project "${SCHEME}.xcodeproj" -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=${UDID}" CODE_SIGNING_ALLOWED=NO >/dev/null
echo "  build succeeded"

APP=$(find ~/Library/Developer/Xcode/DerivedData/${SCHEME}-*/Build/Products/Debug-iphonesimulator \
  -maxdepth 1 -name "${SCHEME}.app" | head -1)

echo "▸ Launching on simulator (C2)"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" >/dev/null 2>&1 || true
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl install "$UDID" "$APP" >/dev/null
xcrun simctl launch "$UDID" "$BUNDLE_ID" -autorunForecast -openPassport >/dev/null
echo "  launched; waiting for two Opus 4.8 calls…"
sleep 50

echo "▸ Locating persisted artifacts (C4)"
CONTAINER=~/Library/Developer/CoreSimulator/Devices/$UDID/data/Containers/Data/Application
RISK=$(find "$CONTAINER" -maxdepth 4 -name "risk_snapshot.json" 2>/dev/null | head -1)
PASS=$(find "$CONTAINER" -maxdepth 4 -name "emergency_passport.json" 2>/dev/null | head -1)
echo "  risk:     ${RISK:-MISSING}"
echo "  passport: ${PASS:-MISSING}"

echo "▸ Asserting rubric sections A & B"
python3 - "$RISK" "$PASS" <<'PY'
import json, sys
risk_path, pass_path = sys.argv[1], sys.argv[2]
fail = []

if not risk_path: fail.append("A: risk_snapshot.json missing")
else:
    r = json.load(open(risk_path))
    if r.get("risk_level") not in {"low","guarded","elevated","high"}: fail.append("A1 risk_level")
    s = r.get("score", -1)
    if not (0 <= s <= 100): fail.append(f"A1 score range ({s})")
    if 0 < s <= 1: fail.append(f"A2 score looks like a 0-1 fraction ({s})")
    if not (24 <= r.get("window_hours",0) <= 72): fail.append("A1 window_hours")
    if not r.get("drivers"): fail.append("A4 no drivers")
    if len(r.get("explanation","")) < 40: fail.append("A6 explanation too short")

if not pass_path: fail.append("B: emergency_passport.json missing")
else:
    p = json.load(open(pass_path))
    ts = p.get("triageSummary","").strip()
    if len(ts) < 20 or ts.lower() in {"placeholder","todo"}: fail.append(f"B2 triageSummary degenerate ({ts!r})")
    if "note:" in ts.lower(): fail.append("B2 triageSummary has meta 'Note:'")
    cf = p.get("criticalFlags", [])
    if not (2 <= len(cf) <= 5): fail.append(f"B1/B3 criticalFlags count ({len(cf)})")

if fail:
    print("✗ FAILED:")
    for f in fail: print("   -", f)
    sys.exit(1)

print("✓ PASS — risk:", risk_path.split('/')[-1], "| passport:", pass_path.split('/')[-1])
print("  level=%s score=%s window=%sh | flags=%d" % (
    r["risk_level"], r["score"], r["window_hours"], len(p["criticalFlags"])))
PY

echo "▸ Done. (Hand the two JSON files + RUBRIC.md to Claude for the full A/B grade.)"
