# RF CLASSIFIER — AI HANDOVER TO ANJALI

**Owner:** Shreeya (AI module)  
**Target MATLAB:** R2026b  
**Status:** Models trained; frozen ensemble evaluated; **integration API prepared, but requires a local MATLAB smoke test before handover**.

## A. What is being delivered

An inference-only 50:50 ensemble of:

1. A 1D CNN that classifies already-preprocessed 1024 x 2 I/Q time-series frames.
2. A 2D CNN that classifies a 64 x 64 log-count constellation-density image made from the same I/Q frame.

The 2D image uses **the bin edges saved with the trained 2D network**; it does NOT estimate bin edges on incoming signals. The two networks' score columns are aligned by stored class names before averaging.

**The models are not inside the downloadable starter kit.** They are only in Shreeya's local project at:

- `models/rf_1dcnn_r2026b.mat`
- `models/rf_2dcnn_constellation_r2026b.mat`

Do not retrain, rename, or overwrite these `.mat` model files to perform deployment.

## B. Install into Shreeya's EXISTING project

Project root: `D:\College\signals and systems\Mathworks_RF_Classifier`

Extract the starter kit elsewhere first. Copy these **new** files into your existing project, preserving directory names:

- `deep_learning/predict_rf_modulation.m`
- `deep_learning/predict_rf_from_raw.m`
- `deep_learning/smoke_test_rf_modulation.m`
- `deep_learning/smoke_test_rf_ai_deployment.m`
- `deep_learning/package_rf_ai_for_anjali.m`
- `docs/AI_HANDOVER_README.md`
- `docs/AI_INTEGRATION_CONTRACT.md`
- `docs/AI_FINAL_RESULTS.md`
- `docs/AI_HANDOVER_MESSAGE.txt` (optional message to send)

Already-existing dependencies included in the starter kit for reference / deployment:

- `deep_learning/make_constellation_density.m`
- `deep_learning/prepare_rf_splits.m` (required ONLY for Shreeya's validation smoke test)
- `preprocessing/remove_dc_offset.m`
- `preprocessing/normalize_amplitude.m`
- `docs/ARYA_AI_FEATURE_CONTRACT.md`

**If those already exist in your project, keep your original verified copies.** The supplied copies are drawn from the project scripts reviewed for compatibility, but overwriting existing code is unnecessary.

Required existing artifacts, generated on Shreeya's machine:

- The TWO real model `.mat` files above
- `results/final_locked_test_comparison.csv`
- `results/final_locked_test_comparison.mat`
- `data/processed/rf_features_v1.mat` (for Shreeya's validation smoke test only; do NOT ship this as an inference prerequisite)

## C. One-time pre-handover check — Shreeya

In the MATLAB Command Window:

```matlab
root = 'D:\College\signals and systems\Mathworks_RF_Classifier';
cd(root);
addpath(fullfile(root,'deep_learning'));
run(fullfile(root,'deep_learning','smoke_test_rf_modulation.m'));
```

Expected terminal text: `VALIDATION-ONLY INFERENCE SMOKE TEST PASSED.`

This checks that `predict_rf_modulation()` returns the same outputs as the established *batched* inference code for six validation examples and rejects malformed frames. It **does not retest model accuracy** and does not use test frames.

After passing, create the **actual delivery ZIP containing your real trained models**:

```matlab
zipPath = package_rf_ai_for_anjali();
```

The new file `RF_AI_Anjali_Delivery.zip` will be created in your project root, with both saved model binaries, the MATLAB inference source, Arya's preprocessing helpers, the integration documentation, and the locked test results. The dataset and retraining scripts are intentionally excluded. If the ZIP already exists, the packager stops rather than silently overwriting it; move/rename the old ZIP first.

**Send Anjali the MATLAB-created `RF_AI_Anjali_Delivery.zip`, not just this starter kit.** This starter kit alone cannot predict because it does not contain your trained models.

## D. Anjali — unzip and smoke test (no dataset needed)

After extracting `RF_AI_Anjali_Delivery.zip` to a new directory and opening MATLAB R2026b:

```matlab
root = 'D:\PATH\TO\EXTRACTED\DELIVERY';
cd(root);
addpath(fullfile(root,'deep_learning'));
run(fullfile(root,'deep_learning','smoke_test_rf_ai_deployment.m'));
```

Expected: `DEPLOYMENT API SMOKE TEST PASSED.` This synthetic-noise test only establishes that the API, paths, and preprocessing execute. A random-noise label has **no accuracy meaning**.

## E. Inference: two supported entry points

Already-preprocessed `1024 x 2` I/Q sequence:

```matlab
result = predict_rf_modulation(iqFrame);
disp(result.label);
disp(table(result.classNames(:), result.classScores(:), ...
    'VariableNames', {'Class','Score'}));
```

Unprocessed complex **baseband** frame of 1024 samples (`I + 1j*Q`), BEFORE Arya's preprocessing:

```matlab
result = predict_rf_from_raw(rawComplexFrame);
```

The raw adapter performs per-frame DC removal then per-frame RMS magnitude normalization using **Arya's functions**. No filtering is applied (consistent with the default training pipeline). For an input that has *already been preprocessed*, call `predict_rf_modulation` directly to avoid doing it twice.

**IMPORTANT**: This raw adapter is for **complex baseband**, not an antenna's passband RF voltage, arbitrary-rate hardware samples, or a streaming receiver. Signal capture, downconversion, synchronization, channel generalization, and segmentation are outside this API.

## F. Requirements and research limitations

- MATLAB R2026b + Deep Learning Toolbox; Arya's original `normalize_amplitude.m` also calls `rms()` (check that the requisite toolbox is installed on the receiving machine).
- Only two known classes: **QPSK** and **16-QAM**.
- Input frame length 1024, consistent sample ordering I then Q, and preprocessing matching the training pipeline.
- Trained/evaluated with 2,000 synthetic frames at a target **10 dB SNR**, split 1,400/300/300.
- **96.00% locked test accuracy** of fixed 50:50 ensemble (288/300); no established performance for new SNRs, channels, unseen emitters or live radio data.
- Scores are softmax-derived ensemble scores, **not calibrated confidence/probabilities**.
- Earlier 1D test evaluation was conducted before the final locked comparison; report this transparently. Do not adjust the frozen ensemble based on held-out test outcomes.

## G. Files Anjali should keep together after extraction

```text
[delivery root]/
    models/rf_1dcnn_r2026b.mat
    models/rf_2dcnn_constellation_r2026b.mat
    deep_learning/predict_rf_modulation.m
    deep_learning/predict_rf_from_raw.m
    deep_learning/make_constellation_density.m
    deep_learning/smoke_test_rf_ai_deployment.m
    preprocessing/remove_dc_offset.m
    preprocessing/normalize_amplitude.m
    docs/AI_HANDOVER_README.md
    docs/AI_INTEGRATION_CONTRACT.md
    docs/AI_FINAL_RESULTS.md
    docs/ARYA_AI_FEATURE_CONTRACT.md
    results/final_locked_test_comparison.csv
    results/final_locked_test_comparison.mat
```

These relative paths matter because the inference code resolves models relative to its own `deep_learning` directory.
