function DefineBackground_Callback(hObject, eventdata, handles)
%% Build and save a background definition from boxed noise-only stretches
% Mark the stretches first: "Load Audio", draw boxes over stretches of time
% that contain no calls and no passing noises, and save. Only the time
% extent of each box is used.

%% Select the files that contain the boxes, and confirm what was read
segments = selectBoxedNoise(handles, 'Define Background');
if isempty(segments); return; end

%% Name and settings
summary = sprintf('%d boxed stretches, %.1f s in total, from %d file(s).', ...
    height(segments), sum(segments.StopTime - segments.StartTime), length(unique(segments.Filename)));
answer = inputdlg({
    [summary ' Name for this background (e.g. rig and date range):']
    'Percentile of the noise taken at each frequency (50 = median):'
    'Flicker scaling (0 = off, 1 = on):'
    'Notes:'}, 'Define Background', [1 80], {'', '50', '0', ''});
if isempty(answer); return; end
if isempty(strtrim(answer{1}))
    errordlg('A name is required.', 'Background Subtraction');
    return
end

h = waitbar(0.5, 'Reading noise audio...');
try
    Background = createBackgroundDefinition(segments, strtrim(answer{1}), ...
        'Percentile', str2double(answer{2}), 'FlickerScaling', isequal(strtrim(answer{3}), '1'), 'Notes', answer{4});
catch ME
    close(h);
    errordlg(ME.message, 'Background Subtraction');
    return
end
close(h);

%% Save. Definitions are never overwritten.
if ~exist(handles.data.settings.backgroundfolder, 'dir')
    mkdir(handles.data.settings.backgroundfolder);
end
defaultname = [regexprep(Background.name, '[^\w\-. ]', '_') ' ' Background.id(1:12) '.mat'];
[savename, savepath] = uiputfile(fullfile(handles.data.settings.backgroundfolder, defaultname), 'Save Background Definition');
if isnumeric(savename); return; end
try
    saveBackgroundDefinition(Background, fullfile(savepath, savename));
catch ME
    errordlg(ME.message, 'Background Subtraction');
    return
end

use = questdlg(sprintf('Saved "%s". Assign it to recordings now?', Background.name), 'Background Subtraction', 'Yes', 'No', 'Yes');
if strcmp(use, 'Yes')
    AssignBackground_Callback(hObject, eventdata, handles, fullfile(savepath, savename));
end
end
