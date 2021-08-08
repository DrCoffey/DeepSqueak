function exportaudio_Callback(hObject, eventdata, handles)
%% Save the audio within user defined time smapn to a WAV file. The
%% default span is the span of the currently selected call.

current_box = handles.data.calls.Box(handles.data.currentcall,:);

% Get the relative playback rate
answer = inputdlg({'Choose Playback Rate:', 'Audio start (s):','Audio stop (s):'},...
                   'Save Audio',...
                   [1 40],...
                   {num2str(handles.data.settings.playback_rate), num2str(current_box(1),'%.3f'), num2str(current_box(1)+current_box(3),'%.3f')}...
                   );
if isempty(answer)
    disp('Cancelled by User');
    return
end

start_sec = str2double(answer{2});
stop_sec = str2double(answer{3});


if isempty(start_sec) || isempty(stop_sec)
    errordlg('Please define valid audio start and stop time','Invalid audio range');
    return;
end

audio = handles.data.AudioSamples(start_sec,stop_sec);

% Convert relative rate to samples/second
rate = str2double(answer{1}) * handles.data.audiodata.SampleRate;

% Get the output file name
[~,detectionName] = fileparts(handles.current_detection_file);
audioname=[detectionName ' Call ' num2str(handles.data.currentcall) '.WAV'];
[FileName,PathName] = uiputfile(audioname,'Save Audio');
if isnumeric(FileName)
    return
end

% Save the file
audiowrite(fullfile(PathName,FileName),audio,rate);
