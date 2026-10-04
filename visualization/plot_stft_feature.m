function plot_stft_feature(features, frame_idx)
% plot_stft_feature Visualizes the extracted STFT representation.
%
% INPUTS:
%   features  - The features struct from extract_features
%   frame_idx - Index of the frame to plot

    if ~isfield(features, 'STFT')
        error('STFT features not present.');
    end
    
    stftData = features.STFT.data(:, :, frame_idx);
    label = features.labels{frame_idx};
    f = features.STFT.frequencyAxis;
    t = features.STFT.timeAxis;
    
    % Convert Hz to MHz for plotting if Fs >= 1e6
    if max(abs(f)) >= 1e5
        f = f / 1e6;
        fLabelStr = 'Frequency (MHz)';
    else
        fLabelStr = 'Frequency (Hz)';
    end
    
    % Convert sec to us for plotting
    t = t * 1e6;
    tLabelStr = 'Time (\mu s)';
    
    figure('Name', sprintf('STFT Feature: %s (Frame %d)', label, frame_idx));
    imagesc(t, f, stftData);
    set(gca, 'YDir', 'normal');
    colormap('jet');
    cb = colorbar;
    
    featType = features.STFT.stftConfig.featureType;
    if strcmp(featType, 'logPower')
        ylabel(cb, 'Log Power (dB)');
    else
        ylabel(cb, 'Magnitude');
    end
    
    title(sprintf('STFT (%s) - %s (Frame %d)', featType, label, frame_idx));
    xlabel(tLabelStr);
    ylabel(fLabelStr);
end
