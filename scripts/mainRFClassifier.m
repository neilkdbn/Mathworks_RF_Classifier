%% RF Classifier — End-to-End Pipeline (100% MATLAB)
% Anjali (integration). Run section-by-section; Save As .mlx Live Script for
% the MathWorks submission. Requires: Communications, Signal Processing,
% Deep Learning Toolbox.
%
%   1. Generate -> 2. Features -> 3. Train (70/15/15) -> 4. Robustness

%% 0. Setup
rng(0);
addpath(fileparts(mfilename('fullpath')));  % scripts on path

%% 1. Generate baseband signals (Neil) — demo-small; scale up for real runs
ds = generateRFSignalDataset('Modulations', ["BPSK","QPSK","16QAM","GFSK"], ...
    'SNRdB', -10:10:20, 'FramesPerCombo', 50, 'Seed', 0);
summary(ds)

%% 2. Extract features (Arya) — 'IQ' for 1D-CNN/LSTM, 'STFT' for 2D-CNN
feats = extractRFfeatures(ds, 'Mode', 'IQ');

%% 3. Train (Shreeya) — stratified 70/15/15 inside
[net, info] = trainRFClassifier(feats, 'MaxEpochs', 3, 'Seed', 0);
% To save: trainRFClassifier(feats, 'SavePath', fullfile('..','models','rfCNN.mat'))

%% 4. Evaluate robustness (Anjali) — overall + per-SNR confusion matrices
X0 = feats.features{1};
XTest = zeros([size(X0) 1 numel(info.TestIdx)], 'single');
for k = 1:numel(info.TestIdx)
    XTest(:,:,1,k) = single(feats.features{info.TestIdx(k)});
end
predictedLabels = classify(net, XTest);
results = evaluateRobustness(feats.modulation(info.TestIdx), predictedLabels, feats.snrDb(info.TestIdx), 'Plot', true);
