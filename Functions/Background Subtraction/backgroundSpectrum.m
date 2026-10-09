function [B, nFrames, spread, psdPerMagnitude] = backgroundSpectrum(Background, window, nfft, SampleRate)
%% Background power spectral density at a given spectrogram resolution
% Returns the chosen percentile, at each frequency, of the power spectral
% density of the stored noise audio. The estimate is made by calling
% spectrogram() itself with the caller's window and nfft, so B has exactly
% the units, scaling and frequency rows of the "p" output that the caller
% gets from spectrogram(audio, window, noverlap, nfft, SampleRate).
%
% window, nfft   in samples, as passed to spectrogram()
% SampleRate     of the audio being cleaned. Must match the definition.
%
% B                 background power spectral density, one value per row
% nFrames           number of noise frames it was estimated from
% spread            interquartile range, in dB, of the noise power in each
%                   row: how much that row flickers. About 6.8 dB for
%                   random noise, less for a steady tone, more for a
%                   source that pulses.
% psdPerMagnitude   factor per row that turns squared STFT magnitude,
%                   abs(s).^2, into power spectral density, p
%
% The result does not depend on the caller's overlap. It is deterministic:
% frames are taken at fixed, evenly spaced positions, never at random.

maxFrames = 2000; % Plenty for a stable percentile, and keeps this fast
minFrames = 50;

if SampleRate ~= Background.SampleRate
    error('DeepSqueak:background:sampleRate', ...
        ['Background "%s" was defined from %g Hz audio and cannot be applied to %g Hz audio. ' ...
        'Define a background from recordings made at the same sample rate.'], ...
        Background.name, Background.SampleRate, SampleRate);
end

%% Results are cached, because many calls share one resolution
persistent cache
if isempty(cache) || cache.Count > 5000
    cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
end
key = sprintf('%s_%d_%d', Background.id, window, nfft);
if isKey(cache, key)
    cached = cache(key);
    B = cached.B;
    nFrames = cached.nFrames;
    spread = cached.spread;
    psdPerMagnitude = cached.psdPerMagnitude;
    return
end

%% Find every position where a whole window fits inside one noise stretch
hop = ceil(window / 2);
segment = [];
start = [];
for i = 1:length(Background.samples)
    starts = (1:hop:(numel(Background.samples{i}) - window + 1))';
    segment = [segment; repmat(i, length(starts), 1)];
    start = [start; starts];
end
if length(start) < minFrames
    error('DeepSqueak:background:tooShort', ...
        ['Background "%s" has too little noise audio for a %g ms window (%d frames, need %d). ' ...
        'Add more or longer noise stretches.'], ...
        Background.name, 1000 * window / SampleRate, length(start), minFrames);
end
if length(start) > maxFrames
    keep = round(linspace(1, length(start), maxFrames));
    segment = segment(keep);
    start = start(keep);
end
nFrames = length(start);

%% Lay the frames end to end and let spectrogram() transform each one
% With zero overlap, every spectrogram column is exactly one frame.
scale = double(intmax(Background.sampleClass)) + 1; % Same scaling as audioread
frames = zeros(window, nFrames);
for i = 1:nFrames
    frames(:,i) = double(Background.samples{segment(i)}(start(i):start(i) + window - 1)) / scale;
end
[s, ~, ~, p] = spectrogram(frames(:), window, 0, nfft, SampleRate, 'yaxis');
p = max(p, realmin); % Never divide by, or take the log of, zero

B = prctile(p, Background.percentile, 2);
spread = diff(prctile(10 * log10(p), [25 75], 2), 1, 2);
psdPerMagnitude = median(p ./ max(abs(s).^2, realmin), 2);

cache(key) = struct('B', B, 'nFrames', nFrames, 'spread', spread, 'psdPerMagnitude', psdPerMagnitude);
end
