function merge_Callback(hObject, eventdata, handles)

cd(handles.data.squeakfolder);
[detectionFilename, detectionFilepath] = uigetfile([handles.data.settings.detectionfolder '/*.mat'],'Select Detection File(s) for Merging','MultiSelect', 'on');
if isnumeric(detectionFilename); return; end

[audiodata, audiopath] = uigetfile({'*.wav;*.wmf;*.flac;*.UVD' 'Audio File';'*.wav' 'WAV (*.wav)'; '*.wmf' 'WMF (*.wmf)'; '*.flac' 'FLAC (*.flac)'; '*.UVD' 'Ultravox File (*.UVD)'},'Select Corresponding Audio File',handles.data.settings.audiofolder);
if isnumeric(audiodata); return; end

hc = waitbar(0,'Merging Output Structures');

cd(handles.data.squeakfolder);
detectionFilename = cellstr(detectionFilename);


AllBoxes = [];
AllScores = [];
AllClass = [];
AllPower = [];
AllAccept = [];

for j = 1:length(detectionFilename)
    Calls = handles.data.loadCalls(fullfile(detectionFilepath, detectionFilename{j}));
    
    AllBoxes = [AllBoxes; Calls.Box];
    AllScores = [AllScores; Calls.Score];
    AllClass = [AllClass; Calls.Type];
    AllPower = [AllPower; Calls.Power];
    AllAccept = [AllAccept; Calls.Accept];
end

% Audio info
audio_info = audioinfo([audiopath audiodata]);
if audio_info.NumChannels > 1
    warning('Audio file contains more than one channel. Use channel 1...')
end

clear('Calls')
%% Merge overlapping boxes
waitbar(.5,hc,'Writing Output Structure');
Calls = merge_boxes(AllBoxes, AllScores .* AllAccept, AllClass, AllPower, audio_info, 1, 0, 0);

[FileName, PathName] = uiputfile(fullfile(handles.data.settings.detectionfolder, '*.mat'), 'Save Merged Detections');
waitbar(1/2, hc, 'Saving...');
save(fullfile(PathName, FileName),'Calls','-v7.3');
update_folders(hObject, eventdata, handles);
close(hc);

