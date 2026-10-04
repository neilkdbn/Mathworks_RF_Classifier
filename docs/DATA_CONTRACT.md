# DATA CONTRACT: MathWorks RF Signal Classification (Phase 1)

This document describes the interface between Neil's RF signal generator, Arya's signal-processing pipeline, and Shreeya's downstream AI model. It is based on the actual inspection of `rf_dataset_v1.mat`.

## A. INPUT DATA
- **Dataset filename:** `rf_dataset_v1.mat`
- **Signal variables:** `qpskData_realistic`, `qamData_realistic`
- **Label variables:** MISSING in file (Inferred via signal variable names as QPSK and 16-QAM)
- **SNR variable:** MISSING in file (Configured in generator as 10 dB, recovered by loader)
- **Sampling frequency:** MISSING in file (Configured in generator as 1e6 Hz, recovered by loader)
- **Signal type:** Baseband I/Q (Complex)
- **Complex/real representation:** Complex (`complex128`)
- **Datatype:** Double-precision float
- **Signal dimensions:** 1024 samples x 1000 frames (for each class)
- **Number of frames/samples:** 1000 frames per class (total 2000 frames)
- **Frame length:** 1024 samples
- **Modulation classes:** QPSK, 16-QAM
- **SNR range:** Fixed at 10 dB

## B. SIGNAL REPRESENTATION
The RF/baseband signal is represented as complex IQ samples:
`x[n] = I[n] + jQ[n]`

## C. DIMENSION CONTRACT
- **Number of samples (per frame):** 1024
- **Number of frames:** 2000 (1000 QPSK, 1000 16-QAM)
- **Channel dimensions:** 1 (Single channel IQ)
- **Label dimensions:** 1 x 2000 categorical/cell array
- **SNR dimensions:** Scalar / Missing (10 dB target)

## D. SAMPLING CONTRACT
- **Fs:** 1 MHz (from generator code, recovered by loader. The original rf_dataset_v1.mat does not persist Fs/SNR metadata. Arya's loader recovers the authoritative generator configuration and stores it explicitly in the processing/feature metadata.)
- **Units:** Hertz
- **Frame duration:** 1.024 milliseconds
- **Samples per frame:** 1024

## E. DATATYPE CONTRACT
- **Signal datatype:** Double-precision complex float (`double`, `complex128`)

## F. LABEL CONTRACT
- **Label type:** Categorical string/cell array of strings
- **Possible modulation classes:** `{'QPSK', '16-QAM'}`
- **Mapping conventions:** The first 1000 columns correspond to QPSK, the next 1000 columns correspond to 16-QAM.

## G. SNR CONTRACT
- **SNR datatype:** Double (Not persisted in .mat file)
- **Units:** dB
- **Values/range:** 10
- **Relationship to each frame:** Applies uniformly to all generated frames.

## H. PREPROCESSING (Phase 2)
- **DC Removal:** Enabled (per frame)
- **RMS Normalization:** Enabled (per frame)
- **Filtering:** Disabled

## I. I/Q FEATURE CONTRACT (Phase 3)
- **Dimensions:** 1024 × 2 × 2000
- **Format:** [Samples, Channels (I,Q), Frames]

## J. STFT FEATURE CONTRACT (Phase 3)
- **Dimensions:** 64 × 61 × 2000
- **STFT Parameters:** 64-sample periodic Hamming window, 48-sample overlap, 64-point centered FFT
- **Format:** [Frequency Bins, Time Bins, Frames]
- **Feature:** Log-Power (`10*log10(abs(S).^2 + eps)`)

## K. AI HANDOFF VALIDATION
Verified by `validate_ai_handoff.m` to ensure no NaNs/Infs, valid dimensions, strictly enforced Fs metadata, and aligned labels for exactly 2000 frames.
