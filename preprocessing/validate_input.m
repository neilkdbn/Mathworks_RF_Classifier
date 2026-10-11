function isValid = validate_input(dataStruct)
% validate_input Validates the standardized data structure returned by load_rf_dataset.
%
% INPUTS:
%   dataStruct - MATLAB struct returned by load_rf_dataset.
%
% OUTPUTS:
%   isValid - Boolean indicating whether validation passed.
%
% EXCEPTONS:
%   Throws an error if validation strictly fails on dimensions, data types, 
%   or required fields.

    isValid = true;
    
    % 1. Check if signals field exists and is not empty
    if ~isfield(dataStruct, 'signals') || isempty(dataStruct.signals)
        error('validate_input:MissingSignals', 'Signal data is missing or empty.');
    end
    
    % 2. Check if labels field exists and matches signal dimensions
    if ~isfield(dataStruct, 'labels') || isempty(dataStruct.labels)
        error('validate_input:MissingLabels', 'Labels are missing or empty.');
    end
    
    numFramesSignal = size(dataStruct.signals, 2);
    numFramesLabel = length(dataStruct.labels);
    
    if numFramesSignal ~= numFramesLabel
        error('validate_input:DimensionMismatch', ...
            'Number of signal frames (%d) does not match number of labels (%d).', ...
            numFramesSignal, numFramesLabel);
    end
    
    % 3. Check signal attributes (must be complex based on inspection)
    if ~isreal(dataStruct.signals) == 0
        error('validate_input:NotComplex', 'Signal data must be complex baseband IQ.');
    end
    
    if ~isfloat(dataStruct.signals)
        error('validate_input:InvalidDatatype', 'Signal data must be float (single or double).');
    end
    
    % 4. Check for NaN or Inf
    if any(isnan(dataStruct.signals(:)))
        error('validate_input:NaNValues', 'Signal contains NaN values.');
    end
    if any(isinf(dataStruct.signals(:)))
        error('validate_input:InfValues', 'Signal contains Inf values.');
    end
    
    % 5. Warn about missing metadata, but don't strictly error if not present
    if isnan(dataStruct.Fs)
        warning('validate_input:MissingFs', 'Sampling frequency (Fs) is missing. Subsequent signal processing features (e.g., spectrograms) will lack physical units.');
    end
    
    if isnan(dataStruct.snr)
        warning('validate_input:MissingSNR', 'Target SNR is missing.');
    end
    
    fprintf('Input validation completed successfully.\n');
end
