---
name: paper-intake
description: "First-run intake for an IEEE manuscript. Detects the environment, then collects title, paper content, methodology, diagram titles, references, and template before any drafting. Use at project start, or whenever research/inputs is empty or project.md has unset fields."
---

# Paper intake

Never draft before intake completes. Never invent an answer to an intake question.

## Step 1 — environment
Run `node scripts/preflight.mjs` (fallback `bash scripts/preflight.sh`).
Read `research/.state/toolkit.md`. If missing tools would block the pipeline,
state the exact install command per tool and ask before running anything.
Never use `sudo`. Then set `MODE` in `research/.state/project.md`:
`full-tex` if pdflatex/xelatex + latexmk exist, else `degraded-markdown`
(degrade is allowed; say so explicitly).

## Step 2 — read what already exists
Check `research/inputs/` and `research/.state/project.md`. Any supplied value is
authoritative — never re-ask and never override it.

## Step 3 — ask, one group at a time
Use the `ask_user` tool. Skip groups already answered.

1. **Title** — "Exact title?" Offer to propose 3 candidates only if the user asks.
   On answer: write `TITLE:` and `TITLE_LOCKED: true`.
2. **Paper content** — topic, problem, contributions (bulleted), any existing
   draft or file path, target length/pages.
3. **Methodology** — supplied (paste/path) or to be designed? If designed: domain,
   constraints, available datasets, compute.
4. **Diagram titles** — "List each figure title and one line on what it must
   show." Offer "you choose" → propose titles separately and wait for approval.
5. **References** — paste list, `.bib` path, DOIs, or "search for me". If search:
   say that every hit will be verified and unverifiable ones flagged.
6. **Template** — venue name and whether the venue supplies a template. If
   undecided, default to **IEEEtran conference** and say that is the default.

## Step 4 — write state
- `research/.state/project.md` — TITLE, TITLE_LOCKED, VENUE, TEMPLATE, MODE,
  Problem, Contributions, inputs ingested.
- `research/.state/plan.md` — section order and word budgets.
- `research/.state/claims.md` — seed a row per contribution: `UNSUPPORTED`.
- `research/inputs/*` — persist each answer verbatim.
- `research/.state/loop.md` — PHASE: BOOTSTRAP, NEXT_ACTION: bootstrap + first draft.

## Step 5 — stop
Report what was collected, what is still unknown, and the exact next action.
Do not start drafting in the same turn.
