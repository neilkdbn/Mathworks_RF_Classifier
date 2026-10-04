% run_arya_pipeline.m
% End-to-end demonstration entry point for the complete Arya signal processing pipeline.

clear;
clc;

addpath('../preprocessing');

fprintf('============================================\n');
fprintf('ARYA SIGNAL PROCESSING PIPELINE\n');
fprintf('============================================\n\n');

%% 1. Load Dataset
fprintf('Loading dataset...\n');
datasetFile = '../rf_dataset_v1.mat';
if ~isfile(datasetFile)
    error('Dataset file %s not found!', datasetFile);
end
data = load_rf_dataset(datasetFile);

%% 2. Validate Input
fprintf('Validating input...\n');
validate_input(data);

numFrames = size(data.signals, 2);
numSamples = size(data.signals, 1);
qpskCount = sum(strcmp(data.labels, 'QPSK'));
qamCount = sum(strcmp(data.labels, '16-QAM'));

fprintf('Input:\n');
fprintf('    %d frames\n', numFrames);
fprintf('    %d samples/frame\n', numSamples);
fprintf('    complex double\n\n');

fprintf('Classes:\n');
fprintf('    QPSK: %d\n', qpskCount);
fprintf('    16-QAM: %d\n\n', qamCount);

%% 3. Preprocess
fprintf('Preprocessing signals...\n');
options_preprocess.removeDC = true;
options_preprocess.normalize = true;
options_preprocess.normMethod = 'rms';
options_preprocess.filter.enable = false;

tic;
processedData = preprocess_iq(data, options_preprocess);
preprocTime = toc;

fprintf('Preprocessing:\n');
fprintf('    DC removal: %s\n', 'YES');
fprintf('    RMS normalization: %s\n', 'YES');
fprintf('    Filtering: %s\n\n', 'DISABLED');

%% 4. Extract Features
fprintf('Extracting features...\n');
options_features.iq.enabled = true;
options_features.stft.enabled = true;
options_features.stft.windowLength = 64;
options_features.stft.overlapLength = 48;
options_features.stft.fftLength = 64;
options_features.stft.featureType = 'logPower';

tic;
features = extract_features(processedData, options_features);
featureExtTime = toc;

fprintf('I/Q:\n');
fprintf('    %d × %d × %d\n\n', size(features.IQ.data, 1), size(features.IQ.data, 2), size(features.IQ.data, 3));

fprintf('STFT:\n');
fprintf('    %d × %d × %d\n\n', size(features.STFT.data, 1), size(features.STFT.data, 2), size(features.STFT.data, 3));

%% 5. Validate Features
fprintf('Validating features...\n');
validate_features(features);

nanIQ = sum(isnan(features.IQ.data(:)));
infIQ = sum(isinf(features.IQ.data(:)));
nanSTFT = sum(isnan(features.STFT.data(:)));
infSTFT = sum(isinf(features.STFT.data(:)));

fprintf('Validation:\n');
fprintf('    NaN: %d\n', nanIQ + nanSTFT);
fprintf('    Inf: %d\n', infIQ + infSTFT);
fprintf('    Alignment: PASS\n\n');

%% 6. Display Runtime
fprintf('Runtime:\n');
fprintf('    Preprocessing: %.4f sec\n', preprocTime);
fprintf('    Feature Extraction: %.4f sec\n', featureExtTime);
fprintf('    Total: %.4f sec\n', preprocTime + featureExtTime);

fprintf('============================================\n');
fprintf('PIPELINE COMPLETE.\n');
fprintf('============================================\n');
