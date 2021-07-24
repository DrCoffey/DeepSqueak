% --- Executes on selection change in popupmenuColorMap.
function popupmenuColorMap_Callback(hObject, eventdata, handles)
    handles.data.cmapName = get(handles.popupmenuColorMap, 'String');
    handles.data.cmapName = handles.data.cmapName(get(handles.popupmenuColorMap, 'Value'));
    handles.data.cmap = feval(handles.data.cmapName{1, 1}, 256);
    colormap(handles.focusWindow, handles.data.cmap);
    colormap(handles.spectogramWindow, handles.data.cmap);
end
