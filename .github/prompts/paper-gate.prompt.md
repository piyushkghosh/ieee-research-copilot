---
description: Run one named rule gate against the manuscript and emit a verdict block only.
agent: research-orchestrator
---
Run exactly one gate (name given after the command, e.g. `citation-integrity-rules`). Follow `.github/skills/paper-gates/SKILL.md`.

1. Read `research/manuscript/ieee-checklist.md` — the gate's items are authoritative.
2. Delegate to the named gate agent with: scope (files or section), checklist IDs, round number.
3. Gate rules: read-only; run the mechanical checks it needs (`bash scripts/audit-tex.sh ...`, `bash scripts/build-pdf.sh`); each finding needs `SEVERITY | checklist ID | file:line | problem | required fix`; uncheckable item → `SKIPPED`, never `PASS`.
4. Write the verdict into `research/.state/gates.md` (one row) and return the verdict block verbatim:
   `GATE / SCOPE / ROUND / VERDICT / CRITICAL / MAJOR / MINOR / ISSUES / EVIDENCE`.
5. `PASS` requires zero CRITICAL and zero MAJOR. Do not rewrite any manuscript file in this command — if fixes are needed, say which writer agent owns them.
