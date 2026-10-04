classdef test_ai_handoff < matlab.unittest.TestCase
    
    methods (Test)
        function testMetadataRecovery(testCase)
            % Test that the loader correctly falls back to authoritative config
            % when Fs and SNR are not provided.
            
            % Create dummy mat file without Fs or SNR
            dummyData.qpskData_realistic = randn(1024, 5) + 1i*randn(1024, 5);
            dummyData.qamData_realistic = randn(1024, 5) + 1i*randn(1024, 5);
            dummyData.numFrames = 10;
            dummyData.samplesPerFrame = 1024;
            
            testFile = 'temp_dummy_dataset.mat';
            save(testFile, '-struct', 'dummyData');
            
            data = load_rf_dataset(testFile);
            
            % Cleanup
            delete(testFile);
            
            % Assert recovery
            testCase.verifyEqual(data.Fs, 1e6);
            testCase.verifyEqual(data.snr, 10);
            testCase.verifyEqual(data.metadata.FsSource, 'generate_signals.m');
            testCase.verifyEqual(data.metadata.targetSNR_dBSource, 'generate_signals.m');
        end
        
        function testInvalidSampleRateFailure(testCase)
            % Create dummy processed data with missing/invalid Fs
            processedData.signals = randn(1024, 2) + 1i*randn(1024, 2);
            processedData.labels = {'QPSK', '16-QAM'};
            processedData.Fs = NaN; % Invalid
            processedData.snr = 10;
            
            options.iq.enabled = false;
            options.stft.enabled = true;
            
            % Assert error is thrown instead of using Fs = 1.0
            testCase.verifyError(@() extract_features(processedData, options), 'extract_stft_features:InvalidFs');
        end
        
        function testHandoffValidation(testCase)
            % Verify that validate_ai_handoff catches dimension errors
            features.frameIds = 1:2000;
            features.labels = repmat({'QPSK'}, 1, 2000); % Only QPSK (should fail)
            features.Fs = 1e6;
            features.snr = 10;
            features.IQ.data = randn(1024, 2, 2000);
            features.STFT.data = randn(64, 61, 2000);
            
            testCase.verifyError(@() validate_ai_handoff(features), 'validate_ai_handoff:Failed');
        end
    end
end
