function filtered_signals = apply_filter(signals, Fs, options)
% apply_filter Applies an optional low-pass filter to the signals.
%
% INPUTS:
%   signals - Complex baseband IQ array
%   Fs      - Sampling frequency
%   options - Struct with filter options (e.g., enable, cutoff, order)
%
% OUTPUTS:
%   filtered_signals - Filtered signals.
%
% NOTE:
%   Filtering is DISABLED by default. The raw QPSK/QAM signals already have
%   pulse shaping (raised cosine) applied during generation. Additional 
%   arbitrary filtering could corrupt the inter-symbol interference properties 
%   or distort phase. This function is provided as a configurable option if 
%   out-of-band noise removal becomes strictly necessary.

    if nargin < 3
        options = struct('enable', false);
    end
    
    if ~options.enable
        filtered_signals = signals;
        return;
    end
    
    if isnan(Fs) || isempty(Fs)
        warning('apply_filter:MissingFs', 'Sampling frequency Fs is missing. Cannot apply filter with physical cutoff. Bypassing filter.');
        filtered_signals = signals;
        return;
    end
    
    % Default parameters if enabled but not fully specified
    if ~isfield(options, 'cutoff')
        options.cutoff = Fs / 4; % Default arbitrary cutoff
    end
    if ~isfield(options, 'order')
        options.order = 8;
    end
    
    % Design a lowpass filter
    % Note: Requires Signal Processing Toolbox
    if license('test', 'Signal_Toolbox')
        try
            d = designfilt('lowpassiir', 'FilterOrder', options.order, ...
                'HalfPowerFrequency', options.cutoff, 'SampleRate', Fs);
                
            % Zero-phase filtering (filtfilt) to preserve phase
            filtered_signals = zeros(size(signals), 'like', signals);
            for k = 1:size(signals, 2)
                % Filter real and imaginary parts separately
                fI = filtfilt(d, real(signals(:, k)));
                fQ = filtfilt(d, imag(signals(:, k)));
                filtered_signals(:, k) = complex(fI, fQ);
            end
        catch ME
            warning('apply_filter:FilterFailed', 'Filtering failed: %s. Returning unfiltered signals.', ME.message);
            filtered_signals = signals;
        end
    else
        warning('apply_filter:NoToolbox', 'Signal Processing Toolbox not available. Bypassing filter.');
        filtered_signals = signals;
    end
end
