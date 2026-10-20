# Plan (living doc — Anjali curates)

## Scope
Software-only RF modulation classification in 100% MATLAB: synthetic
generation → channel impairment → features → CNN → SNR-grouped robustness.

## Phase 1 (this scaffold) — DONE
- [x] `git init` in `E:\rf_matlab`
- [x] Folders: `data/ models/ scripts/ tests/ docs/ utilities/`
- [x] Formal project: `RFClassifier.prj` + `scripts/setupRFClassifierProject.m`
- [x] Interface contracts: Neil/Arya/Shreeya/Anjali function signatures
- [x] `README.md`, `.gitignore`, `LICENSE` (MIT), smoke test

## Next (team integration)
- [ ] Neil: full modulator bank + fading/CFO/AWGN catalogue
- [ ] Arya: STFT/CWT tuning, normalization, framing study
- [ ] Shreeya: CNN/LSTM architecture + hyperparameter sweep
- [ ] Anjali: `.mlx` Live Scripts, confusion-by-SNR report, GitHub push + video

## Open questions
- Repo URL `neilkdbn/Mathworks_RF_Classifier` currently 404 — confirm name/visibility?
- Target MATLAB release (R2024b+ assumed; TOML definition needs R2026b)?
- Full modulation list + SNR grid + frames/combo for the final dataset?

## Risks
- Hand-written `.prj` scaffold vs MathWorks schema drift → mitigated: setup
  script regenerates via API; re-run on any project-load warning.
- Large `.mat` artifacts → ignored by default; use Releases/LFS.
