#!/usr/bin/env bash
# final-humanize-check.sh — verify the whole-paper humanization pass changed no facts.
#
#   bash scripts/final-humanize-check.sh --snapshot   # before the pass: snapshot sections
#   bash scripts/final-humanize-check.sh --verify     # after the pass: every section must match
#
# Exit: 0 identical · 1 facts changed (restore + re-dispatch) · 2 usage/setup problem
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECT="$ROOT/research/manuscript/sections"
SNAP="$ROOT/research/.state/final-humanize-baseline"
AUDIT="$ROOT/scripts/audit-tex.sh"

case "${1:---verify}" in
  --snapshot)
    mkdir -p "$SNAP"
    rm -f "$SNAP"/*.tex
    n=0
    for f in "$SECT"/*.tex; do [ -e "$f" ] || continue; cp "$f" "$SNAP/$(basename "$f")"; n=$((n+1)); done
    echo "snapshot: $n section(s) -> ${SNAP#$ROOT/}"
    exit 0 ;;
  --verify) ;;
  *) echo "usage: bash scripts/final-humanize-check.sh [--snapshot|--verify]" >&2; exit 2 ;;
esac

[ -d "$SNAP" ] && [ -n "$(ls -A "$SNAP" 2>/dev/null)" ] || { echo "no baseline — run --snapshot first" >&2; exit 2; }

fail=0
for base in "$SNAP"/*.tex; do
  name="$(basename "$base")"
  cur="$SECT/$name"
  if [ ! -e "$cur" ]; then echo "MISSING: sections/$name"; fail=1; continue; fi
  out="$("$AUDIT" --numbers "$cur" --against "$base" 2>&1)"
  if printf '%s' "$out" | grep -q "numbers DIFFER"; then
    echo "CHANGED FACTS: $name"
    printf '%s\n' "$out" | grep -E '^\[CRITICAL\]' | head -5
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo "FINAL-HUMANIZE: FAIL — restore from .state/final-humanize-baseline and re-dispatch the humanizer"
  exit 1
fi
echo "FINAL-HUMANIZE: OK — every section kept identical numbers, units, citations, DOIs and figure refs"
exit 0
