% check_feature_reproducibility.m
% Checks feature metadata, compares predictions against backed-up locked results,
% and verifies numerical tolerance and raw signal dimensions.

root = fileparts(mfilename('fullpath'));
if isempty(root), root = pwd; end
addpath(fullfile(root, 'deep_learning'));

% 1. Check features.snr
feat = load(fullfile(root, 'data', 'processed', 'rf_features_v1.mat'), 'features');
f = feat.features;
fprintf('=== features.snr ===\n');
disp(f.snr);
if isfield(f, 'preprocessingInfo')
    disp('=== preprocessingInfo ===');
    disp(f.preprocessingInfo);
end

% 2. Compare backed up results vs current results
res_curr = load(fullfile(root, 'results', 'final_locked_test_comparison.mat'));
res_back = load(fullfile(root, 'results', 'backup_before_rerun', 'final_locked_test_comparison.mat'));

fprintf('=== Comparison between current and backup results ===\n');
fprintf('Predictions identical? pred1: %d, pred2: %d, predEns: %d\n', ...
    isequal(res_curr.pred1, res_back.pred1), ...
    isequal(res_curr.pred2, res_back.pred2), ...
    isequal(res_curr.predEns, res_back.predEns));

diff1 = max(abs(res_curr.scores1(:) - res_back.scores1(:)));
diff2 = max(abs(res_curr.scores2(:) - res_back.scores2(:)));
diffEns = max(abs(res_curr.ensembleScores(:) - res_back.ensembleScores(:)));
fprintf('Max score diff: scores1 = %e, scores2 = %e, ensembleScores = %e\n', ...
    diff1, diff2, diffEns);

fprintf('Current comparison table:\n');
disp(res_curr.comparison);
fprintf('Current confusion matrices:\n');
for k = 1:3
    fprintf('Model %s:\n', res_curr.comparison.Model(k));
    disp(res_curr.confusionMatrices(:,:,k));
end

% 3. Check raw signals vs regenerated features
raw = load(fullfile(root, 'rf_dataset_v1.mat'));
fprintf('=== Checking raw dataset details ===\n');
fprintf('raw numFrames: %d, samplesPerFrame: %d\n', raw.numFrames, raw.samplesPerFrame);
fprintf('raw qam size: [%d, %d], qpsk size: [%d, %d]\n', ...
    size(raw.qamData_realistic,1), size(raw.qamData_realistic,2), ...
    size(raw.qpskData_realistic,1), size(raw.qpskData_realistic,2));
