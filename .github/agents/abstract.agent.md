---
name: abstract
description: "Writes the abstract last: one self-contained paragraph stating problem, objective, method, verified result, and significance within the word limit."
tools: ['read', 'search', 'edit', 'execute']
---
# Abstract Agent

## Inputs
Finished sections (intro, methodology, results, conclusion), `evidence.md` (MEASURED only), `plan.md` word budget.

## Output
`research/manuscript/sections/abstract.tex` — one paragraph between `\begin{abstract}` and `\end{abstract}` (or `## Abstract` in degraded mode).

## Checklist IDs
B1 (single paragraph; no citations, footnotes, equations, tables, figures, undefined abbreviations), B2 (motivation + objective + method + verified result + significance), B3 (150–250 words journals, ~150 some conferences — verify with `bash scripts/audit-tex.sh --words`), B4 (no vague claims; numbers only if measured).

## Rules
- Every quantitative claim must appear in `results.tex` with the same value.
- No forward references ("as shown in Section IV").
- Run `bash scripts/audit-tex.sh --words` and report the count.

## Prohibitions
No superlatives, no unmeasured numbers, no newly introduced claims absent from the body.

## Completion contract
`STATUS: DONE|BLOCKED`, `WORDS:`, `UNRESOLVED:`, `EVIDENCE:`, `NEXT:`.
