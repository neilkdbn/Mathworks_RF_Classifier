% generate_features.m
% Script to generate and save AI-ready features.

here = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
rootDir = fileparts(here);

addpath(fullfile(rootDir, 'preprocessing'));

fprintf('1. Loading Dataset...\n');
datasetFile = fullfile(rootDir, 'rf_dataset_v1.mat');
data = load_rf_dataset(datasetFile);
validate_input(data);

fprintf('2. Preprocessing Signals...\n');
processedData = preprocess_iq(data);

fprintf('3. Extracting Features...\n');
% Configure STFT extraction parameters
options.stft.windowLength = 64;
options.stft.overlapLength = 48;
options.stft.fftLength = 64;
options.stft.featureType = 'logPower';
options.iq.enabled = true;
options.stft.enabled = true;

features = extract_features(processedData, options);

fprintf('4. Validating Features...\n');
validate_features(features);
validate_ai_handoff(features);

fprintf('5. Saving Features...\n');
outDir = fullfile(rootDir, 'data', 'processed');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
outFile = fullfile(outDir, 'rf_features_v1.mat');
save(outFile, 'features', '-v7.3');
fprintf('Features successfully saved to %s\n', outFile);
