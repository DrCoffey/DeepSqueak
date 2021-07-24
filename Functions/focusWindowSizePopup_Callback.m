function focusWindowSizePopup_Callback(hObject, eventdata, handles)
dropdown_items = cellstr(get(hObject,'String'));
focus_seconds = regexp(dropdown_items{get(hObject,'Value')},'([\d*.])*','match');
focus_seconds = str2double(focus_seconds{1});
handles.data.settings.focus_window_size = focus_seconds;
handles.data.saveSettings();

if ~isempty(handles.data.audiodata)
    update_fig(hObject, eventdata, handles);
else
    guidata(hObject, handles);
end
