#!/usr/bin/env bash
# Fetch the upstream blader/humanizer SKILL.md into .humanizer/ (gitignored).
# We never redistribute the text; each machine downloads it itself.
# Upstream declares no LICENSE, so it must not be committed to this repo.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/.humanizer"
OUT="$DEST/SKILL.md"
URLS=(
  "https://raw.githubusercontent.com/blader/humanizer/main/SKILL.md"
  "https://raw.githubusercontent.com/blader/humanizer/master/SKILL.md"
)

mkdir -p "$DEST"

if [ -s "$OUT" ] && grep -q '^## A\. Staging' "$OUT" 2>/dev/null; then
  echo "humanizer: already present ($(wc -c <"$OUT" | tr -d ' ') bytes) — $OUT"
  exit 0
fi

fetch() {
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$1" -o "$2"; else wget -qO "$2" "$1"; fi
}

for u in "${URLS[@]}"; do
  if fetch "$u" "$OUT.tmp" 2>/dev/null; then
    if grep -q '^## A\. Staging' "$OUT.tmp"; then
      mv "$OUT.tmp" "$OUT"
      echo "humanizer: fetched $(wc -c <"$OUT" | tr -d ' ') bytes — $OUT"
      exit 0
    fi
  fi
  rm -f "$OUT.tmp"
done

# Fallback: the cross-agent skills installer.
if command -v npx >/dev/null 2>&1; then
  echo "humanizer: direct download failed, trying 'npx skills add blader/humanizer'"
  if npx --yes skills add blader/humanizer --agent '*' >/dev/null 2>&1; then
    FOUND="$(find "$ROOT/.github" "$ROOT/.claude" "$ROOT/skills" -path '*humanizer*/SKILL.md' 2>/dev/null | head -1)"
    if [ -n "$FOUND" ]; then cp "$FOUND" "$OUT"; echo "humanizer: installed via skills CLI — $OUT"; exit 0; fi
  fi
fi

echo "humanizer: FAILED to obtain SKILL.md (no network and no skills CLI)." >&2
echo "humanizer: fix manually: download https://github.com/blader/humanizer/blob/main/SKILL.md to $OUT" >&2
exit 1
