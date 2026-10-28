---
description: Humanize an existing manuscript with the real blader/humanizer skill — per section, then once across the whole paper.
agent: research-orchestrator
---
Humanize work that already exists. This does not draft, restructure, or re-research anything.

## 0. Load the skill first (hard gate)
`bash scripts/fetch-humanizer.sh` → then the humanizer agent must `read .humanizer/SKILL.md`
in full (32 KB, 26 patterns). If it cannot be loaded, stop and report
`HUMANIZER_SKILL_UNAVAILABLE`. Never proceed on a remembered pattern list.

## 1. Baseline — measure before you touch anything
```
bash scripts/final-humanize-check.sh --snapshot
python3 scripts/style-audit.py --scope research/manuscript/sections
```
Keep the style-audit output: its per-file density is the "before" column of your report.

## 2. Per-section pass — delegate, one section per subagent
Dispatch the `humanizer` agent (via `task`) for each file in
`research/manuscript/sections/*.tex`. Independent files may run in parallel.

Each dispatch carries only: the file path, `research/inputs/voice.md` if it exists, the
instruction to read `.humanizer/SKILL.md` first, and the two invariants:
- `bash scripts/audit-tex.sh --numbers <file> --against <file>.pre-humanize` → identical
- `python3 scripts/style-audit.py <file> --max-density 2.0` → exit 0

You do not edit section files yourself. If delegation is impossible, report
`DELEGATION_UNAVAILABLE`.

## 3. Whole-paper pass
After every section passes, dispatch `humanizer` once in whole-paper mode: read all
sections in manuscript order first, then fix only what shows at scale — repeated
sentences and openers, monotone paragraph lengths, transition phrases used more than
once, terminology and abbreviation drift.

## 4. Verify
```
bash scripts/final-humanize-check.sh --verify        # exit 0 = no number/citation changed
python3 scripts/style-audit.py --max-density 2.0     # exit 0 = tells under threshold
```
Exit 1 from either → restore the affected files from
`research/.state/final-humanize-baseline/`, re-dispatch that section, do not report success.

## 5. Report once
A table only: file | density before | density after | numbers identical | deviations.
Then one line on remaining unresolved items. No prose summary of what humanizing is.

## Rules
- Never change numbers, units, citations, DOIs, names, references, figure/table refs, or claim strength.
- Never merge, split, reorder, or delete sections; never add or remove technical claims.
- Keep passive voice only where the actor is genuinely irrelevant; keep hedges that are load-bearing. Everything else follows the skill's pattern list.
- Do not claim a detector score. Report the lint numbers you measured.
