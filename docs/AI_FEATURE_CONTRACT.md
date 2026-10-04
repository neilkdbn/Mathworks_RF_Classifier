# AI FEATURE CONTRACT (For Shreeya - DL Architect)

This is the definitive handoff document for integrating the RF Dataset into deep learning architectures. 
DO NOT modify the data scaling or orientation unless required by a specific network layer constraint.

## What is provided?
A MATLAB `.mat` struct named `features`, generated via `extract_features.m`.
It guarantees zero NaN/Inf values, unit RMS power normalization, and zero DC offset per-frame.

**DO NOT REPEAT:**
- DC removal
- Global RMS normalization on the raw IQ 
- Random frame reordering (maintain sequence indices until splitting)
- Re-filtering

## 1. I/Q Model Input (1D-CNN / LSTM)
Access: `features.IQ.data`
- **Dimensions:** `1024 x 2 x 2000` (Double Precision)
- **Dimension 1:** Sequence Length / Time (1024 samples)
- **Dimension 2:** Channels (Index 1 = I, Index 2 = Q)
- **Dimension 3:** Observations / Frames

## 2. STFT Model Input (2D-CNN)
Access: `features.STFT.data`
- **Dimensions:** `64 x 61 x 2000` (Double Precision)
- **Dimension 1:** Frequency Bins (64) -> See `features.STFT.frequencyAxis`
- **Dimension 2:** Time Bins (61) -> See `features.STFT.timeAxis`
- **Dimension 3:** Observations / Frames
- **Data Type:** Real-valued Log-Power spectrogram (`dB` scale). 

## 3. Labels and Alignment
Access: `features.labels`
- `1 x 2000` cell array of strings (`{'QPSK', '16-QAM'}`).
- Frame `k` in the I/Q tensor directly corresponds to Frame `k` in the STFT tensor, which directly corresponds to `features.labels{k}` and `features.frameIds(k)`.

## 4. Metadata
- `features.Fs`: 1000000 (1 MHz)
- `features.snr`: 10 (dB)
- `features.preprocessingInfo`: Log of operations performed in Phase 2.
- `features.STFT.stftConfig`: Parameters used to construct the STFT.
