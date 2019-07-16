% --------------------------------------------------------------------
function import_raven_Callback(hObject, eventdata, handles)
% Requires a Raven table and audio file.
% (http://www.birds.cornell.edu/brp/raven/RavenOverview.html)

%% Get the files
[ravenname,ravenpath] = uigetfile([handles.data.squeakfolder '/*.txt'],'Select Raven Log');
ravenTable = readtable([ravenpath ravenname], 'Delimiter', 'tab');
[audioname, audiopath] = uigetfile({'*.wav;*.wmf;*.flac;*.UVD' 'Audio File';'*.wav' 'WAV (*.wav)'; '*.wmf' 'WMF (*.wmf)'; '*.flac' 'FLAC (*.flac)'; '*.UVD' 'Ultravox File (*.UVD)'},'Select Audio File',handles.data.settings.audiofolder);

info = audioinfo([audiopath audioname]);
if info.NumChannels > 1
    warning('Audio file contains more than one channel. Use channel 1...')
end
samplerate = info.SampleRate;
hc = waitbar(0,'Importing Calls from Raven Log');

%% Get the data from the raven file
Rate   = repmat(samplerate, height(ravenTable),1);
Box    = [ravenTable.BeginTime_s_, ravenTable.LowFreq_Hz_/1000, ravenTable.DeltaTime_s_, (ravenTable.HighFreq_Hz_ - ravenTable.LowFreq_Hz_)/1000];
RelBox = [ravenTable.DeltaTime_s_, ravenTable.LowFreq_Hz_/1000, ravenTable.DeltaTime_s_, (ravenTable.HighFreq_Hz_ - ravenTable.LowFreq_Hz_)/1000];
Score  = ones(height(ravenTable),1);
Accept = ones(height(ravenTable),1);
Power  = zeros(height(ravenTable),1);

%% Get the classification from raven, from the variable 'Tags' or 'Annotation'
if ismember('Tags', ravenTable.Properties.VariableNames)
    Type = categorical(ravenTable.Tags);
elseif ismember('Annotation', ravenTable.Properties.VariableNames)
    Type = categorical(ravenTable.Annotation);
else
    Type = categorical(repmat({'USV'}, height(ravenTable), 1));
end

%% Load the audio for each call
WindL = ravenTable.BeginTime_s_ - ravenTable.DeltaTime_s_;
WindR = ravenTable.EndTime_s_   + ravenTable.DeltaTime_s_;
audioSamples = round([WindL WindR]*samplerate);
Audio = cell(height(ravenTable), 1);
for i=1:height(ravenTable)
        waitbar(i/height(ravenTable),hc);
        Audio(i) = {mergeAudio([audiopath audioname], audioSamples(i,:))};
end

%% Put all the variables into a table
Calls = table(Rate,Box,RelBox,Score,Audio,Accept,Type,Power,'VariableNames',{'Rate','Box','RelBox','Score','Audio','Accept','Type','Power'});


[~ ,name] = fileparts(audioname);
[FileName, PathName] = uiputfile(fullfile(handles.data.settings.detectionfolder, [name '.mat']),'Save Call File');
save([PathName,FileName],'Calls','-v7.3');
close(hc);
update_folders(hObject, eventdata, handles);
