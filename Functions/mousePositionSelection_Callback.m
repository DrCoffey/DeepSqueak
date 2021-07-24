function  mousePositionSelection_Callback(hObject,eventdata, handles)
% This fuction runs when the little bar with the green lines  or the page window is clicked or 

handles.data.focusCenter = eventdata.IntersectionPoint(1);
% Ensure the new selection is within the range of audio
handles.data.focusCenter = max(handles.data.focusCenter,  handles.data.settings.focus_window_size/2);
handles.data.focusCenter = min(handles.data.focusCenter,  handles.data.audiodata.Duration - handles.data.settings.focus_window_size/2);

%% Find the call closest to the click and make it the current call
callMidpoints = handles.data.calls.Box(:,1) + handles.data.calls.Box(:,3)/2;
[~, closestCall] = min(abs(callMidpoints - handles.data.focusCenter));
handles.data.currentcall = closestCall;

% update_fig runs guidata so we don't need that here
update_fig(hObject, eventdata, handles);
end

