% --------------------------------------------------------------------
function Import_From_Ultravox_Callback(hObject, eventdata, handles)

[ultravoxName,ultravoxPath] = uigetfile([handles.data.squeakfolder '/*.txt'],'Select Ultravox Log');
if ultravoxName == 0
    return
end
[audioname, audiopath] = uigetfile({
    '*.wav;*.ogg;*.flac;*.UVD;*.au;*.aiff;*.aif;*.aifc;*.mp3;*.m4a;*.mp4' 'Audio File'
    '*.wav' 'WAVE'
    '*.flac' 'FLAC'
    '*.ogg' 'OGG'
    '*.UVD' 'Ultravox File'
    '*.aiff;*.aif', 'AIFF'
    '*.aifc', 'AIFC'
    '*.mp3', 'MP3 (it''s probably a bad idea to record in MP3'
    '*.m4a;*.mp4' 'MPEG-4 AAC'
    }, 'Select Audio File',handles.data.settings.audiofolder);
if audioname == 0
    return
end
AudioFile = fullfile(audiopath,audioname);


% Convert from unicode to ascii
fin = fopen(fullfile(ultravoxPath,ultravoxName),'r');
chars = fscanf(fin,'%c');
chars(1:2) = [];
chars(chars == 0) = [];
chars = strrep(chars,',','.');
fin2 = fopen(fullfile(ultravoxPath,'temp.txt'),'w');
fwrite(fin2, chars, 'uchar');
fclose('all');

% Read file as a table
ultravox = readtable(fullfile(ultravoxPath,'temp.txt'),'Delimiter',';','ReadVariableNames',1,'HeaderLines',0);

% The Ultravox table only contains the frequency at max amplitude, so we
% need to specify the bandwidth.
CallBandwidth = inputdlg('Enter call bandwidth (kHz), because Ultravox doesn''t include it in the output file ','Import from Ultravox', [1 50],{'30'});
if isempty(CallBandwidth); return; end
CallBandwidth = str2double(CallBandwidth);

audiodata = audioinfo(AudioFile);

Calls = struct('Box',struct,'Score',struct,'Accept',struct,'Type',struct,'Power',struct);
hc = waitbar(0,'Importing Calls from Ultravox Log');

for i=1:length(ultravox.Call)
    waitbar(i/length(ultravox.Call),hc);
    
    Calls(i).Box = [
        ultravox.StartTime_s_(i),...
        (ultravox.FreqAtMaxAmp_Hz_(i)/1000) - CallBandwidth / 2,...
        ultravox.StopTime_s_(i) - ultravox.StartTime_s_(i),...
        CallBandwidth];
    
    Calls(i).Score = 1;
    Calls(i).Accept = 1;
    Calls(i).Type = categorical(ultravox.PatternLabel(i));
    Calls(i).Power = 0;
end
close(hc);
Calls = struct2table(Calls);

[FileName, PathName] = uiputfile(fullfile(handles.data.settings.detectionfolder, '*.mat'), 'Save Call File');
filename = fullfile(PathName,FileName);

Calls = merge_boxes(Calls.Box, Calls.Score, Calls.Type, audiodata, 1, 0, 0);

h = waitbar(.9,'Saving Output Structures');
detectiontime = datestr(datetime('now'),'YYYY-MM-DD HH_MM PM');
save(filename,'Calls','audiodata','detectiontime','-v7.3');

close(h);

update_folders(hObject, eventdata, handles);
