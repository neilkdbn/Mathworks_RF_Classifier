classdef test_preprocess_iq < matlab.unittest.TestCase
    
    methods (Test)
        function testPipelineDefault(testCase)
            data.signals = complex(randn(1024, 10), randn(1024, 10));
            data.labels = repmat({'QPSK'}, 1, 10);
            data.Fs = 1e6;
            data.snr = 10;
            
            processed = preprocess_iq(data);
            
            % Dimensions preserved
            testCase.verifyEqual(size(processed.signals), size(data.signals));
            testCase.verifyEqual(processed.labels, data.labels);
            testCase.verifyEqual(processed.Fs, data.Fs);
            
            % Check processing info exists
            testCase.verifyTrue(isfield(processed, 'processingInfo'));
            testCase.verifyEqual(processed.processingInfo.phase, 2);
            testCase.verifyEqual(processed.processingInfo.removeDC, true);
            testCase.verifyEqual(processed.processingInfo.normalize, true);
            testCase.verifyEqual(processed.processingInfo.filterEnabled, false);
            
            % Ensure no NaNs
            testCase.verifyEqual(sum(isnan(processed.signals(:))), 0);
        end
    end
end
