# nikolakakis2024 — Language Models for Music Medicine Generation

- **Authors:** E. Nikolakakis, J. Ching, E. Karystinaios, G. Sipin, G. Widmer, R. Marinescu (UCSC / JKU Linz / Liberty Healthcare)
- **Venue:** Late-Breaking / Demo Session, 25th Int. Society for Music Information Retrieval Conf. (ISMIR 2024), San Francisco
- **Preprint:** arXiv:2411.09080v1 [cs.SD], 13 Nov 2024
- **License:** CC BY 4.0
- **Source file:** `references/LANGUAGE MODELS FOR MUSIC MEDICINE GENERATION 2024.pdf` (supplied by user)

## Method
Fine-tune **MusicGen** (Small/Medium/Large) with **LoRA** (low-rank adaptation) on emotion-tagged music. Prompts are comma-separated tag strings (mood, emotion, instrumentation, genre). Follows the **iso principle**: start at the patient's current valence–arousal state, traverse intermediate states, end at the desired state. 30-second clips generated per state, concatenated into a **~15-minute "music medicine" session**, with crossfades (quarter-length overlap), high-pass filtering, and spectral-gating denoising.

## Data
**MTG-Jamendo** mood/theme subset. Mood tags mapped to the valence–arousal circumplex (Russell/Posner) via a pile-sorting experiment with 3 researchers + 1 LLM (Claude); **Fleiss' kappa = 0.2471** ("fair agreement"); mapping verified by one licensed music therapist.

## Training
2 epochs, LR 7e-6, linear decay; single NVIDIA A40.

## Metrics / results (Table 1, % improvement over non-fine-tuned)
| Model | CLAP ↑ | AUPRC ↑ | Ham ↑ | Inference for 15-min session ↓ | Params ↓ |
|---|---|---|---|---|---|
| MusicGen-Large | 36.8 (+9.85%) | 0.144 (+19.37%) | 0.957 (+1.92%) | 100 ± 5 min | 3.3e9 |
| MusicGen-Medium | 38.7 (+2.97%) | 0.06 (+6.00%) | 0.929 (+0.96%) | 88 ± 10 min | 1.5e9 |
| MusicGen-Small | 33.1 (+19.12%) | 0.031 (−3.44%) | 0.942 (+0.95%) | 48 ± 2 min | 0.3e9 |

Mood/emotion extracted from generated audio with an external emotion-recognition model (Mayerl et al., MediaEval 2021); AUPRC and Hamming score measure agreement with the intended emotion. CLAP measures text–audio alignment.

## Reported limitations (authors')
- Proof of concept; "must still be evaluated experimentally before being clinically applied".
- Future work: user study on mental-wellness outcomes; continuous valence–arousal coordinates instead of discrete states for smoother transitions.

## Gaps identified (for our purposes)
1. **No human/clinical outcome** — all evaluation is model-mediated (CLAP, AUPRC, Hamming); no listener study, no patient-reported outcome, no physiological measure.
2. **Discrete emotion states** — transitions are stepped; the authors themselves propose continuous coordinates but do not implement them.
3. **Seam artefacts** — 30-s clip concatenation with crossfade is a heuristic; long-range musical coherence across 15 min is unmeasured.
4. **Slow inference** — 48–100 min to render a 15-min session; incompatible with interactive or session-time use.
5. **Thin validation of the emotion mapping** — κ = 0.247 is "fair" at best; a single therapist confirms.
6. **No ablation** — LoRA rank, epoch count, prompt schema, and post-processing (HPF, denoising, crossfade length) are untested.
7. **Demo-scale report** — 3-page extended abstract; no statistical test over clips, no variance across seeds.
8. **No reproducibility artefacts** — checkpoints, prompts, and generated audio not released in the paper.
