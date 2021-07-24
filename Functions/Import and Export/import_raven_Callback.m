% --------------------------------------------------------------------
function import_raven_Callback(hObject, eventdata, handles)
% Requires a Raven table and audio file.
% (http://www.birds.cornell.edu/brp/raven/RavenOverview.html)

%% Get the files
[ravenname,ravenpath] = uigetfile([handles.data.squeakfolder '/*.txt'],'Select Raven Log');
ravenTable = readtable([ravenpath ravenname], 'Delimiter', 'tab');
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

audiodata = audioinfo([audiopath audioname]);
if audiodata.NumChannels > 1
    warning('Audio file contains more than one channel. Use channel 1...')
end
hc = waitbar(0,'Importing Calls from Raven Log');

% fix some compatibility issues with Raven's naming
if ~ismember('DeltaTime_s_', ravenTable.Properties.VariableNames)
    ravenTable.DeltaTime_s_ = ravenTable.EndTime_s_ - ravenTable.BeginTime_s_;
end

%% Get the data from the raven file
Box    = [ravenTable.BeginTime_s_, ravenTable.LowFreq_Hz_/1000, ravenTable.DeltaTime_s_, (ravenTable.HighFreq_Hz_ - ravenTable.LowFreq_Hz_)/1000];
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


%% Put all the variables into a table
Calls = table(Box,Score,Accept,Type,Power,'VariableNames',{'Box','Score','Accept','Type','Power'});


[~ ,name] = fileparts(audioname);
[FileName, PathName] = uiputfile(fullfile(handles.data.settings.detectionfolder, [name '.mat']),'Save Call File');
save([PathName,FileName],'Calls', 'audiodata','-v7.3');
close(hc);
update_folders(hObject, eventdata, handles);
