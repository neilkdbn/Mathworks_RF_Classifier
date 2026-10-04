function results = evaluateRobustness(trueLabels, predictedLabels, snrValues, varargin)
%EVALUATEROBUSTNESS Draft SNR robustness evaluation blueprint (Anjali).
%   RESULTS = EVALUATEROBUSTNESS(TRUELABELS, PREDICTEDLABELS, SNRVALUES)
%   scores modulation classification robustness over channel SNR.
%
%   Inputs (vectors, all with equal length N = number of test frames):
%     trueLabels      - ground-truth modulation per frame (categorical,
%                       string, cellstr, or numeric vector).
%     predictedLabels - network predictions per frame (same type/domain as
%                       trueLabels).
%     snrValues       - SNR in dB per frame (numeric vector).
%
%   Name-Value:
%     'Plot' - logical, default true. Draws the overall confusion matrix
%              with confusionchart plus one confusion matrix per SNR level.
%
%   Results (struct):
%     .OverallAccuracy - scalar double, mean(predicted == true).
%     .AccuracyVsSNR  - table (snrDb, accuracy, numFrames).
%     .Confusion      - overall confusion matrix (confusionmat).
%     .ConfusionBySNR - containers.Map (snr dB -> confusion matrix).
%     .YTrue, .YPred  - categorical column vectors as scored.
%
%   % ------------------------------------------------------------------
%   % INTEGRATION BLUEPRINT — where teammate outputs pipe in (tomorrow):
%   % ------------------------------------------------------------------
%   % NEIL (RF Systems Modeler) -> trueLabels + snrValues
%   %   From GENERATERFSIGNALDATASET test split, e.g.:
%   %     ds = generateRFSignalDataset(...);      % Neil's dataset
%   %     trueLabels = ds.modulation(testIdx);    % ground truth
%   %     snrValues  = ds.snrDb(testIdx);         % per-frame SNR (dB)
%   %
%   % ARYA (Signal Processing Lead) -> features behind predictedLabels
%   %   Predictions assume her framing, e.g.:
%   %     feats = extractRFfeatures(ds, 'Mode', 'IQ');  % or 'STFT'
%   %   Keep row order identical to ds so testIdx aligns trueLabels,
%   %   predictedLabels, and snrValues element-wise.
%   %
%   % SHREEYA (Deep Learning Architect) -> predictedLabels
%   %   From the trained classifier, e.g.:
%   %     predictedLabels = classify(net, XTest); % XTest built from feats
%   %
%   % TOMORROW'S WIRING (example end-to-end):
%   %   ds    = generateRFSignalDataset(...);          % Neil
%   %   feats = extractRFfeatures(ds, 'Mode', 'IQ');   % Arya
%   %   [net, info] = trainRFClassifier(feats, ...);   % Shreeya (70/15/15)
%   %   XTest = <stack feats.features(info.TestIdx)>;  % Arya + Shreeya
%   %   results = evaluateRobustness(feats.modulation(info.TestIdx), ...
%   %       classify(net, XTest), feats.snrDb(info.TestIdx));  % Anjali
%   % ------------------------------------------------------------------
%
%   100% MATLAB. No Python.
%
%   See also: confusionchart, confusionmat.

p = inputParser;
p.addRequired('trueLabels');
p.addRequired('predictedLabels');
p.addRequired('snrValues', @isnumeric);
p.addParameter('Plot', true, @islogical);
p.parse(trueLabels, predictedLabels, snrValues, varargin{:});
doPlot = p.Results.Plot;

% Normalize labels to categorical column vectors for stable comparison
% and chart ordering, while validating equal lengths.
YTrue = categorical(trueLabels(:));
YPred = categorical(predictedLabels(:));
snrValues = snrValues(:);
assert(numel(YTrue) == numel(YPred) && numel(YTrue) == numel(snrValues), ...
    'evaluateRobustness:SizeMismatch', ...
    'trueLabels, predictedLabels, and snrValues must have equal length.');
assert(~isempty(YTrue), 'evaluateRobustness:EmptyInput', 'Inputs must be non-empty.');

% Overall classification accuracy.
overallAccuracy = mean(YPred == YTrue);

% Per-SNR accuracy loop.
snrLevels = unique(snrValues);
nLevels = numel(snrLevels);
accPerSNR = zeros(nLevels, 1);
framesPerSNR = zeros(nLevels, 1);
confBySNR = containers.Map('KeyType', 'double', 'ValueType', 'any');
for s = 1:nLevels
    m = snrValues == snrLevels(s);
    framesPerSNR(s) = nnz(m);
    accPerSNR(s) = mean(YPred(m) == YTrue(m));
    confBySNR(snrLevels(s)) = confusionmat(YTrue(m), YPred(m));
end

% Confusion matrices via MATLAB's confusionchart.
C = confusionmat(YTrue, YPred);
if doPlot
    figure('Name', 'RF robustness — overall');
    confusionchart(YTrue, YPred);
    title(sprintf('Overall confusion (acc = %.3f)', overallAccuracy));
    for s = 1:nLevels
        m = snrValues == snrLevels(s);
        figure('Name', sprintf('Confusion @ SNR = %g dB', snrLevels(s)));
        confusionchart(YTrue(m), YPred(m));
        title(sprintf('SNR = %g dB (acc = %.3f, n = %d)', ...
            snrLevels(s), accPerSNR(s), framesPerSNR(s)));
    end
end

results = struct( ...
    'OverallAccuracy', overallAccuracy, ...
    'AccuracyVsSNR', table(snrLevels, accPerSNR, framesPerSNR, ...
        'VariableNames', {'snrDb', 'accuracy', 'numFrames'}), ...
    'Confusion', C, ...
    'ConfusionBySNR', confBySNR, ...
    'YTrue', YTrue, ...
    'YPred', YPred);

fprintf('Overall classification accuracy: %.4f\n', overallAccuracy);
disp(results.AccuracyVsSNR);
end
