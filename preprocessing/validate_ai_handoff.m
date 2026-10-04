function isValid = validate_ai_handoff(features)
% validate_ai_handoff Final validation of the AI-ready feature structure.
% Ensures that the complete data contract is respected before handoff.
%
% INPUTS:
%   features - Struct returned by extract_features
%
% OUTPUTS:
%   isValid - Boolean

    isValid = true;
    fprintf('\n------------------------------------------------------------\n');
    fprintf('AI HANDOFF VALIDATION\n');
    fprintf('------------------------------------------------------------\n');

    %% 1. Dimension Checks
    numFrames = length(features.frameIds);
    expectedFrames = 2000;
    
    if numFrames ~= expectedFrames
        fprintf('Frames: %d (FAIL, expected %d)\n', numFrames, expectedFrames);
        isValid = false;
    else
        fprintf('Frames: %d\n', numFrames);
    end
    
    if isfield(features, 'IQ') && isfield(features.IQ, 'data')
        [iqSamples, iqChannels, iqFrames] = size(features.IQ.data);
        if iqSamples ~= 1024 || iqChannels ~= 2 || iqFrames ~= expectedFrames
            fprintf('I/Q features: %d x %d x %d (FAIL)\n', iqSamples, iqChannels, iqFrames);
            isValid = false;
        else
            fprintf('I/Q features: %d x %d x %d\n', iqSamples, iqChannels, iqFrames);
        end
    else
        fprintf('I/Q features: MISSING (FAIL)\n');
        isValid = false;
    end
    
    if isfield(features, 'STFT') && isfield(features.STFT, 'data')
        [stftFreq, stftTime, stftFrames] = size(features.STFT.data);
        if stftFreq ~= 64 || stftTime ~= 61 || stftFrames ~= expectedFrames
            fprintf('STFT features: %d x %d x %d (FAIL)\n', stftFreq, stftTime, stftFrames);
            isValid = false;
        else
            fprintf('STFT features: %d x %d x %d\n', stftFreq, stftTime, stftFrames);
        end
    else
        fprintf('STFT features: MISSING (FAIL)\n');
        isValid = false;
    end
    
    %% 2. Classes Check
    numLabels = length(features.labels);
    qpskCount = sum(strcmp(features.labels, 'QPSK'));
    qamCount = sum(strcmp(features.labels, '16-QAM'));
    
    fprintf('Classes:\n');
    if qpskCount == 1000 && qamCount == 1000 && numLabels == expectedFrames
        fprintf('  QPSK = 1000\n  16-QAM = 1000\n');
    else
        fprintf('  QPSK = %d\n  16-QAM = %d (FAIL)\n', qpskCount, qamCount);
        isValid = false;
    end
    
    %% 3. Metadata Check
    if isfield(features, 'Fs') && isfinite(features.Fs) && features.Fs > 0
        fprintf('Sample rate: %g Hz\n', features.Fs);
    else
        fprintf('Sample rate: INVALID (FAIL)\n');
        isValid = false;
    end
    
    if isfield(features, 'snr') && isfinite(features.snr)
        fprintf('Target SNR: %g dB\n', features.snr);
    else
        fprintf('Target SNR: INVALID (FAIL)\n');
        isValid = false;
    end
    
    %% 4. NaN / Inf checks
    nanCount = 0;
    infCount = 0;
    
    if isfield(features, 'IQ')
        nanCount = nanCount + sum(isnan(features.IQ.data(:)));
        infCount = infCount + sum(isinf(features.IQ.data(:)));
    end
    if isfield(features, 'STFT')
        nanCount = nanCount + sum(isnan(features.STFT.data(:)));
        infCount = infCount + sum(isinf(features.STFT.data(:)));
    end
    
    fprintf('NaN: %d\n', nanCount);
    fprintf('Inf: %d\n', infCount);
    
    if nanCount > 0 || infCount > 0
        isValid = false;
    end
    
    %% 5. Status
    if isValid
        fprintf('Status: PASS\n');
    else
        fprintf('Status: FAIL\n');
        error('validate_ai_handoff:Failed', 'AI handoff validation failed.');
    end
    fprintf('------------------------------------------------------------\n');
end
