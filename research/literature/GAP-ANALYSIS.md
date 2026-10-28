# Gap analysis — AI music generation (seed set: 2 supplied papers)

Scope: `references/Automatic_music_generation_using_RNN.pdf` (RMKMATE 2023) and `references/LANGUAGE MODELS FOR MUSIC MEDICINE GENERATION 2024.pdf` (ISMIR 2024 LBD). Claims about the wider field are marked `[UNVERIFIED — needs survey]`.

## G1. Evaluation is proxy-only
- P1 scores next-character accuracy (87%) — predicts tokens, not musicality.
- P2 scores CLAP/AUPRC/Hamming against another model, not against listeners.
- Neither reports a listening study protocol, rater population, or agreement statistic (P2 reports κ only for its *label mapping*, not for output quality).
- **Open:** a listening/quality protocol with reported inter-rater agreement, plus correlation between proxy metrics and human ratings.

## G2. No reproducible baseline
Both use non-released artefacts: P1 a private ABC corpus with no split/seed; P2 no checkpoints, prompts, or audio. Neither paper's numbers can be reproduced from the text.
- **Open:** fixed split + seeds + released prompts/config + variance over runs.

## G3. Affect control is coarse
P1 has no conditioning at all. P2 conditions on discrete circumplex states and itself proposes continuous coordinates as future work; κ=0.247 for the state mapping is weak evidence.
- **Open:** continuous valence–arousal conditioning with measured trajectory error.

## G4. Long-form coherence unmeasured
P2 concatenates 30-second clips with quarter-length crossfades; no metric tests musical continuity across the 15-minute session, and seams are acknowledged only implicitly.
- **Open:** a long-horizon coherence metric and/or seam-aware generation.

## G5. Latency forbids interactive use
P2 needs 48 min (Small) to 100 min (Large) to render a 15-minute session. P1 reports no timing at all.
- **Open:** real-time or near-real-time generation, with latency reported per minute of audio.

## G6. Thin ablations
P2 does not ablate LoRA rank, epochs, prompt schema, crossfade length, or the post-processing chain, so the source of its gains is unknown. P1 compares only LSTM vs GRU-ish variants.
- **Open:** component-wise ablation isolating fine-tuning, prompting, and post-processing.

## G7. Missing rigour conventions
No confidence intervals, no significance tests, single runs in both; P1's "70% recall" has no reported sample size.
- **Open:** n runs, mean ± SD, paired test, effect size.

## Candidate research questions (unverified, for the planner to adjudicate)
- RQ1: Does continuous valence–arousal conditioning reduce measured trajectory error versus discrete-state prompts, at equal listening quality?
- RQ2: Do seam-aware generation or overlap-add conditioning improve long-horizon coherence over fixed-length concatenation?
- RQ3: How strongly do CLAP/AUPRC/Hamming correlate with human quality ratings for therapeutic music?
- RQ4: What latency budget is achievable for a 15-minute affect-steered session on a single GPU, and what does it cost in quality?

## Status
`CLAIM_UNVERIFIED` — two-paper seed set. Widening the survey is a prerequisite before any novelty statement enters the manuscript (checklist D4/E5, gate `research-integrity-rules`).
