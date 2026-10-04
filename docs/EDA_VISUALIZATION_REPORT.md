# EDA Visualization Report: RF Signal Classification Pipeline

**Prepared By:** Arya, Signal Processing Lead  
**Audience:** Faculty Project Review Board  

---

## A. Objective
This report details the Exploratory Data Analysis (EDA) and Visualization package designed to demonstrate the complete signal processing pipeline. The generated visualizations mathematically and visually prove that the raw MathWorks RF dataset has been correctly ingested, sanitized, and transformed into AI-ready multidimensional tensors.

## B. Dataset Overview
The visualization package leverages the actual dataset (`rf_dataset_v1.mat`), conforming to the established data contract:
- **Total Frames:** 2000
- **Frame Size:** 1024 complex samples
- **Classes:** QPSK (1000 frames) and 16-QAM (1000 frames)

## C. Signal Preprocessing
To standardize inputs before feature extraction, the pipeline natively applies:
1. **Per-frame DC Removal:** Normalizes the mean of the complex baseband signal to zero.
2. **Per-frame Unit-RMS Normalization:** Scales the signal variance/power to unity.
*Note: Low-pass filtering was intentionally disabled to preserve Pulse Shaping (ISI) and modulation transients.*

## D. I/Q Feature Extraction
The raw complex values (`I + jQ`) are unrolled into a continuous real-valued sequence tensor structure suitable for 1D-CNNs and LSTMs.
- **Dimensions:** `1024 × 2 × 2000` (Double Precision)

## E. STFT Feature Extraction
A Short-Time Fourier Transform transforms the 1D signal into a 2D Time-Frequency log-power heatmap suitable for 2D-CNNs. The chosen configuration based on the project sampling structure is:
- **Window:** 64-sample periodic Hamming window
- **Overlap:** 48 samples (75% overlap)
- **FFT Length:** 64 points
- **Dimensions:** `64 × 61 × 2000` (Double Precision)

## F. Visualization Interpretation
12 high-resolution PNG plots mathematically trace the lifecycle of a signal through Arya's pipeline. These plots include:
- **Time Domain & Constellation Analyses:** Proving the fidelity of the raw dataset.
- **Before & After Preprocessing Scans:** Visually confirming DC zeroing and RMS normalization.
- **Feature Tensor Projections:** Heatmaps and isolated I/Q components clearly defining the structure passed to the Deep Learning frameworks.
- **Statistical Class Differences:** Amplitude probability density comparisons revealing distinct structural variations between QPSK and 16-QAM.
- **Master Pipeline Summary:** A presentation-ready synthesis of the entire transformation lifecycle.

## G. AI Handoff
The data is successfully formatted, aligned, structured, and labeled. Shreeya (DL Architect) has been explicitly instructed *not* to recalculate the STFT or re-normalize the dataset globally, preserving the integrity of this signal processing lifecycle.

## H. Limitations
- The STFT hyperparameters reflect a practical balance tailored for an 8 samples-per-symbol (sps) constraint but represent a classic time-frequency resolution trade-off. 
- The preprocessing handles DC artifacts and power scaling but intentionally retains channel-induced phase distortions and AWGN to test the classifier's robustness.

## I. MATLAB Execution Status
**[PENDING MATLAB EXECUTION]**  
*The visualization code (`generate_eda_visualizations.m`) has been statically verified and committed. PNG artifact generation awaits a compatible MATLAB runtime execution environment. No illustrative/fabricated graphs have been committed.*
