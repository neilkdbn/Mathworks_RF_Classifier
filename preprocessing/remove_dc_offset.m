function processed_signals = remove_dc_offset(signals)
% remove_dc_offset Removes the DC offset (mean) independently for each frame.
%
% INPUTS:
%   signals - Complex baseband IQ array (N samples x M frames)
%
% OUTPUTS:
%   processed_signals - Signals with DC component removed per frame.

    if isempty(signals)
        processed_signals = signals;
        return;
    end
    
    % Calculate mean along dimension 1 (samples within each frame)
    frameMeans = mean(signals, 1, 'omitnan');
    
    % Subtract the mean of each frame from all samples in that frame
    processed_signals = signals - frameMeans;
end
