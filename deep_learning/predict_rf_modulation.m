function result = predict_rf_modulation(iqFrame)
% PREDICT_RF_MODULATION  Classify one already-preprocessed RF I/Q frame.
%
% INPUT:  iqFrame  [1024 x 2] real numeric, columns = I and Q.
%         Input MUST have the same preprocessing as Arya's features.IQ.data.
%         Do not send raw, unpreprocessed ADC samples to this function.
%
% OUTPUT: result.label          string: "16-QAM" or "QPSK"
%         result.classNames     1x2 string array in saved model order
%         result.classScores    1x2 equal-weight ensemble scores
%         result.predictedScore scalar score for the selected class
%         result.cnn1Scores     1x2 1D model scores
%         result.cnn2Scores     1x2 constellation model scores
%
% This is INFERENCE ONLY: no training, no labels, no test data required.
% Model filenames and weights were frozen after final evaluation.
%
% Required files relative to project root:
%   models/rf_1dcnn_r2026b.mat
%   models/rf_2dcnn_constellation_r2026b.mat
%   deep_learning/make_constellation_density.m
%
% MATLAB R2026b; Deep Learning Toolbox.

validateattributes(iqFrame, {'numeric'}, ...
    {'real','finite','nonempty','size',[1024 2]}, ...
    mfilename, 'iqFrame', 1);

% Load models once per MATLAB session for efficient repeated calls.
persistent model1 model2 order2 edges classNames
if isempty(model1)
    root = fileparts(fileparts(mfilename('fullpath')));
    path1 = fullfile(root,'models','rf_1dcnn_r2026b.mat');
    path2 = fullfile(root,'models','rf_2dcnn_constellation_r2026b.mat');
    assert(isfile(path1), 'Missing 1D CNN model: %s', path1);
    assert(isfile(path2), 'Missing constellation CNN model: %s', path2);
    model1 = load(path1,'net','classNames');
    model2 = load(path2,'net','classNames','representationConfig');

    classNames = string(model1.classNames(:)).';
    names2 = string(model2.classNames(:)).';
    [matched,order2] = ismember(classNames,names2);
    assert(all(matched) && numel(classNames)==2 && ...
        numel(names2)==2 && numel(unique(order2))==2, ...
        'Saved CNNs have incompatible output class labels.');
    assert(isequal(sort(classNames),sort(["16-QAM","QPSK"])), ...
        'Unexpected modulation classes in saved model.');
    assert(isfield(model2.representationConfig,'binEdges'), ...
        'Constellation model does not contain binEdges.');
    edges = model2.representationConfig.binEdges;
    assert(numel(edges)==65 && all(diff(edges)>0), ...
        'Unexpected constellation histogram bin edges.');
end

% Path A: the already-preprocessed temporal I/Q sequence.
frame = single(iqFrame);
score1 = minibatchpredict(model1.net, {frame}, ...
    MiniBatchSize=1, ExecutionEnvironment='cpu');

% Path B: image made with the TRAINING-derived, saved histogram bins.
img = make_constellation_density(frame,edges);
nBins = numel(edges)-1;
img = reshape(img,nBins,nBins,1,1);
score2 = minibatchpredict(model2.net,img, ...
    MiniBatchSize=1, ExecutionEnvironment='cpu');

% Match class order before averaging. This must mirror final evaluation.
assert(isequal(size(score1),[1 2]) && isequal(size(score2),[1 2]), ...
    'Unexpected score dimensions from one of the saved CNNs.');
cnn1Scores = double(score1);
cnn2Scores = double(score2(:,order2));
classScores = (cnn1Scores + cnn2Scores)/2;
assert(all(isfinite(classScores)) && all(classScores>=0), ...
    'Invalid classification scores.');

[predictedScore,predIdx] = max(classScores,[],2);
result = struct();
result.label = classNames(predIdx);
result.classNames = classNames;
result.classScores = classScores;
result.predictedScore = predictedScore;
result.cnn1Scores = cnn1Scores;
result.cnn2Scores = cnn2Scores;
result.weights = [0.5 0.5];
end
