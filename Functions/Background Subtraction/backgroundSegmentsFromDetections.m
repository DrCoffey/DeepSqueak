function [segments, labels] = backgroundSegmentsFromDetections(filenames, noiseLabels)
%% Turn hand-drawn boxes into noise segments for createBackgroundDefinition
% Noise-only stretches are marked in the DeepSqueak window like any other
% box ("Load Audio", draw boxes over stretches with no calls, save). Only
% the time extent of each box is used; its frequency extent is ignored.
%
% filenames     detection file, or cell array of detection files
% noiseLabels   labels (Calls.Type) that mark noise-only stretches. If
%               omitted, no segments are returned; use the second output to
%               see which labels the files contain.
%
% segments      table with Filename, StartTime, StopTime, Source. Source is
%               the name of the detection file each stretch was boxed in.
% labels        every label present in the files

filenames = cellstr(filenames);
Filename = {}; StartTime = []; StopTime = []; Source = {};
labels = {};

for i = 1:length(filenames)
    data = load(filenames{i}, 'Calls', 'audiodata');
    if ~isfield(data, 'Calls') || ~isfield(data, 'audiodata') || ~isfield(data.audiodata, 'Filename')
        error('DeepSqueak:background:notDetection', '%s is not a detection file with audio information.', filenames{i});
    end
    Calls = data.Calls;
    if isstruct(Calls)
        Calls = struct2table(Calls, 'AsArray', true);
    end
    if isempty(Calls)
        continue
    end
    labels = union(labels, cellstr(unique(Calls.Type)));
    if nargin < 2
        continue
    end
    if ~isfile(data.audiodata.Filename)
        error('DeepSqueak:background:missingAudio', ...
            'The audio for %s was not found at %s. Open the file with "Load Calls" once to relink it.', ...
            filenames{i}, data.audiodata.Filename);
    end
    rows = ismember(cellstr(Calls.Type), cellstr(noiseLabels));
    n = sum(rows);
    Filename = [Filename; repmat({data.audiodata.Filename}, n, 1)];
    StartTime = [StartTime; Calls.Box(rows,1)];
    StopTime = [StopTime; Calls.Box(rows,1) + Calls.Box(rows,3)];
    [~, sourcename, sourceext] = fileparts(filenames{i});
    Source = [Source; repmat({[sourcename sourceext]}, n, 1)];
end

segments = table(Filename, StartTime, StopTime, Source);
end
