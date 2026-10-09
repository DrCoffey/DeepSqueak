function [count, names] = repointBackgroundAssignments(backgroundfolder, oldId, NewBackground)
%% Switch every recording that uses one definition over to another
% backgroundfolder  folder holding assignment files and definitions
% oldId             id of the definition to move away from
% NewBackground     definition to move to, already saved in the folder
%                   (loaded with loadBackgroundDefinition). Pass [] to
%                   only count the recordings that use oldId.
%
% count   number of recordings that use (or used) oldId
% names   their audio file names

count = 0;
names = {};
files = dir(fullfile(backgroundfolder, '*_background.mat'));
for i = 1:length(files)
    filename = fullfile(files(i).folder, files(i).name);
    data = load(filename);
    if ~isfield(data, 'BackgroundAssignment') || ~strcmp(data.BackgroundAssignment.backgroundId, oldId)
        continue
    end
    count = count + 1;
    names{end+1} = data.BackgroundAssignment.audioName;
    if isempty(NewBackground)
        continue
    end
    BackgroundAssignment = data.BackgroundAssignment;
    if BackgroundAssignment.audioSampleRate ~= NewBackground.SampleRate
        error('DeepSqueak:background:sampleRate', 'Background "%s" cannot be used for %s: the sample rates differ.', NewBackground.name, BackgroundAssignment.audioName);
    end
    [~, definitionName, definitionExt] = fileparts(NewBackground.sourceFile);
    BackgroundAssignment.backgroundId = NewBackground.id;
    BackgroundAssignment.backgroundName = NewBackground.name;
    BackgroundAssignment.definitionFile = [definitionName definitionExt];
    BackgroundAssignment.assigned = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    save(filename, 'BackgroundAssignment');
end
end
