function tests = testPipelineSmoke
%TESTPIPELINESMOKE Anjali: smoke test for pipeline integration.
%   Run: runtests('tests'). All toolboxes stub-safe at tiny scale.
tests = functiontests(localfunctions);
end

function testEndToEndTiny(testCase)
ds = generateRFSignalDataset('Modulations', ["BPSK","QPSK"], ...
    'SNRdB', [0 10], 'FramesPerCombo', 4, 'FrameLength', 256, 'Seed', 1);
verifyEqual(testCase, height(ds), 2*2*4);
feats = extractRFfeatures(ds, 'Mode', 'IQ');
verifyEqual(testCase, height(feats), height(ds));
[net, info] = trainRFClassifier(feats, 'MaxEpochs', 1, 'MiniBatchSize', 8, 'Seed', 1);
verifyTrue(testCase, isa(net, 'SeriesNetwork') || isa(net, 'DAGNetwork') || isa(net, 'dlnetwork'));
res = evaluateRobustness(net, feats, info.TestIdx, 'Plot', false);
verifyTrue(testCase, res.OverallAccuracy >= 0 && res.OverallAccuracy <= 1);
end

function testSTFTPath(testCase)
ds = generateRFSignalDataset('Modulations', "BPSK", ...
    'SNRdB', 10, 'FramesPerCombo', 2, 'FrameLength', 256, 'Seed', 2);
feats = extractRFfeatures(ds, 'Mode', 'STFT', 'STFTWindow', 64, 'STFTOverlap', 48);
verifyEqual(testCase, height(feats), 2);
verifyTrue(testCase, ndims(feats.features{1}) == 2);
end
