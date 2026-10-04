function iq_features = extract_iq_features(processedData)
% extract_iq_features Converts complex baseband signals to a 1D-CNN AI-ready tensor.
%
% INPUTS:
%   processedData - Struct from Phase 2 preprocessing
%
% OUTPUTS:
%   iq_features - Struct containing I/Q features and metadata.
%
% DIMENSION CONTRACT:
%   Output tensor size: [1024, 2, numFrames]
%   Dimension 1: Time samples (1 to 1024)
%   Dimension 2: Channels (1 = I, 2 = Q)
%   Dimension 3: Frame index
%
% NOTE:
%   This layout [SequenceLength, NumChannels, NumObservations] is
%   compatible with MATLAB's Deep Learning Toolbox for 1D CNNs or LSTMs.

    signals = processedData.signals;
    [numSamples, numFrames] = size(signals);
    
    % Preallocate tensor [Samples x 2 x Frames]
    iq_tensor = zeros(numSamples, 2, numFrames, 'double');
    
    % Populate I and Q channels
    for k = 1:numFrames
        iq_tensor(:, 1, k) = real(signals(:, k));
        iq_tensor(:, 2, k) = imag(signals(:, k));
    end
    
    iq_features = struct();
    iq_features.data = iq_tensor;
    iq_features.size = size(iq_tensor);
    iq_features.description = '[Samples x Channels (I,Q) x Frames]';
    
    % Preserve metadata
    iq_features.labels = processedData.labels;
    iq_features.Fs = processedData.Fs;
    iq_features.snr = processedData.snr;
    
    if isfield(processedData, 'processingInfo')
        iq_features.preprocessingInfo = processedData.processingInfo;
    end
end
