% TRAIN_RF_2DCNN_CONSTELLATION
% Experiment: 2D CNN on constellation-density images derived from Arya's
% already-preprocessed I/Q data. MATLAB R2026b, Deep Learning Toolbox.
%
% SAFETY: uses TRAIN and VALIDATION frames only; leaves TEST untouched.
% Does NOT overwrite the existing 1D CNN or STFT models.

clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'deep_learning'));

assert(exist('trainnet','file') ~= 0, 'Deep Learning Toolbox is required.');
assert(exist('histcounts2','file') ~= 0, 'histcounts2 is unavailable.');
baselinePath = fullfile(root,'models','rf_1dcnn_r2026b.mat');
assert(isfile(baselinePath), 'Saved 1D CNN baseline not found.');

% STEP 1: Reuse EXACTLY the saved 1D CNN frame indices.
baseline = load(baselinePath,'split','classNames');
d = prepare_rf_splits(baseline.split.seed);
assert(isequal(d.trainIdx(:),baseline.split.trainIdx(:)) && ...
       isequal(d.valIdx(:),baseline.split.valIdx(:)) && ...
       isequal(d.testIdx(:),baseline.split.testIdx(:)), ...
       'The data split differs from the saved 1D CNN baseline.');
assert(isequal(string(d.classNames(:)),string(baseline.classNames(:))), ...
       'The class order differs from the saved baseline.');

% STEP 2: Calculate ONE histogram range from TRAINING frames ONLY.
% Use an order statistic rather than prctile (avoids an extra toolbox).
allTrainingIQ = cat(1,d.XTrain{:});
trainMagnitudes = sort(abs(allTrainingIQ(:)));
rank = max(1,ceil(0.995*numel(trainMagnitudes)));
radius = max(1.0,double(trainMagnitudes(rank)));
clear allTrainingIQ trainMagnitudes;

numBins = 64;
binEdges = linspace(-radius,radius,numBins+1);
fprintf('Training-only constellation range: [%.3f, %.3f]\n', ...
    -radius,radius);

% STEP 3: Convert frames to 64x64x1 images; do NOT use test frames.
nTrain = numel(d.XTrain);
nVal = numel(d.XVal);
XTrain = zeros(numBins,numBins,1,nTrain,'single');
XVal = zeros(numBins,numBins,1,nVal,'single');

for k = 1:nTrain
    XTrain(:,:,1,k) = make_constellation_density(d.XTrain{k},binEdges);
end
for k = 1:nVal
    XVal(:,:,1,k) = make_constellation_density(d.XVal{k},binEdges);
end
assert(all(isfinite(XTrain(:))) && all(isfinite(XVal(:))), ...
    'Constellation images must be finite.');
fprintf('Constellation images: %d train and %d validation, %dx%d.\n', ...
    nTrain,nVal,numBins,numBins);

% Optional TRAIN-ONLY visualization of average constellation densities.
figure('Name','TRAIN-set constellation-density comparison');
tiledlayout(1,2);
nexttile;
imagesc(squeeze(mean(XTrain(:,:,1,d.YTrain == 'QPSK'),4)));
axis image xy;
colorbar;
title('Training QPSK: mean density');
xlabel('Q bin'); ylabel('I bin');
nexttile;
imagesc(squeeze(mean(XTrain(:,:,1,d.YTrain == '16-QAM'),4)));
axis image xy;
colorbar;
title('Training 16-QAM: mean density');
xlabel('Q bin'); ylabel('I bin');

% STEP 4: Train a modest regularized 2D CNN. Input normalization is OFF
% because the density transform already produces nonnegative log counts.
layers = [
    imageInputLayer([64 64 1],Normalization="none",Name="density_input")
    convolution2dLayer(3,16,Padding="same",Name="conv1")
    batchNormalizationLayer(Name="bn1")
    reluLayer(Name="relu1")
    maxPooling2dLayer(2,Stride=2,Name="pool1")
    convolution2dLayer(3,32,Padding="same",Name="conv2")
    batchNormalizationLayer(Name="bn2")
    reluLayer(Name="relu2")
    maxPooling2dLayer(2,Stride=2,Name="pool2")
    convolution2dLayer(3,64,Padding="same",Name="conv3")
    batchNormalizationLayer(Name="bn3")
    reluLayer(Name="relu3")
    maxPooling2dLayer(2,Stride=2,Name="pool3")
    fullyConnectedLayer(32,Name="spatial_fc")
    reluLayer(Name="spatial_relu")
    dropoutLayer(0.4,Name="dropout")
    fullyConnectedLayer(numel(d.classNames),Name="scores")
    softmaxLayer(Name="probabilities")
];

options = trainingOptions("adam", ...
    MaxEpochs=20, ...
    MiniBatchSize=32, ...
    InitialLearnRate=5e-4, ...
    L2Regularization=1e-4, ...
    ValidationData={XVal,d.YVal}, ...
    ValidationFrequency=44, ...
    ValidationPatience=6, ...
    OutputNetwork="best-validation", ...
    Shuffle="every-epoch", ...
    ExecutionEnvironment="cpu", ...
    Metrics="accuracy", ...
    Plots="training-progress", ...
    Verbose=true);

rng(242,'twister');
fprintf('Training new constellation-density 2D CNN...\n');
[net,info] = trainnet(XTrain,d.YTrain,layers,"crossentropy",options);

% STEP 5: Measure validation only, then save a DISTINCT model.
scoresVal = minibatchpredict(net,XVal, ...
    MiniBatchSize=32,ExecutionEnvironment="cpu");
predVal = scores2label(scoresVal,d.classNames);
valAccuracy = 100*mean(string(predVal(:)) == string(d.YVal(:)));
numQPSK = sum(string(predVal(:)) == "QPSK");
numQAM  = sum(string(predVal(:)) == "16-QAM");
fprintf('\nCONSTELLATION VALIDATION ACCURACY: %.2f%%\n',valAccuracy);
fprintf('Predicted QPSK: %d\n',numQPSK);
fprintf('Predicted 16-QAM: %d\n',numQAM);

split = baseline.split;
classNames = d.classNames;
representationConfig = struct('type','I/Q constellation log-count image', ...
    'numBins',numBins,'binEdges',binEdges,'radius',radius, ...
    'binRangeSource','99.5th percentile of abs(I,Q) in training set only');
modelDir = fullfile(root,'models');
if ~isfolder(modelDir), mkdir(modelDir); end
modelPath = fullfile(modelDir,'rf_2dcnn_constellation_r2026b.mat');
save(modelPath,'net','info','split','classNames', ...
    'representationConfig','valAccuracy','numQPSK','numQAM','-v7.3');
fprintf('Saved NEW model: %s\n',modelPath);
fprintf('Held-out TEST frames were NOT used.\n');
