function ImportFromMUPET_Callback(hObject, eventdata, handles)

[ravenname,ravenpath] = uigetfile(['\*.csv'],'Select MUPET Log');
MUPET = readtable([ravenpath ravenname]);

[audioname, audiopath] = uigetfile({'*.wav;*.flac;*.UVD' 'Audio File';'*.wav' 'WAV(*.wav)'; '*.flac' 'FLAC (*.flac)'; '*.UVD' 'Ultravox File (*.UVD)'},['Select Audio File for ' ravenname],handles.settings.audiofolder);



info = audioinfo([audiopath audioname]);
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
Calls(i).Audio=audioread([audiopath audioname],round([windL windR]*rate),'native');
Calls(i).Accept=1;
Calls(i).Type=categorical({'USV'});
Calls(i).Power = 1;
end
[~,name] = fileparts(ravenname)
[FileName,PathName,FilterIndex] = uiputfile([handles.settings.detectionfolder '/' name '.mat'],'Save Call File');
save([PathName,FileName],'Calls','-v7.3');
close(hc);
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles
