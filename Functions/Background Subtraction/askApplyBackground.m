function apply = askApplyBackground(files, backgroundfolder, purpose)
%% Ask whether a batch operation should apply background removal
% files             the files the operation will work through: detection
%                   files (.mat), audio files, or a mix
% backgroundfolder  folder holding assignment files and definitions
% purpose           what is being made, for the question, e.g. 'training images'
%
% apply   true to apply removal to every recording that has a background
%         assigned, false to apply it to none, [] if the user cancelled.
%
% Nothing is asked, and apply is false, when none of the recordings has a
% background assigned.

files = cellstr(files);
assigned = false(size(files));
for i = 1:length(files)
    [~, ~, ext] = fileparts(files{i});
    if strcmpi(ext, '.mat')
        % A detection file: the recording is named inside it. Files of
        % extracted contours name no recording and so have no background.
        if ~ismember('audiodata', who('-file', files{i})); continue; end
        data = load(files{i}, 'audiodata');
        if ~isfield(data.audiodata, 'Filename'); continue; end
        audiofile = data.audiodata.Filename;
    else
        audiofile = files{i};
    end
    assigned(i) = ~isempty(backgroundfolder) && isfile(backgroundAssignmentFile(audiofile, backgroundfolder));
end

apply = false;
if ~any(assigned)
    return
end

if all(assigned) && length(assigned) == 1
    situation = 'The selected file is from a recording with a background assigned.';
elseif all(assigned)
    situation = sprintf('All %d selected files are from recordings with a background assigned.', length(assigned));
else
    situation = sprintf(['%d of the %d selected files are from recordings with a background assigned. ' ...
        'The other %d have none and are processed without removal either way, so applying it gives a mixed set.'], ...
        sum(assigned), length(assigned), sum(~assigned));
end
answer = questdlg({situation, '', sprintf('Apply background removal when making %s?', purpose)}, ...
    'Background Subtraction', 'Apply', 'Do not apply', 'Cancel', 'Apply');
switch answer
    case 'Apply'
        apply = true;
    case 'Do not apply'
        apply = false;
    otherwise
        apply = [];
end
end
