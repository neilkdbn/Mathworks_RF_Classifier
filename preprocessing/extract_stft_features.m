function stft_features = extract_stft_features(processedData, config)
% extract_stft_features Computes STFT features across the dataset for 2D CNNs.
%
% INPUTS:
%   processedData - Struct from Phase 2 preprocessing
%   config        - (Optional) STFT parameter configuration
%
% OUTPUTS:
%   stft_features - Struct containing 3D STFT tensor and metadata.

    signals = processedData.signals;
    [~, numFrames] = size(signals);
    Fs = processedData.Fs;
    
    if isnan(Fs) || isinf(Fs) || Fs <= 0
        error('extract_stft_features:InvalidFs', 'STFT extraction requires a valid sample rate Fs.');
    end

    % Define STFT Configuration if not provided
    % SCIENTIFIC JUSTIFICATION:
    % Frame is 1024 samples. Fs = 1 MHz.
    % To get a reasonable 2D image (e.g. ~32x32 to ~64x64 grid):
    % Window = 64 samples (64 us). This captures exactly 8 symbols (since 8 sps).
    % Overlap = 48 samples (75% overlap) to yield 61 time steps.
    % FFT Length = 64 (yields 64 frequency bins).
    if nargin < 2
        config = struct();
        config.windowLength = 64;
        config.overlapLength = 48;
        config.fftLength = 64;
        config.featureType = 'logPower'; % Or 'magnitude'
    end
    
    % Pre-calculate axes and dimensions using the first frame
    [s_test, f, t] = compute_stft(signals(:, 1), Fs, config);
    [numFreqBins, numTimeBins] = size(s_test);
    
    % Preallocate tensor [FreqBins x TimeBins x Frames]
    stft_tensor = zeros(numFreqBins, numTimeBins, numFrames, 'double');
    
    for k = 1:numFrames
        [s, ~, ~] = compute_stft(signals(:, k), Fs, config);
        
        switch config.featureType
            case 'magnitude'
                feat = abs(s);
            case 'logPower'
                feat = 10 * log10(abs(s).^2 + eps);
            otherwise
                error('extract_stft_features:InvalidType', 'Unknown featureType.');
        end
        
        stft_tensor(:, :, k) = feat;
    end
    
    stft_features = struct();
    stft_features.data = stft_tensor;
    stft_features.size = size(stft_tensor);
    stft_features.frequencyAxis = f;
    stft_features.timeAxis = t;
    stft_features.stftConfig = config;
    stft_features.description = '[FrequencyBins x TimeBins x Frames]';
    
    % Preserve metadata
    stft_features.labels = processedData.labels;
    stft_features.Fs = processedData.Fs;
    stft_features.snr = processedData.snr;
    
    if isfield(processedData, 'processingInfo')
        stft_features.preprocessingInfo = processedData.processingInfo;
    end
    
    if isfield(processedData, 'metadata')
        stft_features.metadata = processedData.metadata;
    end
end
