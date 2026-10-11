% DIAGNOSE_STFT_SPATIAL_HEAD
% MATLAB R2026b. Controlled follow-up to the 40-frame STFT overfit test.
% Only change: replace global-average pooling with a spatial fully-connected head.
% Uses only TRAINING frames. Does not overwrite either trained model.

clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'deep_learning'));

modelPath = fullfile(root, 'models', 'rf_2dcnn_stft_r2026b.mat');
featurePath = fullfile(root, 'data', 'processed', 'rf_features_v1.mat');
assert(isfile(modelPath), 'Saved 2D CNN model was not found.');
assert(isfile(featurePath), 'Arya STFT feature file was not found.');

m = load(modelPath, 'split', 'inputNorm', 'classNames');
d = prepare_rf_splits(m.split.seed);
assert(isequal(d.trainIdx, m.split.trainIdx), 'Training indices changed.');
assert(isequal(d.valIdx, m.split.valIdx), 'Validation indices changed.');
assert(isequal(d.testIdx, m.split.testIdx), 'Test indices changed.');

s = load(featurePath, 'features');
f = s.features;
assert(isequal(size(f.STFT.data), [64 61 2000]), 'Unexpected STFT dimensions.');

% Select 20 signals of each class from the existing TRAINING split.
qPos = find(d.YTrain == 'QPSK', 20, 'first');
aPos = find(d.YTrain == '16-QAM', 20, 'first');
assert(numel(qPos) == 20 && numel(aPos) == 20, 'Missing training examples.');
positions = [qPos(:); aPos(:)];
frameIndices = d.trainIdx(positions);
YSmall = d.YTrain(positions);

% Convert both label lists into column vectors
expectedLabels = string(YSmall(:));

sourceLabels = string(f.labels(frameIndices));
sourceLabels = sourceLabels(:);

% Verify that labels match
assert(isequal(expectedLabels, sourceLabels), ...
    'Frame/label alignment mismatch.');

F = single(f.STFT.data);
X = reshape(F, 64, 61, 1, []);
XSmall = X(:,:,:,frameIndices);
mu = single(m.inputNorm.mean);
sigma = single(m.inputNorm.std);
assert(isfinite(mu) && isfinite(sigma) && sigma > 0, ...
    'Invalid saved normalization values.');
XSmall = (XSmall - mu) ./ sigma;
assert(all(isfinite(XSmall(:))), 'Nonfinite normalized STFT data.');

fprintf('New diagnostic: %d TRAINING examples (%d QPSK, %d 16-QAM).\n', ...
    numel(YSmall), sum(YSmall == 'QPSK'), sum(YSmall == '16-QAM'));

% The convolution/pooling backbone is UNCHANGED from the original 2D CNN.
% Only the classifier head changes: no global-average pooling.
% In R2026b, fullyConnectedLayer flattens spatial/channel dimensions.
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

rng(142, 'twister');
opts = trainingOptions("adam", ...
    MaxEpochs=60, ...
    MiniBatchSize=8, ...
    InitialLearnRate=1e-3, ...
    Shuffle="every-epoch", ...
    ExecutionEnvironment="cpu", ...
    Metrics="accuracy", ...
    Plots="training-progress", ...
    Verbose=true);

fprintf('Training spatial-head diagnostic (no validation/test frames used)...\n');
[diagnosticSpatialNet, diagnosticSpatialInfo] = trainnet( ...
    XSmall, YSmall, layers, "crossentropy", opts); %#ok<NASGU>

scores = minibatchpredict(diagnosticSpatialNet, XSmall, ...
    MiniBatchSize=8, ExecutionEnvironment="cpu");
YPred = scores2label(scores, d.classNames);
acc = 100 * mean(string(YPred(:)) == string(YSmall(:)));
fprintf('\nSPATIAL-HEAD SUBSET TRAINING ACCURACY: %.2f%% (%d/40).\n', ...
    acc, round(acc * numel(YSmall) / 100));
fprintf('Predicted QPSK: %d\n', sum(string(YPred(:)) == "QPSK"));
fprintf('Predicted 16-QAM: %d\n', sum(string(YPred(:)) == "16-QAM"));
fprintf('This is a TRAINING-ONLY memorization test, NOT generalization performance.\n');
fprintf('No production models or test predictions have been modified.\n');
