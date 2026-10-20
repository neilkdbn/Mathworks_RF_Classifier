function d = prepare_rf_splits(seed)
% PREPARE_RF_SPLITS  Load Arya's processed I/Q features and split frames.
% Input to trainnet is one 1024-by-2 matrix per observation (time x I/Q).
% The same frame indices can also be reused for STFT comparisons later.
if nargin < 1
    seed = 42;
end
root = fileparts(fileparts(mfilename('fullpath')));
featurePath = fullfile(root, 'data', 'processed', 'rf_features_v1.mat');
assert(isfile(featurePath), 'Feature file missing. Run scripts/generate_features.m first.');
loaded = load(featurePath, 'features');
f = loaded.features;
assert(isfield(f, 'IQ') && isfield(f.IQ, 'data'), 'I/Q features not found.');
assert(isequal(size(f.IQ.data), [1024, 2, 2000]), 'Unexpected I/Q size.');
assert(all(isfinite(f.IQ.data(:))), 'I/Q features contain NaN or Inf.');
labels = categorical(string(f.labels(:)));
N = size(f.IQ.data, 3);
assert(numel(labels) == N, 'Feature-to-label mismatch.');
assert(isfield(f, 'frameIds') && numel(f.frameIds) == N, 'Frame IDs missing/misaligned.');
classes = categories(labels);
assert(numel(classes) == 2, 'Expected QPSK and 16-QAM classes.');

% Fixed, stratified, 70/15/15 split; no use of the test set during training.
rng(seed, 'twister');
trainIdx = []; valIdx = []; testIdx = [];
for k = 1:numel(classes)
    idx = find(labels == classes{k});
    idx = idx(randperm(numel(idx)));
    nTr = floor(0.70 * numel(idx));
    nVa = floor(0.15 * numel(idx));
    trainIdx = [trainIdx; idx(1:nTr)]; %#ok<AGROW>
    valIdx = [valIdx; idx(nTr+1:nTr+nVa)]; %#ok<AGROW>
    testIdx = [testIdx; idx(nTr+nVa+1:end)]; %#ok<AGROW>
end
trainIdx = trainIdx(randperm(numel(trainIdx)));
valIdx = valIdx(randperm(numel(valIdx)));
testIdx = testIdx(randperm(numel(testIdx)));
allIdx = [trainIdx; valIdx; testIdx];
assert(numel(allIdx) == N && numel(unique(allIdx)) == N, 'Split overlap or missing frames.');

% trainnet expects [time x channels] matrices for vector sequences.
X = cell(N,1);
for k = 1:N
    X{k} = single(f.IQ.data(:,:,k));
end

d = struct();
d.XTrain = X(trainIdx);
d.YTrain = labels(trainIdx);
d.XVal = X(valIdx);
d.YVal = labels(valIdx);
d.XTest = X(testIdx);
d.YTest = labels(testIdx);
d.trainIdx = trainIdx;
d.valIdx = valIdx;
d.testIdx = testIdx;
d.frameIds = f.frameIds;
d.classNames = classes;
d.seed = seed;

fprintf('Splits: training=%d, validation=%d, testing=%d.\n', ...
    numel(trainIdx), numel(valIdx), numel(testIdx));
assert(isequal(size(d.XTrain{1}), [1024, 2]), 'Wrong vector-sequence shape.');
end
