function selectBackgroundFolder_Callback(hObject, eventdata, handles)
%% Choose the folder that holds background definitions and assignments
path = uigetdir(handles.data.settings.backgroundfolder, 'Select Background Folder');
if isnumeric(path); return; end
handles.data.settings.backgroundfolder = path;
handles.data.saveSettings();
update_folders(hObject, eventdata, handles);
refreshBackground(hObject, guidata(hObject));
end
