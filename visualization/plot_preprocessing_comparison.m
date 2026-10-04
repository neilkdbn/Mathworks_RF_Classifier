function plot_preprocessing_comparison(raw_frame, proc_frame, label_str, frame_idx)
% plot_preprocessing_comparison Plots time-domain comparison of I and Q components.
%
% INPUTS:
%   raw_frame  - Raw complex IQ signal vector
%   proc_frame - Processed complex IQ signal vector
%   label_str  - Modulation class name
%   frame_idx  - Frame index for title

    figure('Name', sprintf('Preprocessing Comparison: %s (Frame %d)', label_str, frame_idx), 'Position', [100, 100, 800, 600]);
    
    n_samples = length(raw_frame);
    t = 1:n_samples;
    
    % I Component
    subplot(2, 2, 1);
    plot(t, real(raw_frame), 'b');
    title('Raw I Component');
    xlabel('Sample Index'); ylabel('Amplitude');
    grid on;
    
    subplot(2, 2, 2);
    plot(t, real(proc_frame), 'r');
    title('Processed I Component');
    xlabel('Sample Index'); ylabel('Normalized Amplitude');
    grid on;
    
    % Q Component
    subplot(2, 2, 3);
    plot(t, imag(raw_frame), 'b');
    title('Raw Q Component');
    xlabel('Sample Index'); ylabel('Amplitude');
    grid on;
    
    subplot(2, 2, 4);
    plot(t, imag(proc_frame), 'r');
    title('Processed Q Component');
    xlabel('Sample Index'); ylabel('Normalized Amplitude');
    grid on;
    
    sgtitle(sprintf('%s - Frame %d: Raw vs Processed', label_str, frame_idx));
end
