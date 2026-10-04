# MathWorks RF Signal Classification Pipeline
**Owner:** Arya (Signal Processing Lead)

This repository contains the dataset preprocessing and feature extraction pipeline connecting raw RF signals to AI-ready structures.

## Scope of Phase 1: Inspection & Loading
- Defines data contracts natively and extracts variables.
- Outputs standardized MATLAB structures.

## Scope of Phase 2: Signal Preprocessing
- DC offset removal (per frame) and RMS amplitude scaling.
- Guarantees clean, zero-frequency artifact-free signals.

## Scope of Phase 3: Feature Extraction (AI Handoff)
- Transforms the normalized RF signal into `[Samples x Channels x Frames]` 1D representations.
- Generates `[Frequency x Time x Frames]` 2D Log-Power STFT representations.
- Guarantees frame and label alignment.
- Defined specifically for Deep Learning consumption. 

## Handoff Contract
Read `docs/AI_FEATURE_CONTRACT.md` for exact dimensional representations required for the DL team.

## Executing the Workflow
```matlab
% Full extraction workflow
cd scripts/
run generate_features.m
```

## Running the Unit Tests
```matlab
% In MATLAB Command Window:
addpath('preprocessing');
addpath('tests');
runtests('*'); % Runs Phase 1, Phase 2, and Phase 3 tests
```

## Architectures Used
- `Signal Processing Toolbox` (for `stft()`)
- `matlab.unittest.TestCase`
