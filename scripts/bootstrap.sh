#!/usr/bin/env bash
# bootstrap.sh — make this project self-sufficient on the current machine.
# Idempotent, prints every action, never uses sudo, and logs what it could not do.
#
#   bash scripts/bootstrap.sh                 # everything, asks once
#   bash scripts/bootstrap.sh --yes           # no prompt (CI / agent use)
#   bash scripts/bootstrap.sh --tex-only      # just IEEEtran.cls/.bst from CTAN
#   bash scripts/bootstrap.sh --no-skills     # skip humanizer + diagram-design
#   bash scripts/bootstrap.sh --no-python     # skip cairosvg
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEXMF="$ROOT/texmf/tex/latex/local"
LOG="$ROOT/research/.state/bootstrap.log"
mkdir -p "$TEXMF" "$(dirname "$LOG")"

ASSUME_YES=0; TEX_ONLY=0; DO_SKILLS=1; DO_PYTHON=1
for a in "$@"; do
  case "$a" in
    -y|--yes) ASSUME_YES=1 ;;
    --tex-only) TEX_ONLY=1 ;;
    --no-skills) DO_SKILLS=0 ;;
    --no-python) DO_PYTHON=0 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown flag: $a" >&2; exit 2 ;;
  esac
done

log() { printf '%s | %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >>"$LOG"; printf '%s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
fetch() { # fetch <url> <dest>
  if have curl; then curl -fsSL --retry 2 -o "$2" "$1"
  elif have wget; then wget -q -O "$2" "$1"
  else log "FAIL no curl/wget — cannot download $1"; return 1; fi
}

need_tex=0
[ -n "${TEXMFHOME:-}" ] && log "note: TEXMFHOME is already set to $TEXMFHOME (project build script overrides it) "
if have kpsewhich && kpsewhich IEEEtran.cls >/dev/null 2>&1; then
  log "OK IEEEtran.cls already resolvable: $(kpsewhich IEEEtran.cls)"
else
  need_tex=1
fi

PLAN=()
[ "$need_tex" = 1 ] && PLAN+=("fetch IEEEtran.cls + IEEEtran.bst (+ optional algorithm2e/algpseudocode/siunitx) from CTAN into texmf/")
[ "$TEX_ONLY" = 1 ] || {
  [ "$DO_SKILLS" = 1 ] && PLAN+=("fetch humanizer SKILL.md into .humanizer/ (upstream text, never committed)")
  [ "$DO_SKILLS" = 1 ] && PLAN+=("clone diagram-design into vendor/diagram-design (gitignored)")
  [ "$DO_PYTHON" = 1 ] && PLAN+=("pip3 install --user cairosvg (SVG→PDF for figures)")
}

echo "bootstrap plan for $ROOT"
for p in "${PLAN[@]:-}"; do [ -n "$p" ] && echo "  - $p"; done
[ ${#PLAN[@]} -eq 0 ] && { echo "nothing to do — toolchain already complete"; log "noop"; exit 0; }

if [ "$ASSUME_YES" != 1 ]; then
  printf 'Proceed? [y/N] '; read -r ans
  case "$ans" in y|Y|yes|YES) ;; *) log "aborted by user"; exit 0 ;; esac
fi

FAILED=0

# ---------- 1. IEEEtran from CTAN (no admin rights: project-local TEXMFHOME) ----------
if [ "$need_tex" = 1 ]; then
  base="https://mirrors.ctan.org/macros/latex/contrib/IEEEtran"
  base_bib="$base/bibtex"
  fetch "$base/IEEEtran.cls" "$TEXMF/IEEEtran.cls" && log "OK IEEEtran.cls" || { FAILED=$((FAILED+1)); log "FAIL IEEEtran.cls"; }
  mkdir -p "$ROOT/texmf/bibtex/bst/local"
  if fetch "$base_bib/IEEEtran.bst" "$ROOT/texmf/bibtex/bst/local/IEEEtran.bst"; then
    log "OK IEEEtran.bst"
  else
    FAILED=$((FAILED+1))
    log "FAIL IEEEtran.bst (CTAN bibtex/ path) — fetch manually from https://ctan.org/pkg/ieeetran into texmf/tex/latex/local/"
  fi
  fetch "$base_bib/IEEEtranS.bst" "$ROOT/texmf/bibtex/bst/local/IEEEtranS.bst" >/dev/null 2>&1 && log "OK IEEEtranS.bst (optional)"
  if [ "$TEX_ONLY" = 1 ] || [ "$DO_SKILLS" = 0 ]; then :; fi
  # optional helper packages, only if CTAN has them as single files
  for pkg in algorithm2e siunitx; do
    if have kpsewhich && kpsewhich "$pkg.sty" >/dev/null 2>&1; then continue; fi
    case "$pkg" in
      algorithm2e) url="$base/../algorithm2e/algorithm2e.sty" ;;
      siunitx) url="https://mirrors.ctan.org/macros/latex/contrib/siunitx/siunitx.sty" ;;
    esac
    fetch "$url" "$TEXMF/$pkg.sty" >/dev/null 2>&1 && log "OK optional $pkg.sty" || log "skip optional $pkg.sty (not a single-file CTAN download; use plain LaTeX if absent)"
  done
  log "TeX assets in $TEXMF — build with TEXMFHOME=$ROOT/texmf (scripts/build-pdf.sh does this)"
fi

[ "$TEX_ONLY" = 1 ] && { log "done (tex-only)"; exit 0; }

# ---------- 2. humanizer (never vendored: upstream declares no license) ----------
if [ "$DO_SKILLS" = 1 ]; then
  if [ -s "$ROOT/.humanizer/SKILL.md" ]; then
    log "OK humanizer SKILL.md already present ($(wc -c <"$ROOT/.humanizer/SKILL.md" | tr -d ' ') bytes)"
  else
    log "fetching humanizer SKILL.md into .humanizer/"
    if bash "$ROOT/scripts/fetch-humanizer.sh" >>"$LOG" 2>&1; then
      log "OK humanizer SKILL.md fetched — $(wc -c <"$ROOT/.humanizer/SKILL.md" | tr -d ' ') bytes"
    else
      FAILED=$((FAILED+1)); log "FAIL humanizer fetch — run: bash scripts/fetch-humanizer.sh"
    fi
  fi
fi

# ---------- 3. diagram-design (MIT, cloned on demand, gitignored) ----------
if [ "$DO_SKILLS" = 1 ]; then
  if [ -f "$ROOT/vendor/diagram-design/skills/diagram-design/SKILL.md" ]; then
    log "OK diagram-design cloned"
  elif have git; then
    if git clone --depth 1 https://github.com/cathrynlavery/diagram-design "$ROOT/vendor/diagram-design" >>"$LOG" 2>&1; then
      log "OK diagram-design → vendor/diagram-design (MIT © 2025 Cathryn Lavery)"
    else
      FAILED=$((FAILED+1)); log "FAIL diagram-design clone (network?) — figure-designer retries on demand"
    fi
  else
    FAILED=$((FAILED+1)); log "FAIL git missing — cannot clone diagram-design"
  fi
fi

# ---------- 4. cairosvg for SVG→PDF ----------
if [ "$DO_PYTHON" = 1 ]; then
  if python3 -c 'import cairosvg' >/dev/null 2>&1; then
    log "OK cairosvg present"
  elif have pip3; then
    if pip3 install --user cairosvg >>"$LOG" 2>&1; then log "OK cairosvg installed (--user)"
    else FAILED=$((FAILED+1)); log "FAIL cairosvg install — figures fall back to rsvg/inkscape/firefox"; fi
  else
    log "skip cairosvg (no pip3) — figures fall back to rsvg/inkscape/firefox"
  fi
fi

# ---------- 5. re-run detection ----------
if have node; then node "$ROOT/scripts/preflight.mjs" --quiet >>"$LOG" 2>&1; else bash "$ROOT/scripts/preflight.sh" >/dev/null 2>&1; fi
log "bootstrap finished with $FAILED failure(s); see research/.state/toolkit.md"
[ "$FAILED" -gt 0 ] && exit 1
exit 0
