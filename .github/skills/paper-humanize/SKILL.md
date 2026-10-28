---
name: paper-humanize
description: "Run a humanizer pass on a manuscript section without breaking IEEE register or technical meaning: remove AI-writing tells, preserve passive voice, hedges, numbers, units, citations, and DOIs, and verify mechanically. Use after content gates pass and before the style gate."
---

# Humanizer pass for IEEE prose

Source of patterns: `blader/humanizer`. It is installed, not vendored (upstream
declares no license). If absent, fetch into the project:

```bash
npx skills add blader/humanizer --agent '*'    # project-local, no --global
```

Read its `SKILL.md` and apply its numbered patterns. If the fetch fails, perform
the pass manually against this subset and say so in `loop.md`.

## Applicability to IEEE papers
Apply in full:
- Section A — staging instead of stating (not-X-but-Y, one-line closers, staged
  run-ups, arguing with no one).
- Section C — inflation and borrowed authority (AI words, inflated significance,
  vague association, `-ing` riders, sales language, borrowed authority).
- Section D — decorative formatting (bold as decoration, decorative headings).
- Section E — chat residue, knowledge-limit disclaimers, heading repeated as first
  sentence, writing about the document instead of its subject.
- Section F — re-explaining what the reader already knows.

Apply selectively:
- Pattern 6 forced triads, pattern 8 dash abuse, pattern 10 hyphen spam.

Suppress:
- Pattern 11 passive voice — standard in methods and results reporting.
- Pattern 9 hedges — legitimate epistemic qualification in science.

Conflict rule: `language-and-style-rules` governs formality; the humanizer governs
AI tells. When they conflict, the style gate wins and the conflict is logged in
`loop.md` for human review.

## Hard invariants
Never change: numbers, units, measurements, citations `[n]`, DOIs, author names,
figure/table references, claim strength, or technical terminology. Never add facts.

## Verification (mandatory)
```bash
cp <section> /tmp/before.tex
# ... edit ...
python3 scripts/audit-tex.py --numbers /tmp/before.tex <section>
```
The multiset of numbers, units, citations, and DOIs must be identical. Any diff is
CRITICAL: revert and re-dispatch the writer. Then report what changed and any
sentence whose meaning shifted enough to need author review.
