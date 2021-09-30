function cancelled = savesession_Callback(hObject, eventdata, handles)
% cancelled = false if saved successfully, else success = true
cancelled = false;

if isempty(handles.data.calls)
    disp('Can''t save session, no calls are loaded')
    return
end

Calls = handles.data.calls;
audiodata = handles.data.audiodata;
[FileName, PathName] = uiputfile(handles.current_detection_file, 'Save Session (.mat)');
if FileName == 0
    cancelled = true;
    return
end

h = waitbar(0.5, 'saving');
save(fullfile(PathName, FileName), 'Calls','audiodata', '-append');
update_folders(hObject, eventdata, handles);
close(h);

