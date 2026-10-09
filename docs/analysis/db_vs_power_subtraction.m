function results = db_vs_power_subtraction(figureFile)
%% Decibel-scale versus power-scale background subtraction, on synthetic audio
% Supports docs/BACKGROUND_SUBTRACTION_METHOD.md. Everything is synthetic
% and seeded, so the numbers reproduce exactly.
%
% Run from the repository root:
%   matlab -batch "addpath(genpath('Functions')); addpath('docs/analysis'); db_vs_power_subtraction('docs/figures/db_vs_power_subtraction.png')"
%
% The recording contains
%   - white noise (the floor),
%   - a steady tone at 60 kHz,
%   - a band of random noise at 29-31 kHz,
%   - 40 loud and 40 quiet upward sweeps from 20 to 80 kHz that cross both.
% The first 6 s contain no sweeps. Seconds 0-3 define the background;
% seconds 3-6 are held-out noise.

rng(7, 'twister');
rate = 250000;
window = 800; noverlap = 400; nfft = 800;   % 3.2 ms, as the DeepSqueak display default
sigma = 0.002;

%% Build the recording
sweepDuration = 0.15; spacing = 0.25; nEach = 40;
T = 6 + 2 * nEach * spacing;
t = (0:1/rate:T - 1/rate)';
floorNoise = sigma * randn(size(t));
tone = 1.85 * sigma * sin(2*pi*60000*t);
band = bandpass(10 * sigma * randn(size(t)), [29000 31000], rate);

% Sweeps, scaled so that their ridge stands a chosen amount above the floor
unit = zeros(size(t));
level_dB = zeros(2*nEach, 1); onset = zeros(2*nEach, 1);
ts = (0:1/rate:sweepDuration - 1/rate)';
for i = 1:2*nEach
    onset(i) = 6 + (i-1) * spacing + 0.05;
    idx = round(onset(i) * rate) + (1:length(ts))';
    unit(idx) = chirp(ts, 20000, sweepDuration, 80000) .* tukeywin(length(ts), 0.1);
    level_dB(i) = 20 + 15 * (i > nEach);     % 40 quiet (+20 dB), then 40 loud (+35 dB)
end
[~, f, tt, pUnit] = spectrogram(unit, window, noverlap, nfft, rate, 'yaxis');
[~, ~, ~, pFloor] = spectrogram(floorNoise(1:3*rate), window, noverlap, nfft, rate, 'yaxis');
floorMean = mean(pFloor(:));
inSweep = false(size(tt)); sweepLevel = zeros(size(tt));
for i = 1:2*nEach
    cols = tt > onset(i) + 0.01 & tt < onset(i) + sweepDuration - 0.01;
    inSweep(cols) = true; sweepLevel(cols) = level_dB(i);
end
unitRidge = median(max(pUnit(:, inSweep), [], 1));
sweeps = zeros(size(t));
for i = 1:2*nEach
    idx = round(onset(i) * rate) + (1:length(ts))';
    sweeps(idx) = unit(idx) * sqrt(10^(level_dB(i)/10) * floorMean / unitRidge);
end
x = floorNoise + tone + band + sweeps;

%% Spectrograms
[~, ~, ~, p] = spectrogram(x, window, noverlap, nfft, rate, 'yaxis');
[~, ~, ~, pSweeps] = spectrogram(sweeps, window, noverlap, nfft, rate, 'yaxis');
rows = f >= 10000 & f <= 100000;              % the range a call box would cover
define = tt < 3; heldout = tt > 3 & tt < 6;

Bmedian = median(p(:, define), 2);            % what DeepSqueak's definition uses
Bmean = mean(p(:, define), 2);                % what power subtraction needs
R = median(Bmedian);
flatFloor = 0.01 * median(Bmean);             % 20 dB below the typical background

version = struct('name', {}, 'p', {});
version(1).name = 'Unprocessed';                        version(1).p = p;
version(2).name = 'Decibel-scale (implemented)';        version(2).p = p .* (R ./ Bmedian);
version(3).name = 'Power, subtract 1 x mean';           version(3).p = max(p - 1 * Bmean, flatFloor);
version(4).name = 'Power, subtract 4 x mean';           version(4).p = max(p - 4 * Bmean, flatFloor);
clippedAt = [NaN, NaN, 1, 4];

%% Measures
[~, toneRow] = min(abs(f - 60000));
bandRows = find(f >= 29500 & f <= 30500);
ordinary = rows & abs(f - 60000) > 3000 & abs(f - 30000) > 3000;
rowIndex = find(rows);
[~, trueRidge] = max(pSweeps(rows, :), [], 1);
trueFreq = f(rowIndex(trueRidge))';
atTone = abs(trueFreq - 60000) < 1000; atBand = abs(trueFreq - 30000) < 1000;
elsewhere = abs(trueFreq - 60000) > 3000 & abs(trueFreq - 30000) > 3000;

results = table();
for v = 1:length(version)
    q = version(v).p;
    % 1. How far the bright pixels of a band row stand above those of ordinary rows, in noise alone
    bright = 10*log10(prctile(q(:, heldout), 95, 2));
    typical = median(bright(ordinary));
    toneExcess = bright(toneRow) - typical;
    bandExcess = median(bright(bandRows)) - typical;
    % 2. Share of noise pixels replaced by the floor value (information discarded)
    if isnan(clippedAt(v)); clipped = 0; else; clipped = 100 * mean(p(rows, heldout) <= clippedAt(v) * Bmean(rows), 'all'); end
    % 3. Does the loudest frequency at each moment of a sweep fall on the sweep?
    [~, ridge] = max(q(rows, :), [], 1);
    hit = abs(ridge - trueRidge) <= 2;
    acc = @(sel) 100 * mean(hit(sel));
    quiet = inSweep & sweepLevel == 20; loud = inSweep & sweepLevel == 35;
    % 4. DeepSqueak's "Entropy" (geometric over arithmetic mean of magnitude across frequency) in noise alone
    I = sqrt(q(rows, heldout));
    flatness = median(geomean(I, 1) ./ mean(I, 1));
    results = [results; table({version(v).name}, toneExcess, bandExcess, clipped, ...
        acc(quiet & elsewhere), acc(quiet & atBand), acc(quiet & atTone), ...
        acc(loud & elsewhere), acc(loud & atBand), acc(loud & atTone), flatness, ...
        'VariableNames', {'Version', 'ToneRowExcess_dB', 'BandRowsExcess_dB', 'NoisePixelsClipped_pct', ...
        'Quiet_elsewhere_pct', 'Quiet_atBand_pct', 'Quiet_atTone_pct', ...
        'Loud_elsewhere_pct', 'Loud_atBand_pct', 'Loud_atTone_pct', 'NoiseFlatness'})];
end

fprintf('Tone row stands %.1f dB and band rows %.1f dB above the floor (median level, noise only).\n', ...
    10*log10(Bmedian(toneRow) / R), 10*log10(median(Bmedian(bandRows)) / R));
fprintf('Sweep columns scored: quiet %d (at band %d, at tone %d), loud %d (at band %d, at tone %d).\n', ...
    sum(inSweep & sweepLevel == 20), sum(inSweep & sweepLevel == 20 & atBand), sum(inSweep & sweepLevel == 20 & atTone), ...
    sum(inSweep & sweepLevel == 35), sum(inSweep & sweepLevel == 35 & atBand), sum(inSweep & sweepLevel == 35 & atTone));
% Check on the theory used in the write-up: noise power in one row is exponentially distributed
ordinaryRow = find(ordinary, 1) + 40;
fprintf('Ordinary row, noise only: std/mean of power %.3f (exponential: 1), interquartile range %.2f dB (exponential: 6.83).\n', ...
    std(p(ordinaryRow, heldout)) / mean(p(ordinaryRow, heldout)), diff(10*log10(prctile(p(ordinaryRow, heldout), [25 75]))));
fprintf('Decibel-scale version is exactly reversible: max relative error after undoing the gain %.1e.\n', ...
    max(abs(version(2).p .* (Bmedian ./ R) - p) ./ p, [], 'all'));
disp(results);

%% Figure: one quiet and one loud sweep, the same color scale in every panel
if nargin > 0
    show = tt > onset(nEach) - 0.06 & tt < onset(nEach + 1) + sweepDuration + 0.06;
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [0 0 1500 800]);
    base = 10*log10(R);
    for v = 1:4
        ax = subplot(2, 2, v);
        imagesc(ax, tt(show), f(rows)/1000, 10*log10(version(v).p(rows, show)), base + [-12, 30]);
        axis(ax, 'xy'); colormap(ax, inferno);
        title(ax, version(v).name); ylabel(ax, 'Frequency (kHz)'); xlabel(ax, 'Time (s)');
    end
    cb = colorbar(ax, 'Position', [0.93 0.11 0.012 0.8]); cb.Label.String = 'dB/Hz';
    sgtitle(fig, 'Synthetic: quiet sweep (+20 dB) then loud sweep (+35 dB), crossing a noise band (30 kHz) and a tone (60 kHz)');
    exportgraphics(fig, figureFile, 'Resolution', 100);
    close(fig);
end
end
