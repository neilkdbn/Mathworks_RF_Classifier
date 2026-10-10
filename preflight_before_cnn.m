%% RF CLASSIFIER: PRE-TRAINING MATLAB VERIFICATION
% Place this file directly in the Mathworks_RF_Classifier project root.
% Run it using: preflight_before_cnn
% Checks the saved data + feature handoff without rerunning generate_signals.m.
% It runs the repository's existing unit tests, but does not train a model.

root = fileparts(mfilename('fullpath'));
assert(isfolder(fullfile(root,'preprocessing')), 'Missing preprocessing folder.');
assert(isfolder(fullfile(root,'tests')), 'Missing tests folder.');
assert(isfile(fullfile(root,'rf_dataset_v1.mat')), 'Missing raw dataset.');
assert(isfile(fullfile(root,'data','processed','rf_features_v1.mat')), ...
    'Missing feature file. Run scripts/generate_features.m first.');

addpath(fullfile(root,'preprocessing'));
fprintf('\n============= RF PRE-TRAINING CHECK =============\n');
fprintf('Project: %s\n', root);

%% 1. Installed dependencies
assert(~isempty(which('hamming')) && ~isempty(which('stft')), ...
    'Signal Processing Toolbox functions unavailable.');
assert(~isempty(which('trainnet')), ...
    'trainnet unavailable. Install/activate Deep Learning Toolbox.');
fprintf('[PASS] MATLAB signal processing and deep learning functions found.\n');
if isempty(which('pskmod')) || isempty(which('qammod')) || isempty(which('awgn'))
    fprintf('[NOTE] Communications Toolbox modulation/noise functions are unavailable.\n');
    fprintf('       You can check saved data, but regenerating Neil''s data requires Communications Toolbox.\n');
else
    fprintf('[PASS] Communications Toolbox modulation/noise functions found.\n');
end

%% 2. Run all existing tests from the correct relative-path location
oldFolder = pwd;
try
    cd(fullfile(root,'tests'));
    testResults = runtests(pwd);
catch ME
    cd(oldFolder);
    rethrow(ME);
end
cd(oldFolder);

nPassed = sum([testResults.Passed]);
nFailed = sum([testResults.Failed]);
nIncomplete = sum([testResults.Incomplete]);
fprintf('Unit test cases: %d passed, %d failed, %d incomplete.\n', ...
    nPassed, nFailed, nIncomplete);
assert(~isempty(testResults) && all([testResults.Passed]), ...
    'Tests did not all pass. Review the MATLAB Test Results before proceeding.');
fprintf('[PASS] All reported unit test cases passed.\n');

%% 3. Verify original saved RF frames
raw = load(fullfile(root,'rf_dataset_v1.mat'));
assert(isfield(raw,'qpskData_realistic') && isfield(raw,'qamData_realistic'), ...
    'Raw dataset is missing modulation matrices.');
assert(isequal(size(raw.qpskData_realistic), [1024 1000]), ...
    'Unexpected QPSK raw data dimensions.');
assert(isequal(size(raw.qamData_realistic), [1024 1000]), ...
    'Unexpected 16-QAM raw data dimensions.');
assert(all(isfinite(raw.qpskData_realistic(:))) && ...
       all(isfinite(raw.qamData_realistic(:))), ...
    'Raw RF dataset contains non-finite values.');
fprintf('[PASS] Original RF dataset: 1000 frames/class, 1024 samples/frame.\n');

%% 4. Verify saved AI features and label/ID mapping
loaded = load(fullfile(root,'data','processed','rf_features_v1.mat'),'features');
f = loaded.features;
assert(isfield(f,'IQ') && isfield(f,'STFT'), 'Feature set is incomplete.');
assert(isequal(size(f.IQ.data),[1024 2 2000]), 'Incorrect I/Q tensor shape.');
assert(isequal(size(f.STFT.data),[64 61 2000]), 'Incorrect STFT tensor shape.');
assert(isreal(f.IQ.data) && isreal(f.STFT.data), 'Expected real-valued tensors.');
assert(all(isfinite(f.IQ.data(:))) && all(isfinite(f.STFT.data(:))), ...
    'Feature tensor contains NaN or Inf.');
assert(numel(f.labels)==2000 && numel(f.frameIds)==2000, ...
    'Label/frame-ID count mismatch.');
assert(isequal(f.frameIds(:),(1:2000)'), ...
    'Frame IDs are missing, duplicated, or reordered.');
labels = string(f.labels(:));
assert(all(labels(1:1000)=="QPSK") && all(labels(1001:2000)=="16-QAM"), ...
    'Labels do not match the raw data concatenation order.');
assert(isfinite(f.Fs) && f.Fs==1e6 && isfinite(f.snr) && f.snr==10, ...
    'Unexpected saved sampling rate / target SNR.');
fprintf('[PASS] I/Q, STFT, label order, frame IDs, and metadata.\n');

%% 5. Independently reconstruct I/Q from the original dataset
% This checks actual per-frame values, not just dimensions.
data = load_rf_dataset(fullfile(root,'rf_dataset_v1.mat'));
processed = preprocess_iq(data);
IQ = complex(reshape(f.IQ.data(:,1,:),1024,2000), ...
             reshape(f.IQ.data(:,2,:),1024,2000));
maxIQError = max(abs(IQ(:) - processed.signals(:)));
assert(maxIQError < 1e-9, ...
    'Saved I/Q data do not match a fresh preprocessing run.');
meanDC = max(abs(mean(processed.signals,1)));
frameRMS = sqrt(mean(abs(processed.signals).^2,1));
maxRMSDeviation = max(abs(frameRMS-1));
assert(meanDC < 1e-9 && maxRMSDeviation < 1e-9, ...
    'DC removal or per-frame RMS normalization does not match the contract.');
fprintf('[PASS] I/Q reconstructed from original data; max error = %.3g.\n',maxIQError);

%% 6. Independently spot-check actual STFT values
spotFrames = [1 750 1001 2000];
maxSTFTError = 0;
for k = spotFrames
    [s,~,~] = compute_stft(processed.signals(:,k), f.Fs, f.STFT.stftConfig);
    expected = 10*log10(abs(s).^2 + eps);
    observed = f.STFT.data(:,:,k);
    maxSTFTError = max(maxSTFTError, max(abs(expected(:)-observed(:))));
end
assert(maxSTFTError < 1e-9, 'STFT values do not match recomputation.');
fprintf('[PASS] STFT spot-check matches recomputation; max error = %.3g.\n',maxSTFTError);

fprintf('\nPRE-TRAINING HANDOFF CHECKS: PASS\n');
fprintf('NOTE: This does NOT prove the original generator was freshly rerun,\n');
fprintf('      or that its channel modeling and frame independence are ideal.\n');
fprintf('      Final research runs need generator-seed/filter-state review,\n');
fprintf('      saved split indices, and an untouched independent test set.\n');
fprintf('==================================================\n');
