---
description: Run one or more loop rounds of the IEEE paper build until every open item passes its gates.
agent: research-orchestrator
---
Follow `.github/skills/paper-loop/SKILL.md` exactly. This is the engine, not a chat.

1. Read `research/.state/loop.md`, then `project.md`, `plan.md`, `evidence.md`, `claims.md`, `gates.md`, and `research/.state/toolkit.md` (re-run `bash scripts/preflight.sh` if it is older than the current session or missing).
2. If `loop.md` PHASE is `INTAKE` or title/method/refs are missing: stop and tell me to run `/paper-start` first. Do not invent inputs.
3. Select the single highest-priority unblocked item from the open-items table (order: content correctness → sections → figures → style → compile → submission).
4. Delegate to the owning agent with only: item id, target file(s), checklist IDs, round number, and the relevant inputs. Do not paste the whole manuscript.
5. Run the owning gates via the `paper-gate` prompt or directly (`ieee-format-rules`, `citation-integrity-rules`, `research-integrity-rules`, `methodology-reproducibility-rules`, `technical-consistency-rules`, `language-and-style-rules`, `privacy-and-data-rules`, then `final-submission-gate`).
6. On `BLOCK`: append the issues verbatim to `loop.md`, increment that item's round, re-dispatch the owning writer with **only the issue list**. Gates never rewrite.
7. On `PASS`: set the item `DONE` in `plan.md`, record the verdict in `gates.md`, update `claims.md` evidence links.
8. Three rounds on the same item without PASS → stop, escalate to me with the unresolved issues. Never mark PASS yourself, never soften a gate, never edit a rule agent's output.
9. Stop this round after one item (or one parallel set of disjoint files) and report: item, agent used, gate verdicts, files changed, next action.

Degraded mode (no TeX): compile gate is `SKIPPED (no TeX)`; everything else still runs.
