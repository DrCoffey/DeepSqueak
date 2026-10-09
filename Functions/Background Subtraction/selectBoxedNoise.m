function segments = selectBoxedNoise(handles, title)
%% Ask for file(s) of boxed noise and return their stretches
% Returns an empty table if the user cancels or nothing usable is chosen.
% The dialog says what was read, so it is clear the file was understood.

segments = table();

[filename, pathname] = uigetfile(fullfile(handles.data.settings.detectionfolder, '*.mat'), ...
    'Select file(s) in which noise-only stretches are boxed', 'MultiSelect', 'on');
if isnumeric(filename); return; end
files = fullfile(pathname, cellstr(filename));

try
    [~, labels] = backgroundSegmentsFromDetections(files);
catch ME
    errordlg(ME.message, 'Background Subtraction');
    return
end
if isempty(labels)
    errordlg('The selected file(s) contain no boxes.', 'Background Subtraction');
    return
end

%% Which boxes mark noise?
descriptions = cell(size(labels));
boxes = zeros(size(labels));
seconds = zeros(size(labels));
try
    for i = 1:length(labels)
        found = backgroundSegmentsFromDetections(files, labels(i));
        boxes(i) = height(found);
        seconds(i) = sum(found.StopTime - found.StartTime);
        descriptions{i} = sprintf('"%s":   %d boxes,   %.1f s in total', labels{i}, boxes(i), seconds(i));
    end
catch ME
    errordlg(ME.message, 'Background Subtraction');
    return
end
readnames = strjoin(cellstr(filename), ', ');

if length(labels) == 1
    % Every box has the same label, so there is nothing to choose between
    use = questdlg({['Read:  ' readnames], '', ...
        sprintf('It holds %d boxes, all labelled "%s", covering %.1f s in total.', boxes, labels{1}, seconds), '', ...
        'Use all of these boxes as noise-only stretches?'}, ...
        title, 'Use them', 'Cancel', 'Use them');
    if ~strcmp(use, 'Use them'); return; end
    idx = 1;
else
    idx = listdlg('ListString', descriptions, 'Name', title, ...
        'PromptString', {['Read:  ' readnames], 'The boxes are grouped by label below.', 'Select the label(s) whose boxes mark noise-only stretches.'}, ...
        'ListSize', [450, 200]);
    if isempty(idx); return; end
end

try
    segments = backgroundSegmentsFromDetections(files, labels(idx));
catch ME
    errordlg(ME.message, 'Background Subtraction');
    segments = table();
end
end
