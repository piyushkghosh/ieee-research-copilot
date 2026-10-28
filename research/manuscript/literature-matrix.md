# Literature comparison matrix

Rows are verified from supplied PDFs only. Any row added later must carry its source and be checked by `citation-integrity-rules`.

| Key | Venue / Year | Method | Data | Metric | Reported result | Limitation | Gap |
|---|---|---|---|---|---|---|---|
| bhuvana2023 | RMKMATE 2023 (IEEE), DOI 10.1109/RMKMATE59243.2023.10369221 | Double-stacked LSTM / GRU over ABC notation; Flask UI | Private ABC corpus (size, splits, license unreported) | Character-level accuracy; subjective listener recall | 87% train accuracy; 70% recall in subjective evaluation | Monophonic only; no benchmark; token accuracy ≠ musical quality | No reproducible data/split/seed; no modern baseline; no conditioning; no statistics |
| nikolakakis2024 | ISMIR 2024 LBD (arXiv:2411.09080) | MusicGen + LoRA, iso-principle prompting, 30-s clip concatenation | MTG-Jamendo mood/theme subset; circumplex mapping (Fleiss κ=0.247) | CLAP, AUPRC, Hamming score | MusicGen-Large CLAP 36.8 (+9.85%), AUPRC 0.144, Ham 0.957 | No user/clinical study; discrete states; 48–100 min inference for 15 min audio | No human outcome; no continuous affect control; no ablation; no released artefacts |

## Positioning (what is genuinely open)

Both works evaluate generated audio with **proxy signals** — next-token accuracy in one, CLAP/emotion-classifier agreement in the other — and neither closes the loop with listeners or patients. Neither reports a reproducible benchmark configuration (data splits, seeds, code), so cross-paper comparison is impossible. The unoccupied intersection is *affect-continuous, long-form, reproducible generation with human-validated evaluation at interactive latency*.

> These are the only two papers read so far. Novelty claims in this project remain `CLAIM_UNVERIFIED` until the survey is widened and recorded in `research/literature/notes/`.
