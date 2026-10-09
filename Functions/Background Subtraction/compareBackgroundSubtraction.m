function fig = compareBackgroundSubtraction(audiofile, Background, startTime, duration, varargin)
%% Show a stretch of audio before and after background subtraction
% Needs only an audio file and a background definition.
%
% audiofile    audio file to inspect
% Background   definition from loadBackgroundDefinition
% startTime    start of the stretch (s)
% duration     length of the stretch (s)
%
% Optional name-value pairs:
%   'WindowSize'  spectrogram window (s), default 0.0032
%   'Overlap'     spectrogram overlap (s), default half the window
%   'NFFT'        spectrogram nfft (s), default the window
%   'FreqRange'   [low high] in kHz to display, default the full range
%   'Visible'     'on' (default) or 'off'

p = inputParser;
addParameter(p, 'WindowSize', 0.0032);
addParameter(p, 'Overlap', []);
addParameter(p, 'NFFT', []);
addParameter(p, 'FreqRange', []);
addParameter(p, 'Visible', 'on');
parse(p, varargin{:});

info = audioinfo(audiofile);
if info.NumChannels ~= 1
    error('DeepSqueak:background:multichannel', 'Background subtraction only supports single channel audio.');
end
rate = info.SampleRate;
window = round(rate * p.Results.WindowSize);
if isempty(p.Results.Overlap); noverlap = round(window / 2); else; noverlap = round(rate * p.Results.Overlap); end
if isempty(p.Results.NFFT); nfft = window; else; nfft = round(rate * p.Results.NFFT); end

first = max(round(startTime * rate), 1);
last = min(round((startTime + duration) * rate), info.TotalSamples);
audio = audioread(audiofile, [first, last]);

[~, f, t, before] = spectrogram(audio, window, noverlap, nfft, rate, 'yaxis');
[~, after, gain, k] = applyBackgroundSubtraction(Background, [], before, window, nfft, rate);
B = backgroundSpectrum(Background, window, nfft, rate);
R = backgroundReference(Background, B, nfft, rate);
t = t + (first - 1) / rate;
f = f / 1000;

freqRange = p.Results.FreqRange;
if isempty(freqRange); freqRange = [0, f(end)]; end
rows = f >= freqRange(1) & f <= freqRange(2);

before_dB = 10 * log10(before);
after_dB = 10 * log10(after);

% One color scale for both images, set from the cleaned one
clim = [prctile(after_dB(rows,:), 20, 'all'), prctile(after_dB(rows,:), 99.9, 'all')];

[~, audioname, ext] = fileparts(audiofile);
fig = figure('Color', 'w', 'Position', [50, 50, 1500, 800], 'Visible', p.Results.Visible, ...
    'Name', 'Background subtraction: before and after');

ax1 = subplot(2, 4, 1:3);
imagesc(ax1, t, f(rows), before_dB(rows,:), clim);
axis(ax1, 'xy'); colormap(ax1, inferno);
ylabel(ax1, 'Frequency (kHz)');
title(ax1, ['Before: ' audioname ext], 'Interpreter', 'none');

ax2 = subplot(2, 4, 5:7);
imagesc(ax2, t, f(rows), after_dB(rows,:), clim);
axis(ax2, 'xy'); colormap(ax2, inferno);
ylabel(ax2, 'Frequency (kHz)'); xlabel(ax2, 'Time (s)');
title(ax2, sprintf('After: background "%s" (%s)', Background.name, Background.id(1:12)), 'Interpreter', 'none');
cb = colorbar(ax2, 'southoutside'); cb.Label.String = 'Power spectral density (dB/Hz)';
linkaxes([ax1, ax2], 'xy');

% Typical level at each frequency in this stretch, and the background
ax3 = subplot(2, 4, [4, 8]);
plot(ax3, 10*log10(B(rows)), f(rows), 'Color', [.6 .6 .6], 'LineWidth', 2); hold(ax3, 'on');
plot(ax3, median(before_dB(rows,:), 2), f(rows), 'Color', [.85 .33 .1]);
plot(ax3, median(after_dB(rows,:), 2), f(rows), 'Color', [0 .45 .74]);
xline(ax3, 10*log10(R), ':', 'Color', [.3 .3 .3]);
ylim(ax3, freqRange); grid(ax3, 'on');
xlabel(ax3, 'dB/Hz'); ylabel(ax3, 'Frequency (kHz)');
legend(ax3, {'Background definition', 'This stretch, before (median)', 'This stretch, after (median)', 'Reference level'}, 'Location', 'southoutside');
if all(k == 1)
    title(ax3, sprintf('Largest attenuation %.1f dB', -10*log10(min(gain(rows)))));
else
    title(ax3, {sprintf('Largest attenuation %.1f dB', -10*log10(min(gain(rows)))), sprintf('Flicker scaling on: exponents %.2f to %.2f', min(k(rows)), max(k(rows)))});
end
end
