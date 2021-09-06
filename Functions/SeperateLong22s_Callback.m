function NewCalls = SeperateLong22s_Callback(hObject, eventdata, handles, inputfile, Calls)
%% Get if clicked through menu, or using the long call network
if nargin == 3
    [trainingdata, trainingpath] = uigetfile([handles.data.settings.detectionfolder '/*.mat'],'Select Detection File','MultiSelect', 'off');
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
        }, ['Select Corresponding Audio File for ' trainingdata], handles.data.settings.audiofolder);

    inputfile = fullfile(audiopath, audioname);
    hc = waitbar(0,'Loading File');
    Calls = loadCallfile([trainingpath trainingdata],handles);

end

audiodata = audioinfo(inputfile);
if audiodata.NumChannels > 1
    warning('Audio file contains more than one channel. Use channel 1...')
end

newBoxes = [];
newScores = [];
newPower = [];


%% First, find all the overlapping calls

% Get the oldBoxes
oldBoxes = Calls.Box;

% Pad the oldBoxes so that all of the audio is contained within the box
oldBoxes(:,1) = oldBoxes(:,1) - 0.5;
oldBoxes(:,2) = oldBoxes(:,2) - 2.0;
oldBoxes(:,3) = oldBoxes(:,3) + 1.0;
oldBoxes(:,4) = oldBoxes(:,4) + 4.0;

% Calculate overlap ratio
overlapRatio = bboxOverlapRatio(oldBoxes, oldBoxes);

g = graph(overlapRatio);

% Make new oldBoxes from the minimum and maximum start and end time of each
% overlapping box.
componentIndices = conncomp(g);
begin_time = accumarray(componentIndices', oldBoxes(:,1), [], @min);
lower_freq = accumarray(componentIndices', oldBoxes(:,2), [], @min);
end_time__ = accumarray(componentIndices', oldBoxes(:,1)+oldBoxes(:,3), [], @max);
high_freq_ = accumarray(componentIndices', oldBoxes(:,2)+oldBoxes(:,4), [], @max);

merged_scores = accumarray(componentIndices', Calls.Score, [], @mean);

call_duration = end_time__ - begin_time;
call_bandwidth = high_freq_ - lower_freq;

%% Now, extract the spectrogram from each box, and find the calls within the box by using tonality
for i=1:length(begin_time)

    % If ran through the menu
    if nargin == 3
        waitbar(i/height(Calls),hc,'Splitting Calls');
    end

    % Get the audio
    WindL=round((begin_time(i)-0.1) .* audiodata.SampleRate);
    pad = [];
    if WindL<=1
        pad=zeros(abs(WindL),1);
        WindL = 1;
    end
    WindR=round((end_time__(i)+0.1) .* audiodata.SampleRate);
    WindR = min(WindR,audiodata.TotalSamples); % Prevent WindR from being greater than total samples

    audio = audioread(inputfile,[WindL WindR]); % Take channel 1
    audio = [pad; mean(audio - mean(audio,1),2)];

    % Make the spectrogram
    windowsize = round(audiodata.SampleRate * 0.02);
    noverlap = round(audiodata.SampleRate * 0.01);
    nfft = round(audiodata.SampleRate * 0.02);

    [s, fr, ti] = spectrogram(audio,windowsize,noverlap,nfft,audiodata.SampleRate,'yaxis');

    % Get the part of the spectrogram within the frequency bandwidth
    x1 = axes2pix(length(ti),ti,call_duration(i));
    x2 = axes2pix(length(ti),ti,call_duration(i));
    lowfreq = axes2pix(length(fr),fr./1000,lower_freq(i));
    hi_freq = axes2pix(length(fr),fr./1000,high_freq_(i));
    I = abs(s(round(lowfreq:hi_freq),:));
    % Calculate the entropy
    entropy = 1 - (geomean(I,1) ./ mean(I,1));

    % Tonality of the upper region
    I2 = abs(s(round(hi_freq:min(2*hi_freq-lowfreq,size(s,1))),:));
    UpperEntropy = 1 - (geomean(I2,1) ./ mean(I2,1));
    % Use MAD to estimate mean and sd of entropy
    EntropyMedian = median(UpperEntropy);
    EntropySD = 1.4826 * median(abs(EntropyMedian - UpperEntropy));

    CallRegions = entropy > EntropyMedian + EntropySD*3;
    %CallRegions = entropy > EntropyMedian + 0.1;
    % Calls must have continuously high tonality
    radius = find(ti>0.1,1);
    CallRegions = movmean(CallRegions,radius);

    CallRegions = [0, CallRegions, 0];
    startime = find(CallRegions(1:end-1) < 0.5 & CallRegions(2:end) >= 0.5);
    stoptime = find(CallRegions(1:end-1) >= 0.5 & CallRegions(2:end) < 0.5);

    newBoxes = [newBoxes
        ti(startime)' + (WindL ./ audiodata.SampleRate),...
        repmat(lower_freq(i),length(startime),1),...
        ti(stoptime - startime)',...
        repmat(high_freq_(i)-lower_freq(i),length(startime),1)];

    newScores = [newScores; repmat(merged_scores(i),length(startime),1)];
end

%%

% Now that we have new boxes of high tonality regions, exclude the new
% boxes that don't overlap with the old boxes.
overlapRatio = bboxOverlapRatio(newBoxes, oldBoxes);
OverlapsWithOld = any(overlapRatio,2);

% Re Make Call Structure
for i=1:size(newBoxes,1)
    if nargin == 3
        waitbar(i/length(newBoxes),hc,'Remaking Structure');
    end

    if ~OverlapsWithOld; continue; end


    % Final Structure
    NewCalls(i).Box=newBoxes(i,:);
    NewCalls(i).Score=newScores(i);
    NewCalls(i).Type=categorical({'USV'});
    NewCalls(i).Accept=1;

end
    NewCalls = struct2table(NewCalls);

if nargin == 3
    [FileName,PathName] = uiputfile(fullfile(handles.data.settings.detectionfolder,trainingdata),'Save Merged Detections');
    waitbar(i/length(newBoxes),hc,'Saving...');
    Calls = NewCalls;
    save(fullfile(PathName, FileName), 'Calls', 'audiodata', '-v7.3');
    update_folders(hObject, eventdata, handles);
    close(hc);
end
