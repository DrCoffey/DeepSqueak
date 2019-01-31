function exportaudio_Callback(hObject, eventdata, handles)
%% Save the audio around the box to a WAVE file

% Convert audio to double
   audio = handles.calls(handles.currentcall).Audio;
if ~isfloat(audio)
    audio = double(audio) / (double(intmax(class(audio)))+1);
end

% Get the relative playback rate
rate = inputdlg('Choose Playback Rate:','Save Audio',[1 50],{num2str(handles.settings.playback_rate)});
if isempty(rate)
    disp('Cancelled by User')
    return
end

% Convert relative rate to samples/second
rate = str2double(rate{:}) * handles.calls(handles.currentcall).Rate;

% Get the output file name
[~,detectionName] = fileparts(handles.current_detection_file);
audioname=[detectionName ' Call ' num2str(handles.currentcall) '.WAV'];
[FileName,PathName] = uiputfile(audioname,'Save Audio');
if isnumeric(FileName)
    return
end

% Save the file
audiowrite(fullfile(PathName,FileName),audio,rate);
