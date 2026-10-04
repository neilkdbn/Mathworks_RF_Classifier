classdef test_iq_feature_extraction < matlab.unittest.TestCase
    
    methods (Test)
        function testIQReconstruction(testCase)
            % 1. Create a dummy processedData struct
            numFrames = 10;
            len = 1024;
            processedData.signals = complex(randn(len, numFrames), randn(len, numFrames));
            processedData.labels = repmat({'QPSK'}, 1, numFrames);
            processedData.Fs = 1e6;
            processedData.snr = 10;
            
            % 2. Extract features
            iq_features = extract_iq_features(processedData);
            
            % 3. Check dimensions
            testCase.verifyEqual(size(iq_features.data), [len, 2, numFrames]);
            
            % 4. Verify Reconstruction
            for k = 1:numFrames
                orig = processedData.signals(:, k);
                recon = complex(iq_features.data(:, 1, k), iq_features.data(:, 2, k));
                testCase.verifyLessThan(max(abs(orig - recon)), 1e-12, 'Reconstruction failed for frame');
            end
        end
    end
end
