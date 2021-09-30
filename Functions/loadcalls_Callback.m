% --- Executes on button press in LOAD CALLS.
function success = loadcalls_Callback(hObject, eventdata, handles, filename)
% If filename is not given, load the file selected in the dropdown menu.

cancelled = checkForUnsavedChanges(hObject, eventdata, handles);
if cancelled
    return
end

h = waitbar(0,'Loading Calls Please wait...');
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);
if nargin == 3 % if "Load Calls" button pressed, load the selected file, else reload the current file
    if isempty(handles.detectionfiles)
        close(h);
        errordlg(['No valid detection files in current folder. Select a folder containing detection files with '...
            '"File -> Select Detection Folder", then choose the desired file in the "Detected Call Files" dropdown box.'])
        return
    end
    handles.current_file_id = get(handles.popupmenuDetectionFiles,'Value');
    handles.current_detection_file = fullfile(handles.detectionfiles(handles.current_file_id).folder,  handles.detectionfiles(handles.current_file_id).name);
elseif isfile(filename)
    handles.current_detection_file = filename;
end

handles.data.calls = [];
handles.data.audiodata = [];
[handles.data.calls, handles.data.audiodata] = loadCallfile(handles.current_detection_file, handles);

% Position of the focus window to the first call in the file
handles.data.focusCenter = handles.data.calls.Box(1,1) + handles.data.calls.Box(1,3)/2;

% For some unknown reason, if "h" is closed after running
% "initialize_display", then holding down an arror key will be a little
% slower. See update_fig.m for details
close(h);
initialize_display(hObject, eventdata, handles);
