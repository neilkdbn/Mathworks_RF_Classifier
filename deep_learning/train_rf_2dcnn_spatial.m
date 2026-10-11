% TRAIN_RF_2DCNN_SPATIAL
% MATLAB R2026b. Train a 2-D STFT CNN with a spatially aware head.
% Uses exactly the saved 1-D CNN split (70/15/15) and training-only STFT
% normalization. Does NOT use the test set and does NOT overwrite models.

clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'deep_learning'));

baselinePath = fullfile(root, 'models', 'rf_1dcnn_r2026b.mat');
old2DPath = fullfile(root, 'models', 'rf_2dcnn_stft_r2026b.mat');
featurePath = fullfile(root, 'data', 'processed', 'rf_features_v1.mat');
assert(isfile(baselinePath), 'Saved 1D CNN baseline is missing.');
assert(isfile(old2DPath), 'Saved original STFT model is missing.');
assert(isfile(featurePath), 'Arya STFT features are missing.');

baseline = load(baselinePath, 'split', 'classNames');
old2D = load(old2DPath, 'split', 'inputNorm', 'classNames');
d = prepare_rf_splits(baseline.split.seed);
assert(isequal(d.trainIdx, baseline.split.trainIdx) && ...
       isequal(d.valIdx, baseline.split.valIdx) && ...
       isequal(d.testIdx, baseline.split.testIdx), ...
       'Current split does not match the saved 1D CNN baseline.');
assert(isequal(d.trainIdx, old2D.split.trainIdx) && ...
       isequal(d.valIdx, old2D.split.valIdx) && ...
       isequal(d.testIdx, old2D.split.testIdx), ...
       'Current split does not match the original STFT model.');
assert(isequal(string(d.classNames(:)), string(old2D.classNames(:))), ...
       'Class order has changed.');

loaded = load(featurePath, 'features');
f = loaded.features;
assert(isequal(size(f.STFT.data), [64 61 2000]), ...
       'Expected STFT data dimensions [64 61 2000].');
assert(all(isfinite(f.STFT.data(:))), 'STFT contains NaN or Inf.');
trainLabels = string(f.labels(d.trainIdx));
valLabels = string(f.labels(d.valIdx));
assert(isequal(trainLabels(:), string(d.YTrain(:))) && ...
       isequal(valLabels(:), string(d.YVal(:))), ...
       'STFT features and class labels are misaligned.');

% Use exactly the normalization learned from the original TRAINING data.
mu = single(old2D.inputNorm.mean);
sigma = single(old2D.inputNorm.std);
assert(isscalar(mu) && isscalar(sigma) && ...
       isfinite(mu) && isfinite(sigma) && sigma > 0, ...
       'Invalid saved training-only normalization.');
X = reshape(single(f.STFT.data), 64, 61, 1, []);
XTrain = (X(:,:,:,d.trainIdx) - mu) ./ sigma;
XVal = (X(:,:,:,d.valIdx) - mu) ./ sigma;
assert(all(isfinite(XTrain(:))) && all(isfinite(XVal(:))), ...
       'Nonfinite normalized STFT values.');
clear X;

% Same convolutional backbone as the first STFT model.
% Difference: retain spatial features using a fully connected head
% instead of globalAveragePooling2dLayer.
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
    fullyConnectedLayer(64, Name="spatial_fc")
    reluLayer(Name="spatial_relu")
    fullyConnectedLayer(numel(d.classNames), Name="scores")
    softmaxLayer(Name="probabilities")
];

opts = trainingOptions("adam", ...
    MaxEpochs=20, ...
    MiniBatchSize=32, ...
    InitialLearnRate=1e-3, ...
    ValidationData={XVal, d.YVal}, ...
    ValidationFrequency=44, ...
    ValidationPatience=8, ...
    OutputNetwork="best-validation", ...
    Shuffle="every-epoch", ...
    ExecutionEnvironment="cpu", ...
    Metrics="accuracy", ...
    Plots="training-progress", ...
    Verbose=true);

rng(142, 'twister');
fprintf('Training spatial-head STFT CNN: %d train, %d validation.\n', ...
    numel(d.YTrain), numel(d.YVal));
[net, info] = trainnet(XTrain, d.YTrain, layers, "crossentropy", opts);

% Measure validation predictions, NOT the untouched test set.
scores = minibatchpredict(net, XVal, ...
    MiniBatchSize=32, ExecutionEnvironment="cpu");
YPredVal = scores2label(scores, d.classNames);
valAccuracy = mean(string(YPredVal(:)) == string(d.YVal(:)));
fprintf('\nSpatial-head validation accuracy: %.2f%%\n', 100*valAccuracy);
fprintf('Predicted QPSK: %d\n', sum(string(YPredVal(:)) == "QPSK"));
fprintf('Predicted 16-QAM: %d\n', sum(string(YPredVal(:)) == "16-QAM"));

split = baseline.split;
classNames = d.classNames;
inputNorm = old2D.inputNorm;
modelDir = fullfile(root, 'models');
if ~isfolder(modelDir), mkdir(modelDir); end
modelPath = fullfile(modelDir, 'rf_2dcnn_spatial_r2026b.mat');
save(modelPath, 'net', 'info', 'split', 'classNames', ...
    'inputNorm', 'valAccuracy', '-v7.3');
fprintf('Saved separately: %s\n', modelPath);
fprintf('Untouched TEST set was NOT evaluated.\n');
