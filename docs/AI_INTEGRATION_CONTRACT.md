# AI MODULE ↔ INTEGRATION CONTRACT

## 1. Preprocessed-I/Q API (recommended for existing Arya pipeline)

MATLAB function: `result = predict_rf_modulation(iqFrame)`

| Item | Contract |
|---|---|
| Input | One real numeric `1024 x 2` MATLAB array (single or double) |
| First dimension | 1024 ordered time samples |
| Second dimension | `(:,1) = I`, `(:,2) = Q` |
| Finite | No NaN or Inf |
| Scaling | DC-removed and RMS-normalized **per frame**, matching Arya's `features.IQ.data` |
| Class set | `"16-QAM"`, `"QPSK"` only |
| Result label | `result.label` (string scalar) |
| Scores | `result.classNames` and matching 1x2 `result.classScores` |
| Winner's score | `result.predictedScore` (scalar, not calibrated confidence) |
| Component scores | `result.cnn1Scores`, `result.cnn2Scores` (aligned class order) |
| Ensemble | fixed, untrained average `0.5*scores1 + 0.5*scores2` |

`classNames` order is read from the **saved model**; never assume it is alphabetical. Use the label to find the intended score.

Example:

```matlab
result = predict_rf_modulation(iqFrame);
for k = 1:numel(result.classNames)
    fprintf('%s: %.4f\n', char(result.classNames(k)), result.classScores(k));
end
fprintf('Prediction: %s\n', char(result.label));
```

## 2. Raw complex baseband convenience API

Function: `result = predict_rf_from_raw(rawComplexFrame)`

Input is a numeric **complex** vector with exactly 1024 samples representing I + 1j*Q at baseband. The adapter applies:

1. `remove_dc_offset(x)` on the complex frame
2. `normalize_amplitude(x,'rms')` on the same frame
3. `[real(x),imag(x)]` to construct `1024 x 2` input
4. `predict_rf_modulation()`

No filtering, carrier/timing recovery, resampling, segmentation, demodulation, or actual RF downconversion is performed. Do not call this adapter for an already-normalized frame.

## 3. Constellation processing

The inference function computes a 64x64 log1p-density histogram of the preprocessed I and Q columns. Histogram edges are read from `model2.representationConfig.binEdges` saved during training, derived solely from the **training set** (range about `[-1.668, 1.668]` in the reported run). Never recompute or modify these edges during integration.

## 4. Model loading and deployment

`predict_rf_modulation` caches both networks in MATLAB persistent variables after its first call. It loads them relative to its `.m` file, from a sibling `models` folder. It is not an online-learning function and never writes model parameters.

- MATLAB version used to prepare training: R2026b
- Required: Deep Learning Toolbox, MATLAB functions such as `minibatchpredict`, `histcounts2`, `scores2label`
- For the raw adapter: Arya's `remove_dc_offset.m` and `normalize_amplitude.m` with availability of `rms()`
- No internet, cloud, GPU, dataset, or Communications Toolbox required by the inference code itself

## 5. Rejection and limitations

- Input shape other than 1024x2 triggers an error in processed API.
- Non-finite input triggers an error.
- Raw near-zero-energy frame triggers an error.
- An out-of-distribution signal will **still** receive one of two known labels; there is currently **no unknown-modulation detector** or validated confidence threshold.
- Single-signal inference latency and deployment throughput have not yet been benchmarked.
- All reported benchmark results derive from synthetic signals at one configured operating point; they are not field-performance guarantees.

## 6. Anjali's acceptance criteria

1. Run `smoke_test_rf_ai_deployment.m` in the extracted **actual delivery archive** successfully.
2. Call both APIs with representative valid frames supplied by the upstream team.
3. Check result labels and score class alignment.
4. Confirm invalid shapes/errors are handled in the GUI/integration layer.
5. Independently verify frame boundaries, sample rate, signal source, and preprocessing parity before any live demo.
6. Record latency and behavior at varied SNR/channel conditions as *new work*, separate from locked final evaluation.
