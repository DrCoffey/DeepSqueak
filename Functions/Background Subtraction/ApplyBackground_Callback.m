function ApplyBackground_Callback(hObject, eventdata, handles)
%% Switch background removal on or off for the open recording
% Works on the open recording only, using the definition assigned to it.
% It changes what is shown and measured in the main window. It does not
% change the assignment.

if isempty(handles.data.backgroundAssigned)
    errordlg('The open recording has no background assigned.', 'Background Subtraction');
    return
end
handles.data.applyBackground = ~handles.data.applyBackground;
refreshBackground(hObject, handles);
end
