# PHASE 2: PREPROCESSING

This document outlines the technical details and decisions behind the signal preprocessing pipeline implemented for the MathWorks RF Signal Classification project.

## Objective
The goal is to prepare raw RF data from Neil's generator for feature extraction by normalizing amplitudes, removing unwanted offsets, and preserving the underlying modulation schemes (QPSK, 16-QAM).

## Pipeline Stages
1. **Quality Analysis**: Computes statistical measurements of the raw signals (Mean, RMS, Peak, NaN/Inf counts) without modifying the data.
2. **DC Removal**: Removes the mean complex value for each frame independently. This eliminates zero-frequency artifacts that might skew feature extraction (like STFT).
3. **Amplitude Normalization**: Scales the signal so its RMS power equals 1. This prevents power differences from overshadowing phase/shape differences in downstream neural networks.
4. **Optional Filtering**: An optional, disabled-by-default, low-pass filter stage. Since the generator already applies pulse shaping (raised cosine), additional filtering could distort phase/ISI.

## Design Decisions
- **RMS Normalization vs Peak**: Digital modulation methods (QAM) use amplitude variations for encoding symbols. RMS normalization maintains average power consistency across frames while preserving the constellation's relative amplitude levels, whereas peak normalization is vulnerable to solitary noise spikes.
- **Filter Disabled**: Enabled filtering requires `Fs` (sampling rate), which is reconstructed from generator configurations but absent per-frame in the stored dataset. Bypassing filtering prevents phase distortion on pre-shaped datasets.

## Output Contract
- **Input Dimensions**: 1024 x 2000 complex double
- **Output Dimensions**: 1024 x 2000 complex double (guaranteed no NaN/Inf)
- **Labels**: Preserved
- **Metadata**: Fs and SNR preserved as stored in Phase 1 structure.

Phase 3 feature extraction routines will directly ingest this modular, validated data structure.
