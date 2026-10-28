#!/usr/bin/env bash
# build-pdf.sh — compile the manuscript and audit the build.
# Usage: bash scripts/build-pdf.sh [--clean]
# Exit: 0 PASS · 1 FAIL · 3 SKIPPED (no TeX / degraded mode)
# Prints a machine-readable tail:
#   BUILD: PASS|FAIL|SKIPPED
#   PDF: <path|none>
#   PAGES: <n|unknown>
#   ISSUES: <n>
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MS="$ROOT/research/manuscript"
TEX="$MS/main.tex"
OUTDIR="$MS/build"
LOG="$OUTDIR/build.log"
CLEAN=0
[ "${1:-}" = "--clean" ] && CLEAN=1

issues=0
fail() { printf 'ISSUE: %s\n' "$*"; issues=$((issues + 1)); }

# ---- preconditions ----
if [ ! -f "$TEX" ]; then
  echo "ISSUE: $TEX not found (manuscript skeleton missing)"
  echo "BUILD: FAIL"; echo "PDF: none"; echo "PAGES: unknown"; echo "ISSUES: 1"
  exit 1
fi

ENGINE=""
for e in pdflatex xelatex lualatex; do command -v "$e" >/dev/null 2>&1 && { ENGINE="$e"; break; }; done
if [ -z "$ENGINE" ]; then
  echo "BUILD: SKIPPED"
  echo "REASON: no TeX engine on PATH — degraded-markdown mode, compile gate is SKIPPED (no TeX)"
  echo "PDF: none"; echo "PAGES: unknown"; echo "ISSUES: 0"
  exit 3
fi

# IEEEtran must resolve (system or project texmf)
export TEXMFHOME="$ROOT/texmf"
export BSTINPUTS="$ROOT/texmf/bibtex/bst//:${BSTINPUTS:-}"
export BIBINPUTS="$ROOT/research/manuscript//:${BIBINPUTS:-}"
if ! kpsewhich IEEEtran.cls >/dev/null 2>&1; then
  echo "BUILD: SKIPPED"
  echo "REASON: IEEEtran.cls not found — run: bash scripts/bootstrap.sh --tex-only"
  echo "PDF: none"; echo "PAGES: unknown"; echo "ISSUES: 0"
  exit 3
fi

mkdir -p "$OUTDIR"
if [ "$CLEAN" = "1" ]; then
  rm -f "$OUTDIR"/*.aux "$OUTDIR"/*.log "$OUTDIR"/*.bbl "$OUTDIR"/*.blg "$OUTDIR"/*.fls "$OUTDIR"/*.fdb_latexmk "$OUTDIR"/*.out "$OUTDIR"/*.toc
fi

# ---- compile ----
status=0
if command -v latexmk >/dev/null 2>&1; then
  ( cd "$MS" && latexmk -pdf -interaction=nonstopmode -halt-on-error \
      -outdir="$OUTDIR" -pdflatex="$ENGINE %O %S" main.tex ) >"$LOG" 2>&1 || status=$?
else
  ( cd "$MS" && "$ENGINE" -interaction=nonstopmode -halt-on-error -output-directory="$OUTDIR" main.tex ) >"$LOG" 2>&1 || status=$?
  # second pass for refs, then bibtex if a .aux with citations exists
  ( cd "$MS" && "$ENGINE" -interaction=nonstopmode -halt-on-error -output-directory="$OUTDIR" main.tex ) >>"$LOG" 2>&1 || status=$?
  if [ -f "$OUTDIR/main.aux" ] && grep -q '\\citation' "$OUTDIR/main.aux"; then
    ( cd "$OUTDIR" && bibtex main ) >>"$LOG" 2>&1 || status=$?
    ( cd "$MS" && "$ENGINE" -interaction=nonstopmode -halt-on-error -output-directory="$OUTDIR" main.tex ) >>"$LOG" 2>&1 || status=$?
  fi
fi

PDF="$OUTDIR/main.pdf"
[ -f "$PDF" ] || PDF=""
if [ "$status" -ne 0 ] || [ -z "$PDF" ]; then
  fail "compile failed (exit $status); see $LOG"
  grep -m5 -E '^!|^l\.[0-9]+' "$LOG" 2>/dev/null | sed 's/^/  /'
  echo "BUILD: FAIL"; echo "PDF: none"; echo "PAGES: unknown"; echo "ISSUES: $issues"
  exit 1
fi

# ---- log audit ----
LOG2="$OUTDIR/main.log"
[ -f "$LOG2" ] || LOG2="$LOG"
undef=$(grep -cE 'Reference .* undefined|Citation .* undefined|There were undefined' "$LOG2" 2>/dev/null || true)
[ "${undef:-0}" -gt 0 ] && fail "$undef undefined reference/citation warning(s) in log"
mult=$(grep -cE 'multiply defined' "$LOG2" 2>/dev/null || true)
[ "${mult:-0}" -gt 0 ] && fail "$mult multiply-defined label(s)"
errs=$(grep -cE '^! ' "$LOG2" 2>/dev/null || true)
[ "${errs:-0}" -gt 0 ] && fail "LaTeX errors recorded in log"

# ---- page count and venue limit ----
pages="unknown"
if command -v pdfinfo >/dev/null 2>&1; then
  pages=$(pdfinfo "$PDF" 2>/dev/null | awk '/^Pages:/{print $2}')
fi
limit=$(sed -n 's/^PAGE_LIMIT:[[:space:]]*//p' "$ROOT/research/.state/project.md" 2>/dev/null | head -1 | tr -dc '0-9')
if [ -n "${limit:-}" ] && [ "$pages" != "unknown" ] && [ "$pages" -gt "$limit" ] 2>/dev/null; then
  fail "page count $pages exceeds venue limit $limit"
fi

# ---- fonts embedded (submission sanity) ----
if command -v pdffonts >/dev/null 2>&1; then
  notemb=$(pdffonts "$PDF" 2>/dev/null | awk 'NR>2 && $0 !~ / yes /{c++} END{print c+0}')
  [ "${notemb:-0}" -gt 0 ] && fail "$notemb font(s) not embedded — submission risk"
fi

echo "PDF: ${PDF:-none}"
echo "PAGES: ${pages:-unknown}"
if [ "$issues" -eq 0 ]; then echo "BUILD: PASS"; else echo "BUILD: FAIL"; fi
echo "ISSUES: $issues"
[ "$issues" -eq 0 ] && exit 0 || exit 1
