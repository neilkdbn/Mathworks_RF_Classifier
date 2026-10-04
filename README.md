# MathWorks RF Signal Classification (100% MATLAB)

Software-only RF signal classification pipeline: programmatically generate
synthetic RF datasets, apply channel models, and train a deep learning model
to classify modulation schemes. Strictly **100% MATLAB — no Python**.

## Team & Roles

| Member  | Role | Owns |
|---------|------|------|
| Neil    | RF Systems Modeler | Clean + impaired baseband signals (Communications, Phased Array System Toolboxes) |
| Arya    | Signal Processing Lead | Feature extraction / pre-processing into I/Q sequences or STFT spectrograms (Signal Processing, Wavelet Toolboxes) |
| Shreeya | Deep Learning Architect | AI model design + training (Deep Learning Toolbox) |
| Anjali  | Project & Testing Lead | Pipeline integration, robustness testing, MathWorks compliance, GitHub submission |

## Systematic Workflow

1. Define signal parameters & scope
2. Generate baseband signals (AWGN, multipath fading, CFO, timing drift)
3. Extract features (1D-CNN/LSTM on I/Q, or 2D-CNN on STFT spectrograms)
4. Train AI model (**70% train / 15% val / 15% test**)
5. Evaluate robustness (confusion matrices grouped by SNR)
6. Package for MathWorks (`.prj`, `.mlx` Live Scripts, GitHub README + video)

Reference design: MathWorks `Modulation Classification with Deep Learning`
example (`openExample('comm/ModulationClassificationWithDeepLearningExample')`).

## Repository Structure

```text
RFClassifier.prj              Formal MATLAB Project (SingleFile; see note below)
scripts/
  setupRFClassifierProject.m  Canonical project generator — run once in MATLAB
  generateRFSignalDataset.m   Neil:  synthetic impaired waveform generation
  extractRFfeatures.m         Arya:  I/Q framing + STFT spectrograms
  trainRFClassifier.m         Shreeya: CNN training, 70/15/15 split
  evaluateRobustness.m        Anjali: accuracy-vs-SNR + confusion matrices
  mainRFClassifier.m          End-to-end pipeline script (Save As .mlx for submission)
  startup.m / finish.m        Project startup / shutdown
tests/
  testPipelineSmoke.m         matlab.unittest smoke test (Anjali)
data/  models/  docs/  utilities/
```

## Quickstart (requires MATLAB + toolboxes)

```matlab
cd('E:\rf_matlab')
addpath('scripts')
setupRFClassifierProject()   % creates/opens RFClassifier project, sets path, shortcuts
mainRFClassifier             % end-to-end demo (or open + Save As Live Script .mlx)
runTests('tests')            % or: runtests('tests')
```

Required toolboxes: Communications, Signal Processing, Deep Learning.
Optional: Phased Array System, Wavelet.

## MATLAB Project note (.prj)

This repo ships a `RFClassifier.prj` scaffold so the project opens on clone.
MathWorks reserves the right to change the internal XML schema, so the
**source of truth** is `scripts/setupRFClassifierProject.m`, which uses
`matlab.project.createProject` to (re)generate a compliant project:

- `DefinitionFilesType = FixedPathMultiFile` (merge-friendly, R2020b+ default)
- `scripts/`, `utilities/`, `tests/` on the project path
- `data/`, `models/` tracked; large `*.mat` ignored via `.gitignore`
- Shortcuts: setup, main pipeline, run tests
- `scripts/startup.m` as project startup file

If MATLAB ever reports the checked-in `.prj` as out of date, just re-run the
setup function — it rebuilds the definition files in place.

## Reproducibility

- All randomness seeded via `rng(...)` with the seed saved alongside data.
- Train/val/test split fixed at 70/15/15, stratified by modulation × SNR.
- Confusion matrices reported overall **and grouped by SNR** (Anjali).

## License

MIT — see `LICENSE`.
