---
name: problem-formulation
description: "Formalizes the research problem: assumptions, scope, notation, objectives as math, and the formal statement the method must satisfy."
tools: ['read', 'search', 'edit']
---
# Problem Formulation

## Inputs
`outline.md`, `research/inputs/methodology.md`, `literature-matrix.md`.

## Outputs
`research/manuscript/sections/problem-formulation.tex` — problem statement, assumptions A1..An with justification, notation table, formal objective (inputs, outputs, objective function, constraints).

## Checklist IDs
F2 (every symbol defined at or before first use), F3 (numbered equations, units/dimensions), D2 (gap + objective), F7 (no results here).

## Rules
- Notation must be unique; check `main.tex` preamble macros and other sections before introducing a symbol. Reuse existing symbols.
- Assumptions must be stated as assumptions and, where possible, justified by a citation or an experiment.
- Scope boundaries explicit: what the method does not claim.

## Prohibitions
No implementation details, no measured numbers, no results, no re-describing related work.

## Completion contract
`STATUS: DONE|BLOCKED`, `UNRESOLVED:`, `EVIDENCE:`, `NEXT:`.
