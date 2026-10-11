# Model Evaluation and Robustness Assessment Report

**Project:** MathWorks RF Classifier  
**Branch:** `feature/anjali-robustness-evaluation`  
**Date:** October 11, 2026  
**Evaluator:** Anjali (Integration & Robustness Lead)  
**Target Environment:** MATLAB R2026b (Deep Learning Toolbox)

---

## 1. Executive Summary

This report documents the verification, held-out test evaluation, and robustness assessment for the frozen RF modulation classifier models developed by Shreeya and Arya.

Key measured findings on the held-out test split (300 frames, 150 QPSK / 150 16-QAM):
- **1D CNN (Temporal I/Q):** 95.33% test accuracy (286/300), Macro F1 = 0.9533
- **2D CNN (Constellation Density):** 93.00% test accuracy (279/300), Macro F1 = 0.9299
- **Equal-Weight Ensemble (50:50):** 96.00% test accuracy (288/300), Macro F1 = 0.9599

All models were evaluated in inference-only mode without retraining, fine-tuning, or altering network weights. Results exactly match pre-rerun baselines preserved in `results/backup_before_rerun/`.

---

## 2. Experimental Configuration & Dataset Provenance

### 2.1 Dataset Parameters
- **Source Artifact:** `rf_dataset_v1.mat` (raw baseband signals)
- **Feature Artifact:** `data/processed/rf_features_v1.mat`
- **Total Dataset Size:** 2,000 frames
  - QPSK: 1,000 frames
  - 16-QAM: 1,000 frames
- **Frame Length:** 1,024 complex samples per frame
- **Operating Channel:** Rayleigh multipath fading (delays: `[0, 1.5, 3.2] µs`, gains: `[0, -3, -10] dB`, Doppler shift: 50 Hz), pulse shaped via Raised Cosine transmit filter (sps = 8, rolloff = 0.35, span = 6).
- **Target SNR:** 10 dB AWGN (single operating point).

### 2.2 Feature Preprocessing Pipeline
Signal preprocessing was performed using the restored and verified Phase 2 & 3 pipeline:
1. **DC Offset Removal (`remove_dc_offset.m`):** Zero-centering I and Q channels.
2. **Amplitude Normalization (`normalize_amplitude.m`):** RMS normalization per frame ($x / \text{rms}(x)$).
3. **Temporal I/Q Features (`extract_iq_features.m`):** Formatted as $[1024 \times 2]$ single-precision tensors per observation (`time \times channel`).
4. **Constellation Density Maps (`make_constellation_density.m`):** $64 \times 64$ log-histogram density grid computed using frozen bin edges derived strictly from the training partition:
   - Bin edge range: $[-1.6685, +1.6685]$ (radius: 1.6685, 99.5th percentile of training $\max(|I|,|Q|)$).

### 2.3 Data Partitioning
- **Partitioning Algorithm:** Stratified split implemented in `deep_learning/prepare_rf_splits.m` using random seed `42` (`'twister'`).
- **Proportions:**
  - **Training:** 70% (1,400 frames: 700 QPSK, 700 16-QAM)
  - **Validation:** 15% (300 frames: 150 QPSK, 150 16-QAM)
  - **Test (Held-Out):** 15% (300 frames: 150 QPSK, 150 16-QAM)
- **Index Verification:** `m1.split.testIdx` and `m2.split.testIdx` stored within the model checkpoints are identical to `prepare_rf_splits(42).testIdx`.

---

## 3. Held-Out Test Evaluation Results

The evaluation script `deep_learning/evaluate_rf_final_locked.m` was executed on the 300 held-out test frames.

### 3.1 Quantitative Summary

| Model | Test Accuracy (%) | Test Correct | Macro F1 | 16-QAM Recall | QPSK Recall |
|---|---|---|---|---|---|
| **1D CNN (I/Q)** | 95.33% | 286 / 300 | 0.9533 | 148 / 150 (98.67%) | 138 / 150 (92.00%) |
| **2D CNN (Constellation)** | 93.00% | 279 / 300 | 0.9299 | 146 / 150 (97.33%) | 133 / 150 (88.67%) |
| **Equal-Weight Ensemble (50:50)** | **96.00%** | **288 / 300** | **0.9599** | **150 / 150 (100.0%)** | **138 / 150 (92.00%)** |

### 3.2 Confusion Matrices (Held-Out Test Set)
*Rows = True Class, Columns = Predicted Class. Class ordering: `[16-QAM, QPSK]`.*

#### 1D CNN:
$$\begin{pmatrix} 148 & 2 \\ 12 & 138 \end{pmatrix}$$

#### 2D CNN (Constellation Density):
$$\begin{pmatrix} 146 & 4 \\ 17 & 133 \end{pmatrix}$$

#### Equal-Weight Ensemble (50:50 Score Average):
$$\begin{pmatrix} 150 & 0 \\ 12 & 138 \end{pmatrix}$$

### 3.3 Observations
- The ensemble eliminates all false positives against 16-QAM on the test split (150/150 16-QAM correctly classified).
- The remaining 12 errors in the ensemble are QPSK signals misclassified as 16-QAM.
- The net test gain of the ensemble over the standalone 1D CNN is 2 test frames (288 vs 286).

---

## 4. Reproducibility & Provenance Assessment

### 4.1 What Has Been Scientifically Verified
1. **Model Checkpoint Integrity:** Both `models/rf_1dcnn_r2026b.mat` and `models/rf_2dcnn_constellation_r2026b.mat` are intact, valid MATLAB `dlnetwork` architectures, and have unperturbed weights.
2. **Metadata Consistency:** Class names (`["16-QAM", "QPSK"]`), seed (`42`), and partition index vectors (`trainIdx`, `valIdx`, `testIdx`) match across both models and `prepare_rf_splits.m`.
3. **Inference Bit-Agreement:** Re-running inference on `data/processed/rf_features_v1.mat` reproduced identical discrete class predictions (`pred1`, `pred2`, `predEns`) to the pre-rerun baseline in `results/backup_before_rerun/final_locked_test_comparison.mat`. Score differences across all 300 test frames were $< 4 \times 10^{-6}$, consistent with single-precision floating-point arithmetic.
4. **Smoke Test Passing:** Both single-frame inference (`smoke_test_rf_modulation.m`) and deployment API validation (`smoke_test_rf_ai_deployment.m`) pass without errors.

### 4.2 Scientific Caveats & What Cannot Be Claimed
1. **Lack of Checksum / Waveform Provenance:** The saved model files store partition indices and seed, but do not store cryptographic SHA-256 hashes or raw sample tensors of the original training data. While partition indices are deterministic, index alignment alone is not mathematical proof that the regenerated features are bit-for-bit identical to the original training inputs.
2. **Small Absolute Margin:** The ensemble's improvement over the 1D model is only 2 frames out of 300 on the test split and 1 frame on validation. This modest difference is not statistically significant and does not establish general superiority.

---

## 5. Robustness Evaluation & Multi-SNR Gap Analysis

### 5.1 Operating Point Limitation
All evaluations above reflect performance at **a single operating point: SNR = 10 dB**.
A high accuracy at 10 dB does **not** establish:
- Robustness across lower SNR regimes (e.g., $-10$ dB to $+5$ dB), where noise exceeds signal power.
- Robustness to uncalibrated Carrier Frequency Offset (CFO) or timing jitter.
- Out-of-distribution generalization to other modulation schemes or varying Doppler profiles.

### 5.2 Technical Blockers for Multi-SNR Evaluation
1. **Existing Datasets Lack Multi-SNR Data:** Both `rf_dataset_v1.mat` and `rf_features_v1.mat` strictly contain signals simulated at 10 dB SNR. No multi-SNR labeled datasets exist in repository artifacts.
2. **Placeholder Modulator in `generateRFSignalDataset.m`:** Line 77 of `scripts/generateRFSignalDataset.m` generates complex Gaussian noise:
   ```matlab
   tx = (randn(N,1) + 1j*randn(N,1)) / sqrt(2);
   ```
   for all modulation types except PAM4. This function cannot be used to generate valid multi-SNR modulation data; evaluating models on Gaussian noise produces meaningless labels.

### 5.3 Single-SNR Robustness Check (`evaluateRobustness.m`)
Executing `scripts/evaluateRobustness.m` on the verified 10 dB held-out test split yields:
```text
Overall classification accuracy: 0.9600
    snrDb    accuracy    numFrames
    _____    ________    _________
     10        0.96         300   
```
The robustness evaluation harness itself is verified and operational for tabular multi-SNR analysis once multi-SNR data is provided.

### 5.4 Recommended Next Steps to Unblock Full Robustness Evaluation
1. **Implement Genuine Modulator Bank in `generateRFSignalDataset.m`:** Replace the `randn` stub with actual digital modulators (`comm.QPSKModulator` or `pskmod`, `comm.RectangularQAMModulator` or `qammod`) matching Neil/Arya's parameters (`sps=8`, `rolloff=0.35`, `span=6`).
2. **Synthesize Multi-SNR Evaluation Set:** Generate an independent test split over an SNR sweep (e.g., `-10:2:20` dB) across 300–500 frames per SNR point.
3. **Execute `evaluateRobustness.m` Across SNR Range:** Plot accuracy vs. SNR curve and waterfall confusion matrices to characterize the SNR cliff / degradation threshold.
