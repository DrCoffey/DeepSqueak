function exportaudio_Callback(hObject, eventdata, handles)
%% Save the audio around the box to a WAVE file
   audio = handles.calls(handles.currentcall).Audio;
if ~isa(audio,'double')
    audio = double(audio) / (double(intmax(class(audio)))+1);
end

paddedsound = [zeros(3125,1); audio; zeros(3125,1)]; % Get audio around the box
audiostart = handles.calls(handles.currentcall).RelBox(1) * handles.calls(handles.currentcall).Rate;
audiolength = handles.calls(handles.currentcall).RelBox(3) * handles.calls(handles.currentcall).Rate;
tmpaudio = paddedsound(round(audiostart:audiostart+audiolength + 6249));

rate = inputdlg('Choose Playback Rate:','Save Audio',[1 50],{num2str(handles.settings.playback_rate)});
if isempty(rate)
    disp('Cancelled by User')
    return
end
rate = str2num(rate{:}) * handles.calls(handles.currentcall).Rate;
audioname=[handles.current_detection_file(1:end-4) ' Call ' num2str(handles.currentcall) '.WAV'];
[FileName,PathName] = uiputfile(audioname,'Save Audio');
if isnumeric(FileName)
    disp('Cancelled by User')
    return
end
audiowrite([PathName FileName],tmpaudio,(rate));
guidata(hObject, handles);