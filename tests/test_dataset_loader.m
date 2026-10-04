classdef test_dataset_loader < matlab.unittest.TestCase
    % test_dataset_loader Tests for load_rf_dataset.m
    
    properties
        ValidDatasetPath = '../rf_dataset_v1.mat';
    end
    
    methods (Test)
        
        function testLoadValidDataset(testCase)
            % Test if a valid dataset can be loaded without error
            import matlab.unittest.constraints.IsFile;
            
            testCase.assumeThat(testCase.ValidDatasetPath, IsFile, 'rf_dataset_v1.mat must exist for this test.');
            
            dataStruct = load_rf_dataset(testCase.ValidDatasetPath);
            
            % Verify expected fields exist
            testCase.verifyTrue(isfield(dataStruct, 'signals'), 'signals field is missing');
            testCase.verifyTrue(isfield(dataStruct, 'labels'), 'labels field is missing');
            testCase.verifyTrue(isfield(dataStruct, 'Fs'), 'Fs field is missing');
            testCase.verifyTrue(isfield(dataStruct, 'snr'), 'snr field is missing');
            
            % Verify dimensions
            % 1000 frames QPSK + 1000 frames 16-QAM = 2000 frames total
            testCase.verifyEqual(size(dataStruct.signals, 2), 2000, 'Total frames should be 2000');
            testCase.verifyEqual(size(dataStruct.signals, 1), 1024, 'Samples per frame should be 1024');
            testCase.verifyEqual(length(dataStruct.labels), 2000, 'There should be 2000 labels');
        end
        
        function testInvalidPath(testCase)
            % Test if an invalid path throws expected error
            invalidPath = 'non_existent_file.mat';
            testCase.verifyError(@() load_rf_dataset(invalidPath), 'load_rf_dataset:FileNotFound');
        end
        
    end
end
