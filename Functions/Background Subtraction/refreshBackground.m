function refreshBackground(hObject, handles)
%% Look up the open recording's background again, and redraw
% Call after anything that may have changed which background the open
% recording is assigned, or whether removal is switched on for it.

if isempty(handles.data.audiodata)
    updateBackgroundIndicator(handles);
    return
end
try
    assigned = backgroundForAudio(handles.data.audiodata, handles.data.settings.backgroundfolder);
catch ME
    errordlg(ME.message, 'Background Subtraction');
    rethrow(ME);
end
handles.data.backgroundAssigned = assigned;
if handles.data.applyBackground
    handles.data.background = assigned;
else
    handles.data.background = [];
end
updateBackgroundIndicator(handles);

% Redraw, and rescale the colors to the new levels
if isfield(handles, 'epochSpect') && isvalid(handles.epochSpect)
    update_fig(hObject, [], handles, true);
    handles = guidata(hObject);
    handles.data.clim = prctile(handles.data.page_spect.s_display,[10,90], 'all')';
    % This callback stores handles through its caller's parent, so give it a menu item
    change_spectogram_contrast_Callback(handles.backgroundCompareMenu,[],handles);
end
end
