function savesession_Callback(hObject, eventdata, handles)

handles.v_det = get(handles. popupmenuDetectionFiles,'Value');
if isfield(handles,'current_detection_file')
    handles.SaveFile = handles.detectionfiles(handles.v_det).name;
    handles.SaveFile = handles.current_detection_file;
else
    handles.SaveFile = [strtok(handles.audiofiles(handles.v_det).name,'.') '.mat'];
end

% temp = handles.data.audiodata.samples;
% handles.data.audiodata.samples = [];
guidata(hObject, handles);

Calls = handles.data.calls;
audiodata = handles.data.audiodata;
[FileName, PathName] = uiputfile(fullfile(handles.data.settings.detectionfolder, handles.SaveFile), 'Save Session (.mat)');
if FileName == 0
    return
end
h = waitbar(0.5, 'saving');


save(fullfile(PathName, FileName), 'Calls','audiodata', '-v7.3');
% handles.data.audiodata.samples = temp;
update_folders(hObject, eventdata, handles);
guidata(hObject, handles);
close(h);
