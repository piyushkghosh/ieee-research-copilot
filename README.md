# IEEE Research Paper Copilot

A multi-agent workspace for writing IEEE research papers in VS Code with GitHub Copilot.

The pack turns Copilot Chat into a research team: an orchestrator, stage agents (planning, literature, methodology, experiments), one writer per IEEE section, and eight independent rule gates that audit the manuscript and block it when the evidence, citations, or formatting do not hold up.

Nothing is invented. Numbers must trace to a measured artifact, references must resolve, and the manuscript compiles to a PDF before the final gate will pass.

---

## Quick start

**Prerequisites**

| Requirement | Notes |
|---|---|
| VS Code | 1.100 or newer |
| GitHub Copilot + Copilot Chat extension | signed in; custom agents and skills require a Copilot plan |
| Node.js or Bash | used by the preflight script |
| LaTeX (optional) | `pdflatex` + `IEEEtran` — if absent, the workspace degrades to Markdown |

```bash
git clone https://github.com/<your-account>/ieee-research-copilot.git
cd ieee-research-copilot
code .
```

In VS Code, open Copilot Chat, select the **research-orchestrator** agent, and send:

```
/paper-start
```

That is the only command you need. `/paper-start` is a pipeline, not a form: it detects your toolchain, writes the toolchain report, and then interviews you before a single sentence is drafted.

---

## What `/paper-start` does

1. **Toolchain preflight** — runs `scripts/preflight.sh` (Node) or falls back to Bash, probes TeX engines, `IEEEtran`, PDF tools, Python, browsers and SVG converters, and writes `research/.state/toolkit.md` with `MODE: full-tex` or `MODE: degraded-markdown` plus the exact install command for anything missing. It never runs `sudo` and never installs silently.
2. **Optional bootstrap** — offers to fetch `IEEEtran.cls`/`.bst` from CTAN into the project's own `texmf/`, install the humanizer skill, and clone the diagram-design skill. All local, all reversible.
3. **Context intake** — asks you, one group at a time:
   - the paper title (locked once you give it)
   - the topic, problem, contributions, and any existing draft
   - whether the methodology is yours or should be designed
   - diagram titles and what each figure must show
   - references: paste a list, point at a `.bib`, give DOIs, or ask it to search
   - the target venue and template (defaults to the IEEE conference template)
4. **State initialization** — records everything in `research/inputs/` and `research/.state/`, then stops and asks you to run `/paper-loop`.

Answers you give are authoritative. The pack never overwrites your text with a generated version.

---

## The writing loop

```
/paper-loop
```

One iteration = one open item, carried to a verdict:

1. Read `research/.state/loop.md`, pick the highest-priority unblocked item.
2. Dispatch the owning agent with the item, its target file, and the relevant checklist IDs only.
3. Run the gates that own that item.
4. **BLOCK** → append the issues verbatim to `loop.md`, increment the round, re-dispatch the writer with only the issue list.
5. **PASS** → close the item and update the plan.

A gate cannot pass itself by rewriting the text — the eight rule gates are read-only. After three rounds on the same item the orchestrator stops and escalates to you instead of iterating forever.

Gate order: content → humanizer → language → consistency → compile → final submission.

### State lives on disk

Closing the chat, restarting VS Code, or losing the session costs nothing:

| File | Purpose |
|---|---|
| `research/.state/project.md` | title, venue, template, mode |
| `research/.state/plan.md` | section plan, owners, word budgets, figure list |
| `research/.state/evidence.md` | append-only ledger: `MEASURED` / `PLANNED` / `ASSUMED` |
| `research/.state/claims.md` | every claim, its evidence anchor, its status |
| `research/.state/gates.md` | one row per gate run: verdict, round, issue counts |
| `research/.state/loop.md` | round, phase, open items, next action |
| `research/.state/toolkit.md` | what this machine can actually do |

Re-invoking the orchestrator resumes from `loop.md`.

---

## Agents

**Orchestration** — `research-orchestrator`. Owns the loop, delegates, never writes paper text.

**Stages**

| Agent | Responsibility |
|---|---|
| `research-planner` | problem, objectives, research questions, contribution claims, objective→experiment map |
| `literature-review` | related work, comparison matrix, gaps, verified sources only |
| `problem-formulation` | assumptions, notation, formal objective |
| `methodology` | pipeline, architecture, algorithms, equations |
| `implementation` | datasets, splits, versions, seeds, hyperparameters |
| `experimental-design` | hypotheses, baselines, metrics, statistics, falsification criteria |
| `results-analysis` | measured results, tables, evidence-ledger entries |

**Section writers** — `ieee-section-writer`, `title`, `abstract`, `keyword`, `introduction`, `discussion`, `conclusion`, `acknowledgment`, `appendix`, `figure-table`, `references`.

**Advisory reviewers** — `ieee-compliance`, `research-integrity`, `final-reviewer`.

**Rule gates** (read-only, emit `VERDICT: PASS | BLOCK` with CRITICAL / MAJOR / MINOR issues)

| Gate | Enforces |
|---|---|
| `ieee-format-rules` | template, numbering, captions, page limits, fonts, PDF build |
| `citation-integrity-rules` | every citation resolves, every entry verified, no invented DOIs |
| `research-integrity-rules` | no fabricated data, no unearned novelty, planned ≠ completed |
| `methodology-reproducibility-rules` | datasets, splits, seeds, versions, metrics, baselines |
| `technical-consistency-rules` | terminology, symbols, abstract↔results↔conclusion agreement |
| `language-and-style-rules` | formal academic register, no promotional claims |
| `privacy-and-data-rules` | licences, PII, credentials, human-subject ethics |
| `final-submission-gate` | all gates green, every number evidenced, checklist written |

**Tools** — `humanizer` (removes AI-tell phrasing while proving numbers, units, citations and DOIs are byte-identical before and after), `figure-designer` (print-safe diagrams via the diagram-design skill).

---

## Layout

```
.github/
  copilot-instructions.md    global rules for every agent
  agents/                    32 custom agents
  skills/                    intake, loop, state, gates, figures, humanize
  prompts/                   /paper-start, /paper-loop, /paper-gate
research/
  inputs/                    your title, draft, methodology, figures, refs, template
  literature/                notes + GAP-ANALYSIS.md
  experiments/               design, protocol, raw outputs
  figures/fig-NN/            rendered figure assets
  manuscript/
    main.tex                 IEEEtran skeleton
    sections/*.tex           one file per section, one owner each
    ieee-checklist.md        single source of truth for every gate
    build/paper.pdf          compiled output
  .state/                    loop, plan, evidence, claims, gates, toolkit
scripts/
  preflight.mjs|sh           toolchain detection
  bootstrap.sh|ps1           CTAN, skills, converters (no sudo)
  build-pdf.sh               compile gate with log audit
  audit-tex.py               citations, figures, word counts, number diff
  selftest.sh                verifies the pack itself
  new-project.sh             clean per-author copy
```

---

## Scripts

```bash
bash scripts/preflight.sh          # what this machine can do → research/.state/toolkit.md
bash scripts/bootstrap.sh          # fetch IEEEtran, install skills, converters
bash scripts/bootstrap.sh --tex-only --yes
bash scripts/build-pdf.sh          # BUILD: PASS|FAIL|SKIPPED, PAGES:, ISSUES:
python3 scripts/audit-tex.py --all
python3 scripts/audit-tex.py --numbers sections/results.tex --against /tmp/results.bak
bash scripts/selftest.sh           # self-check of the pack
bash scripts/new-project.sh ../my-paper
```

`build-pdf.sh` returns exit 3 with `BUILD: SKIPPED` when no TeX engine exists — the loop records `SKIPPED (no TeX)` and continues in Markdown rather than pretending to compile.

---

## Writing with real sources

Drop PDFs into `research/inputs/papers/`, then:

```bash
pdftotext -layout research/inputs/papers/your-paper.pdf -
```

Every extracted claim becomes a note under `research/literature/notes/<citekey>.md`. The literature agent records the method, data, metrics, reported numbers and limitations, then derives gaps. Claims that rest on too few papers are labelled `CLAIM_UNVERIFIED` and the integrity gate refuses to let novelty claims through on that basis.

---

## Two authors, two papers

Each project directory is independent. Share the pack, never the research state:

```bash
bash scripts/new-project.sh ~/papers/my-ieee-paper
```

The copy keeps agents, skills, prompts and scripts, and resets `research/.state/`, `research/inputs/`, literature notes, figures and build artefacts. Each author then runs `/paper-start` in their own copy, with their own title and references.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `/paper-start` not listed | Copilot Chat must be installed and signed in; reload the window after cloning |
| `MODE: degraded-markdown` | install TeX, or run `bash scripts/bootstrap.sh --tex-only` if only `IEEEtran` is missing |
| `BUILD: SKIPPED` | no TeX engine on PATH — the workspace stays in Markdown mode by design |
| `IEEEtran.cls not found` | `bash scripts/bootstrap.sh --tex-only --yes` |
| figures fail to convert | `pip3 install --user cairosvg`, or install `rsvg-convert` / Firefox |
| gate blocks forever | check `research/.state/loop.md`; after three rounds it escalates instead of looping |

---

## Design principles

- **Evidence before prose.** A sentence with a number and no `MEASURED` evidence row is a CRITICAL finding.
- **Auditors never author.** Gates flag and demand fixes; the owning writer makes them.
- **No silent installs.** Every missing tool is reported with the exact command.
- **Your text wins.** Supplied titles, methodology and figure captions are locked and cannot be changed by an agent.
- **Nothing is claimed as done that was not verified.** Compilation, citation resolution and number integrity are checked mechanically, not asserted.

---

## Attribution

- `IEEEtran` class and bibliography style are fetched from CTAN at setup time and are not redistributed here.
- The [humanizer](https://github.com/blader/humanizer) skill is installed at setup time; the upstream repository declares no licence, so its text is never copied into this repo.
- The [diagram-design](https://github.com/cathrynlavery/diagram-design) skill is MIT licensed, © 2025 Cathryn Lavery, and is cloned on demand into `vendor/`.

This project is not affiliated with or endorsed by IEEE. It does not predict or guarantee acceptance at any venue.
