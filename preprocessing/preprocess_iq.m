function processedData = preprocess_iq(dataStruct, options)
% preprocess_iq Modular preprocessing pipeline for RF Baseband signals.
%
% INPUTS:
%   dataStruct - MATLAB struct returned by load_rf_dataset
%   options    - (Optional) Struct defining processing options
%
% OUTPUTS:
%   processedData - MATLAB struct containing processed signals and metadata.
%
% PIPELINE STAGES:
%   1. Validation
%   2. Quality Analysis (Raw)
%   3. DC Offset Removal
%   4. Amplitude/Power Normalization
%   5. Filtering (disabled by default)
%   6. Validation (Processed)

    if nargin < 2
        options = struct();
    end
    
    % Default pipeline options
    if ~isfield(options, 'removeDC')
        options.removeDC = true;
    end
    if ~isfield(options, 'normalize')
        options.normalize = true;
    end
    if ~isfield(options, 'normMethod')
        options.normMethod = 'rms';
    end
    if ~isfield(options, 'filter')
        options.filter = struct('enable', false);
    end
    
    % 1. Validation
    isValid = validate_input(dataStruct);
    if ~isValid
        error('preprocess_iq:InvalidInput', 'Input data structure failed validation.');
    end
    
    processedData = dataStruct; % Copy structure to preserve metadata and labels
    
    % 2. Quality Analysis (Raw)
    processedData.processingInfo.rawQuality = analyze_signal_quality(dataStruct);
    
    % Get the raw signals
    current_signals = dataStruct.signals;
    
    % 3. DC Offset Removal
    if options.removeDC
        current_signals = remove_dc_offset(current_signals);
    end
    
    % 4. Amplitude/Power Normalization
    if options.normalize
        current_signals = normalize_amplitude(current_signals, options.normMethod);
    end
    
    % 5. Filtering
    if options.filter.enable
        current_signals = apply_filter(current_signals, dataStruct.Fs, options.filter);
    end
    
    % Assign processed signals back
    processedData.signals = current_signals;
    
    % 6. Post-Processing Validation checks
    if any(isnan(processedData.signals(:)))
        error('preprocess_iq:NaNIntroduced', 'Preprocessing introduced NaN values.');
    end
    if any(isinf(processedData.signals(:)))
        error('preprocess_iq:InfIntroduced', 'Preprocessing introduced Inf values.');
    end
    
    % Update Processing Info
    processedData.processingInfo.phase = 2;
    processedData.processingInfo.removeDC = options.removeDC;
    processedData.processingInfo.normalize = options.normalize;
    processedData.processingInfo.normMethod = options.normMethod;
    processedData.processingInfo.filterEnabled = options.filter.enable;
    if options.filter.enable
        processedData.processingInfo.filterConfig = options.filter;
    end
    
    processedData.processingInfo.processedQuality = analyze_signal_quality(processedData);
end
