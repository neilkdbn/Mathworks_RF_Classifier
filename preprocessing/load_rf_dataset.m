function dataStruct = load_rf_dataset(datasetPath)
% load_rf_dataset Loads the RF dataset and standardizes it into a structure.
%
% INPUTS:
%   datasetPath - String or character array specifying path to .mat dataset.
%
% OUTPUTS:
%   dataStruct - MATLAB struct containing:
%       .signals         : N x M complex array of samples
%       .labels          : Categorical or numeric array for labels
%       .samplesPerFrame : Number of samples in each frame
%       .numFrames       : Number of frames per class
%       .Fs              : Sampling frequency (if available, else NaN)
%       .snr             : Target SNR (if available, else NaN)
%
% NOTES:
%   This function deals with missing fields by logging warnings and assigning
%   empty/NaN values, leaving downstream validation to validate_input.m.

    if nargin < 1
        datasetPath = '../rf_dataset_v1.mat';
    end

    if ~isfile(datasetPath)
        error('load_rf_dataset:FileNotFound', 'The specified dataset file was not found: %s', datasetPath);
    end
    
    raw = load(datasetPath);
    
    dataStruct = struct();
    
    % Check for expected signal data based on inspection
    if isfield(raw, 'qpskData_realistic') && isfield(raw, 'qamData_realistic')
        % Concatenate signals along the frames (columns)
        dataStruct.signals = [raw.qpskData_realistic, raw.qamData_realistic];
        
        % Generate labels since they are missing in the raw MAT file
        numQPSK = size(raw.qpskData_realistic, 2);
        numQAM = size(raw.qamData_realistic, 2);
        dataStruct.labels = [repmat({'QPSK'}, 1, numQPSK), repmat({'16-QAM'}, 1, numQAM)];
    else
        warning('load_rf_dataset:MissingSignals', 'qpskData_realistic or qamData_realistic not found.');
        dataStruct.signals = [];
        dataStruct.labels = [];
    end
    
    % Check for metadata
    if isfield(raw, 'samplesPerFrame')
        dataStruct.samplesPerFrame = raw.samplesPerFrame;
    else
        dataStruct.samplesPerFrame = NaN;
    end
    
    if isfield(raw, 'numFrames')
        dataStruct.numFrames = raw.numFrames;
    else
        dataStruct.numFrames = NaN;
    end
    
    % Fs is missing in rf_dataset_v1.mat
    if isfield(raw, 'Fs')
        dataStruct.Fs = raw.Fs;
    elseif isfield(raw, 'sampleRate')
        dataStruct.Fs = raw.sampleRate;
    else
        warning('load_rf_dataset:MissingFs', 'Sampling frequency (Fs) missing in dataset.');
        dataStruct.Fs = NaN;
    end
    
    % SNR is missing in rf_dataset_v1.mat
    if isfield(raw, 'snr')
        dataStruct.snr = raw.snr;
    elseif isfield(raw, 'target_snr_db')
        dataStruct.snr = raw.target_snr_db;
    else
        warning('load_rf_dataset:MissingSNR', 'Target SNR missing in dataset.');
        dataStruct.snr = NaN;
    end
end
