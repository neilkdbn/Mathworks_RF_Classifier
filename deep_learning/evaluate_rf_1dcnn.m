% EVALUATE_RF_1DCNN  Held-out test-set evaluation, run after training.
% The untouched 15%% test set is used only here.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'deep_learning'));
modelPath = fullfile(root, 'models', 'rf_1dcnn_r2026b.mat');
assert(isfile(modelPath), 'Saved model missing. Run train_rf_1dcnn.m first.');
s = load(modelPath, 'net', 'split', 'classNames');
d = prepare_rf_splits(s.split.seed);
assert(isequal(d.trainIdx, s.split.trainIdx) && ...
       isequal(d.valIdx, s.split.valIdx) && ...
       isequal(d.testIdx, s.split.testIdx), 'Data split changed!');

scores = minibatchpredict(s.net, d.XTest, MiniBatchSize=32, ExecutionEnvironment="cpu");
YPred = scores2label(scores, s.classNames);
trueText = string(d.YTest(:));
predText = string(YPred(:));
assert(numel(trueText) == numel(predText), 'Prediction count mismatch.');
accuracy = mean(trueText == predText);

cls = string(s.classNames(:));
C = zeros(numel(cls));
for i = 1:numel(cls)
    for j = 1:numel(cls)
        C(i,j) = sum(trueText == cls(i) & predText == cls(j));
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
writetable(perClass, fullfile(outDir, 'cnn_per_class_metrics.csv'));
frameIds = d.frameIds(d.testIdx);
predictions = table(frameIds(:), trueText, predText, ...
    'VariableNames', {'FrameId','Actual','Predicted'});
writetable(predictions, fullfile(outDir, 'cnn_test_predictions.csv'));
save(fullfile(outDir, 'cnn_test_evaluation.mat'), ...
    'accuracy','C','perClass','predictions','cls');

fig = figure;
cm = confusionchart(d.YTest, YPred);
cm.Title = sprintf('RF 1D CNN | Held-out Test Accuracy: %.2f%%', accuracy*100);
exportgraphics(fig, fullfile(outDir, 'cnn_confusion_matrix.png'), Resolution=180);
disp(perClass);
fprintf('Held-out accuracy: %.2f%% at target 10 dB SNR.\n', 100*accuracy);
fprintf('Note: single-SNR test; no SNR robustness claim yet.\n');
