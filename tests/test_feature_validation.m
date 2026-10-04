classdef test_feature_validation < matlab.unittest.TestCase
    
    methods (Test)
        function testValidFeatures(testCase)
            features.frameIds = 1:5;
            features.labels = {'A', 'B', 'C', 'D', 'E'};
            
            features.IQ.data = randn(1024, 2, 5);
            
            testCase.verifyTrue(validate_features(features));
        end
        
        function testInvalidAlignment(testCase)
            features.frameIds = 1:5;
            features.labels = {'A', 'B', 'C'}; % Mismatch
            testCase.verifyError(@() validate_features(features), 'validate_features:AlignmentError');
        end
        
        function testNaNInIQ(testCase)
            features.frameIds = 1:2;
            features.labels = {'A', 'B'};
            features.IQ.data = randn(1024, 2, 2);
            features.IQ.data(1, 1, 1) = NaN;
            
            testCase.verifyError(@() validate_features(features), 'validate_features:IQNaNInf');
        end
    end
end
