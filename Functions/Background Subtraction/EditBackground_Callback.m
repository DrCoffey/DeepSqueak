function EditBackground_Callback(hObject, eventdata, handles, action)
%% Add a file of boxed noise to a background definition, or remove one
% action is 'add' or 'remove'.
%
% A saved definition never changes. Editing saves a new definition beside
% the old one, then offers to switch over the recordings that used the old
% one.

%% Which definition?
[filename, pathname] = uigetfile(fullfile(handles.data.settings.backgroundfolder, '*.mat'), 'Select the Background Definition to change');
if isnumeric(filename); return; end
try
    Background = loadBackgroundDefinition(fullfile(pathname, filename));
catch ME
    errordlg(ME.message, 'Background Subtraction');
    return
end
sources = backgroundSources(Background);
listing = arrayfun(@(i) sprintf('%s      (%d stretches, %.1f s, from %s)', ...
    sources.Source{i}, sources.Stretches(i), sources.Seconds(i), sources.AudioFile{i}), (1:height(sources))', 'UniformOutput', false);

%% Make the new definition
h = [];
try
    switch action
        case 'add'
            segments = selectBoxedNoise(handles, 'Add Boxed Noise');
            if isempty(segments); return; end
            h = waitbar(0.5, 'Reading noise audio...');
            NewBackground = addToBackgroundDefinition(Background, segments);
        case 'remove'
            if height(sources) < 2
                errordlg(sprintf('Background "%s" has only one source, %s. Removing it would leave nothing.', Background.name, sources.Source{1}), 'Background Subtraction');
                return
            end
            idx = listdlg('ListString', listing, 'Name', 'Remove Boxed Noise', ...
                'PromptString', {sprintf('Background "%s" is made of these sources.', Background.name), 'Select the one(s) to remove.'}, ...
                'ListSize', [650, 250]);
            if isempty(idx); return; end
            NewBackground = removeFromBackgroundDefinition(Background, sources.Source(idx));
    end
catch ME
    if ~isempty(h); close(h); end
    errordlg(ME.message, 'Background Subtraction');
    return
end
if ~isempty(h); close(h); end

%% Save it as a new file. The old definition is kept.
newSources = backgroundSources(NewBackground);
defaultname = [regexprep(NewBackground.name, '[^\w\-. ]', '_') ' ' NewBackground.id(1:12) '.mat'];
[savename, savepath] = uiputfile(fullfile(pathname, defaultname), ...
    sprintf('Save the changed definition (%d source(s), %.1f s)', height(newSources), NewBackground.totalDuration));
if isnumeric(savename); return; end
try
    saveBackgroundDefinition(NewBackground, fullfile(savepath, savename));
    NewBackground = loadBackgroundDefinition(fullfile(savepath, savename));
catch ME
    errordlg(ME.message, 'Background Subtraction');
    return
end
fprintf(1, 'Background "%s": %s (%d source(s), %.1f s) saved as %s (%d source(s), %.1f s).\n', Background.name, ...
    Background.id(1:12), height(sources), Background.totalDuration, NewBackground.id(1:12), height(newSources), NewBackground.totalDuration);

%% Switch over the recordings that used the old one
folder = handles.data.settings.backgroundfolder;
[count, names] = repointBackgroundAssignments(folder, Background.id, []);
if count > 0 && strcmpi(fullfile(savepath, '.'), fullfile(folder, '.'))
    shown = names(1:min(count, 8));
    if count > 8; shown{end+1} = sprintf('... and %d more', count - 8); end
    move = questdlg([{sprintf('%d recording(s) use the previous version of "%s":', count, Background.name)}, shown, ...
        {'', 'Switch them to the changed version?'}], 'Background Subtraction', 'Switch them', 'Leave them', 'Switch them');
    if strcmp(move, 'Switch them')
        try
            repointBackgroundAssignments(folder, Background.id, NewBackground);
            fprintf(1, '%d recording(s) switched to %s.\n', count, NewBackground.id(1:12));
        catch ME
            errordlg(ME.message, 'Background Subtraction');
        end
    end
elseif count > 0
    msgbox(sprintf('%d recording(s) still use the previous version. Save changed definitions in the background folder to be offered the switch.', count), 'Background Subtraction');
end
refreshBackground(hObject, handles);
end
