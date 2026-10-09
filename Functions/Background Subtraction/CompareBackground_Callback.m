function CompareBackground_Callback(hObject, eventdata, handles)
%% Show the current page before and after background subtraction

if isempty(handles.data.backgroundAssigned)
    errordlg('The open recording has no background assigned.', 'Background Subtraction');
    return
end
if isempty(handles.data.audiodata)
    errordlg('Load an audio or detection file first.', 'Background Subtraction');
    return
end

fig = compareBackgroundSubtraction(handles.data.audiodata.Filename, handles.data.backgroundAssigned, ...
    handles.data.windowposition, handles.data.settings.pageSize, ...
    'WindowSize', handles.data.settings.spect.windowsize, ...
    'Overlap', handles.data.settings.spect.noverlap, ...
    'NFFT', handles.data.settings.spect.nfft, ...
    'FreqRange', [handles.data.settings.LowFreq, min(handles.data.settings.HighFreq, handles.data.audiodata.SampleRate/2000)]);

% update_fig closes stray figures that it can find, so hide this one from it
fig.HandleVisibility = 'off';
end
