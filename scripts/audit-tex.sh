#!/usr/bin/env bash
# audit-tex.sh — cross-platform wrapper for audit-tex.py.
# Windows installs of Python expose `python`/`py`, not always `python3`;
# Git for Windows provides the bash needed to run this.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for py in python3 python py; do
  if command -v "$py" >/dev/null 2>&1; then
    exec "$py" "$ROOT/scripts/audit-tex.py" "$@"
  fi
done
echo "audit: no Python interpreter found (tried python3, python, py)." >&2
echo "audit: install Python 3 from python.org and tick 'Add python.exe to PATH'." >&2
exit 2
