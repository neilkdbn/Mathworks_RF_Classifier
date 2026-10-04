classdef test_feature_pipeline < matlab.unittest.TestCase
    
    methods (Test)
        function testPipelineEndToEnd(testCase)
            processedData.signals = complex(randn(1024, 10), randn(1024, 10));
            processedData.labels = repmat({'QPSK'}, 1, 10);
            processedData.Fs = 1e6;
            processedData.snr = 10;
            processedData.processingInfo.phase = 2;
            
            options.iq.enabled = true;
            options.stft.enabled = false;
            
            features = extract_features(processedData, options);
            
            testCase.verifyTrue(isfield(features, 'IQ'));
            testCase.verifyFalse(isfield(features, 'STFT'));
            testCase.verifyEqual(features.metadata.phase, 3);
        end
    end
end
