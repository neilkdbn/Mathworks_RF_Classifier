% 1. Define Parameters
numFrames = 1000;          
samplesPerFrame = 1024;    
sps = 8;                   
symbolsPerFrame = samplesPerFrame / sps;
sampleRate = 1e6;          % Baseband Sample Rate for fading

% 2. Design a Raised Cosine Transmit Filter (Pulse Shaping)
rolloff = 0.35;
span = 6;                  
txFilter = comm.RaisedCosineTransmitFilter( ...
    'RolloffFactor', rolloff, ...
    'FilterSpanInSymbols', span, ...
    'OutputSamplesPerSymbol', sps);

% 3. Define the Rayleigh Fading Channel Object
fadingChannel = comm.RayleighChannel( ...
    'SampleRate', sampleRate, ...
    'PathDelays', [0 1.5e-6 3.2e-6], ...
    'AveragePathGains', [0 -3 -10], ...
    'MaximumDopplerShift', 50);

% Define Target SNR
target_snr_db = 10;

% 4. Generate Realistic QPSK Data (Fading + AWGN)
M_qpsk = 4;
qpskData_realistic = zeros(samplesPerFrame, numFrames);

for i = 1:numFrames
    % Generate and modulate
    dataSymbols = randi([0 M_qpsk-1], symbolsPerFrame, 1);
    modSignal = pskmod(dataSymbols, M_qpsk, pi/4);
    txSignal = txFilter(modSignal);
    
    % Apply Fading and Noise
    fadedSignal = fadingChannel(txSignal);
    noisyFadedSignal = awgn(fadedSignal(1:samplesPerFrame), target_snr_db, 'measured');
    
    % Store
    qpskData_realistic(:, i) = noisyFadedSignal;
    reset(fadingChannel); % Reset for the next frame
end

% 5. Generate Realistic 16-QAM Data (Fading + AWGN)
M_qam = 16;
qamData_realistic = zeros(samplesPerFrame, numFrames);

for i = 1:numFrames
    % Generate and modulate
    dataSymbols = randi([0 M_qam-1], symbolsPerFrame, 1);
    modSignal = qammod(dataSymbols, M_qam, 'UnitAveragePower', true);
    txSignal = txFilter(modSignal);
    
    % Apply Fading and Noise
    fadedSignal = fadingChannel(txSignal);
    noisyFadedSignal = awgn(fadedSignal(1:samplesPerFrame), target_snr_db, 'measured');
    
    % Store
    qamData_realistic(:, i) = noisyFadedSignal;
    reset(fadingChannel); % Reset for the next frame
end

% 6. Save the dataset for Arya (Signal Processing Lead)
save('rf_dataset_v1.mat', 'qpskData_realistic', 'qamData_realistic', 'samplesPerFrame', 'numFrames');

% Optional: Visualize the realistic distortion
scatterplot(qpskData_realistic(:, 1));
title('Realistic QPSK Constellation (Fading + 10dB AWGN)');