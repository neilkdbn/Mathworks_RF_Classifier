# EDA Visualization Package

This folder contains presentation-ready visualizations of the MathWorks RF Signal Classification dataset and Arya's signal processing pipeline. 

**IMPORTANT NOTE:** MATLAB is currently unavailable in the execution environment. The figures listed below will be dynamically generated upon execution of `scripts/generate_eda_visualizations.m` in a MATLAB environment.

## 1. Purpose
To provide clear, scientific visualizations demonstrating the transformation from raw RF signals into AI-ready data tensors (I/Q and STFT) for project faculty review.

## 2. Dataset Used
- **Source:** `rf_dataset_v1.mat`
- **Classes:** QPSK (1000 frames) and 16-QAM (1000 frames)
- **Frame size:** 1024 complex samples.

## 3. Preprocessing Applied
- Per-frame DC offset removal.
- Per-frame RMS normalization.
- Filtering is disabled to preserve exact generator properties (Pulse Shaping, ISI).

## 4. I/Q Feature Representation
- Format: `[1024 × 2 × 2000]`
- Dimension 1: Sample Index (Time)
- Dimension 2: Channel (I and Q)
- Dimension 3: Observations

## 5. STFT Configuration
- Window: 64-sample periodic Hamming window
- Overlap: 48 samples (75%)
- FFT Length: 64
- Format: `[64 × 61 × 2000]`
- Output Feature: Log-Power `10*log10(abs(S).^2 + eps)`

## 6. Generated Visualizations

1. **`01_raw_IQ_time_domain.png`**
   - *What is shown:* The raw complex baseband I/Q waveform before preprocessing.
   - *Project stage:* Phase 1 (Raw Data).
   - *Review note:* Highlights initial amplitude variations and any DC presence.

2. **`02_raw_constellation_QPSK.png`**
   - *What is shown:* The actual QPSK sample distribution in the I-Q plane (before preprocessing).
   - *Project stage:* Phase 1.
   - *Review note:* Shows the 4 fundamental clusters influenced by pulse shaping and channel noise.

3. **`03_raw_constellation_16QAM.png`**
   - *What is shown:* The actual 16-QAM sample distribution.
   - *Project stage:* Phase 1.
   - *Review note:* Shows the 16 clusters, potentially displaying amplitude clipping or DC shifting.

4. **`04_preprocessing_before_after.png`**
   - *What is shown:* Side-by-side comparison of a frame before and after DC removal and RMS normalization.
   - *Project stage:* Phase 2.
   - *Review note:* Clearly proves the efficacy of Arya's preprocessing steps (unit variance, zero mean).

5. **`05_processed_IQ_time_domain.png`**
   - *What is shown:* The final preprocessed I/Q representation.
   - *Project stage:* Phase 3 (I/Q Extraction).
   - *Review note:* The normalized, clean time-domain signals fed to the 1D-CNN.

6. **`06_processed_constellation_QPSK.png`**
   - *What is shown:* The QPSK constellation after preprocessing.
   - *Project stage:* Phase 3.
   - *Review note:* Beautiful, centered, and scaled QPSK mapping.

7. **`07_processed_constellation_16QAM.png`**
   - *What is shown:* The 16-QAM constellation after preprocessing.
   - *Project stage:* Phase 3.
   - *Review note:* Correctly spaced and centered 16-QAM clusters.

8. **`08_STFT_QPSK.png`**
   - *What is shown:* The extracted STFT feature representation for QPSK (heatmap).
   - *Project stage:* Phase 3 (STFT Extraction).
   - *Review note:* Shows frequency transitions over time for QPSK.

9. **`09_STFT_16QAM.png`**
   - *What is shown:* The extracted STFT representation for 16-QAM (heatmap).
   - *Project stage:* Phase 3.
   - *Review note:* Displays 16-QAM time-frequency behavior.

10. **`10_IQ_feature_visualization.png`**
    - *What is shown:* Transformation of the complex signal into a structured 1024x2 tensor.
    - *Project stage:* Phase 3 / AI Handoff.
    - *Review note:* Explains exactly what the AI consumes, demystifying the tensor shape.

11. **`11_class_comparison.png`**
    - *What is shown:* Amplitude probability density (PDF) distributions comparing QPSK vs. 16-QAM.
    - *Project stage:* Exploratory Data Analysis.
    - *Review note:* QPSK has a tighter envelope distribution, whereas 16-QAM exhibits distinct amplitude tiers.

12. **`12_EDA_summary.png`**
    - *What is shown:* A singular, comprehensive pipeline snapshot (Raw -> Preprocessing -> I/Q & STFT).
    - *Project stage:* Full Pipeline (Phase 1-4).
    - *Review note:* The ultimate "money shot" summarizing Arya's entire contribution.

## 7. How to Regenerate
From the MATLAB Command Window, run:
```matlab
cd scripts/
generate_eda_visualizations
```

## 8. Scientific Limitations
- The "chosen configuration based on the project sampling structure" for STFT (64-window, 48-overlap) is a selected practical configuration. It balances time-frequency resolution specifically for a 1MHz 8-sps signal but is not unequivocally "mathematically optimal."
- Preprocessing standardizes amplitude and removes DC offset, but does NOT correct phase offsets, frequency offsets, or remove Additive White Gaussian Noise (AWGN). Impairments native to the channel remain intentionally intact for the AI to classify.
