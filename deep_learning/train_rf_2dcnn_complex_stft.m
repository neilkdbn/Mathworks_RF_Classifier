% TRAIN_RF_2DCNN_COMPLEX_STFT
% MATLAB R2026b: controlled phase-preserving STFT experiment.
% Uses Arya's preprocessed I/Q, original STFT parameters, and the
% original 1D CNN train/validation split. Never accesses test frames.
% Saves a NEW model without overwriting previous experiments.

clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'deep_learning'));
addpath(fullfile(root, 'preprocessing'));

baselinePath = fullfile(root, 'models', 'rf_1dcnn_r2026b.mat');
featurePath = fullfile(root, 'data', 'processed', 'rf_features_v1.mat');
assert(isfile(baselinePath) && isfile(featurePath), ...
    'Saved 1D model or processed feature file is missing.');
assert(exist('compute_stft', 'file') ~= 0, ...
    'Cannot find Arya''s compute_stft.m function.');

b = load(baselinePath, 'split', 'classNames');
d = prepare_rf_splits(b.split.seed);
assert(isequal(d.trainIdx(:), b.split.trainIdx(:)) && ...
       isequal(d.valIdx(:), b.split.valIdx(:)) && ...
       isequal(d.testIdx(:), b.split.testIdx(:)), ...
       'Saved 1D model partitions do not match current partitions.');
assert(isequal(string(d.classNames(:)), string(b.classNames(:))), ...
       'Class-name order differs from the saved baseline.');

s = load(featurePath, 'features');
f = s.features;
assert(isequal(size(f.IQ.data), [1024 2 2000]), ...
    'Unexpected I/Q feature dimensions.');
cfg = f.STFT.stftConfig;
Fs = double(f.Fs);

% Allocate ONLY the original training and validation observations.
nTr = numel(d.trainIdx);
nVa = numel(d.valIdx);
XTrain = zeros(64, 61, 2, nTr, 'single');
XVal = zeros(64, 61, 2, nVa, 'single');

fprintf('Computing phase-preserving STFT for %d training frames...\n', nTr);
for j = 1:nTr
    idx = d.trainIdx(j);
    iq = complex(f.IQ.data(:,1,idx), f.IQ.data(:,2,idx));
    spec = compute_stft(iq, Fs, cfg);
    assert(isequal(size(spec), [64 61]), 'Unexpected complex STFT shape.');
    XTrain(:,:,1,j) = single(real(spec));
    XTrain(:,:,2,j) = single(imag(spec));
end

fprintf('Computing phase-preserving STFT for %d validation frames...\n', nVa);
for j = 1:nVa
    idx = d.valIdx(j);
    iq = complex(f.IQ.data(:,1,idx), f.IQ.data(:,2,idx));
    spec = compute_stft(iq, Fs, cfg);
    assert(isequal(size(spec), [64 61]), 'Unexpected complex STFT shape.');
    XVal(:,:,1,j) = single(real(spec));
    XVal(:,:,2,j) = single(imag(spec));
end


% Verify feature and label alignment
% Convert all label arrays into column vectors

trainFeatureLabels = string(f.labels(d.trainIdx));
trainFeatureLabels = trainFeatureLabels(:);

trainSplitLabels = string(d.YTrain(:));

valFeatureLabels = string(f.labels(d.valIdx));
valFeatureLabels = valFeatureLabels(:);

valSplitLabels = string(d.YVal(:));

% Check actual label alignment
assert(isequal(trainFeatureLabels, trainSplitLabels) && ...
    isequal(valFeatureLabels, valSplitLabels), ...
    'Features and labels are genuinely misaligned.');

disp('Feature-label alignment verified successfully!');

assert(all(isfinite(XTrain(:))) && all(isfinite(XVal(:))), ...
       'Complex STFT channels contain nonfinite values.');

% Shared scaling across real and imaginary channels, fitted on TRAIN only.
mu = mean(double(XTrain(:)));
sigma = std(double(XTrain(:)));
assert(isfinite(mu) && isfinite(sigma) && sigma > 0, ...
    'Invalid training normalization statistics.');
XTrain = (XTrain - single(mu)) ./ single(sigma);
XVal = (XVal - single(mu)) ./ single(sigma);

% Use the SAME spatial-head architecture as the prior model.
% This isolates the representation change as much as practical.
layers = [
    imageInputLayer([64 61 2], Normalization="none", Name="complex_stft")
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
fprintf('Training 2-channel complex-STFT CNN: %d train, %d validation.\n', nTr, nVa);
[net, info] = trainnet(XTrain, d.YTrain, layers, "crossentropy", opts);

scores = minibatchpredict(net, XVal, ...
    MiniBatchSize=32, ExecutionEnvironment="cpu");
YPredVal = scores2label(scores, d.classNames);
valAccuracy = 100 * mean(string(YPredVal(:)) == string(d.YVal(:)));
fprintf('\nCOMPLEX-STFT VALIDATION ACCURACY: %.2f%%\n', valAccuracy);
fprintf('Predicted QPSK: %d\n', sum(string(YPredVal(:)) == "QPSK"));
fprintf('Predicted 16-QAM: %d\n', sum(string(YPredVal(:)) == "16-QAM"));

split = b.split;
classNames = d.classNames;
inputNorm = struct('mean', mu, 'std', sigma, ...
    'description', 'Shared Re/Im complex-STFT scaling using train only');
representation = 'Complex STFT (real and imaginary channels)';
modelPath = fullfile(root, 'models', 'rf_2dcnn_complex_stft_r2026b.mat');
save(modelPath, 'net', 'info', 'split', 'classNames', 'inputNorm', ...
    'representation', 'valAccuracy', '-v7.3');
fprintf('Saved NEW model: %s\n', modelPath);
fprintf('Held-out TEST data remains untouched.\n');
