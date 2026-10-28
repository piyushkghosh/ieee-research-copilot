#!/usr/bin/env bash
# Create a clean, independent copy of this pack for another person or another paper.
# Each copy has its own research/.state, inputs, literature and manuscript — no shared data.
#
# Usage: bash scripts/new-project.sh <destination> [--from-git]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-}"
FROM_GIT="${2:-}"

if [ -z "$DEST" ]; then
  echo "usage: bash scripts/new-project.sh <destination> [--from-git]"; exit 2
fi
case "$DEST" in /*) ;; *) DEST="$PWD/$DEST" ;; esac
if [ -e "$DEST" ] && [ -n "$(ls -A "$DEST" 2>/dev/null)" ]; then
  echo "refusing: $DEST exists and is not empty"; exit 1
fi
mkdir -p "$DEST"

if [ "$FROM_GIT" = "--from-git" ] && git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  git clone --depth 1 "file://$ROOT" "$DEST.tmp" >/dev/null 2>&1
  shopt -s dotglob
  mv "$DEST.tmp"/* "$DEST"/
  rmdir "$DEST.tmp"; rm -rf "$DEST/.git"
  shopt -u dotglob
else
  # copy the pack, leaving behind per-person state and generated artefacts
  tar -C "$ROOT" -cf - \
    --exclude=.git --exclude=build --exclude=vendor --exclude=texmf \
    --exclude=research/.state --exclude=research/literature --exclude=research/figures \
    --exclude=research/experiments --exclude=research/datasets \
    --exclude=research/manuscript/build --exclude=research/manuscript/literature-matrix.md \
    --exclude='research/inputs/papers/*.pdf' \
    . | tar -C "$DEST" -xf -
fi

# fresh per-person state
mkdir -p "$DEST/research/.state" "$DEST/research/literature/notes" \
         "$DEST/research/figures" "$DEST/research/experiments" "$DEST/research/datasets" \
         "$DEST/research/inputs/papers" "$DEST/research/manuscript/build" "$DEST/build"
cp "$ROOT"/research/.state/{project,plan,evidence,claims,gates,loop}.md "$DEST/research/.state/" 2>/dev/null || true
rm -f "$DEST/research/.state/toolkit.md" "$DEST/research/.state/bootstrap.log"

# blank the reference list so no one inherits another project's citations
: > "$DEST/research/inputs/refs.txt"
cat > "$DEST/research/inputs/refs.txt" <<'REFS'
# One reference per line: DOI, arXiv id, URL, or a full citation.
# literature-review verifies each entry before it reaches refs.bib.
REFS
: > "$DEST/research/inputs/refs.bib"

# reset the loop to intake
cat > "$DEST/research/.state/loop.md" <<'LOOP'
# Loop state

ROUND: 0
PHASE: INTAKE
NEXT_ACTION: run `bash scripts/preflight.sh`, read research/.state/toolkit.md, then ask the six intake groups

## Open items
| # | Item | Owner | Rounds used | Status |
|---|---|---|---|---|
| 1 | intake (title, content, methodology, diagrams, references, template) | research-orchestrator | 0 | OPEN |

## Escalations
_none_

## Human decisions
_none_

## Round log
LOOP

find "$DEST" -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true
echo "new project: $DEST"
echo "next:"
echo "  cd $DEST"
echo "  bash scripts/preflight.sh && bash scripts/bootstrap.sh"
echo "  then open it in VS Code and run /paper-start"
