function normalized_signals = normalize_amplitude(signals, method)
% normalize_amplitude Normalizes the amplitude/power of the signals independently per frame.
%
% INPUTS:
%   signals - Complex baseband IQ array (N samples x M frames)
%   method  - Normalization method: 'rms' (default) or 'peak'
%
% OUTPUTS:
%   normalized_signals - Normalized signal array.
%
% JUSTIFICATION: 
%   RMS normalization is chosen as the default because digital modulation 
%   (like QAM) encodes information in both amplitude and phase. Peak 
%   normalization is vulnerable to single-sample noise spikes, while RMS 
%   normalization provides a stable statistical power scaling across frames
%   while preserving the internal constellation power ratios.

    if nargin < 2
        method = 'rms';
    end
    
    normalized_signals = zeros(size(signals), 'like', signals);
    
    numFrames = size(signals, 2);
    
    for k = 1:numFrames
        frame = signals(:, k);
        
        switch lower(method)
            case 'rms'
                % Calculate RMS magnitude
                normFactor = rms(abs(frame), 'omitnan');
                
            case 'peak'
                % Calculate peak magnitude
                normFactor = max(abs(frame), [], 'omitnan');
                
            otherwise
                error('normalize_amplitude:InvalidMethod', 'Unsupported method: %s', method);
        end
        
        % Robust handling for zero-energy or near-zero frames
        if normFactor < 1e-12 || isnan(normFactor)
            normalized_signals(:, k) = frame; % Leave unchanged to avoid Div/0
        else
            normalized_signals(:, k) = frame ./ normFactor;
        end
    end
end
