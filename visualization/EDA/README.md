# RF Signal Classification — Actual Dataset EDA Visualization Package

**Prepared for:** Arya — Signal Processing

## Execution status

The uploaded project branch contained the actual `rf_dataset_v1.mat` and the committed MATLAB visualization implementation.

The 12 PNG figures in this folder were generated **from the actual `rf_dataset_v1.mat`** in this environment by faithfully reproducing the numerical operations specified by the committed MATLAB scripts. A MATLAB runtime itself was not available here, so these PNGs are **data-derived reproductions of the committed MATLAB visualization logic**, not claims of MATLAB-runtime execution.

## Dataset

- Source: `rf_dataset_v1.mat`
- Raw QPSK array: `1024 × 1000` complex double
- Raw 16-QAM array: `1024 × 1000` complex double
- Combined: `1024 × 2000` complex double
- Classes: QPSK (1000), 16-QAM (1000)

## Preprocessing reproduced

Exactly following the committed MATLAB pipeline:

1. Per-frame complex mean/DC removal.
2. Per-frame RMS normalization.
3. Filtering disabled.

The resulting processed signal has unit RMS per frame.

## Feature representations

### I/Q

`1024 × 2 × 2000`

- Channel 1 = I
- Channel 2 = Q
- Channel 3 = frame

### STFT

`64 × 61 × 2000`

- 64-sample periodic Hamming window
- 48-sample overlap
- 64-point FFT
- centered frequency arrangement
- log-power feature

`10*log10(abs(S).^2 + eps)`

## Figures

1. `01_raw_IQ_time_domain.png` — raw QPSK and 16-QAM I/Q waveforms.
2. `02_raw_constellation_QPSK.png` — actual raw QPSK constellation.
3. `03_raw_constellation_16QAM.png` — actual raw 16-QAM constellation.
4. `04_preprocessing_before_after.png` — actual QPSK before/after preprocessing.
5. `05_processed_IQ_time_domain.png` — final processed I/Q waveforms.
6. `06_processed_constellation_QPSK.png` — processed QPSK constellation.
7. `07_processed_constellation_16QAM.png` — processed 16-QAM constellation.
8. `08_STFT_QPSK.png` — QPSK STFT log-power representation.
9. `09_STFT_16QAM.png` — 16-QAM STFT log-power representation.
10. `10_IQ_feature_visualization.png` — actual 1024×2 I/Q representation for a frame.
11. `11_class_comparison.png` — actual post-preprocessing amplitude distributions.
12. `12_EDA_summary.png` — compact summary of the complete signal-processing flow.

## Important metadata note

The raw MAT file does not contain `Fs` or SNR metadata. The committed `load_rf_dataset.m` therefore assigns `NaN` to these fields, and `extract_stft_features.m` falls back to `Fs = 1.0` for STFT processing. Consequently, the STFT figures in this package use the implementation's normalized frequency/time fallback rather than a physical 1 MHz axis.

This does not change the STFT tensor dimensions or log-power extraction, but it should be corrected in the MATLAB runtime if a physical frequency axis in Hz is required.

## How the figures relate to Arya's work

The visual sequence is:

Raw RF baseband
→ DC removal
→ RMS normalization
→ I/Q representation
→ STFT representation
→ class comparison
→ AI-ready feature representation

The figures are intended as evidence for the Signal Processing Lead contribution during faculty review.
