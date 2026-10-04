classdef test_normalize_amplitude < matlab.unittest.TestCase
    
    methods (Test)
        function testRMSNormalization(testCase)
            signals = complex(randn(1024, 5), randn(1024, 5));
            % Increase amplitude of one frame artificially
            signals(:, 1) = signals(:, 1) * 10;
            
            normalized = normalize_amplitude(signals, 'rms');
            
            % Check dimensions
            testCase.verifyEqual(size(normalized), size(signals));
            
            % Verify RMS is 1
            rms_vals = rms(abs(normalized), 1);
            testCase.verifyLessThan(abs(rms_vals - 1), 1e-10);
        end
        
        function testZeroHandling(testCase)
            signals = zeros(1024, 2);
            normalized = normalize_amplitude(signals, 'rms');
            
            % Should remain zeros, no NaN
            testCase.verifyEqual(sum(isnan(normalized(:))), 0);
            testCase.verifyEqual(sum(abs(normalized(:))), 0);
        end
    end
end
