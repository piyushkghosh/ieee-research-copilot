---
name: paper-ralph
description: "Autonomous, low-token execution loop. Use when the user says 'just do it', 'don't ask me', 'continue all', 'run autonomously', or invokes /paper-run. Converts the plan into stories and drives them to passing with at most one question per run."
---
# Paper Ralph — autonomous loop

Goal: finish the paper with the fewest possible turns. Every `ask_user` costs the
user credits, so questions are a last resort, not a workflow step.

## Non-negotiable rule: one question per run

At most **one** `ask_user` call per run, and only for something that cannot be
derived or safely defaulted:

- credentials, API keys, private datasets, licensed corpus access
- a user-only decision with real consequences (venue deadline, author order)
- a value that would be fabricated if guessed (measured results, grant numbers)

Everything else: **propose, record, continue.** Record the assumption in
`project.md` under "User decisions" as `ASSUMED (auto): <what> — change if wrong`.
Mark downstream claims that depend on an assumption as `PROVISIONAL`.

Opening line of an autonomous run is the single allowed confirmation:

> Running autonomously: I will assume sensible defaults for anything you have not
> given me, mark those assumptions in `project.md`, and only stop if I hit
> something I cannot invent (data, credentials, venue rules). Say "stop" to halt.

If the user already typed something like "don't ask me", skip even that.

## State: `research/.state/ralph.json`

```json
{
  "goal": "<one line: what finished means>",
  "autonomy": true,
  "stories": [
    { "id": 1, "title": "Intake", "owner": "research-orchestrator",
      "acceptance": "project.md has TITLE, VENUE, TEMPLATE, contributions; inputs ingested",
      "passes": false, "rounds": 0, "notes": "" }
  ]
}
```

Write this file **once** per plan revision (not per turn). Check progress with
`node scripts/ralph-status.mjs` — it prints the table and exits 0 only when every
story passes.

## Loop (one story per iteration)

1. `node scripts/ralph-status.mjs --next` → prints the highest-priority story with `passes:false`.
2. **Delegate it as a subagent.** Invoke the owner agent through the subagent tool
   (`task` in GitHub Copilot; `agent` in the Local harness), naming the agent
   explicitly, and pass only: story text, acceptance check, file paths, checklist IDs.
   Do not restate the whole plan.

   The loop driver never performs a story itself. If delegation fails twice, stop with
   `DELEGATION_UNAVAILABLE` and the error — no inline fallback.
3. Run the acceptance check yourself (a script, `bash scripts/build-pdf.sh`, `bash scripts/audit-tex.sh`, or a gate agent). An acceptance check is evidence, not opinion.
4. Pass → set `passes:true` in `ralph.json`, append one line to `research/.state/progress.md`
   (`<iso-time> | <id> <title> | PASS | <evidence>`), move on **without narrating**.
5. Fail → append the failure to `progress.md`, increment `rounds`, re-dispatch the same owner with only the failure text. Three failed rounds on one story = genuine blocker: report and stop.
6. Stop when `ralph-status.mjs` exits 0, or on a real blocker.

## Parallelism

Stories writing disjoint files may be dispatched in the same turn (e.g. literature and
methodology). Stories sharing a file (results → discussion) run in sequence. Never let
two subagents edit the same file concurrently.

## Story set (default order)

Intake → bootstrap/preflight → planner (problem, RQs) → literature → methodology →
experimental design → implementation → results → abstract+intro+related → discussion
+ conclusion → figures → references → content gates → humanizer → style gate →
consistency gate → compile gate → final-submission-gate.

Each story's `acceptance` must be checkable by a command or a gate verdict — never
"looks good".

## Output discipline (this is where the credits go)

- One short progress line per story: `[3/18] methodology — PASS (rounds: 1)`.
- No essay per step. No "here is what I recorded" summaries. No restating state.
- The full report happens **once**, at the end: stories passed, gates verdict,
  unresolved items, assumptions made, artifact path.
- Never re-ask anything already present in `research/inputs/` or `project.md`.
- Never ask "should I continue?" — continuing is the default.

## Degraded mode

If `toolkit.md` says `degraded-markdown`, one line is enough: `compile gate SKIPPED (no TeX); run bash scripts/bootstrap.sh --tex-only for a PDF`. Do not stop the loop for this.
