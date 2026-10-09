function id = backgroundHash(Background)
%% SHA-256 fingerprint of everything that determines a background's effect
% Covers the noise audio, the sample rate, the percentile, the format
% version and whether flicker scaling is on. Two
% definitions with the same id give identical results. The name, notes and
% source file paths are deliberately excluded.

md = java.security.MessageDigest.getInstance('SHA-256');
header = sprintf('DeepSqueakBackground v%d|%.17g|%.17g|%s|%d', ...
    Background.formatVersion, Background.SampleRate, Background.percentile, Background.sampleClass, length(Background.samples));
if Background.formatVersion >= 3
    % Later formats have settings beyond the percentile
    header = sprintf('%s|flicker%d', header, Background.flickerScaling);
end
md.update(uint8(header));
for i = 1:length(Background.samples)
    md.update(uint8(sprintf('|%d|', numel(Background.samples{i}))));
    md.update(typecast(Background.samples{i}(:), 'uint8'));
end
id = sprintf('%02x', typecast(md.digest(), 'uint8'));
end
