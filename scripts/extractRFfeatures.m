function feats = extractRFfeatures(ds, varargin)
%EXTRACTRFFEATURES Arya (Signal Processing Lead): I/Q + STFT features.
%   FEATS = EXTRACTRFFEATURES(DS, 'Mode', MODE) converts the dataset table
%   from GENERATERFSIGNALDATASET into network-ready features.
%
%   Modes:
%     'IQ'   - [2 x frameLength] real/imag sequences (1D-CNN/LSTM path)
%     'STFT' - [freq x time x 1] magnitude spectrograms (2D-CNN path,
%              Signal Processing Toolbox stft / Wavelet Toolbox cwt option)
%
%   Returns a table with variables: features (cell), modulation, snrDb.
%
%   Status: Phase-1 interface contract with working default implementation.
%
%   See also: generateRFSignalDataset, trainRFClassifier.

p = inputParser;
p.addRequired('ds', @(t) istable(t));
p.addParameter('Mode', "IQ", @(x) any(validatestring(x, {'IQ','STFT'})));
p.addParameter('STFTWindow', 128, @isnumeric);
p.addParameter('STFTOverlap', 96, @isnumeric);
p.parse(ds, varargin{:});
mode = char(p.Results.Mode);

n = height(ds);
f = cell(n,1);
for i = 1:n
    x = ds.signal{i}(:);
    switch mode
        case 'IQ'
            f{i} = single([real(x).'; imag(x).']);      % 2 x N
        case 'STFT'
            S = stft(x, 'Window', hamming(p.Results.STFTWindow), ...
                'OverlapLength', p.Results.STFTOverlap, 'Centered', false);
            f{i} = single(abs(S));                       % F x T
    end
end
feats = table(f, ds.modulation, ds.snrDb, ...
    'VariableNames', {'features','modulation','snrDb'});
end
