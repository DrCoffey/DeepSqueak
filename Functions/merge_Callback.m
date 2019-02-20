function merge_Callback(hObject, eventdata, handles)

cd(handles.squeakfolder);
[detectionFilename, detectionFilepath] = uigetfile([handles.settings.detectionfolder '/*.mat'],'Select Detection File(s) for Merging','MultiSelect', 'on');
if isnumeric(detectionFilename); return; end

[audiodata, audiopath] = uigetfile({'*.wav;*.wmf;*.flac;*.UVD' 'Audio File';'*.wav' 'WAV (*.wav)'; '*.wmf' 'WMF (*.wmf)'; '*.flac' 'FLAC (*.flac)'; '*.UVD' 'Ultravox File (*.UVD)'},'Select Corresponding Audio File',handles.settings.audiofolder);
if isnumeric(audiodata); return; end

hc = waitbar(0,'Merging Output Structures');

cd(handles.squeakfolder);
detectionFilename = cellstr(detectionFilename);


AllBoxes = [];
AllScores = [];
AllClass = [];
AllPower = [];
AllAccept = [];

for j = 1:length(detectionFilename)
    load(fullfile(detectionFilepath,detectionFilename{j}),'Calls');
    AllBoxes = [AllBoxes; vertcat(Calls.Box)];
    AllScores = [AllScores; vertcat(Calls.Score)];
    AllClass = [AllClass; vertcat(Calls.Type)];
    AllPower = [AllPower; vertcat(Calls.Power)];
    AllAccept = [AllAccept; vertcat(Calls.Accept)];
end

% Audio info
audio_info = audioinfo([audiopath audiodata]);
if audio_info.NumChannels > 1
    warning('Audio file contains more than one channel. Use channel 1...')
end

clear('Calls')
%% Merge overlapping boxes
waitbar(.5,hc,'Writing Output Structure');
Calls = merge_boxes(AllBoxes, AllScores .* AllAccept, AllClass, AllPowers, audio_info, 0, 0.1, 0)



[FileName,PathName] = uiputfile(fullfile(handles.settings.detectionfolder, '*.mat'),'Save Merged Detections');
waitbar(i/length(merged_boxes),hc,'Saving...');
save(fullfile(PathName,FileName),'Calls','-v7.3');
update_folders(hObject, eventdata, handles);
close(hc);

