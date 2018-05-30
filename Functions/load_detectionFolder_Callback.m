function load_detectionFolder_Callback(hObject, eventdata, handles)
% Find audio in folder
path=uigetdir(handles.settings.detectionfolder,'Select Detection File Folder');
if isnumeric(path);return;end
handles.settings.detectionfolder = path;
settings = handles.settings;
save([handles.squeakfolder '/settings.mat'],'-struct','settings')
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles