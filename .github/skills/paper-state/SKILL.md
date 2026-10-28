---
name: paper-state
description: "Read and write the research/.state files correctly: project, plan, evidence, claims, gates, loop, toolkit. Use when recording a decision, logging evidence, updating status, or resuming after a context reset."
---

# State files

All under `research/.state/`. Never delete history: append, then update the
current-value table.

| File | Owner | Rule |
|------|-------|------|
| `project.md` | orchestrator | TITLE and TITLE_LOCKED are user-authoritative. Decisions log is append-only. |
| `plan.md` | orchestrator | One row per section and figure; status TODO/DRAFT/GATE/FIX/DONE. |
| `evidence.md` | any agent | Append-only ledger. Tag every entry MEASURED, PLANNED, or ASSUMED. |
| `claims.md` | research-integrity | Every asserted claim gets a row with evidence and status. |
| `gates.md` | rule agents | Latest verdict per gate, with round and issue counts. |
| `loop.md` | orchestrator | ROUND, PHASE, NEXT_ACTION, open items, escalations, human decisions. |
| `toolkit.md` | preflight | Generated. Do not hand-edit. |

## Rules
- Only `MEASURED` evidence may be written as a result in the manuscript.
- A claim cannot move to `SUPPORTED` without an evidence ID that exists in
  `evidence.md`.
- `NEXT_ACTION` must be executable by a fresh agent with no memory of this
  conversation: name the agent, the file, and the checklist items.
- Round counters only increase. Never reset to hide a failed loop.
