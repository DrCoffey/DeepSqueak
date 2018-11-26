% --------------------------------------------------------------------
function savesession_Callback(hObject, eventdata, handles)

handles.v_det = get(handles. popupmenuDetectionFiles,'Value');
handles.SaveFile=[handles.detectionfiles(handles.v_det).name];
handles.SaveFile = handles.current_detection_file;
Calls=handles.calls;
[FileName,PathName] = uiputfile(fullfile(handles.settings.detectionfolder,handles.SaveFile),'Save Session (.mat)');
if FileName == 0
    return
end
h = waitbar(0.5,'saving');


save(fullfile(PathName,FileName),'Calls','-v7.3');

update_folders(hObject, eventdata, handles);
guidata(hObject, handles);
close(h);
