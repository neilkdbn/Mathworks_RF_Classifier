% inspect_models_and_data.m
% Inspects saved model binaries, dataset structures, split metadata, and seeds.

root = fileparts(mfilename('fullpath'));
if isempty(root), root = pwd; end

fprintf('=== 1. Inspecting 1D Model File ===\n');
m1_info = whos('-file', fullfile(root, 'models', 'rf_1dcnn_r2026b.mat'));
disp(struct2table(m1_info));
m1 = load(fullfile(root, 'models', 'rf_1dcnn_r2026b.mat'));
disp('Fields in m1:');
disp(fieldnames(m1));
disp('Class names:');
disp(m1.classNames);
disp('Split struct in m1:');
disp(m1.split);

fprintf('\n=== 2. Inspecting 2D Model File ===\n');
m2_info = whos('-file', fullfile(root, 'models', 'rf_2dcnn_constellation_r2026b.mat'));
disp(struct2table(m2_info));
m2 = load(fullfile(root, 'models', 'rf_2dcnn_constellation_r2026b.mat'));
disp('Fields in m2:');
disp(fieldnames(m2));
disp('Class names:');
disp(m2.classNames);
disp('Split struct in m2:');
disp(m2.split);
disp('Representation config in m2:');
disp(m2.representationConfig);

fprintf('\n=== 3. Inspecting rf_dataset_v1.mat ===\n');
if isfile(fullfile(root, 'rf_dataset_v1.mat'))
    raw_info = whos('-file', fullfile(root, 'rf_dataset_v1.mat'));
    disp(struct2table(raw_info));
    raw = load(fullfile(root, 'rf_dataset_v1.mat'));
    disp('Fields in raw:');
    disp(fieldnames(raw));
    if isfield(raw, 'data')
        disp('Fields in raw.data:');
        disp(fieldnames(raw.data));
        disp('Size of raw.data.signals:');
        disp(size(raw.data.signals));
        disp('Labels:');
        disp(unique(raw.data.labels));
        disp('Counts:');
        disp(table(unique(raw.data.labels(:)), 'VariableNames', {'Label'}));
        if isfield(raw.data, 'snr') || isfield(raw.data, 'snrDb') || isfield(raw.data, 'SNR')
            fprintf('SNR field found in raw.data!\n');
        else
            fprintf('No explicit SNR field in raw.data.\n');
        end
    end
else
    fprintf('rf_dataset_v1.mat NOT FOUND\n');
end

fprintf('\n=== 4. Inspecting data/processed/rf_features_v1.mat ===\n');
feat_path = fullfile(root, 'data', 'processed', 'rf_features_v1.mat');
if isfile(feat_path)
    feat_info = whos('-file', feat_path);
    disp(struct2table(feat_info));
    f = load(feat_path);
    disp('Fields in features file:');
    disp(fieldnames(f));
    disp('Fields in f.features:');
    disp(fieldnames(f.features));
    disp('Size of IQ.data:');
    disp(size(f.features.IQ.data));
    disp('Unique labels in features:');
    disp(unique(f.features.labels));
    if isfield(f.features, 'provenance') || isfield(f.features, 'metadata')
        disp('Provenance / metadata:');
        if isfield(f.features, 'provenance'), disp(f.features.provenance); end
        if isfield(f.features, 'metadata'), disp(f.features.metadata); end
    else
        disp('No provenance/metadata field in f.features');
    end
else
    fprintf('rf_features_v1.mat NOT FOUND\n');
end

fprintf('\n=== 5. Comparing Splits and Seeds ===\n');
addpath(fullfile(root, 'deep_learning'));
d = prepare_rf_splits(m1.split.seed);
fprintf('m1 seed: %d, m2 seed: %d, d seed: %d\n', m1.split.seed, m2.split.seed, d.seed);
fprintf('m1 trainIdx == m2 trainIdx: %d\n', isequal(m1.split.trainIdx, m2.split.trainIdx));
fprintf('m1 valIdx == m2 valIdx: %d\n', isequal(m1.split.valIdx, m2.split.valIdx));
fprintf('m1 testIdx == m2 testIdx: %d\n', isequal(m1.split.testIdx, m2.split.testIdx));
fprintf('d trainIdx == m1 trainIdx: %d\n', isequal(d.trainIdx, m1.split.trainIdx));
fprintf('d valIdx == m1 valIdx: %d\n', isequal(d.valIdx, m1.split.valIdx));
fprintf('d testIdx == m1 testIdx: %d\n', isequal(d.testIdx, m1.split.testIdx));
if isfield(m1.split, 'frameIds')
    fprintf('m1 has frameIds: isequal with d.frameIds? %d\n', isequal(m1.split.frameIds, d.frameIds));
else
    fprintf('m1.split does NOT have frameIds field.\n');
end
if isfield(m2.split, 'frameIds')
    fprintf('m2 has frameIds: isequal with d.frameIds? %d\n', isequal(m2.split.frameIds, d.frameIds));
else
    fprintf('m2.split does NOT have frameIds field.\n');
end
