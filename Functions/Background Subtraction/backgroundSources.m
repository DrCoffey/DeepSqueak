function [sources, segments] = backgroundSources(Background)
%% What a background definition is made of, one row per source
% A source is one file's worth of boxed noise: the unit that is added to
% or removed from a definition.
%
% sources    table: Source, AudioFile, Stretches, Seconds
% segments   the definition's segments table, with a Source variable even
%            for definitions saved before sources were recorded (for
%            those, the source is the audio file name)

segments = Background.segments;
if ~ismember('Source', segments.Properties.VariableNames)
    [~, names, exts] = cellfun(@fileparts, segments.Filename, 'UniformOutput', false);
    segments.Source = strcat(names, exts);
end

[Source, ~, group] = unique(segments.Source, 'stable');
AudioFile = cell(size(Source));
Stretches = zeros(size(Source));
Seconds = zeros(size(Source));
for i = 1:length(Source)
    rows = group == i;
    [~, names, exts] = cellfun(@fileparts, unique(segments.Filename(rows)), 'UniformOutput', false);
    AudioFile{i} = strjoin(strcat(names, exts), ', ');
    Stretches(i) = sum(rows);
    Seconds(i) = sum(segments.StopSample(rows) - segments.StartSample(rows) + 1) / Background.SampleRate;
end
sources = table(Source, AudioFile, Stretches, Seconds);
end
