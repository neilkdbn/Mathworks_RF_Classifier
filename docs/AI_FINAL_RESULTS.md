# RF CLASSIFIER — FROZEN RESULTS AND EXPERIMENT HISTORY

**Experiment scope:** 2,000 generated RF frames, equally split QPSK and 16-QAM, target SNR 10 dB. **Data split:** 1,400 training / 300 validation / 300 testing, stratified and identical for both successful models.

## Locked comparisons

| Model | Validation accuracy | Test accuracy | Test correct | Test macro F1 |
|---|---:|---:|---:|---:|
| 1D CNN, preprocessed temporal I/Q | 95.67% | 95.33% | 286/300 | 0.9533 |
| 2D CNN, 64x64 constellation-density histogram | 95.67% | 93.00% | 279/300 | 0.9299 |
| **Fixed 50:50 score ensemble** | **96.00%** | **96.00%** | **288/300** | **0.9599** |

### Locked TEST confusion matrices

Rows = actual, columns = predicted, class order = `[16-QAM, QPSK]`.

1D CNN:

```text
148   2
 12 138
```

2D constellation CNN:

```text
146   4
 17 133
```

Equal-weight ensemble:

```text
150   0
 12 138
```

For the ensemble, 16-QAM recall is 150/150 = 100%, QPSK recall is 138/150 = 92%; overall 288/300 = 96%.

### Validation confusion matrices

1D CNN:

```text
144   6
  7 143
```

2D constellation CNN (reconstructed using 150/150 class balance, 287 correct overall, and predicted counts 161 16-QAM / 139 QPSK):

```text
149   1
 12 138
```

Equal-weight ensemble:

```text
149   1
 11 139
```

The two successful individual networks each made 13 mistakes on validation, but only 5 were common to both. They disagreed on 16 validation frames. Their distinct errors motivate a fixed score-average, but the ensemble's validation gain was only **one sample**, and its test gain over 1D was **two samples**; this does **not** establish statistically proven superiority.

## Negative results (validation only)

| Experimental model | Validation result |
|---|---|
| Original log-power STFT 2D CNN with global average pooling | 50%, single-class collapse |
| Log-power STFT with spatial fully-connected head | 50%, training/validation overfitting |
| Complex real/imaginary STFT 2D CNN | 51%, overfitting |

These failures are specific to the tested features, architectures and settings; they do **not** prove that STFT-based modulation classifiers are inherently ineffective.

## Evaluation protocol and caveats

- The ensemble was selected on validation using a **fixed 50:50 average** and was **not** subsequently tuned on test frames.
- The 1D model's test accuracy had already been evaluated earlier in development; the final locked comparison repeated that 1D test while evaluating the 2D and ensemble. Document this history transparently rather than calling the complete project a perfectly untouched one-time test.
- No live/real-world RF, unseen SNRs/channels, out-of-distribution modulation families, throughput/latency, or calibrated confidence was established in this study.
- The real test files, if present in Shreeya's project, are `results/final_locked_test_comparison.csv` and `.mat`; this Markdown document is a readable summary only. The MATLAB-built delivery ZIP includes the original result files.
- Do not retrain or retune after reading final test outcomes. Future experiments should use new data or new properly separated evaluation protocols.
