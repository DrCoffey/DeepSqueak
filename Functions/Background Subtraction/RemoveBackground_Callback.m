function RemoveBackground_Callback(hObject, eventdata, handles)
%% Remove the background assignment from recordings in the audio folder
% Removes assignments only. Definitions are kept.

update_folders(hObject, eventdata, handles);
handles = guidata(hObject);
if isempty(handles.audiofiles)
    errordlg('No audio files in the current audio folder.', 'Background Subtraction');
    return
end
audiofiles = fullfile({handles.audiofiles.folder}, {handles.audiofiles.name});
hasBackground = cellfun(@(f) isfile(backgroundAssignmentFile(f, handles.data.settings.backgroundfolder)), audiofiles);
if ~any(hasBackground)
    msgbox('No recording in the current audio folder has a background assigned.', 'Background Subtraction');
    return
end
audiofiles = audiofiles(hasBackground);
names = handles.audiofilesnames(hasBackground);

initial = 1;
if ~isempty(handles.data.audiodata)
    open = find(strcmpi(audiofiles, handles.data.audiodata.Filename), 1);
    if ~isempty(open); initial = open; end
end
idx = listdlg('ListString', names, 'Name', 'Background Subtraction', 'InitialValue', initial, ...
    'PromptString', {'Remove the background assignment from which recordings?', 'Select one or more.'}, ...
    'ListSize', [500, 300]);
if isempty(idx); return; end

confirm = questdlg(sprintf('Remove the background assignment from %d recording(s)? The definitions are kept.', length(idx)), ...
    'Background Subtraction', 'Remove', 'Cancel', 'Cancel');
if ~strcmp(confirm, 'Remove'); return; end

for i = idx
    removeBackgroundAssignment(audiofiles{i}, handles.data.settings.backgroundfolder);
end
fprintf(1, 'Background assignment removed from %d recording(s).\n', length(idx));
refreshBackground(hObject, handles);
end
