% EVALUATE_RF_2DCNN_STFT
% Evaluate trained 2D STFT CNN once on the untouched, matching 300 test frames.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'deep_learning'));
modelPath = fullfile(root, 'models', 'rf_2dcnn_stft_r2026b.mat');
featurePath = fullfile(root, 'data', 'processed', 'rf_features_v1.mat');
assert(isfile(modelPath), 'Train the STFT 2D CNN first.');
assert(isfile(featurePath), 'Saved STFT feature file is missing.');

s = load(modelPath, 'net', 'split', 'classNames', 'inputNorm');
d = prepare_rf_splits(s.split.seed);
assert(isequal(d.testIdx, s.split.testIdx) && ...
       isequal(d.trainIdx, s.split.trainIdx) && ...
       isequal(d.valIdx, s.split.valIdx), ...
       'Train/validation/test split mismatch.');
loaded = load(featurePath, 'features');
f = loaded.features;
assert(isequal(size(f.STFT.data), [64 61 2000]), 'STFT tensor changed.');
X = reshape(single(f.STFT.data), 64, 61, 1, []);
XTest = X(:, :, :, d.testIdx);
XTest = (XTest - single(s.inputNorm.mean)) ./ single(s.inputNorm.std);

scores = minibatchpredict(s.net, XTest, ...
    MiniBatchSize=32, ExecutionEnvironment="cpu");
YPred = scores2label(scores, s.classNames);
actual = string(d.YTest(:));
predicted = string(YPred(:));
assert(numel(actual) == numel(predicted), 'Prediction count mismatch.');
accuracy = mean(actual == predicted);

cls = string(s.classNames(:));
C = zeros(numel(cls));
for i = 1:numel(cls)
    for j = 1:numel(cls)
        C(i,j) = sum(actual == cls(i) & predicted == cls(j));
    end
end
TP = diag(C);
precision = TP ./ max(sum(C,1)', 1);
recall = TP ./ max(sum(C,2), 1);
F1 = 2 * precision .* recall ./ max(precision + recall, eps);
perClass = table(cls, precision, recall, F1, ...
    'VariableNames', {'Class','Precision','Recall','F1'});

outDir = fullfile(root, 'results');
if ~isfolder(outDir), mkdir(outDir); end
writetable(perClass, fullfile(outDir, 'stft_cnn_per_class_metrics.csv'));
frameIds = d.frameIds(d.testIdx);
predictions = table(frameIds(:), actual, predicted, ...
    'VariableNames', {'FrameId','Actual','Predicted'});
writetable(predictions, fullfile(outDir, 'stft_cnn_test_predictions.csv'));
save(fullfile(outDir, 'stft_cnn_test_evaluation.mat'), ...
    'accuracy', 'C', 'perClass', 'predictions', 'cls');
fig = figure;
cm = confusionchart(d.YTest, YPred);
cm.Title = sprintf('RF STFT 2D CNN | Held-out Test Accuracy: %.2f%%', 100*accuracy);
exportgraphics(fig, fullfile(outDir, 'stft_cnn_confusion_matrix.png'), Resolution=180);
disp(perClass);
fprintf('STFT 2D CNN held-out accuracy: %.2f%% (10 dB target SNR).\n', 100*accuracy);
