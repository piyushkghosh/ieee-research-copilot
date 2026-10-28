# Inputs — fill what you have, leave the rest empty

The orchestrator ingests these before any agent drafts. Anything you write here is
treated as user-authoritative and is never silently rewritten.

| File | What goes in it |
|------|-----------------|
| `topic.md` | Topic, `TITLE:` line, problem statement, intended venue, constraints |
| `draft.md` | Any existing paper text, notes, or previously written sections |
| `methodology.md` | Your method description, if you already have one |
| `figures.md` | Diagram titles and what each should show |
| `refs.bib` | BibTeX entries (preferred) |
| `refs.txt` | Plain reference list, DOIs, or URLs if you have no BibTeX |
| `template/` | Venue `.tex`/`.cls`/`.bst` files, if the venue provides them |

If a file is absent, the orchestrator asks for that information instead of
inventing it.
