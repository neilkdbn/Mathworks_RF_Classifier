function [net, info] = trainRFClassifier(feats, varargin)
%TRAINRFCLASSIFIER Shreeya (Deep Learning Architect): modulation CNN.
%   [NET, INFO] = TRAINRFCLASSIFIER(FEATS, 'Name',Value,...) trains a CNN
%   on the feature table from EXTRACTRFFEATURES with a fixed stratified
%   70% train / 15% val / 15% test split (split indices returned in INFO).
%
%   Options: 'MaxEpochs' (default 8, demo-small), 'MiniBatchSize' (128),
%   'Seed' (0), 'SavePath' ("", optional .mat save of NET+INFO).
%
%   Architecture follows the MathWorks modulation-classification CNN: stacked
%   conv-BN-ReLU blocks on 1024-sample frames (or spectrograms), final
%   fully-connected + softmax over the modulation classes.
%
%   Status: Phase-1 interface contract; full tuning is Shreeya's deliverable.
%
%   See also: extractRFfeatures, evaluateRobustness.

p = inputParser;
p.addRequired('feats', @(t) istable(t));
p.addParameter('MaxEpochs', 8, @isnumeric);
p.addParameter('MiniBatchSize', 128, @isnumeric);
p.addParameter('Seed', 0, @isnumeric);
p.addParameter('SavePath', "", @(x) isstring(x) || ischar(x));
p.parse(feats, varargin{:});
o = p.Results;
rng(o.Seed);

% Stack features into 4-D network input.
X0 = feats.features{1};
sz = size(X0);
X = zeros([sz 1 height(feats)], 'single');
for i = 1:height(feats), X(:,:,1,i) = single(feats.features{i}); end
Y = feats.modulation;

% Stratified 70/15/15 split.
cv = cvpartition(Y, 'Holdout', 0.30);
iTest = test(cv); iTmp = training(cv);
cv2 = cvpartition(Y(iTmp), 'Holdout', 0.50);   % 15/15 of total
iVal = false(size(iTmp)); iVal(iTmp) = test(cv2);
iTrn = false(size(iTmp)); iTrn(iTmp) = training(cv2);

layers = modClassCNNLayers(size(X0), numel(categories(Y)));
opts = trainingOptions('adam', 'MaxEpochs', o.MaxEpochs, ...
    'MiniBatchSize', o.MiniBatchSize, ...
    'ValidationData', {X(:,:,:,iVal), Y(iVal)}, ...
    'ValidationFrequency', 50, 'Verbose', false, 'Plots', 'none');
[net, info.TrainingHistory] = trainNetwork(X(:,:,:,iTrn), Y(iTrn), layers, opts);
info.TestIdx = find(iTest); info.ValIdx = find(iVal); info.TrainIdx = find(iTrn);
info.ClassNames = categories(Y);
if strlength(string(o.SavePath)) > 0, save(o.SavePath, 'net', 'info', '-v7.3'); end
end

function layers = modClassCNNLayers(inputSize, nClasses)
% Compact CNN in the spirit of helperModClassCNN.
layers = [
    imageInputLayer(inputSize, 'Normalization', 'zscore', 'Name', 'in')
    convolution2dLayer([1 7], 64, 'Padding', 'same', 'Name', 'c1')
    batchNormalizationLayer('Name', 'b1')
    reluLayer('Name', 'r1')
    maxPooling2dLayer([1 2], 'Stride', [1 2], 'Name', 'p1')
    convolution2dLayer([2 7], 32, 'Padding', 'same', 'Name', 'c2')
    batchNormalizationLayer('Name', 'b2')
    reluLayer('Name', 'r2')
    maxPooling2dLayer([1 2], 'Stride', [1 2], 'Name', 'p2')
    fullyConnectedLayer(128, 'Name', 'fc')
    reluLayer('Name', 'r3')
    fullyConnectedLayer(nClasses, 'Name', 'fcOut')
    softmaxLayer('Name', 'sm')
    classificationLayer('Name', 'out')];
end
