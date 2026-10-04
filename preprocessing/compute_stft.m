function [s, f, t] = compute_stft(frame, Fs, config)
% compute_stft Computes the STFT of a single complex signal frame.
%
% INPUTS:
%   frame  - Complex signal vector (e.g., 1024x1)
%   Fs     - Sampling frequency in Hz
%   config - Struct with fields: windowLength, overlapLength, fftLength
%
% OUTPUTS:
%   s - Complex STFT matrix
%   f - Frequency axis vector
%   t - Time axis vector

    % Use a Hamming window for good sidelobe suppression
    win = hamming(config.windowLength, 'periodic');
    
    % Compute STFT using MATLAB's stft function
    % Centered frequency output is standard for baseband IQ
    [s, f, t] = stft(frame, Fs, 'Window', win, ...
                     'OverlapLength', config.overlapLength, ...
                     'FFTLength', config.fftLength, ...
                     'FrequencyRange', 'centered');
end
