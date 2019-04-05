% --------------------------------------------------------------------
function import_raven_Callback(hObject, eventdata, handles)
% Requires a Raven table and audio file.
% (http://www.birds.cornell.edu/brp/raven/RavenOverview.html)

[ravenname,ravenpath] = uigetfile([handles.data.squeakfolder '/*.txt'],'Select Raven Log');
raven = tdfread([ravenpath ravenname]);
[audioname, audiopath] = uigetfile({'*.wav;*.wmf;*.flac;*.UVD' 'Audio File';'*.wav' 'WAV (*.wav)'; '*.wmf' 'WMF (*.wmf)'; '*.flac' 'FLAC (*.flac)'; '*.UVD' 'Ultravox File (*.UVD)'},'Select Audio File',handles.data.settings.audiofolder);

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
    Calls(i).Box = [raven.Begin_Time_0x28s0x29(i), raven.Low_Freq_0x28Hz0x29(i)/1000, raven.Delta_Time_0x28s0x29(i), (raven.High_Freq_0x28Hz0x29(i)-raven.Low_Freq_0x28Hz0x29(i))/1000];
    WindL = raven.Begin_Time_0x28s0x29(i) - raven.Delta_Time_0x28s0x29(i);
    WindR = raven.End_Time_0x28s0x29(i) + raven.Delta_Time_0x28s0x29(i);
    
    Calls(i).RelBox=[raven.Delta_Time_0x28s0x29(i), raven.Low_Freq_0x28Hz0x29(i)/1000, raven.Delta_Time_0x28s0x29(i), (raven.High_Freq_0x28Hz0x29(i)-raven.Low_Freq_0x28Hz0x29(i))/1000];
    Calls(i).Score = 1;
    
    audio = mergeAudio([audiopath audioname], round([WindL WindR]*rate));
    
    Calls(i).Audio = audio;
    Calls(i).Accept=1;
    try
    Calls(i).Type=raven.Annotation(i);
    catch
    Calls(i).Type=categorical({'USV'});
    end
    Calls(i).Power = 0;
end
Calls = struct2table(Calls);

[~ ,name] = fileparts(audioname);
[FileName, PathName] = uiputfile(fullfile(handles.data.settings.detectionfolder, [name '.mat']),'Save Call File');
save([PathName,FileName],'Calls','-v7.3');
close(hc);
update_folders(hObject, eventdata, handles);
