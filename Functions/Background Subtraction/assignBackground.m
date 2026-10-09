function written = assignBackground(audiofiles, Background, backgroundfolder)
%% Point one or more recordings at a background definition
% audiofiles        audio file name, or cell array of names, anywhere
% Background        definition from loadBackgroundDefinition, or its file name
% backgroundfolder  folder holding assignment files and definitions
%
% Writes one assignment file per recording into the background folder,
% replacing any assignment the recording already had. A copy of the
% definition is saved into the folder if it is not already there. Nothing
% is written beside the audio.
%
% written   the assignment files written

audiofiles = cellstr(audiofiles);
if ischar(Background) || isstring(Background)
    Background = loadBackgroundDefinition(Background);
end
if ~isfolder(backgroundfolder)
    mkdir(backgroundfolder);
end

%% Check every recording before writing anything
info = cell(size(audiofiles));
for i = 1:length(audiofiles)
    info{i} = audioinfo(audiofiles{i});
    if info{i}.NumChannels ~= 1
        error('DeepSqueak:background:multichannel', ...
            'Background subtraction only supports single channel audio. %s has %d channels.', audiofiles{i}, info{i}.NumChannels);
    end
    if info{i}.SampleRate ~= Background.SampleRate
        error('DeepSqueak:background:sampleRate', ...
            'Background "%s" was defined from %g Hz audio and cannot be assigned to %s (%g Hz). Nothing was assigned.', ...
            Background.name, Background.SampleRate, audiofiles{i}, info{i}.SampleRate);
    end
end

%% Make sure the definition itself is in the folder
try
    stored = findBackgroundDefinition(backgroundfolder, Background.id, '');
catch ME
    if ~strcmp(ME.identifier, 'DeepSqueak:background:definitionMissing'); rethrow(ME); end
    filename = fullfile(backgroundfolder, [regexprep(Background.name, '[^\w\-. ]', '_') ' ' Background.id(1:12) '.mat']);
    saveBackgroundDefinition(Background, filename);
    stored = loadBackgroundDefinition(filename);
end
[~, definitionName, definitionExt] = fileparts(stored.sourceFile);

%% Write the assignments
written = cell(size(audiofiles));
for i = 1:length(audiofiles)
    [~, name, ext] = fileparts(info{i}.Filename);
    BackgroundAssignment = struct( ...
        'formatVersion', 1, ...
        'audioName', [name ext], ...
        'audioTotalSamples', info{i}.TotalSamples, ...
        'audioSampleRate', info{i}.SampleRate, ...
        'backgroundId', Background.id, ...
        'backgroundName', Background.name, ...
        'definitionFile', [definitionName definitionExt], ...
        'assigned', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
    written{i} = backgroundAssignmentFile(info{i}.Filename, backgroundfolder);
    save(written{i}, 'BackgroundAssignment');
end
end
