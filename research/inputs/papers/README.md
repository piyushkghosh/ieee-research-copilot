# Drop reference PDFs here

Put each paper you want the Copilot to read in this folder (PDF, or `.txt`/`.md` exports).
`literature-review` extracts them with `pdftotext -layout`, writes one note per paper to
`research/literature/notes/<citekey>.md`, and adds a row to `research/manuscript/literature-matrix.md`.

Rules:
- One file per paper, filename readable (`authorYear-short-title.pdf`).
- Never move another person's papers in here; this folder is per-project, not shared.
- Every extracted claim keeps its source filename so `citation-integrity-rules` can trace it.
