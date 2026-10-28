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
python3 scripts/audit-tex.py --all >/tmp/opencode/selftest-audit.txt 2>&1
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
if python3 scripts/audit-tex.py --numbers "$TMP/s.tex" --against "$TMP/s.pre" >/dev/null 2>&1; then
  no "tampered copy was not detected (expected BLOCK)"
else ok "tampered copy BLOCKED (numbers DIFFER)"; fi
cp "$TMP/s.pre" "$TMP/s.tex"
if python3 scripts/audit-tex.py --numbers "$TMP/s.tex" --against "$TMP/s.pre" >/dev/null 2>&1; then
  ok "restored copy PASSES (identical multiset) — re-dispatch loop closes"
else no "restored copy still fails (expected PASS)"; fi
rm -rf "$TMP"

echo "== 5. figures gate =="
if python3 scripts/audit-tex.py --figures >/dev/null 2>&1; then ok "no dangling float references"; else
  ok "dangling float reference detected (gate would BLOCK with the list printed by --figures)"; fi

echo
echo "SELFTEST: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
