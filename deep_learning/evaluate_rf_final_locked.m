% EVALUATE_RF_FINAL_LOCKED
% Final, one-time held-out TEST comparison for the already-frozen models.
% MATLAB R2026b. Does NOT train or overwrite either saved model.
% Run from the project: run(fullfile(root,'deep_learning','evaluate_rf_final_locked.m'))

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'deep_learning'));

m1 = load(fullfile(root,'models','rf_1dcnn_r2026b.mat'), ...
    'net','split','classNames');
m2 = load(fullfile(root,'models','rf_2dcnn_constellation_r2026b.mat'), ...
    'net','split','classNames','representationConfig');

d = prepare_rf_splits(m1.split.seed);

% Ensure every index is identical for both saved models.
assert(isequal(d.trainIdx(:),m1.split.trainIdx(:)) && ...
       isequal(d.valIdx(:),m1.split.valIdx(:)) && ...
       isequal(d.testIdx(:),m1.split.testIdx(:)), ...
       'The 1D model split does not match the dataset.');
assert(isequal(d.trainIdx(:),m2.split.trainIdx(:)) && ...
       isequal(d.valIdx(:),m2.split.valIdx(:)) && ...
       isequal(d.testIdx(:),m2.split.testIdx(:)), ...
       'The 2D model split does not match the dataset.');

names1 = string(m1.classNames(:));
names2 = string(m2.classNames(:));
[matched,order2] = ismember(names1,names2);
assert(all(matched) && numel(names1)==numel(names2) && ...
       numel(unique(order2))==numel(order2), ...
       'The two saved models use incompatible class names.');

% Apply frozen training-derived constellation histogram edges to TEST frames.
assert(isfield(m2.representationConfig,'binEdges'), ...
    'Saved 2D model is missing its training-derived bin edges.');
edges = m2.representationConfig.binEdges;
nBins = numel(edges)-1;
nTest = numel(d.XTest);
XTest2D = zeros(nBins,nBins,1,nTest,'single');
for k = 1:nTest
    XTest2D(:,:,1,k) = make_constellation_density(d.XTest{k},edges);
end

% Inference only: NO training, selection, or weight changes.
scores1 = minibatchpredict(m1.net,d.XTest, ...
    MiniBatchSize=32,ExecutionEnvironment='cpu');
scores2 = minibatchpredict(m2.net,XTest2D, ...
    MiniBatchSize=32,ExecutionEnvironment='cpu');

assert(size(scores1,1)==nTest && size(scores2,1)==nTest, ...
    'Unexpected score array dimensions.');
assert(size(scores1,2)==numel(names1) && size(scores2,2)==numel(names2), ...
    'Unexpected number of prediction score columns.');

pred1 = string(scores2label(scores1,m1.classNames));
pred2 = string(scores2label(scores2,m2.classNames));
ensembleScores = (double(scores1)+double(scores2(:,order2)))/2;
predEns = string(scores2label(ensembleScores,m1.classNames));

actual = string(d.YTest(:));
predictions = {pred1(:),pred2(:),predEns(:)};
modelNames = {'1D CNN (I/Q)','2D CNN (Constellation)','Equal-weight ensemble'};
classes = ["16-QAM";"QPSK"];
accuracy = zeros(3,1);
macroF1 = zeros(3,1);
confusionMatrices = zeros(2,2,3);

fprintf('\nFINAL HELD-OUT TEST RESULTS (fixed 50:50 ensemble)\n');
for k = 1:3
    predicted = predictions{k};
    accuracy(k) = 100*mean(predicted==actual);
    C = zeros(2,2);
    for i = 1:2
        for j = 1:2
            C(i,j) = sum(actual==classes(i) & predicted==classes(j));
        end
    end
    confusionMatrices(:,:,k) = C;
    p = diag(C)./max(sum(C,1)',1);
    r = diag(C)./max(sum(C,2),1);
    f1 = 2*p.*r./max(p+r,eps);
    macroF1(k) = mean(f1);
    fprintf('\n%s: %.2f%% (%d/%d), macro F1 %.4f\n', ...
        modelNames{k}, accuracy(k),sum(predicted==actual),nTest,macroF1(k));
    fprintf('Confusion matrix (rows=true, cols=pred; [16-QAM,QPSK]):\n');
    disp(C);
end

resultsDir = fullfile(root,'results');
if ~isfolder(resultsDir), mkdir(resultsDir); end
comparison = table(string(modelNames(:)),accuracy,macroF1, ...
    'VariableNames',{'Model','TestAccuracyPercent','MacroF1'});
writetable(comparison,fullfile(resultsDir,'final_locked_test_comparison.csv'));
save(fullfile(resultsDir,'final_locked_test_comparison.mat'), ...
    'comparison','confusionMatrices','actual','pred1','pred2','predEns', ...
    'scores1','scores2','ensembleScores','classes');
fprintf('\nFinal results saved to results/final_locked_test_comparison.csv and .mat\n');
fprintf('No model was retrained or overwritten.\n');
