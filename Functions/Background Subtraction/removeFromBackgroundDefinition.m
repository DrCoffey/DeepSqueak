function NewBackground = removeFromBackgroundDefinition(Background, sources)
%% A new background definition: an existing one minus some of its sources
% Background   definition from loadBackgroundDefinition
% sources      source name, or cell array of names, as listed by
%              backgroundSources(Background)
%
% The existing definition is not changed. The result is a separate
% definition with its own id, the same name and settings, and a record of
% the definition it came from.

sources = cellstr(sources);
[~, segments] = backgroundSources(Background);
unknown = setdiff(sources, segments.Source);
if ~isempty(unknown)
    error('DeepSqueak:background:unknownSource', 'Background "%s" has no source named %s.', Background.name, strjoin(unknown, ', '));
end
keep = ~ismember(segments.Source, sources);
if ~any(keep)
    error('DeepSqueak:background:noSegments', 'Removing these sources would leave background "%s" with no noise at all.', Background.name);
end

previous = Background.id;
NewBackground = Background;
[NewBackground.segments, order] = sortrows(segments(keep,:), {'Filename', 'StartSample'});
kept = Background.samples(keep);
NewBackground.samples = kept(order);
NewBackground.totalDuration = sum(NewBackground.segments.StopSample - NewBackground.segments.StartSample + 1) / Background.SampleRate;
NewBackground.created = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
NewBackground.software = backgroundSoftwareInfo();
NewBackground.derivedFrom = previous;
if isfield(NewBackground, 'sourceFile')
    NewBackground = rmfield(NewBackground, 'sourceFile');
end
NewBackground.id = backgroundHash(NewBackground);
end
