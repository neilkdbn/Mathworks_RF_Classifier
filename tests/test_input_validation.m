classdef test_input_validation < matlab.unittest.TestCase
    % test_input_validation Tests for validate_input.m
    
    methods (Test)
        
        function testValidInput(testCase)
            % Test validate_input with a valid struct
            data.signals = complex(randn(1024, 10), randn(1024, 10));
            data.labels = repmat({'QPSK'}, 1, 10);
            data.Fs = 1e6;
            data.snr = 10;
            
            testCase.verifyTrue(validate_input(data), 'Valid input should pass validation');
        end
        
        function testMissingSignals(testCase)
            % Test validate_input without signals
            data.labels = repmat({'QPSK'}, 1, 10);
            
            testCase.verifyError(@() validate_input(data), 'validate_input:MissingSignals');
        end
        
        function testMissingLabels(testCase)
            % Test validate_input without labels
            data.signals = complex(randn(1024, 10), randn(1024, 10));
            
            testCase.verifyError(@() validate_input(data), 'validate_input:MissingLabels');
        end
        
        function testDimensionMismatch(testCase)
            % Test mismatch between signals and labels
            data.signals = complex(randn(1024, 10), randn(1024, 10));
            data.labels = repmat({'QPSK'}, 1, 5); % Only 5 labels
            
            testCase.verifyError(@() validate_input(data), 'validate_input:DimensionMismatch');
        end
        
        function testNotComplex(testCase)
            % Test signals that are strictly real
            data.signals = randn(1024, 10);
            data.labels = repmat({'QPSK'}, 1, 10);
            
            testCase.verifyError(@() validate_input(data), 'validate_input:NotComplex');
        end
        
        function testNaNValues(testCase)
            % Test NaN detection
            data.signals = complex(randn(1024, 10), randn(1024, 10));
            data.signals(1, 1) = NaN;
            data.labels = repmat({'QPSK'}, 1, 10);
            
            testCase.verifyError(@() validate_input(data), 'validate_input:NaNValues');
        end
        
    end
end
