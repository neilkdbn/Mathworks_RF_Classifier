classdef test_dc_offset_removal < matlab.unittest.TestCase
    
    methods (Test)
        function testRemoveDC(testCase)
            % Create complex signal with known DC offset
            numFrames = 10;
            len = 1024;
            
            offsetI = 5.0;
            offsetQ = -2.5;
            
            % Zero-mean noise + DC offset
            sI = randn(len, numFrames) + offsetI;
            sQ = randn(len, numFrames) + offsetQ;
            
            signals = complex(sI, sQ);
            
            processed = remove_dc_offset(signals);
            
            % Check that output has same dimensions
            testCase.verifyEqual(size(processed), size(signals));
            
            % Check that mean is approximately zero
            means = mean(processed, 1);
            
            testCase.verifyLessThan(abs(real(means)), 1e-10, 'I component mean not zero');
            testCase.verifyLessThan(abs(imag(means)), 1e-10, 'Q component mean not zero');
        end
    end
end
