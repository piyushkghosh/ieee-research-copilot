# User decisions & corrections (append-only)

Every correction the user makes is permanent. Writers read this file before drafting;
gates check that a corrected item has not come back. Never delete a row. Never silently
revert a corrected title, wording, number, structure, or design decision.

| ID | Date | Scope | User instruction | Applied to | Status |
|---|---|---|---|---|---|
| D-0 | init | global | Pack defaults (IEEEtran conference, degraded mode allowed) | — | ACTIVE |

## Rules

- A new correction gets the next id `D-<n>`, a scope (file, section, or `global`), and status `ACTIVE`.
- Only an explicit later user instruction may supersede a row; reference both ids (`D-7 supersedes D-3`).
- Corrections override anything an agent inferred, assumed, or generated earlier — including `ASSUMED (auto)` values.
- `technical-consistency-rules` treats any regression against an `ACTIVE` row as **CRITICAL**.
- Writers receive the relevant `ACTIVE` rows in their dispatch prompt; they do not need to search for them.
