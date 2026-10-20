function isValid = validate_features(features)
% validate_features Validates extracted features for dimensions and integrity.
%
% INPUTS:
%   features - Struct returned by extract_features
%
% OUTPUTS:
%   isValid - Boolean

    isValid = true;
    numFrames = length(features.frameIds);
    numLabels = length(features.labels);
    
    if numFrames ~= numLabels
        error('validate_features:AlignmentError', 'Frame IDs count does not match label count.');
    end
    
    % Validate IQ
    if isfield(features, 'IQ')
        iqData = features.IQ.data;
        if ~isreal(iqData)
            error('validate_features:IQNotReal', 'I/Q features must be real-valued.');
        end
        if any(isnan(iqData(:))) || any(isinf(iqData(:)))
            error('validate_features:IQNaNInf', 'I/Q features contain NaN or Inf.');
        end
        if size(iqData, 3) ~= numFrames
            error('validate_features:IQAlignmentError', 'IQ frame count mismatch.');
        end
        
        % Validate QPSK and QAM specific counts if they are the dataset we expect (2000 total)
        if numFrames == 2000
            qpskCount = sum(strcmp(features.labels, 'QPSK'));
            qamCount = sum(strcmp(features.labels, '16-QAM'));
            if qpskCount ~= 1000 || qamCount ~= 1000
                error('validate_features:ClassImbalance', 'Expected 1000 QPSK and 1000 16-QAM.');
            end
        end
    end
    
    % Validate STFT
    if isfield(features, 'STFT')
        stftData = features.STFT.data;
        if ~isreal(stftData)
            error('validate_features:STFTNotReal', 'STFT features must be real-valued for CNN.');
        end
        if any(isnan(stftData(:))) || any(isinf(stftData(:)))
            error('validate_features:STFTNaNInf', 'STFT features contain NaN or Inf.');
        end
        if size(stftData, 3) ~= numFrames
            error('validate_features:STFTAlignmentError', 'STFT frame count mismatch.');
        end
        
        % Check that all frames have identical dimensions
        [fBins, tBins, frames] = size(stftData);
        if frames ~= numFrames
             error('validate_features:STFTDimError', 'STFT dimension 3 mismatch.');
        end
    end
    
    fprintf('Feature validation successful.\n');
end
