% SMOKE_TEST_RF_AI_DEPLOYMENT
% Anjali: run in an extracted delivery folder (no dataset needed).
% Checks loading, preprocessing, and output shapes using dummy I/Q noise.
% Does NOT establish classification accuracy; these are NOT test examples.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'deep_learning'));
addpath(fullfile(root,'preprocessing'));
assert(isfile(fullfile(root,'models','rf_1dcnn_r2026b.mat')));
assert(isfile(fullfile(root,'models','rf_2dcnn_constellation_r2026b.mat')));

rng(20261010,'twister');
raw = complex(randn(1024,1),randn(1024,1));
result = predict_rf_from_raw(raw);
assert(isscalar(result.label) && any(result.label==["16-QAM","QPSK"]));
assert(isequal(size(result.classScores),[1,2]));
assert(all(isfinite(result.classScores)));
assert(abs(sum(result.classScores)-1)<1e-3);

frame = [real(raw),imag(raw)];
frame = frame-mean(frame,1);
frame = frame/sqrt(mean(sum(frame.^2,2)));
result2 = predict_rf_modulation(frame);
assert(isequal(size(result2.classScores),[1 2]));

fprintf('DEPLOYMENT API SMOKE TEST PASSED.\n');
fprintf('Example output label (random noise, NOT a valid modulation test): %s\n', char(result.label));
fprintf('Result score shape: 1x2, classes: %s, %s\n', ...
    char(result.classNames(1)),char(result.classNames(2)));
fprintf('This is an integration check, NOT an accuracy or RF robustness test.\n');
