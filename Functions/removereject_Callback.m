function removereject_Callback(hObject, eventdata, handles)

handles.calls = handles.calls(handles.calls.Accept, :);
handles.currentcall = 1;

update_fig(hObject, eventdata, handles);
guidata(hObject, handles);