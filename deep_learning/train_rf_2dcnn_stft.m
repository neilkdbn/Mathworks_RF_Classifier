% TRAIN_RF_2DCNN_STFT
% MATLAB R2026b: train a 2D CNN on Arya's 64x61 log-power STFT features.
% IMPORTANT: uses exactly the same frame splits as the saved 1D CNN.
% Requires Deep Learning Toolbox and the completed 1D baseline.

clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'deep_learning'));

model1DPath = fullfile(root, 'models', 'rf_1dcnn_r2026b.mat');
featurePath = fullfile(root, 'data', 'processed', 'rf_features_v1.mat');
assert(isfile(model1DPath), 'First save the trained 1D CNN model.');
assert(isfile(featurePath), 'Arya feature file is missing.');

baseline = load(model1DPath, 'split', 'classNames');
d = prepare_rf_splits(baseline.split.seed);
assert(isequal(d.trainIdx, baseline.split.trainIdx) && ...
       isequal(d.valIdx, baseline.split.valIdx) && ...
       isequal(d.testIdx, baseline.split.testIdx), ...
       'Saved 1D split and current split do not match.');

loaded = load(featurePath, 'features');
f = loaded.features;
assert(isfield(f, 'STFT') && isfield(f.STFT, 'data'), ...
       'STFT features are missing.');
assert(isequal(size(f.STFT.data), [64, 61, 2000]), ...
       'Expected STFT dimensions [64 61 2000].');
assert(all(isfinite(f.STFT.data(:))), ...
       'STFT contains NaN or Inf values.');
% d.XTrain, d.XVal and d.XTest carry split indices; indexing by the same
% indices below preserves each frame's label and its I/Q/STFT pairing.
X = reshape(single(f.STFT.data), 64, 61, 1, []);
XTrain = X(:, :, :, d.trainIdx);
XVal   = X(:, :, :, d.valIdx);

% Standardize *STFT images only*, using training pixels ONLY (no leakage).
% This does not redo Arya's raw I/Q normalization or recompute STFT.
mu = mean(double(XTrain(:)));
sigma = std(double(XTrain(:)));
assert(isfinite(sigma) && sigma > 0, 'Invalid training STFT standard deviation.');
XTrain = (XTrain - single(mu)) ./ single(sigma);
XVal   = (XVal   - single(mu)) ./ single(sigma);

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

options = trainingOptions("adam", ...
    MaxEpochs=12, ...
    MiniBatchSize=32, ...
    InitialLearnRate=1e-3, ...
    ValidationData={XVal, d.YVal}, ...
    ValidationFrequency=20, ...
    OutputNetwork="best-validation", ...
    Shuffle="every-epoch", ...
    ExecutionEnvironment="cpu", ...
    Metrics="accuracy", ...
    Plots="training-progress", ...
    Verbose=true);

rng(42, "twister");
fprintf('Training STFT 2D CNN on %d frames; validating on %d frames.\n', ...
    numel(d.trainIdx), numel(d.valIdx));
[net, info] = trainnet(XTrain, d.YTrain, layers, "crossentropy", options);

split = baseline.split;
classNames = d.classNames;
inputNorm = struct('mean', mu, 'std', sigma, ...
                   'description', 'Training-only global STFT pixel standardization');
modelDir = fullfile(root, 'models');
if ~isfolder(modelDir), mkdir(modelDir); end
modelPath = fullfile(modelDir, 'rf_2dcnn_stft_r2026b.mat');
save(modelPath, 'net', 'info', 'split', 'classNames', 'inputNorm', '-v7.3');
fprintf('Saved trained STFT 2D CNN: %s\n', modelPath);
