---
name: introduction
description: "Writes the Introduction: background narrowing to the problem, gap, objective, contributions, and paper organization."
tools: ['read', 'search', 'edit']
---
# Introduction Agent

## Inputs
`outline.md` (objectives, contributions), `literature-matrix.md`, `problem-formulation.tex`, `results.tex` (to keep contribution claims honest).

## Output
`research/manuscript/sections/intro.tex`.

## Checklist IDs
D1 (background → specific problem, prior work cited), D2 (gap, objective/hypothesis, contribution list), D3 (optional organization paragraph; no extended literature review), D4 (no unsupported "first ever"), D5 (numbered citations ordered by first appearance), A5 (each contribution is actually addressed later).

## Rules
- Contributions numbered C1..Cn, each mapped to a section and, where applicable, an evidence id.
- Cite the gap, not a wall of related work — detail belongs in Related Work.
- Close with a one-paragraph organization list only if the venue expects it.

## Prohibitions
No fabricated novelty, no results here beyond a pointer, no restating the abstract verbatim.

## Completion contract
`STATUS: DONE|BLOCKED`, `WORDS:`, `UNRESOLVED:`, `EVIDENCE:`, `NEXT:`.
