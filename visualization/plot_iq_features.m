function plot_iq_features(features, frame_idx)
% plot_iq_features Visualizes the extracted I/Q representation.
%
% INPUTS:
%   features  - The features struct from extract_features
%   frame_idx - Index of the frame to plot

    if ~isfield(features, 'IQ')
        error('IQ features not present.');
    end
    
    iqData = features.IQ.data(:, :, frame_idx);
    label = features.labels{frame_idx};
    Fs = features.Fs;
    
    numSamples = size(iqData, 1);
    
    if ~isnan(Fs)
        t = (0:numSamples-1) / Fs * 1e6; % microseconds
        xLabelStr = 'Time (\mu s)';
    else
        t = 1:numSamples;
        xLabelStr = 'Sample Index';
    end
    
    figure('Name', sprintf('I/Q Feature: %s (Frame %d)', label, frame_idx));
    plot(t, iqData(:, 1), 'b', 'DisplayName', 'I Component');
    hold on;
    plot(t, iqData(:, 2), 'r', 'DisplayName', 'Q Component');
    grid on;
    title(sprintf('I/Q Representation - %s (Frame %d)', label, frame_idx));
    xlabel(xLabelStr);
    ylabel('Amplitude');
    legend('Location', 'best');
end
