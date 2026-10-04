% compare_preprocessing.m
% Script to compare raw and processed datasets side-by-side.

% 1. Load Data
addpath('../preprocessing');
addpath('../visualization');

datasetFile = '../rf_dataset_v1.mat';
if ~isfile(datasetFile)
    error('Dataset file %s not found!', datasetFile);
end

data = load_rf_dataset(datasetFile);

% 2. Pick deterministic representative frames
% Assumes first 1000 are QPSK, next 1000 are 16-QAM
qpsk_first_idx = 1;
qpsk_mid_idx = 500;
qam_first_idx = 1001;
qam_mid_idx = 1500;

indices = [qpsk_first_idx, qpsk_mid_idx, qam_first_idx, qam_mid_idx];
labels = {'QPSK (First)', 'QPSK (Mid)', '16-QAM (First)', '16-QAM (Mid)'};

% 3. Preprocess
processedData = preprocess_iq(data);

% 4. Visualization comparison
fprintf('Starting Preprocessing Comparison...\n');

for i = 1:length(indices)
    idx = indices(i);
    
    raw_frame = data.signals(:, idx);
    proc_frame = processedData.signals(:, idx);
    
    % Plot time domain comparison
    plot_preprocessing_comparison(raw_frame, proc_frame, labels{i}, idx);
    
    % Plot constellation (Scatter)
    plot_constellation(raw_frame, proc_frame, labels{i});
end

fprintf('Comparison Complete.\n');
