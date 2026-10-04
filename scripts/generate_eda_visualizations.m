% scripts/generate_eda_visualizations.m
% Generates the complete EDA visualization package for the MathWorks RF Signal Classification project.

clear; clc; close all;

fprintf('============================================\n');
fprintf('ARYA EDA VISUALIZATION PIPELINE\n');
fprintf('============================================\n\n');

%% 1. Setup Directories & Paths
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fullfile(scriptDir, '..');
edaOutDir = fullfile(projectRoot, 'visualization', 'EDA');

if ~exist(edaOutDir, 'dir')
    mkdir(edaOutDir);
end

addpath(fullfile(projectRoot, 'preprocessing'));
addpath(fullfile(projectRoot, 'visualization'));

%% 2. Load Dataset
fprintf('Loading dataset...\n');
datasetFile = fullfile(projectRoot, 'rf_dataset_v1.mat');
if ~isfile(datasetFile)
    error('Dataset file %s not found!', datasetFile);
end
data = load_rf_dataset(datasetFile);
validate_input(data);

%% 3. Identify Representative Frames
% Deterministically pick the first QPSK and first 16-QAM frame
idxQPSK = find(strcmp(data.labels, 'QPSK'), 1, 'first');
idx16QAM = find(strcmp(data.labels, '16-QAM'), 1, 'first');

if isempty(idxQPSK) || isempty(idx16QAM)
    error('Required classes (QPSK, 16-QAM) not found in dataset labels.');
end

%% 4. Preprocessing & Feature Extraction
fprintf('Running Preprocessing & Feature Extraction...\n');
options_preprocess.removeDC = true;
options_preprocess.normalize = true;
options_preprocess.normMethod = 'rms';
options_preprocess.filter.enable = false;

processedData = preprocess_iq(data, options_preprocess);

options_features.iq.enabled = true;
options_features.stft.enabled = true;
options_features.stft.windowLength = 64;
options_features.stft.overlapLength = 48;
options_features.stft.fftLength = 64;
options_features.stft.featureType = 'logPower';

features = extract_features(processedData, options_features);
numSamples = 1024;
t = 1:numSamples; % time samples

%% 5. Generate Visualizations

% Common Figure Settings
figWidth = 1600;
figHeight = 1000;

% Helper function to save figure
save_fig = @(f, name) exportgraphics(f, fullfile(edaOutDir, [name, '.png']), 'Resolution', 300);

%% Vis 1: 01_raw_IQ_time_domain.png
fprintf('Generating 01_raw_IQ_time_domain.png...\n');
f1 = figure('Position', [100, 100, figWidth, figHeight], 'Name', 'Raw I/Q Time Domain');
tiledlayout(2, 1, 'TileSpacing', 'compact');
% QPSK
nexttile;
plot(t, real(data.signals(:, idxQPSK)), 'b', t, imag(data.signals(:, idxQPSK)), 'r');
title('Raw QPSK I/Q'); xlabel('Sample Index'); ylabel('Amplitude'); legend('I', 'Q'); grid on;
% 16-QAM
nexttile;
plot(t, real(data.signals(:, idx16QAM)), 'b', t, imag(data.signals(:, idx16QAM)), 'r');
title('Raw 16-QAM I/Q'); xlabel('Sample Index'); ylabel('Amplitude'); legend('I', 'Q'); grid on;
save_fig(f1, '01_raw_IQ_time_domain'); close(f1);

%% Vis 2: 02_raw_constellation_QPSK.png
fprintf('Generating 02_raw_constellation_QPSK.png...\n');
f2 = figure('Position', [100, 100, figHeight, figHeight], 'Name', 'Raw QPSK Constellation');
plot(real(data.signals(:, idxQPSK)), imag(data.signals(:, idxQPSK)), 'b.');
axis equal; title('Raw QPSK Constellation'); xlabel('In-phase'); ylabel('Quadrature'); grid on;
save_fig(f2, '02_raw_constellation_QPSK'); close(f2);

%% Vis 3: 03_raw_constellation_16QAM.png
fprintf('Generating 03_raw_constellation_16QAM.png...\n');
f3 = figure('Position', [100, 100, figHeight, figHeight], 'Name', 'Raw 16-QAM Constellation');
plot(real(data.signals(:, idx16QAM)), imag(data.signals(:, idx16QAM)), 'r.');
axis equal; title('Raw 16-QAM Constellation'); xlabel('In-phase'); ylabel('Quadrature'); grid on;
save_fig(f3, '03_raw_constellation_16QAM'); close(f3);

%% Vis 4: 04_preprocessing_before_after.png
fprintf('Generating 04_preprocessing_before_after.png...\n');
f4 = figure('Position', [100, 100, figWidth, figHeight], 'Name', 'Preprocessing Before/After');
tiledlayout(2, 2, 'TileSpacing', 'compact');
sgtitle('Per-frame DC removal + unit-RMS normalization');

% Before (QPSK)
nexttile;
plot(t, real(data.signals(:, idxQPSK)), 'b', t, imag(data.signals(:, idxQPSK)), 'r');
title('Before Preprocessing (Time Domain)'); grid on;
nexttile;
plot(real(data.signals(:, idxQPSK)), imag(data.signals(:, idxQPSK)), 'k.'); axis equal;
title('Before Preprocessing (Constellation)'); grid on;

% After (QPSK)
nexttile;
plot(t, real(processedData.signals(:, idxQPSK)), 'b', t, imag(processedData.signals(:, idxQPSK)), 'r');
title('After Preprocessing (Time Domain)'); grid on;
nexttile;
plot(real(processedData.signals(:, idxQPSK)), imag(processedData.signals(:, idxQPSK)), 'k.'); axis equal;
title('After Preprocessing (Constellation)'); grid on;
save_fig(f4, '04_preprocessing_before_after'); close(f4);

%% Vis 5: 05_processed_IQ_time_domain.png
fprintf('Generating 05_processed_IQ_time_domain.png...\n');
f5 = figure('Position', [100, 100, figWidth, figHeight], 'Name', 'Processed I/Q Time Domain');
tiledlayout(2, 1, 'TileSpacing', 'compact');
% QPSK
nexttile;
plot(t, features.IQ.data(:, 1, idxQPSK), 'b', t, features.IQ.data(:, 2, idxQPSK), 'r');
title('Processed QPSK I/Q'); xlabel('Sample Index'); ylabel('Amplitude'); legend('I', 'Q'); grid on;
% 16-QAM
nexttile;
plot(t, features.IQ.data(:, 1, idx16QAM), 'b', t, features.IQ.data(:, 2, idx16QAM), 'r');
title('Processed 16-QAM I/Q'); xlabel('Sample Index'); ylabel('Amplitude'); legend('I', 'Q'); grid on;
save_fig(f5, '05_processed_IQ_time_domain'); close(f5);

%% Vis 6: 06_processed_constellation_QPSK.png
fprintf('Generating 06_processed_constellation_QPSK.png...\n');
f6 = figure('Position', [100, 100, figHeight, figHeight], 'Name', 'Processed QPSK Constellation');
plot(features.IQ.data(:, 1, idxQPSK), features.IQ.data(:, 2, idxQPSK), 'b.');
axis equal; title('Processed QPSK Constellation'); xlabel('In-phase'); ylabel('Quadrature'); grid on;
save_fig(f6, '06_processed_constellation_QPSK'); close(f6);

%% Vis 7: 07_processed_constellation_16QAM.png
fprintf('Generating 07_processed_constellation_16QAM.png...\n');
f7 = figure('Position', [100, 100, figHeight, figHeight], 'Name', 'Processed 16-QAM Constellation');
plot(features.IQ.data(:, 1, idx16QAM), features.IQ.data(:, 2, idx16QAM), 'r.');
axis equal; title('Processed 16-QAM Constellation'); xlabel('In-phase'); ylabel('Quadrature'); grid on;
save_fig(f7, '07_processed_constellation_16QAM'); close(f7);

%% Vis 8: 08_STFT_QPSK.png
fprintf('Generating 08_STFT_QPSK.png...\n');
f8 = figure('Position', [100, 100, figWidth, figHeight], 'Name', 'QPSK STFT');
imagesc(features.STFT.timeAxis, features.STFT.frequencyAxis, features.STFT.data(:, :, idxQPSK));
set(gca, 'YDir', 'normal'); colormap('jet'); cb = colorbar; ylabel(cb, 'Log Power (dB)');
title({'QPSK STFT Log-Power Representation', '64-sample Hamming window | 48-sample overlap | 64-point FFT'});
xlabel('Time (s)'); ylabel('Frequency (Hz)');
save_fig(f8, '08_STFT_QPSK'); close(f8);

%% Vis 9: 09_STFT_16QAM.png
fprintf('Generating 09_STFT_16QAM.png...\n');
f9 = figure('Position', [100, 100, figWidth, figHeight], 'Name', '16-QAM STFT');
imagesc(features.STFT.timeAxis, features.STFT.frequencyAxis, features.STFT.data(:, :, idx16QAM));
set(gca, 'YDir', 'normal'); colormap('jet'); cb = colorbar; ylabel(cb, 'Log Power (dB)');
title({'16-QAM STFT Log-Power Representation', '64-sample Hamming window | 48-sample overlap | 64-point FFT'});
xlabel('Time (s)'); ylabel('Frequency (Hz)');
save_fig(f9, '09_STFT_16QAM'); close(f9);

%% Vis 10: 10_IQ_feature_visualization.png
fprintf('Generating 10_IQ_feature_visualization.png...\n');
f10 = figure('Position', [100, 100, figWidth, figHeight], 'Name', 'IQ Feature Visuals');
tiledlayout(3, 1, 'TileSpacing', 'compact');
sgtitle({'I/Q AI Input Representation', '1024 samples x 2 channels'});
nexttile; plot(t, real(processedData.signals(:, idxQPSK)), 'b', t, imag(processedData.signals(:, idxQPSK)), 'r');
title('Original Complex Signal (Preprocessed)'); legend('Real', 'Imag'); grid on;
nexttile; imagesc(t, 1, features.IQ.data(:, 1, idxQPSK)'); title('I Component Heatmap'); yticks([]);
nexttile; imagesc(t, 1, features.IQ.data(:, 2, idxQPSK)'); title('Q Component Heatmap'); yticks([]); colormap('parula');
save_fig(f10, '10_IQ_feature_visualization'); close(f10);

%% Vis 11: 11_class_comparison.png
fprintf('Generating 11_class_comparison.png...\n');
f11 = figure('Position', [100, 100, figWidth, figHeight], 'Name', 'Class Comparison');
tiledlayout(1, 2, 'TileSpacing', 'compact');
% QPSK Amplitude Distribution
nexttile;
ampQPSK = abs(processedData.signals(:, idxQPSK));
histogram(ampQPSK, 50, 'Normalization', 'pdf', 'FaceColor', 'b');
title('QPSK Amplitude Distribution'); xlabel('Amplitude'); ylabel('Density'); grid on;
% 16-QAM Amplitude Distribution
nexttile;
amp16QAM = abs(processedData.signals(:, idx16QAM));
histogram(amp16QAM, 50, 'Normalization', 'pdf', 'FaceColor', 'r');
title('16-QAM Amplitude Distribution'); xlabel('Amplitude'); ylabel('Density'); grid on;
sgtitle('Amplitude Distribution Comparison (QPSK vs 16-QAM)');
save_fig(f11, '11_class_comparison'); close(f11);

%% Vis 12: 12_EDA_summary.png
fprintf('Generating 12_EDA_summary.png...\n');
f12 = figure('Position', [100, 100, figWidth, figHeight], 'Name', 'EDA Summary');
tiledlayout(2, 2, 'TileSpacing', 'compact');
sgtitle({'Arya Signal Processing Pipeline Summary', 'Raw RF -> DC Removal -> RMS Normalization -> Features'});

% 1: Raw Signal
nexttile;
plot(t, real(data.signals(:, idxQPSK)), 'b'); title('1. Raw Waveform (I)'); grid on;

% 2: Processed Constellation
nexttile;
plot(real(processedData.signals(:, idx16QAM)), imag(processedData.signals(:, idx16QAM)), 'k.');
axis equal; title('2. Processed Constellation (16-QAM)'); grid on;

% 3: I/Q Representation
nexttile;
imagesc(features.IQ.data(:, :, idxQPSK)'); title('3. I/Q Tensor: 1024x2 (QPSK)');
yticks([1 2]); yticklabels({'I', 'Q'}); colormap('parula');

% 4: STFT Representation
nexttile;
imagesc(features.STFT.timeAxis, features.STFT.frequencyAxis, features.STFT.data(:, :, idxQPSK));
set(gca, 'YDir', 'normal'); title('4. STFT Tensor: 64x61 (QPSK)'); colormap('jet');
save_fig(f12, '12_EDA_summary'); close(f12);

%% 6. Calculate Real Statistics
fprintf('\n--- Real Dataset Statistics ---\n');
qpsk_all = processedData.signals(:, strcmp(processedData.labels, 'QPSK'));
qam_all = processedData.signals(:, strcmp(processedData.labels, '16-QAM'));

fprintf('QPSK:\n');
fprintf('  Mean: %g + %gj\n', mean(real(qpsk_all(:))), mean(imag(qpsk_all(:))));
fprintf('  RMS: %g\n', rms(qpsk_all(:)));
fprintf('  Peak Magnitude: %g\n', max(abs(qpsk_all(:))));

fprintf('16-QAM:\n');
fprintf('  Mean: %g + %gj\n', mean(real(qam_all(:))), mean(imag(qam_all(:))));
fprintf('  RMS: %g\n', rms(qam_all(:)));
fprintf('  Peak Magnitude: %g\n', max(abs(qam_all(:))));

fprintf('EDA Visualization Pipeline Completed Successfully.\n');
