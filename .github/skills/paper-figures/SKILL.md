---
name: paper-figures
description: "Produce IEEE-printable figures: plan with the figure-table agent, design with diagram-design (downloaded on demand), force a grayscale-safe print profile, export vector PDF into research/figures, then pass the format gate. Use for any architecture diagram, pipeline, flowchart, or data plot."
---

# Figure pipeline

## 0. Dependency (on demand, not vendored)
The diagram-design skill is MIT-licensed (© 2025 Cathryn Lavery) but is **not**
committed here. If `vendor/diagram-design/skills/diagram-design/SKILL.md` is
absent, fetch it:

```bash
mkdir -p vendor && git clone --depth 1 https://github.com/cathrynlavery/diagram-design vendor/diagram-design
```

Then read `vendor/diagram-design/skills/diagram-design/SKILL.md` and the
`references/` file for the chosen visual type. If git or network is unavailable,
degrade: draw with TikZ/pgfplots directly and record the fallback in `loop.md`.

## 1. Plan (figure-table agent)
Decide the semantic pattern before the visual type. State in one sentence what
the reader must understand, then the single message the figure carries. Above 9
nodes means it is probably two figures.

## 2. Design (figure-designer)
Use diagram-design's selection table and layout grammar, with the deletion-first
rule. Override every screen token with this print profile:

| Token | Screen default | Print override |
|-------|----------------|----------------|
| paper | `#f5f5f5` | `#ffffff` |
| ink | `#2d3142` | `#000000` |
| accent | `#bf4520` | `#000000` fill or `#555555` outline (no colour-only meaning) |
| emphasis | coral | line weight, hatching, or bold label |
| min text | 12 px | 8 pt at final column width |
| width | fluid | 3.5 in single column, 7.16 in double column |

Constraints: grayscale-legible; every edge labelled; units on axes; `<title>` and
`<desc>` retained for accessibility; no decorative colour.

## 3. Export
Follow `references/export.md` (manual only, never unprompted). Produce the
diagram-only SVG, then convert to vector PDF:

```bash
python3 -m cairosvg fig.svg -o fig.pdf     # if cairosvg is installed
```

Fallback chain: `firefox --headless --print-to-pdf=fig.pdf file.html` →
`rsvg-convert` → `inkscape` → keep SVG and note the limitation.

Data plots: pgfplots/TikZ in `main.tex`, not matplotlib (it is broken on some
installs; preflight detects this).

## 4. Place and gate
Save to `research/figures/fig-01/`, include via `\includegraphics`, caption below,
numbered "Fig. 1", referenced in text. Then run `ieee-format-rules` (K5, J4, H2).
