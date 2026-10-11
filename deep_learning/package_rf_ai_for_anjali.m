function zipPath = package_rf_ai_for_anjali()
% PACKAGE_RF_AI_FOR_ANJALI Export a self-contained inference delivery ZIP.
%
% FIRST copy all provided .m/.md kit files to the matching project folders.
% THEN run:
%    cd('D:\College\signals and systems\Mathworks_RF_Classifier');
%    addpath(fullfile(pwd,'deep_learning'));
%    run(fullfile(pwd,'deep_learning','smoke_test_rf_modulation.m'));
%    zipPath = package_rf_ai_for_anjali();
%
% This tool gathers the TWO REAL SAVED MATLAB NETWORKS from YOUR laptop.
% It does not retrain, include the dataset, or modify existing model files.

root = fileparts(fileparts(mfilename('fullpath')));
required = {
    'models/rf_1dcnn_r2026b.mat'
    'models/rf_2dcnn_constellation_r2026b.mat'
    'deep_learning/predict_rf_modulation.m'
    'deep_learning/predict_rf_from_raw.m'
    'deep_learning/make_constellation_density.m'
    'deep_learning/smoke_test_rf_ai_deployment.m'
    'preprocessing/remove_dc_offset.m'
    'preprocessing/normalize_amplitude.m'
    'docs/AI_HANDOVER_README.md'
    'docs/AI_INTEGRATION_CONTRACT.md'
    'docs/AI_FINAL_RESULTS.md'
    'docs/ARYA_AI_FEATURE_CONTRACT.md'
    'results/final_locked_test_comparison.csv'
    'results/final_locked_test_comparison.mat'
    };
for k = 1:numel(required)
    absolutePath = fullfile(root,strrep(required{k},'/',filesep));
    assert(isfile(absolutePath), ...
        'Required handover file is missing: %s',absolutePath);
end

% MATLAB zip() stores paths relative to the specified project root.
zipPath = fullfile(root,'RF_AI_Anjali_Delivery.zip');
if isfile(zipPath)
    error('package_rf_ai_for_anjali:AlreadyExists', ...
        'Delivery ZIP already exists. Rename/move the old ZIP before rerunning: %s',zipPath);
end
zip(zipPath,required,root);
assert(isfile(zipPath),'ZIP was not created.');
info = dir(zipPath);
fprintf('\nANJALI HANDOVER DELIVERY ZIP CREATED:\n%s\n',zipPath);
fprintf('Archive size: %.2f MB\n',info.bytes/1024/1024);
fprintf('Includes two SAVED model binaries, inference, preprocessing, docs and RESULTS.\n');
fprintf('Does NOT include the training dataset or any retraining code.\n');
fprintf('After extraction, Anjali can run deep_learning/smoke_test_rf_ai_deployment.m\n');
end
