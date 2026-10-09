function AssignBackground_Callback(hObject, eventdata, handles, definitionFile)
%% Point recordings in the audio folder at a background definition
% definitionFile is optional; without it, a file picker asks for one.
% Assigning says which definition a recording uses. Whether removal is
% applied to the open recording is a separate switch (ApplyBackground_Callback).

%% Which definition?
if nargin < 4
    [filename, pathname] = uigetfile(fullfile(handles.data.settings.backgroundfolder, '*.mat'), 'Select Background Definition');
    if isnumeric(filename); return; end
    definitionFile = fullfile(pathname, filename);
end
try
    Background = loadBackgroundDefinition(definitionFile);
catch ME
    errordlg(ME.message, 'Background Subtraction');
    return
end

%% Which recordings?
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);
if isempty(handles.audiofiles)
    errordlg('No audio files in the current audio folder. Choose one with "File > Select Audio Folder".', 'Background Subtraction');
    return
end
audiofiles = fullfile({handles.audiofiles.folder}, {handles.audiofiles.name});
hasBackground = cellfun(@(f) isfile(backgroundAssignmentFile(f, handles.data.settings.backgroundfolder)), audiofiles);
listing = handles.audiofilesnames;
listing(hasBackground) = strcat(listing(hasBackground), '      [has a background]');

% Start with the open recording selected, if it is in this folder
initial = 1;
if ~isempty(handles.data.audiodata)
    open = find(strcmpi(audiofiles, handles.data.audiodata.Filename), 1);
    if ~isempty(open); initial = open; end
end
idx = listdlg('ListString', listing, 'Name', 'Background Subtraction', 'InitialValue', initial, ...
    'PromptString', {sprintf('Assign background "%s" to which recordings?', Background.name), 'Select one or more.'}, ...
    'ListSize', [500, 300]);
if isempty(idx); return; end

if any(hasBackground(idx))
    replace = questdlg(sprintf('%d of the selected recordings already have a background. Replace it?', sum(hasBackground(idx))), ...
        'Background Subtraction', 'Replace', 'Cancel', 'Cancel');
    if ~strcmp(replace, 'Replace'); return; end
end

%% Assign
try
    written = assignBackground(audiofiles(idx), Background, handles.data.settings.backgroundfolder);
catch ME
    errordlg(ME.message, 'Background Subtraction');
    return
end
fprintf(1, 'Background "%s" (%s) assigned to %d recording(s).\n', Background.name, Background.id(1:12), length(written));
refreshBackground(hObject, handles);
end
