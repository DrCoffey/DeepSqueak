function [s, p, gain, k] = applyBackgroundSubtraction(Background, s, p, window, nfft, SampleRate)
%% Remove a defined background from a spectrogram
% Subtracts the background from the spectrogram on a decibel scale and adds
% back one constant, the reference level R, so that the overall level is kept:
%
%     p_clean(f,t) [dB] = p(f,t) [dB] - B(f) [dB] + R [dB]
%
% which is the same as multiplying each frequency row by the gain R / B(f).
% In stretches that contain only background, every frequency then has the
% same typical level. Sound that rises above the background keeps its
% level relative to the background at its frequency.
%
% If the definition has flicker scaling turned on, each row's deviation
% from its background is also multiplied by an exponent k(f), so that every
% row flickers by the same amount (see backgroundExponent):
%
%     p_clean(f,t) [dB] = R [dB] + k(f) * ( p(f,t) [dB] - B(f) [dB] )
%
% Background     a definition from loadBackgroundDefinition, or [] to do nothing
% s, p           complex STFT and power spectral density from
%                spectrogram(audio, window, noverlap, nfft, SampleRate),
%                with all frequency rows present. Either may be [].
% gain           R / B(f), one value per frequency row
% k              exponent per frequency row; all ones without flicker scaling
%
% Everything applied is fixed by the definition and the resolution. Nothing
% is estimated from the audio being cleaned.

gain = 1;
k = 1;
if isempty(Background)
    return
end
if ischar(Background)
    % squeakData marks the background 'unresolved' whenever a new recording is
    % set. Whoever opened the recording must look up its background first.
    error('DeepSqueak:background:unresolved', ...
        'The background for this recording has not been looked up. Set it with backgroundForAudio before computing spectrograms.');
end

[B, ~, spread, psdPerMagnitude] = backgroundSpectrum(Background, window, nfft, SampleRate);
gain = backgroundReference(Background, B, nfft, SampleRate) ./ B;
k = backgroundExponent(Background, spread);

if (~isempty(p) && size(p,1) ~= length(gain)) || (~isempty(s) && size(s,1) ~= length(gain))
    error('DeepSqueak:background:rows', 'Background subtraction must be applied before frequency rows are removed.');
end

if all(k == 1)
    if ~isempty(p); p = p .* gain; end
    if ~isempty(s); s = s .* sqrt(gain); end
    return
end

%% Flicker scaling: an extra factor (p / B)^(k - 1) at each point
if ~isempty(p)
    relative = p ./ B;
else
    relative = psdPerMagnitude .* abs(s).^2 ./ B;
end
extra = relative .^ (k - 1);
extra(relative == 0) = 1; % A point with no power stays at no power
if ~isempty(p); p = p .* gain .* extra; end
if ~isempty(s); s = s .* sqrt(gain .* extra); end
end
