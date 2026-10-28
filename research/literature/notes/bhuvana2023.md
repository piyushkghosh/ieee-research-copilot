# bhuvana2023 — Automatic music generation using RNN

- **Authors:** V. Bhuvana Kumar, M. Kathiravan (Hindustan Institute of Science & Technology, Chennai)
- **Venue:** 2023 Int. Conf. on Research Methodologies in Knowledge Management, AI and Telecommunication Engineering (RMKMATE), IEEE
- **DOI:** 10.1109/RMKMATE59243.2023.10369221
- **Source file:** `references/Automatic_music_generation_using_RNN.pdf` (supplied by user)
- **Status:** extracted from the supplied PDF (title/DOI/venue verified from the PDF's own header)

## Method
Symbolic melody generation over **ABC notation**. Recurrent models (LSTM / GRU), reports a "double stacked layer LSTM" as best. Framed as multi-class classification over 92 next-character classes with a softmax output.

## Data
A private ABC-notation corpus assembled by the authors. Size, license, splits, and class distribution are not reported.

## Metrics reported
- Character-level training accuracy: 0.84 at epoch 78, ~82% earlier, up to **87%** after further training.
- Subjective evaluation by listeners with classical-music interest / performers / composers / digital composers; reports **70% recall** for the double-stacked LSTM "outperforming the composer pattern".

## System
Flask web UI (home page → "predict" → generated sequence page). HTML/CSS front end.

## Reported limitations (authors')
- Only single-stream / monophonic output; multi-instrument and polyphonic music left for future work.
- Handling of unfamiliar notes not solved; suggests filtering "new noises" and substituting known motifs.

## Gaps identified (for our purposes)
1. **Metric validity** — character accuracy measures token prediction, not musical quality; no perceptual or musicological evaluation protocol is defined.
2. **No standard benchmark** — private ABC corpus, no split, no seed, no released code/data ⇒ irreproducible.
3. **No modern baselines** — WaveNet/MuseGAN/Magenta cited in the survey but not compared experimentally; no Transformer/diffusion baseline.
4. **No statistical rigour** — single run, no variance, no significance test, no confidence interval.
5. **Monophonic only** — no polyphony, no multi-track, no instrumentation control.
6. **No conditioning** — no emotion, genre, or user-intent control signal.
7. **Subjective study underspecified** — listener count, background, task, and agreement statistic are not reported.
8. **No cost/latency reporting** — inference time, model size, hardware unspecified.
