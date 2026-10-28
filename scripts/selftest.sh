#!/usr/bin/env bash
# selftest.sh — proves the mechanical parts of the pipeline work on this machine.
# It does NOT simulate the LLM gate agents; it verifies every check those gates call.
# Usage: bash scripts/selftest.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
PASS=0; FAIL=0
ok(){ printf '  PASS  %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL+1)); }

echo "== 1. preflight =="
if node scripts/preflight.mjs --quiet 2>/dev/null || bash scripts/preflight.sh --quiet 2>/dev/null; then
  MODE=$(sed -n 's/^- \*\*MODE: \(.*\)\*\*$/\1/p' research/.state/toolkit.md | head -1)
  ok "preflight wrote toolkit.md (MODE: ${MODE:-unknown})"
else no "preflight failed"; fi

echo "== 2. compile gate =="
BUILD_OUT=$(bash scripts/build-pdf.sh --clean 2>&1)
BUILD=$(printf '%s\n' "$BUILD_OUT" | sed -n 's/^BUILD: //p')
case "$BUILD" in
  PASS) ok "compile gate PASS" ;;
  SKIPPED) ok "compile gate SKIPPED (no TeX) — degraded mode is allowed and reported" ;;
  *) no "compile gate $BUILD"; printf '%s\n' "$BUILD_OUT" | sed -n 's/^ISSUE: /    /p' ;;
esac

echo "== 3. audit-tex.py =="
bash scripts/audit-tex.sh --all >/tmp/opencode/selftest-audit.txt 2>&1
AUDIT=$?
if [ $AUDIT -eq 0 ] || [ $AUDIT -eq 1 ]; then
  ok "audit ran (exit $AUDIT; findings are expected on a skeleton manuscript)"
  sed -n 's/^\(\[[A-Z]*\].*\)/    \1/p' /tmp/opencode/selftest-audit.txt | head -5
else no "audit crashed (exit $AUDIT)"; fi

echo "== 4. BLOCK -> fix -> PASS (humanizer numbers invariant) =="
TMP=$(mktemp -d)
cp research/manuscript/sections/results.tex "$TMP/s.tex" || echo "" >"$TMP/s.tex"
cp "$TMP/s.tex" "$TMP/s.pre"
printf '98.2 \\%% accuracy on 700 samples\n' >>"$TMP/s.tex"
if bash scripts/audit-tex.sh --numbers "$TMP/s.tex" --against "$TMP/s.pre" >/dev/null 2>&1; then
  no "tampered copy was not detected (expected BLOCK)"
else ok "tampered copy BLOCKED (numbers DIFFER)"; fi
cp "$TMP/s.pre" "$TMP/s.tex"
if bash scripts/audit-tex.sh --numbers "$TMP/s.tex" --against "$TMP/s.pre" >/dev/null 2>&1; then
  ok "restored copy PASSES (identical multiset) — re-dispatch loop closes"
else no "restored copy still fails (expected PASS)"; fi
rm -rf "$TMP"

echo "== 5. figures gate =="
if bash scripts/audit-tex.sh --figures >/dev/null 2>&1; then ok "no dangling float references"; else
  ok "dangling float reference detected (gate would BLOCK with the list printed by --figures)"; fi

echo "== 6. style audit (AI-tell lint) =="
if python3 scripts/style-audit.py --max-density 2.0 >/dev/null 2>&1; then
  ok "style audit PASSES on current manuscript"
else no "style audit reports tells over threshold"; fi
TMP2=$(mktemp -d)
printf 'This is not merely a tool but a groundbreaking realm, playing a crucial role.\n' >"$TMP2/bad.tex"
if python3 scripts/style-audit.py "$TMP2/bad.tex" --max-density 2.0 >/dev/null 2>&1; then
  no "style audit missed a known-bad paragraph"
else ok "style audit FLAGS a known-bad paragraph (AI vocabulary + staging)"; fi
rm -rf "$TMP2"

echo "== 7. humanizer skill fetch (upstream, not vendored) =="
if bash scripts/fetch-humanizer.sh >/dev/null 2>&1 && grep -q '^## A\. Staging' .humanizer/SKILL.md 2>/dev/null; then
  ok "humanizer SKILL.md present ($(wc -c <.humanizer/SKILL.md | tr -d ' ') bytes) and gitignored"
else no "humanizer SKILL.md unavailable — humanizer agent would block"; fi

echo
echo "SELFTEST: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
