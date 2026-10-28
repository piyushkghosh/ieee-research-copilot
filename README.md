# IEEE Research Paper Copilot

A multi-agent research-writing pack for **GitHub Copilot in VS Code**. It turns Copilot into a
research team: an orchestrator, stage agents, one writer per IEEE section, advisory reviewers, and
eight read-only rule gates that audit instead of rewriting.

State lives on disk, so work survives context loss: the loop resumes from `research/.state/loop.md`.
Every round either passes the gates or produces a fix list; nothing is marked done without evidence.

## Quick start

1. Open this folder in VS Code with GitHub Copilot Chat (agent mode enabled).
2. Start the loop:

   ```
   /paper-start
   ```

   It runs the toolchain preflight, reports what this machine can and cannot do, then asks you the
   intake questions — **title, paper content, methodology, diagram titles, references, template** —
   one group at a time. Nothing is drafted until you answer.

3. Continue the loop with `/paper-loop`; audit one gate on demand with `/paper-gate`.
4. Build the PDF at any time:

   ```
   bash scripts/build-pdf.sh
   ```

Output: `research/manuscript/build/paper.pdf`.

## Manual setup (optional — the agents do this too)

```bash
node scripts/preflight.mjs        # detect tools; writes research/.state/toolkit.md
bash scripts/bootstrap.sh         # interactive: prints every command before running it
bash scripts/bootstrap.sh --tex-only --yes   # IEEEtran only, no prompts
```

`bootstrap.sh` never uses `sudo`. It fetches `IEEEtran.cls` / `IEEEtran.bst` from CTAN into
`./texmf/` (resolved via `TEXMFHOME`, which `build-pdf.sh` sets for you), installs the humanizer
skill, clones diagram-design into `vendor/`, and installs `cairosvg` for SVG→PDF.

## Folder map

```
.github/
  copilot-instructions.md   global rules every agent inherits
  agents/                   32 custom agents (Copilot format: name/description/tools)
  skills/                   paper-intake, paper-loop, paper-state, paper-gates,
                            paper-figures, paper-humanize
  prompts/                  /paper-start, /paper-loop, /paper-gate
research/
  inputs/                   YOUR material: topic, draft, methodology, figures, refs, template
  .state/                   project, plan, evidence, claims, gates, loop, toolkit
  manuscript/               main.tex, sections/*.tex, refs.bib, ieee-checklist.md
  literature/ datasets/ experiments/ figures/
scripts/
  preflight.mjs|.sh  bootstrap.sh  build-pdf.sh  audit-tex.py
texmf/                      project-local LaTeX assets (no admin rights needed)
```

## Put your material in `research/inputs/`

| File | Holds |
|---|---|
| `topic.md` | title, venue, template, problem, constraints |
| `draft.md` | anything you already wrote |
| `methodology.md` | your method — treated as authoritative, never silently redesigned |
| `figures.md` | diagram titles and what each shows (titles are locked once supplied) |
| `refs.bib` / `refs.txt` | references, DOIs, URLs |
| `template/` | the venue's `.tex`/`.cls`/`.bst`, which overrides the default IEEEtran conference setup |

Missing files are questions, not guesses. If a file is absent the agent asks you.

## Agent roster

| Group | Agents |
|---|---|
| Orchestrator | `research-orchestrator` |
| Stage | `research-planner`, `literature-review`, `problem-formulation`, `methodology`, `implementation`, `experimental-design`, `results-analysis` |
| Section writers | `ieee-section-writer`, `title`, `abstract`, `keyword`, `introduction`, `discussion`, `conclusion`, `acknowledgment`, `appendix`, `figure-table`, `references` |
| Reviewers (advisory) | `ieee-compliance`, `research-integrity`, `final-reviewer` |
| Rule gates (read-only) | `ieee-format-rules`, `citation-integrity-rules`, `research-integrity-rules`, `methodology-reproducibility-rules`, `technical-consistency-rules`, `language-and-style-rules`, `privacy-and-data-rules`, `final-submission-gate` |
| Tools | `humanizer`, `figure-designer` |

Gates have no edit rights. They emit `VERDICT: PASS|BLOCK` with issues classified
CRITICAL / MAJOR / MINOR, and the orchestrator re-dispatches the owning writer with only that issue
list. Three rounds on one item, then it escalates to you — a gate that softens to end a loop is
treated as a critical failure.

## The loop

```
intake → preflight/bootstrap → plan → draft section → content gates
      → humanizer (numbers diff must be empty) → style gate → consistency gate
      → compile gate → item closed → next item → final-submission-gate
```

Gate order matters: the humanizer pass runs before the style gate, and `audit-tex.py --numbers
--against` must show an identical multiset of numbers, units, citations, DOIs and refs, or the edit
is reverted.

## Degraded mode (no TeX)

If `preflight` finds no TeX engine or no `IEEEtran.cls`, the pack does not stop. It writes Markdown
into `research/manuscript/`, marks the compile gate `SKIPPED (no TeX)`, and reports the exact
install command for your platform. Nothing pretends to have compiled.

## Honesty rules baked in

- No fabricated citations, DOIs, datasets, or results. Unverifiable sources are marked `UNVERIFIED`.
- Every number in the manuscript must trace to a `MEASURED` row in `research/.state/evidence.md`.
- Planned experiments are never described as completed.
- `final-submission-gate` never claims acceptance and never claims IEEE approval.

## Licensing

- **diagram-design** (https://github.com/cathrynlavery/diagram-design) — MIT © 2025 Cathryn Lavery.
  Cloned on demand into `vendor/` (gitignored).
- **humanizer** (https://github.com/blader/humanizer) — the upstream repository declares **no
  license**, so its text is never copied into this repo. The `humanizer` agent installs it locally
  with `npx skills add blader/humanizer`.
- IEEEtran is fetched from CTAN at setup time; it is not redistributed here.

Not affiliated with or endorsed by IEEE.
