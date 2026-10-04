classdef test_feature_alignment < matlab.unittest.TestCase
    
    methods (Test)
        function testAlignment(testCase)
            numFrames = 20;
            processedData.signals = complex(randn(1024, numFrames), randn(1024, numFrames));
            processedData.labels = cell(1, numFrames);
            for i = 1:numFrames
                processedData.labels{i} = sprintf('Label_%d', i);
            end
            processedData.Fs = 1e6;
            processedData.snr = 10;
            
            options.iq.enabled = true;
            options.stft.enabled = false;
            
            features = extract_features(processedData, options);
            
            % Ensure frame IDs match
            testCase.verifyEqual(length(features.frameIds), numFrames);
            
            for i = 1:numFrames
                testCase.verifyEqual(features.labels{i}, processedData.labels{i});
            end
            
            testCase.verifyEqual(size(features.IQ.data, 3), numFrames);
        end
    end
end
