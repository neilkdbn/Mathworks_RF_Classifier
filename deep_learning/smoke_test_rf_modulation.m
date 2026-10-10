% SMOKE_TEST_RF_MODULATION
% Pre-handover validation: evaluates the inference API using a few
% VALIDATION frames only, checks agreement with batched model inference.
% Requires the local feature dataset and prepare_rf_splits.m.
% No training and no test-set access.

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'deep_learning'));
model1Path = fullfile(root,'models','rf_1dcnn_r2026b.mat');
model2Path = fullfile(root,'models','rf_2dcnn_constellation_r2026b.mat');
assert(isfile(model1Path) && isfile(model2Path), ...
    'The two trained model .mat files must be present in models/.');
assert(isfile(fullfile(root,'data','processed','rf_features_v1.mat')), ...
    'The local processed feature file is needed for this validation-only smoke test.');

m1 = load(model1Path,'net','split','classNames');
m2 = load(model2Path,'net','split','classNames','representationConfig');
d = prepare_rf_splits(m1.split.seed);
assert(isequal(d.valIdx(:),m1.split.valIdx(:)) && ...
       isequal(d.valIdx(:),m2.split.valIdx(:)), ...
       'Saved model validation indices do not match.');

% Six known validation frames: three from each class. No test frames.
classes = ["QPSK","16-QAM"];
idx = zeros(6,1);
for j = 1:2
    match = find(string(d.YVal(:))==classes(j),3);
    assert(numel(match)==3,'Expected three validation frames for each class.');
    idx((j-1)*3+(1:3)) = match(:);
end

% Reference batched inference, identical to the verified evaluation script.
X = d.XVal(idx);
edges = m2.representationConfig.binEdges;
nBins = numel(edges)-1;
X2D = zeros(nBins,nBins,1,numel(idx),'single');
for k = 1:numel(idx)
    X2D(:,:,1,k) = make_constellation_density(X{k},edges);
end
s1 = minibatchpredict(m1.net,X,MiniBatchSize=6,ExecutionEnvironment='cpu');
s2 = minibatchpredict(m2.net,X2D,MiniBatchSize=6,ExecutionEnvironment='cpu');
names1 = string(m1.classNames(:));
names2 = string(m2.classNames(:));
[matched,order2] = ismember(names1,names2);
assert(all(matched),'Model class names differ.');
referenceScores = (double(s1)+double(s2(:,order2)))/2;

fprintf('Checking six VALIDATION-only input frames...\n');
for k = 1:numel(idx)
    out = predict_rf_modulation(X{k});
    assert(isscalar(out.label) && any(out.label==classes), ...
        'Invalid predicted label returned.');
    assert(isequal(size(out.classScores),[1 2]) && ...
        all(isfinite(out.classScores)) && ...
        all(out.classScores>=0) && ...
        abs(sum(out.classScores)-1)<1e-3, ...
        'Invalid ensemble score dimensions/range.');
    assert(all(string(out.classNames(:))==names1), ...
        'The function returned an unexpected class order.');
    difference = max(abs(out.classScores-referenceScores(k,:)));
    assert(difference<1e-4, ...
        'Single-frame inference does not match frozen batched inference.');
    fprintf('True: %-6s | Predicted: %-6s | Top score: %.4f\n', ...
        char(string(d.YVal(idx(k)))),char(out.label),out.predictedScore);
end

% Check that malformed inputs are rejected.
rejected = false;
try
    predict_rf_modulation(zeros(100,2));
catch
    rejected = true;
end
assert(rejected,'The API did not reject an invalid frame shape.');

fprintf('\nVALIDATION-ONLY INFERENCE SMOKE TEST PASSED.\n');
fprintf('Six frames matched the batched baseline within 1e-4.\n');
fprintf('This is an API check, not a new measurement of model accuracy.\n');
