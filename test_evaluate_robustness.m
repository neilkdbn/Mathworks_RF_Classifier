% test_evaluate_robustness.m
% Tests evaluateRobustness execution on the verified 10 dB held-out test split.

root = fileparts(mfilename('fullpath'));
if isempty(root), root = pwd; end
addpath(fullfile(root, 'scripts'));
res = load(fullfile(root, 'results', 'final_locked_test_comparison.mat'));

snr10 = repmat(10, numel(res.actual), 1);
results = evaluateRobustness(res.actual, res.predEns, snr10, 'Plot', false);
disp('Robustness function executed successfully on 10 dB test set:');
disp(results.AccuracyVsSNR);
