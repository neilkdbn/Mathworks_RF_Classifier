classdef test_signal_quality < matlab.unittest.TestCase
    
    methods (Test)
        function testAnalyzeQuality(testCase)
            data.signals = complex(randn(1024, 10), randn(1024, 10));
            
            q = analyze_signal_quality(data);
            
            testCase.verifyTrue(isfield(q, 'meanI'));
            testCase.verifyTrue(isfield(q, 'meanQ'));
            testCase.verifyTrue(isfield(q, 'rms'));
            testCase.verifyTrue(isfield(q, 'power'));
            testCase.verifyTrue(isfield(q, 'peak'));
            testCase.verifyTrue(isfield(q, 'nanCount'));
            testCase.verifyEqual(q.nanCount, 0);
        end
        
        function testNaNDetection(testCase)
            data.signals = complex(randn(10, 2), randn(10, 2));
            data.signals(1, 1) = NaN;
            
            q = analyze_signal_quality(data);
            testCase.verifyEqual(q.nanCount, 1);
        end
    end
end
