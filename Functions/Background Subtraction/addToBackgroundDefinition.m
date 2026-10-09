function NewBackground = addToBackgroundDefinition(Background, segments)
%% A new background definition: an existing one plus more noise stretches
% Background   definition from loadBackgroundDefinition
% segments     table of stretches to add, as for createBackgroundDefinition
%              (for example from backgroundSegmentsFromDetections)
%
% The existing definition is not changed. The result is a separate
% definition with its own id, the same name and settings, and a record of
% the definition it came from. The noise already in the definition is taken
% from the definition itself, so its original recordings are not needed.
% Building a definition in steps gives the same id as building it at once.

addition = createBackgroundDefinition(segments, Background.name);
if addition.SampleRate ~= Background.SampleRate
    error('DeepSqueak:background:sampleRate', ...
        'Background "%s" holds %g Hz audio; the stretches to add are %g Hz.', Background.name, Background.SampleRate, addition.SampleRate);
end
if ~strcmp(addition.sampleClass, Background.sampleClass)
    error('DeepSqueak:background:sampleFormat', 'The stretches to add are not in the same sample format as the definition.');
end

%% Refuse audio that is already in the definition, so nothing is counted twice
[~, existing] = backgroundSources(Background);
for i = 1:height(addition.segments)
    same = strcmp(existing.Filename, addition.segments.Filename{i});
    overlap = same & existing.StartSample <= addition.segments.StopSample(i) & existing.StopSample >= addition.segments.StartSample(i);
    identical = cellfun(@(x) isequal(x, addition.samples{i}), Background.samples);
    if any(overlap) || any(identical)
        [~, name, ext] = fileparts(addition.segments.Filename{i});
        error('DeepSqueak:background:alreadyIncluded', ...
            'Background "%s" already contains noise from %s between %.2f and %.2f s. Nothing was added.', ...
            Background.name, [name ext], addition.segments.StartTime(i), addition.segments.StopTime(i));
    end
end

NewBackground = rebuild(Background, [existing; addition.segments], [Background.samples; addition.samples]);
end

function Background = rebuild(Background, segments, samples)
% Put the stretches in their fixed order and stamp the definition
previous = Background.id;
[segments, order] = sortrows(segments, {'Filename', 'StartSample'});
Background.segments = segments;
Background.samples = samples(order);
Background.totalDuration = sum(segments.StopSample - segments.StartSample + 1) / Background.SampleRate;
Background.created = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
Background.software = backgroundSoftwareInfo();
Background.derivedFrom = previous;
if isfield(Background, 'sourceFile')
    Background = rmfield(Background, 'sourceFile');
end
Background.id = backgroundHash(Background);
end
