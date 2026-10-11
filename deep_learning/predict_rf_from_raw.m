function result = predict_rf_from_raw(rawComplexFrame)
% PREDICT_RF_FROM_RAW  DC-remove, RMS-normalize, classify one complex frame.
% rawComplexFrame: [1024 x 1] complex baseband samples, NOT an RF carrier.
% Calls Arya's ORIGINAL remove_dc_offset and normalize_amplitude functions.
% Never normalize twice: if an input is already preprocessed, call
% predict_rf_modulation([real(frame), imag(frame)]) directly instead.
%
% This is a convenience adapter, not hardware capture or a streaming system.
% MATLAB R2026b; Deep Learning Toolbox; preprocessing helpers included.

validateattributes(rawComplexFrame,{'single','double'}, ...
    {'vector','numel',1024,'finite','nonempty'},mfilename,'rawComplexFrame',1);
assert(~isreal(rawComplexFrame), ...
    'Expected complex baseband samples I+jQ. For processed 1024x2 input, use predict_rf_modulation.');

root = fileparts(fileparts(mfilename('fullpath')));
preprocDir = fullfile(root,'preprocessing');
assert(isfolder(preprocDir),'The preprocessing directory is missing.');
% Prioritize the copy of Arya's actual helpers shipped with this project.
addpath(preprocDir,'-begin');

x = double(rawComplexFrame(:));
x = remove_dc_offset(x);
energy = sqrt(mean(abs(x).^2));
assert(isfinite(energy) && energy > 1e-12, ...
    'Input has negligible energy after DC removal; refusing to classify.');
x = normalize_amplitude(x,'rms');
iqFrame = [real(x),imag(x)];
result = predict_rf_modulation(iqFrame);
result.inputMode = "raw-complex -> DC removal -> per-frame RMS normalization";
end
