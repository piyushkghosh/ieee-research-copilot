---
description: Start or resume an IEEE paper in this repo — checks tools, runs intake, then begins the loop.
agent: research-orchestrator
---

Start the IEEE Research Paper Copilot for this repository. Follow `.github/skills/paper-intake/SKILL.md` exactly.

1. Run `bash scripts/preflight.sh` (or `node scripts/preflight.mjs`). Read `research/.state/toolkit.md`. State the detected `MODE` and list every missing tool with the exact fix command. Do not install anything without asking. Never use sudo.
2. Read `research/.state/loop.md`, `project.md`, `plan.md`, and every file in `research/inputs/`. Anything the user already supplied is authoritative — never re-ask, never overwrite.
3. Ask the missing intake questions one group at a time with `ask_user`, in this order: title · paper content/contributions/draft · methodology (supplied vs designed) · diagram titles and what each shows · references (paste / .bib path / DOIs / search) · template (venue or default IEEEtran conference). Wait for each answer.
4. Write the answers into `research/inputs/*`, `research/.state/{project,plan,claims,loop}.md`, and lock `TITLE_LOCKED: true` unless the user asked for title proposals.
5. If TeX is missing and the user accepts degraded mode, set `MODE: degraded-markdown` and record that the compile gate will be `SKIPPED (no TeX)`.
6. Stop. Do not draft any prose in this step. Report: mode, files written, what is still unknown, and the next action.

If `research/.state/loop.md` already shows PHASE other than INTAKE, resume there instead and say so.
