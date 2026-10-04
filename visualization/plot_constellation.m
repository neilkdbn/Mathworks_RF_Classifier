function plot_constellation(raw_frame, proc_frame, label_str)
% plot_constellation Plots the scatter (constellation) of the signal.
%
% NOTE: For signals with pulse shaping or fading (as in this dataset), 
% this represents the received sample cloud rather than the ideal constellation.

    figure('Name', sprintf('Constellation Comparison: %s', label_str), 'Position', [150, 150, 800, 400]);
    
    subplot(1, 2, 1);
    scatter(real(raw_frame), imag(raw_frame), 10, 'b', 'filled', 'MarkerFaceAlpha', 0.5);
    title(sprintf('Raw Constellation Cloud\n(%s)', label_str));
    xlabel('In-Phase (I)'); ylabel('Quadrature (Q)');
    grid on; axis square;
    
    subplot(1, 2, 2);
    scatter(real(proc_frame), imag(proc_frame), 10, 'r', 'filled', 'MarkerFaceAlpha', 0.5);
    title(sprintf('Processed Constellation Cloud\n(%s)', label_str));
    xlabel('In-Phase (I)'); ylabel('Quadrature (Q)');
    grid on; axis square;
end
