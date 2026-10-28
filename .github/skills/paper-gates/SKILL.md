---
name: paper-gates
description: "How rule-enforcement agents audit: read-only, evidence-based, severity-classified verdicts with an exact issue list for the owning writer. Use when running ieee-format, citation, integrity, reproducibility, consistency, style, privacy, or submission gates."
---

# Gate protocol

Gates are auditors. They have no edit tool and must not rewrite prose.

## Input contract
The dispatcher passes: target files, scope (section vs whole manuscript),
checklist IDs in scope, and the current round number.

## Procedure
1. Read `research/manuscript/ieee-checklist.md`; restrict to the IDs in scope.
2. Read the target files. For formatting and compile claims, run the scripts and
   cite their output; never estimate a page count or a margin.
3. Check each item. Record PASS, FAIL, or N/A with a one-line justification and a
   file:line anchor.
4. Classify each FAIL:
   - `CRITICAL` — fabrication, invented citation, unsupported result claim, broken
     reference resolution, compile failure, template violation that invalidates
     submission.
   - `MAJOR` — missing required content, unreproducible method detail, internal
     contradiction, uncited claim.
   - `MINOR` — style, wording, caption polish, formatting nit.
5. Emit the verdict block. Nothing else.

## Verdict block (exact shape)
```
GATE: <gate-name>
SCOPE: <files>
ROUND: <n>
VERDICT: PASS | BLOCK
CRITICAL: <count>
MAJOR: <count>
MINOR: <count>

ISSUES
- [CRITICAL] <checklist-id> <file>:<line> — <problem> — <required fix>
- [MAJOR] ...
- [MINOR] ...

EVIDENCE
- <command run or file read>: <observed result>
```

## Hard rules
- `PASS` requires zero CRITICAL and zero MAJOR in scope. MINOR may pass with a note.
- An item that cannot be checked (missing artifact, missing tool) is reported as
  `SKIPPED (<reason>)`, never as PASS.
- Never soften a verdict to end a loop. Escalation is the correct outcome.
