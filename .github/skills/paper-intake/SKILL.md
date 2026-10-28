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

### Step 2b — ingest sources before asking about the title
If `research/inputs/papers/` holds PDFs, run `pdftotext -layout <pdf>` and write one
note per paper to `research/literature/notes/<citekey>.md`, then a first
`research/manuscript/literature-matrix.md`. If `research/inputs/topic.md` or
`draft.md` has content, read it now.

The paper is about **the user's research subject** — never about this repository,
the agent pack, Copilot, or the process of writing papers. Titles, gaps, and
contributions must be derived from the ingested sources. If nothing has been
ingested yet, asking for a title is premature: ask for the topic or the papers first.

## Step 2c — methodology-only projects
If the user provides a methodology but no topic, title, or contributions:

1. Set `SOURCE_OF_TRUTH: methodology` in `project.md` and treat `research/inputs/methodology.md`
   (or the pasted text) as immutable input.
2. Derive, do not ask: the problem the method addresses, the contribution list, research
   questions, the pipeline and figure plan, and the reference topics that the method
   implies. Mark each derived item `PROVISIONAL`.
3. Propose one title from the method's core mechanism and record it with
   `TITLE_LOCKED: false` so the user can correct it later.
4. Do not interrogate the user about the remaining groups; continue to drafting under
   `AUTONOMY: on`.

## Step 3 — ask, one group at a time
Use the `ask_user` tool. Skip groups already answered.

1. **Title** — "Exact title?" If `topic.md`/`papers/`/`literature-matrix.md` exist,
   offer 3 candidates derived from that material and name the source file each came
   from. Otherwise ask for the topic first. On answer: write `TITLE:` and
   `TITLE_LOCKED: true`.
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

## Autonomous mode (when the user says "don't ask me", "just do it", or /paper-run)

Ask nothing except the single opening line in `paper-ralph`. Then:

- Title: derive from `topic.md`/`papers/`; if nothing exists, use a descriptive
  placeholder and record `TITLE_AUTO: true` so it is revisited, never an invented claim.
- Paper content: use `draft.md`/`topic.md`; list contributions only where the draft supports them.
- Methodology: if not supplied, mark `PROPOSED` and continue — do not ask.
- Diagram titles: derive from the methodology; record them in `figures.md`.
- References: use `refs.txt`/`refs.bib`; verify each; leave the list as-is if nothing else exists.
- Template: IEEEtran conference unless a template is present.
- Record every default as `ASSUMED (auto)` in `project.md`.

Do not produce per-group status essays. Write the files, then one line: `intake complete — MODE: <mode>, N assumptions recorded`.
