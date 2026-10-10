function img = make_constellation_density(iqFrame, binEdges)
% MAKE_CONSTELLATION_DENSITY Convert one 1024x2 preprocessed I/Q frame
% into a 2D constellation-density image. Does NOT modify Arya's data.
%
% iqFrame: [time x 2] with column 1 = I, column 2 = Q
% binEdges: fixed bin edges computed from TRAINING data only
% img: [numBins x numBins] single log-count image

assert(isnumeric(iqFrame) && size(iqFrame,2) == 2, ...
    'Expected an I/Q matrix of dimensions [time x 2].');
assert(all(isfinite(iqFrame(:))), 'Non-finite I/Q samples.');
assert(isnumeric(binEdges) && isvector(binEdges) && ...
    numel(binEdges) >= 3 && all(diff(binEdges) > 0), ...
    'binEdges must be a strictly increasing vector.');

I = double(iqFrame(:,1));
Q = double(iqFrame(:,2));

% Clip rare outliers to the shared training-derived range instead of
% discarding their samples. This does not re-normalize the I/Q frames.
lo = binEdges(1);
hi = binEdges(end);
I = min(max(I,lo),hi);
Q = min(max(Q,lo),hi);

counts = histcounts2(I,Q,binEdges,binEdges);
img = single(log1p(counts));

nBins = numel(binEdges)-1;
assert(isequal(size(img),[nBins nBins]), 'Unexpected image size.');
assert(all(isfinite(img(:))), 'Non-finite constellation image.');
end
