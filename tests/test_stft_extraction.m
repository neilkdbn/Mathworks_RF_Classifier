classdef test_stft_extraction < matlab.unittest.TestCase
    
    methods (Test)
        function testSTFTDimensions(testCase)
            % Need Signal Processing Toolbox for stft
            if ~license('test', 'Signal_Toolbox')
                return; % Skip test
            end
            
            numFrames = 5;
            len = 1024;
            processedData.signals = complex(randn(len, numFrames), randn(len, numFrames));
            processedData.labels = repmat({'QPSK'}, 1, numFrames);
            processedData.Fs = 1e6;
            processedData.snr = 10;
            
            config.windowLength = 64;
            config.overlapLength = 48;
            config.fftLength = 64;
            config.featureType = 'logPower';
            
            stft_features = extract_stft_features(processedData, config);
            
            % Check that output is 3D real matrix
            testCase.verifyTrue(isreal(stft_features.data));
            testCase.verifyEqual(size(stft_features.data, 3), numFrames);
            
            % Check axes
            testCase.verifyTrue(isfield(stft_features, 'frequencyAxis'));
            testCase.verifyTrue(isfield(stft_features, 'timeAxis'));
            
            % Verify dimensions match axes length
            testCase.verifyEqual(size(stft_features.data, 1), length(stft_features.frequencyAxis));
            testCase.verifyEqual(size(stft_features.data, 2), length(stft_features.timeAxis));
        end
    end
end
