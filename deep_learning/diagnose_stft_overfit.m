% DIAGNOSE_STFT_OVERFIT
% MATLAB R2026b small-subset learning diagnostic for existing 2D CNN.
% Trains a FRESH network on 20 QPSK and 20 16-QAM TRAINING frames only.
% Deliberately tests training-set memorization, NOT generalization.
% Does not modify saved production models, dataset, or test set.

clc;
root = fileparts(mfilename('fullpath'));
% This script is intended to be placed in the project's deep_learning folder.
root = fileparts(root);
addpath(fullfile(root, 'deep_learning'));

modelPath = fullfile(root, 'models', 'rf_2dcnn_stft_r2026b.mat');
featurePath = fullfile(root, 'data', 'processed', 'rf_features_v1.mat');
assert(isfile(modelPath), 'Existing 2D model file not found.');
assert(isfile(featurePath), 'Processed STFT data file not found.');

m = load(modelPath, 'split', 'inputNorm', 'classNames');
d = prepare_rf_splits(m.split.seed);
assert(isequal(d.trainIdx, m.split.trainIdx), 'Training indices changed.');
assert(isequal(d.valIdx, m.split.valIdx), 'Validation indices changed.');
assert(isequal(d.testIdx, m.split.testIdx), 'Test indices changed.');

s = load(featurePath, 'features');
F = single(s.features.STFT.data);
assert(isequal(size(F), [64 61 2000]), 'Unexpected STFT dimensions.');
X = reshape(F, 64, 61, 1, []);

qIdx = d.trainIdx(d.YTrain == 'QPSK');
aIdx = d.trainIdx(d.YTrain == '16-QAM');
assert(numel(qIdx) >= 20 && numel(aIdx) >= 20, 'Not enough samples in each class.');
smallIdx = [qIdx(1:20); aIdx(1:20)];
YSmall = categorical(string(s.features.labels(smallIdx)));
YSmall = YSmall(:);
XSmall = X(:,:,:,smallIdx);
% Reuse the exact STFT normalization used by the original 2D CNN.
XSmall = (XSmall - single(m.inputNorm.mean)) ./ single(m.inputNorm.std);
assert(all(isfinite(XSmall(:))), 'Nonfinite values found after normalization.');

fprintf('Diagnostic set: %d examples, QPSK=%d, 16-QAM=%d.\n', ...
    numel(YSmall), sum(YSmall=='QPSK'), sum(YSmall=='16-QAM'));

% SAME architecture as the original 2D CNN, but trained from scratch.
layers = [
    imageInputLayer([64 61 1], Normalization="none", Name="stft_input")
    convolution2dLayer(3, 16, Padding="same", Name="conv1")
    reluLayer(Name="relu1")
    maxPooling2dLayer(2, Stride=2, Name="pool1")
    convolution2dLayer(3, 32, Padding="same", Name="conv2")
    reluLayer(Name="relu2")
    maxPooling2dLayer(2, Stride=2, Name="pool2")
    convolution2dLayer(3, 64, Padding="same", Name="conv3")
    reluLayer(Name="relu3")
    globalAveragePooling2dLayer(Name="global_pool")
    fullyConnectedLayer(numel(d.classNames), Name="scores")
    softmaxLayer(Name="probabilities")
];

rng(142, 'twister');
opts = trainingOptions('adam', ...
    MaxEpochs=60, ...
    MiniBatchSize=8, ...
    InitialLearnRate=1e-3, ...
    Shuffle='every-epoch', ...
    ExecutionEnvironment='cpu', ...
    Metrics='accuracy', ...
    Plots='training-progress', ...
    Verbose=true);

fprintf('Starting diagnostic training (training data ONLY)...\n');
[diagnosticNet, diagnosticInfo] = trainnet(XSmall, YSmall, layers, ...
    'crossentropy', opts); %#ok<NASGU>

scores = minibatchpredict(diagnosticNet, XSmall, MiniBatchSize=8, ...
    ExecutionEnvironment='cpu');
predicted = scores2label(scores, m.classNames);
smallAccuracy = 100 * mean(string(predicted(:)) == string(YSmall(:)));
fprintf('\nSmall-subset TRAINING accuracy: %.2f%% (%d/40 correct).\n', ...
    smallAccuracy, round(smallAccuracy/100*numel(YSmall)));
fprintf('This is a memorization diagnostic, NOT validation or test accuracy.\n');
% Do not replace the saved rf_2dcnn_stft_r2026b.mat model with this diagnostic model.
