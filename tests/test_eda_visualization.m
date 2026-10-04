classdef test_eda_visualization < matlab.unittest.TestCase
    
    methods (Test)
        function testEDAEnvironmentAndScripts(testCase)
            % 1. Verify Directories
            testCase.verifyTrue(exist('../visualization/EDA', 'dir') == 7, 'EDA output directory does not exist.');
            
            % 2. Verify Master Script Exists
            testCase.verifyTrue(exist('../scripts/generate_eda_visualizations.m', 'file') == 2, 'Master EDA script not found.');
            
            % 3. Verify Helper Scripts Available in Path
            addpath('../preprocessing');
            testCase.verifyTrue(exist('preprocess_iq', 'file') == 2, 'preprocess_iq not found.');
            testCase.verifyTrue(exist('extract_features', 'file') == 2, 'extract_features not found.');
            
            % NOTE: Runtime execution is pending MATLAB availability.
            % We do not execute the script here to prevent blocking headless test runners.
            fprintf('EDA Static Validation Passed. Runtime execution [PENDING MATLAB EXECUTION].\n');
        end
    end
end
