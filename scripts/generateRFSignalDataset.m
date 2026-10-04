function ds = generateRFSignalDataset(varargin)
%GENERATERFSIGNALDATASET Neil (RF Systems Modeler): synthetic impaired RF data.
%   DS = GENERATERFSIGNALDATASET('Name',Value,...) generates one complex
%   baseband frame per (modulation, SNR) combination with channel
%   impairments, and returns a table with variables:
%       signal (cell, [N x 1] complex double), modulation (categorical),
%       snrDb (double), sampleRate (double).
%
%   Name-Value options:
%     'Modulations'  - string vector, default ["BPSK","QPSK","8PSK","16QAM", ...
%                        "64QAM","PAM4","GFSK","CPFSK"] (subset of the
%                        MathWorks modulation-classification example set)
%     'SNRdB'        - double vector, default -10:5:20
%     'FramesPerCombo' - frames per (mod,SNR), default 200 (demo-small)
%     'FrameLength'  - complex samples per frame, default 1024
%     'SampleRate'   - Hz, default 200e3
%     'Seed'         - rng seed, default 0 (reproducibility)
%     'SavePath'     - .mat path to save DS, default "" (no save)
%
%   Impairments applied (Communications Toolbox): Rician multipath fading
%   (comm.RicianChannel), carrier frequency offset, timing drift via
%   resampling, AWGN (awgn). Clean path uses phased-array / comm modulators
%   per helperModClassGetModulator pattern.
%
%   Status: Phase-1 interface contract. Full modulator bank is Neil's
%   deliverable; this returns correctly-shaped seeded data so Arya/Shreeya/
%   Anjali can integrate now.
%
%   See also: extractRFfeatures, trainRFClassifier.

p = inputParser;
p.addParameter('Modulations', ["BPSK","QPSK","8PSK","16QAM","64QAM","PAM4","GFSK","CPFSK"], @(x) isstring(x) || iscellstr(x));
p.addParameter('SNRdB', -10:5:20, @isnumeric);
p.addParameter('FramesPerCombo', 200, @(x) isnumeric(x) && isscalar(x));
p.addParameter('FrameLength', 1024, @(x) isnumeric(x) && isscalar(x));
p.addParameter('SampleRate', 200e3, @isnumeric);
p.addParameter('Seed', 0, @isnumeric);
p.addParameter('SavePath', "", @(x) isstring(x) || ischar(x));
p.parse(varargin{:});
o = p.Results;
mods = string(o.Modulations);

rng(o.Seed);
nComb = numel(mods) * numel(o.SNRdB);
nTot  = nComb * o.FramesPerCombo;
sig   = cell(nTot, 1);
mod   = strings(nTot, 1);
snr   = zeros(nTot, 1);
idx = 0;
for mi = 1:numel(mods)
    for si = 1:numel(o.SNRdB)
        for k = 1:o.FramesPerCombo
            idx = idx + 1;
            tx = synthModFrame(mods(mi), o.FrameLength);
            rx = applyTestChannel(tx, o.SampleRate, o.SNRdB(si));
            sig{idx} = rx;
            mod(idx) = mods(mi);
            snr(idx) = o.SNRdB(si);
        end
    end
end
ds = table(sig, categorical(mod), snr, ...
    repmat(o.SampleRate, nTot, 1), ...
    'VariableNames', {'signal','modulation','snrDb','sampleRate'});
if strlength(string(o.SavePath)) > 0
    save(o.SavePath, 'ds', '-v7.3');
end
end

function tx = synthModFrame(modType, N)
% Placeholder modulator: unit-variance complex symbols with pulse shaping
% stub. Neil replaces with comm.* modulators + RRC filtering.
switch modType
    case "PAM4"
        tx = (randi([0 3], N, 1)*2 - 3) + 0j;
    otherwise
        tx = (randn(N,1) + 1j*randn(N,1)) / sqrt(2);
end
tx = tx / rms(tx);
end

function rx = applyTestChannel(tx, fs, snrDb)
% Mirrors helperModClassTestChannel: fading -> CFO -> timing drift -> AWGN.
ric = comm.RicianChannel('SampleRate', fs, ...
    'PathDelays', [0 1.8 3.4]/fs, ...
    'AveragePathGains', [0 -2 -10], 'KFactor', 4);
out = ric(tx);
fo = 5e-3*fs*randn;                       % residual carrier offset
n = (0:length(out)-1).';
out = out .* exp(1j*2*pi*fo/fs*n);
C = 1 + 50e-6*randn;                      % clock drift
t = (0:length(out)-1)'/fs; tp = (0:length(out)-1)'/(fs*C);
out = interp1(t, out, tp, 'linear', 'extrap');
rx = awgn(out, snrDb, 'measured');
release(ric);
end
