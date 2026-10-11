function features = extract_features(processedData, options)
% extract_features Master function for Phase 3 Feature Extraction.
%
% INPUTS:
%   processedData - Struct from Phase 2
%   options       - (Optional) Struct defining extraction config
%
% OUTPUTS:
%   features - Struct containing AI-ready IQ and STFT representations.

    if nargin < 2
        options = struct();
    end
    
    if ~isfield(options, 'iq')
        options.iq.enabled = true;
    end
    if ~isfield(options, 'stft')
        options.stft.enabled = true;
        % Provide scientifically justified defaults explicitly here if desired
        options.stft.windowLength = 64;
        options.stft.overlapLength = 48;
        options.stft.fftLength = 64;
        options.stft.featureType = 'logPower';
    end
    
    features = struct();
    
    % Validate Input
    if ~isfield(processedData, 'signals') || isempty(processedData.signals)
        error('extract_features:InvalidInput', 'processedData missing signals field.');
    end
    
    % Create unified frame IDs for provenance
    numFrames = size(processedData.signals, 2);
    features.frameIds = 1:numFrames;
    features.labels = processedData.labels;
    features.Fs = processedData.Fs;
    features.snr = processedData.snr;
    
    if isfield(processedData, 'processingInfo')
        features.preprocessingInfo = processedData.processingInfo;
    end
    
    % 1. Extract I/Q Features
    if options.iq.enabled
        features.IQ = extract_iq_features(processedData);
    end
    
    % 2. Extract STFT Features
    if options.stft.enabled
        features.STFT = extract_stft_features(processedData, options.stft);
    end
    
    features.metadata.phase = 3;
    features.metadata.timestamp = datetime('now');
end
