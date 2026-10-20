% TRAIN_RF_1DCNN  First MATLAB R2026b classifier using Arya's I/Q features.
% Requires Deep Learning Toolbox. No changes to Arya's preprocessing.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'deep_learning'));
assert(exist('trainnet', 'file') ~= 0, 'Install Deep Learning Toolbox first.');
d = prepare_rf_splits(42);

% A small 1-D CNN following MathWorks' sequence classification pattern.
% Each observation is a 1024-by-2 (time-by-IQ) matrix.
layers = [
    sequenceInputLayer(2, Normalization="none", MinLength=1024, Name="iq_input")
    convolution1dLayer(5, 16, Padding="same", Name="conv1")
    reluLayer(Name="relu1")
    layerNormalizationLayer(Name="norm1")
    maxPooling1dLayer(4, Stride=4, Name="pool1")
    convolution1dLayer(5, 32, Padding="same", Name="conv2")
    reluLayer(Name="relu2")
    layerNormalizationLayer(Name="norm2")
    maxPooling1dLayer(4, Stride=4, Name="pool2")
    convolution1dLayer(5, 64, Padding="same", Name="conv3")
    reluLayer(Name="relu3")
    globalAveragePooling1dLayer(Name="global_pool")
    fullyConnectedLayer(numel(d.classNames), Name="scores")
    softmaxLayer(Name="probabilities")
];

options = trainingOptions("adam", ...
    MaxEpochs=12, ...
    MiniBatchSize=32, ...
    InitialLearnRate=1e-3, ...
    ValidationData={d.XVal, d.YVal}, ...
    ValidationFrequency=20, ...
    OutputNetwork="best-validation", ...
    Shuffle="every-epoch", ...
    ExecutionEnvironment="cpu", ...
    Metrics="accuracy", ...
    Plots="training-progress", ...
    Verbose=true);

% Verify the corrected minimum sequence length before training.
assert(layers(1).MinLength == 1024, "Unexpected sequence minimum length.");
fprintf("CNN MinLength: %d\n", layers(1).MinLength);

[net, info] = trainnet(d.XTrain, d.YTrain, layers, "crossentropy", options);
split = struct('seed', d.seed, 'trainIdx', d.trainIdx, ...
    'valIdx', d.valIdx, 'testIdx', d.testIdx);
classNames = d.classNames;
modelDir = fullfile(root, 'models');
if ~isfolder(modelDir), mkdir(modelDir); end
modelPath = fullfile(modelDir, 'rf_1dcnn_r2026b.mat');
save(modelPath, 'net', 'info', 'split', 'classNames', '-v7.3');
fprintf('Trained model saved: %s\n', modelPath);
