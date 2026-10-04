% inspect_dataset.m
% Script to inspect the RF dataset contents and print a summary.
% Owner: Arya - Signal Processing Lead

datasetFile = '../rf_dataset_v1.mat';

fprintf('============================================================\n');
fprintf('DATASET INSPECTION SCRIPT\n');
fprintf('============================================================\n');

if ~isfile(datasetFile)
    error('Dataset file %s not found!', datasetFile);
end

% 1. Display available variables
fprintf('Loading dataset: %s\n', datasetFile);
whos_out = whos('-file', datasetFile);
fprintf('\nVariables in file:\n');
for i = 1:length(whos_out)
    isComplexStr = 'Real';
    if whos_out(i).complex
        isComplexStr = 'Complex';
    end
    fprintf(' - %s: %s [%s] (%s)\n', whos_out(i).name, num2str(whos_out(i).size), whos_out(i).class, isComplexStr);
end

% 2. Load dataset
data = load(datasetFile);

% 3. Identify Candidate Variables
candidate_signals = {};
candidate_labels = {};
candidate_snr = {};
candidate_fs = {};

fields = fieldnames(data);
for i = 1:length(fields)
    var = data.(fields{i});
    if isnumeric(var) && ~isscalar(var)
        candidate_signals{end+1} = fields{i};
    elseif isscalar(var)
        % Ignore explicitly known scalars
        if contains(lower(fields{i}), 'fs') || contains(lower(fields{i}), 'rate')
            candidate_fs{end+1} = fields{i};
        elseif contains(lower(fields{i}), 'snr')
            candidate_snr{end+1} = fields{i};
        end
    end
end

fprintf('\n--- Candidate Variables ---\n');
fprintf('Signals: %s\n', strjoin(candidate_signals, ', '));
fprintf('Labels: %s\n', strjoin(candidate_labels, ', '));
if isempty(candidate_labels)
    fprintf('Labels: MISSING\n');
end
if isempty(candidate_snr)
    fprintf('SNR: MISSING\n');
end
if isempty(candidate_fs)
    fprintf('Fs: MISSING\n');
end

% 4. Inspect specific signals
fprintf('\n--- Signal Properties ---\n');
for i = 1:length(candidate_signals)
    sigName = candidate_signals{i};
    sigData = data.(sigName);
    
    fprintf('Signal: %s\n', sigName);
    fprintf(' - Size: %d x %d\n', size(sigData, 1), size(sigData, 2));
    fprintf(' - Datatype: %s\n', class(sigData));
    
    if ~isreal(sigData)
        fprintf(' - Complex: Yes\n');
    else
        fprintf(' - Complex: No\n');
    end
    
    numNaN = sum(isnan(sigData(:)));
    numInf = sum(isinf(sigData(:)));
    fprintf(' - NaN values: %d\n', numNaN);
    fprintf(' - Inf values: %d\n', numInf);
    fprintf('\n');
end

fprintf('============================================================\n');
fprintf('Inspection Complete.\n');
fprintf('============================================================\n');
