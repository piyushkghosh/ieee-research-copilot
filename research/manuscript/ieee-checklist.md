# IEEE Manuscript Checklist — single source of truth

Every rule agent cites this file by item ID. If a rule is not here, it is not
enforced. Venue template in `research/inputs/template/` overrides any item marked
`[template]`. Items marked `[external]` come from IEEE Author Center guidance and
were not covered by the supplied rules PDF; verify against the venue page before
enforcing them as hard blocks.

## A. Global structure
- A1 `[template]` Exact target venue template and class file. Conference default:
  `IEEEtran` conference mode.
- A2 `[external]` Section headings use Roman numerals (I, II, III…), subsections
  A, B, C, sub-subsections 1), 2). Acknowledgment and References are unnumbered.
- A3 Abstract precedes Index Terms; Index Terms precede the first section.
- A4 `[template]` Page limit respected, including references.
- A5 Every claimed contribution in the Introduction is addressed by a later
  section and is traceable to evidence.

## B. Abstract
- B1 Single paragraph, self-contained, no citations, footnotes, displayed
  equations, tables, figures, or undefined abbreviations.
- B2 Contains motivation, objective, method, main verified result, significance.
- B3 Length 150–250 words for journals; some conferences require ~150. Written
  last, after results are final.
- B4 No vague claims. Quantitative result only if measured.

## C. Index Terms
- C1 3–5 terms (journals permit up to 10), alphabetical, comma-separated.
- C2 First letter capitalized unless acronym or proper noun; acronyms defined.
- C3 No sentences, citations, or equations. Heading is "Index Terms" or
  "Keywords" per venue.

## D. Introduction
- D1 Background narrows to a specific problem; prior work cited.
- D2 Gap, objective/hypothesis, and contribution summary present.
- D3 Optional organization paragraph; no extended literature review.
- D4 No unsupported "first ever" novelty claim.
- D5 Citations numbered in square brackets by order of first appearance.

## E. Related work / Literature
- E1 Organized by theme, not chronology.
- E2 For each approach: assumption, input, output, limitation stated.
- E3 Primary sources cited; 15–40 references for a conference paper, more for a
  journal; prioritize the last 3–7 years unless a seminal work requires otherwise.
- E4 Comparison table present when methods are compared; every row traceable to a
  verified source.
- E5 Ends by positioning the proposed method against the identified gaps.
- E6 No uncritical praise of prior work. Venue may title this section "Previous
  Research" or "Background" `[template]`.

## F. Problem formulation / Methodology
- F1 High-level overview plus architecture or pipeline diagram.
- F2 Every symbol defined at or before first use; notation consistent.
- F3 Equations numbered and referenced in text; dimensions and units stated.
- F4 Design decisions justified, not merely described.
- F5 Pseudocode for multi-step algorithms.
- F6 Figures and tables referenced as "Fig. 1" and "Table I".
- F7 No results and no low-level implementation minutiae in this section.

## G. Implementation and experimental setup
- G1 Dataset name, size, source, license, splits, class distribution, preprocessing.
- G2 Hardware, OS, framework and library versions, random seed.
- G3 Hyperparameters, epochs, batch size, tuning protocol.
- G4 Metric definitions and baseline justifications.
- G5 Cross-validation / run count / statistical test / confidence interval.
- G6 Reporting of failed or discarded configurations where they affect the claim.
- G7 Datasets and libraries cited.

## H. Results and discussion
- H1 Objective reporting separated from interpretation; observation before cause.
- H2 Self-explanatory captions; labeled axes with units; legends present.
- H3 Every figure and table referenced in the text at least once.
- H4 Comparisons made under identical conditions; deviations disclosed.
- H5 Exact values with error bars, standard deviation, or confidence intervals.
- H6 Ablations, sensitivity, runtime, and failure cases included where the claim
  depends on them.
- H7 Negative or anomalous results acknowledged, not omitted.
- H8 No table-value restatement in prose; no overgeneralization.
- H9 Every superiority claim backed by a measurement in this paper.

## I. Conclusion and future work
- I1 Restates problem, solution, demonstrated findings, implications.
- I2 Quantifies the main contribution; only demonstrated results.
- I3 Limitations stated; ties back to the gap named in the Introduction.
- I4 No new methods, citations, or results; not a verbatim abstract repeat.
- I5 1–3 paragraphs for a conference paper.
- I6 Future work: 2–5 concrete, feasible directions, each tied to a stated
  limitation. No "more research is needed".

## J. Title, references, figures, acknowledgment, appendix
- J1 `[external]` Title specific, concise, descriptive, and an accurate reflection
  of the actual contribution. No unearned superlatives.
- J2 `[external]` Every in-text citation resolves to exactly one reference entry;
  every entry is cited at least once.
- J3 `[external]` No fabricated authors, titles, years, venues, or DOIs. Unverified
  entries are marked `UNVERIFIED` for human review, never silently accepted.
- J4 `[external]` Figure captions below figures; table titles above tables; figure
  numbering sequential; table numbering Roman.
- J5 `[external]` Acknowledgment lists only legitimate funding, institutional
  support, and named contributors. No ghost authorship.
- J6 `[external]` Appendix only where the venue permits; supplementary proofs,
  extended algorithms, extra results; referenced from the body.

## K. Mechanical checks (scripts, not judgement)
- K1 `scripts/audit-tex.py --citations` — every `\cite`/`[n]` has a matching bib
  entry and vice versa.
- K2 `scripts/audit-tex.py --numbers` — number/unit/citation multiset unchanged
  across a humanizer pass (non-empty diff = CRITICAL).
- K3 `scripts/audit-tex.py --figures` — every float referenced, no undefined refs.
- K4 `scripts/build-pdf.sh` — exit 0, PDF exists, no `undefined` in the log, page
  count within the venue limit.
- K5 Figure print profile — grayscale-legible, no colour-only encoding, ≥8 pt at
  final width, vector output preferred, ≥300 dpi if raster is demanded.
- K6 Word counts — abstract 150–250, section budgets from `plan.md`.
