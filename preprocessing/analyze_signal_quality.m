function quality = analyze_signal_quality(dataStruct)
% analyze_signal_quality Calculates diagnostic measurements for the RF signals.
%
% INPUTS:
%   dataStruct - Validated MATLAB struct containing .signals
%
% OUTPUTS:
%   quality - Struct with diagnostic properties for the entire dataset

    signals = dataStruct.signals;
    
    % Ensure complex double
    if ~isfloat(signals)
        signals = double(signals);
    end
    
    quality = struct();
    
    % Statistics over the entire dataset
    quality.meanI = mean(real(signals(:)), 'omitnan');
    quality.meanQ = mean(imag(signals(:)), 'omitnan');
    
    mag = abs(signals(:));
    quality.rms = rms(mag, 'omitnan');
    quality.power = mean(mag.^2, 'omitnan');
    quality.peak = max(mag, [], 'omitnan');
    quality.min = min(mag, [], 'omitnan');
    
    quality.nanCount = sum(isnan(signals(:)));
    quality.infCount = sum(isinf(signals(:)));
    
    if quality.rms > 0
        quality.crestFactor = quality.peak / quality.rms;
    else
        quality.crestFactor = NaN;
    end
end
