% --------------------------------------------------------------------
function import_raven_Callback(hObject, eventdata, handles)
% Requires a Raven table and audio file.
% (http://www.birds.cornell.edu/brp/raven/RavenOverview.html)

[ravenname,ravenpath] = uigetfile([handles.squeakfolder '/*.txt'],'Select Raven Log');
raven = tdfread([ravenpath ravenname]);
[audioname, audiopath] = uigetfile({'*.wav;*.wmf;*.flac;*.UVD' 'Audio File';'*.wav' 'WAV (*.wav)'; '*.wmf' 'WMF (*.wmf)'; '*.flac' 'FLAC (*.flac)'; '*.UVD' 'Ultravox File (*.UVD)'},'Select Audio File',handles.settings.audiofolder);

info = audioinfo([audiopath audioname]);
if info.NumChannels > 1
    warning('Audio file contains more than one channel. Use channel 1...')
end

rate = info.SampleRate;
Calls = struct('Rate',struct,'Box',struct,'RelBox',struct,'Score',struct,'Audio',struct,'Accept',struct,'Type',struct,'Power',struct);
hc = waitbar(0,'Importing Calls from Raven Log'); 
for i=1:length(raven.Selection)
         waitbar(i/length(raven.Selection),hc); 

Calls(i).Rate = rate;
Calls(i).Box = [raven.Begin_Time_0x28s0x29(i), raven.Low_Freq_0x28Hz0x29(i)/1000, raven.Delta_Time_0x28s0x29(i), raven.Delta_Freq_0x28Hz0x29(i)/1000];
windL = raven.Begin_Time_0x28s0x29(i) - raven.Delta_Time_0x28s0x29(i);
if windL < 0
    windL = 1 / rate;
end
windR = raven.End_Time_0x28s0x29(i) + raven.Delta_Time_0x28s0x29(i);
Calls(i).RelBox=[raven.Delta_Time_0x28s0x29(i), raven.Low_Freq_0x28Hz0x29(i)/1000, raven.Delta_Time_0x28s0x29(i), raven.Delta_Freq_0x28Hz0x29(i)/1000];
Calls(i).Score = 1;

audio = audioread([audiopath audioname],round([windL windR]*rate),'native');
Calls(i).Audio = mean(audio,2); % Just take the first audio channel
Calls(i).Accept=1;
Calls(i).Type=raven.Annotation(i);
Calls(i).Power = 0;
end
[~,name] = fileparts(audioname)
[FileName,PathName,FilterIndex] = uiputfile([handles.settings.detectionfolder '/' name '.mat'],'Save Call File');
save([PathName,FileName],'Calls','-v7.3');
close(hc);
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles
