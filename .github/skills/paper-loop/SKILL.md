---
name: paper-loop
description: "The drive-to-completion loop for an IEEE manuscript: read state, dispatch one owning agent, run gates, re-dispatch on BLOCK, repeat until every item passes or the round budget forces an escalation. Use whenever work should continue autonomously until the paper is submission-ready."
---

# Paper loop

State is on disk. Context loss is normal; `research/.state/loop.md` is the resume
point.

## Cycle
1. **Read** `research/.state/loop.md`, `project.md`, `plan.md`, `gates.md`.
   If `NEXT_ACTION` is set, do exactly that.
2. **Pick** the highest-priority OPEN item with no unmet dependency.
   Independent items with disjoint output files may run in parallel (one `task`
   dispatch each); never parallelize two writers on the same file.
3. **Dispatch** the owning agent with only: the item, its input paths, its output
   path, and the relevant checklist item IDs. Do not paste the whole conversation.
4. **Gate** the result: run every gate that owns the touched scope. Gates return
   `VERDICT: PASS|BLOCK` and issues tagged CRITICAL/MAJOR/MINOR.
5. **On BLOCK**: append the issues to `loop.md`, increment that item's round
   counter, re-dispatch the **owning writer** with the issue list only. Gates never
   rewrite.
6. **On PASS**: mark the item closed, update `gates.md`, set the next action.
7. **Budget**: 3 rounds per item. On the fourth attempt, stop and escalate to the
   human with the unresolved issues. A silent pass is a critical failure.
8. **Terminate** when every item in `plan.md` is PASS, all gates in `gates.md` are
   PASS or `SKIPPED (<reason>)`, `scripts/build-pdf.sh` returns 0 (or
   `SKIPPED (no TeX)` in degraded mode), and `final-submission-gate` returns PASS.
   Then report the artifact path, page count, and any unresolved MINOR issues.

## Gate order for a section
content gates → humanizer → style gate → consistency re-check → compile.
The humanizer pass is followed by `scripts/audit-tex.py --numbers`; any diff in
numbers, units, citations, or DOIs is CRITICAL and the pass is reverted.

## Anti-patterns
- Declaring done because a writer said so.
- Letting a gate edit the manuscript.
- Re-running the same failing dispatch without changing the input.
- Fabricating a measurement to satisfy a results gate.
