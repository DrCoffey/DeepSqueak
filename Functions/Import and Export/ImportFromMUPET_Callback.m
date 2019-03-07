function ImportFromMUPET_Callback(hObject, eventdata, handles)

[ravenname, ravenpath] = uigetfile('*.csv','Select MUPET Log');
MUPET = readtable([ravenpath ravenname]);

[audioname, audiopath] = uigetfile({'*.wav;*.wmf;*.flac;*.UVD' 'Audio File';'*.wav' 'WAV (*.wav)'; '*.wmf' 'WMF (*.wmf)'; '*.flac' 'FLAC (*.flac)'; '*.UVD' 'Ultravox File (*.UVD)'},['Select Audio File for ' ravenname],handles.data.settings.audiofolder);



info = audioinfo([audiopath audioname]);
if info.NumChannels > 1
    warning('Audio file contains more than one channel. Use channel 1...')
end

rate = info.SampleRate;
Calls = struct('Rate',struct,'Box',struct,'RelBox',struct,'Score',struct,'Audio',struct,'Accept',struct,'Type',struct,'Power',struct);
hc = waitbar(0,'Importing Calls from MUPET Log');
for i=1:length(MUPET.SyllableNumber)
    waitbar(i/length(MUPET.SyllableNumber),hc);
    
    Calls(i).Rate = rate;
    Calls(i).Box = [MUPET.SyllableStartTime_sec_(i), MUPET.minimumFrequency_kHz_(i), MUPET.syllableDuration_msec_(i)/1000, MUPET.frequencyBandwidth_kHz_(i)];
    windL = Calls(i).Box(1) - Calls(i).Box(3);
    if windL < 0
        windL = 1 / rate;
    end
    windR = Calls(i).Box(1) + 2*Calls(i).Box(3);
    Calls(i).RelBox=[MUPET.syllableDuration_msec_(i)/1000, MUPET.minimumFrequency_kHz_(i), MUPET.syllableDuration_msec_(i)/1000, MUPET.frequencyBandwidth_kHz_(i)];
    Calls(i).Score = 1;
    
    audio = audioread([audiopath audioname],round([windL windR]*rate),'native');
    Calls(i).Audio = mean(audio - mean(audio,1,'native'),2,'native');
    
    Calls(i).Accept=1;
    Calls(i).Type=categorical({'USV'});
    Calls(i).Power = 1;
end
Calls = struct2table(Calls);
[~, name] = fileparts(ravenname);
[FileName, PathName] = uiputfile(fullfile(handles.data.settings.detectionfolder, [name '.mat']),'Save Call File');
save([PathName, FileName],'Calls','-v7.3');
close(hc);
update_folders(hObject, eventdata, handles);
