function  Calls=SqueakDetect(inputfile,networkfile,fname,Settings,currentFile,totalFiles,networkname)
% Find Squeaks
h = waitbar(0,'Initializing');

info = audioinfo(inputfile);
if info.SampleRate < (Settings(4)*1000)*2
    disp('Warning: Upper Range Above Samplng Frequency');
    Settings(4)=floor(info.SampleRate/2000);
end


% Get network and spectrogram settings
network=networkfile.detector;
wind=networkfile.wind;
noverlap=networkfile.noverlap;
nfft=networkfile.nfft;


% Adjust settings, so spectrograms are the same for different sample rates
wind = round(wind * info.SampleRate);
noverlap = round(noverlap * info.SampleRate);
nfft = round(nfft * info.SampleRate);

AllBoxes=[];
AllScores=[];
AllClass=[];
AllPowers=[]; 
c=0;
%Calls = struct('Rate',struct,'Box',struct,'RelBox',struct,'Score',struct,'Audio',struct,'Accept',struct,'Power',struct);

if Settings(1)>info.Duration
    time=info.Duration;
    disp([fname ' is shorter then the requested analysis duration. Only the first ' num2str(info.Duration) ' will be processed.'])
elseif Settings(1)==0
    time=info.Duration;
else
    time=Settings(1);
end
chunksize=Settings(2);
overlap=Settings(3);
score_cuttoff=Settings(6);

% spectrange = info.SampleRate / 2000; % get range of spectrogram in KHz
% upper_freq = round((spectrange - Settings(4)) * (1 + floor(nfft / 2)) / spectrange); % get upper limit
% lower_freq = round((spectrange - Settings(5)) * (1 + floor(nfft / 2)) / spectrange); % get upper limit


% Detect Calls
for i = 1:((time - overlap) / (chunksize - overlap))
    tic
    
    % Extract the audio chunk
    % For the first audio chunk, set the first sample to 1
    if i==1
        windL=1;
        windR=chunksize*info.SampleRate;
    else
        windL=windR  - (overlap*info.SampleRate);
        windR=windL + (chunksize*info.SampleRate);
    end
    
    % Read the audio
    audio = audioread(inputfile,floor([windL, windR]));
    if wind > length(audio)
        errordlg(['For this network, audio chucks must be at least ' num2str(networkfile.wind) ' seconds long.']);
        return
    end
    % Create the spectrogram
    [s,fr,ti] = spectrogram(audio,wind,noverlap,nfft,info.SampleRate,'yaxis');
    
    upper_freq = find(fr>=Settings(4)*1000,1);
    lower_freq = find(fr>=Settings(5)*1000,1);
    
    % Extract the region within the frequency range
    s = s(lower_freq:upper_freq,:);
    s = flip(abs(s),1);
    
    
    % Normalize gain setting
    med=median(s(:));
    im = mat2gray(s,[med*.1 med*30]);
    
    % Subtract the 5th percentile to remove horizontal noise bands
    %im = im - prctile(im,5,2);
    
    % Detect!
    try
        % Convert spectrogram to uint8 for detection, because network
        % is trained with uint8 images
        [bboxes, scores, Class] = detect(network, im2uint8(im), 'ExecutionEnvironment','auto','NumStrongestRegions',Inf,'Threshold',.5);
        
        % Calculate each call's power
        for j = 1:size(bboxes,1)
            AllPowers = [AllPowers
                max(max(...
                s(bboxes(j,2):bboxes(j,2)+bboxes(j,4)-1,bboxes(j,1):bboxes(j,3)+bboxes(j,1)-1)))];
        end
        
        bboxes(:,1) = ti(bboxes(:,1)) + (windL ./ info.SampleRate);
        bboxes(:,2) = fr(upper_freq - (bboxes(:,2) + bboxes(:,4))) ./ 1000;
        bboxes(:,3) = ti(bboxes(:,3));
        bboxes(:,4) = fr(bboxes(:,4)) ./ 1000;
        
        
        
        
        AllBoxes=[AllBoxes
            bboxes(Class == 'USV',:)];
        AllScores=[AllScores
            scores(Class == 'USV',:)];
        AllClass=[AllClass
            Class(Class == 'USV',:)];
        
    catch ME
        warning('Error in Network, Skiping Audio Chunk');
        disp(ME.message);
    end
    c=c+1;
    t=toc;
    waitbar(i/((time - overlap) / (chunksize - overlap)),h,sprintf(['Detection Speed: ' num2str((chunksize - overlap)/(t)) 'x  Call Fragments Found:' num2str(length(AllBoxes)) '\n File ' num2str(currentFile) ' of ' num2str(totalFiles)]));
end
close(h);


%% Merge overlapping boxes
% Sort the boxes by start time
[AllBoxes,index] = sortrows(AllBoxes);
AllScores=AllScores(index);
AllClass=AllClass(index);
AllPowers=AllPowers(index);

% Find all the boxes that overlap in time
% Set frequency on all boxes to be equal, so that only time is considered
OverBoxes=AllBoxes;
OverBoxes(:,2)=1;
OverBoxes(:,4)=1;

% Calculate overlap ratio
try
overlapRatio = bboxOverlapRatio(OverBoxes, OverBoxes);

% Merge all boxes with overlap ratio greater than 0.2
OverlapMergeThreshold = 0.;
overlapRatio(overlapRatio<OverlapMergeThreshold)=0;

% Create a graph with the connected boxes
g = graph(overlapRatio);


% Make new boxes from the minimum and maximum start and end time of each
% overlapping box.
componentIndices = conncomp(g);
begin_time = accumarray(componentIndices', AllBoxes(:,1), [], @min);
lower_freq = accumarray(componentIndices', AllBoxes(:,2), [], @min);
end_time__ = accumarray(componentIndices', AllBoxes(:,1)+AllBoxes(:,3), [], @max);
high_freq_ = accumarray(componentIndices', AllBoxes(:,2)+AllBoxes(:,4), [], @max);

merged_scores = accumarray(componentIndices', AllScores, [], @mean);
merged_powers = accumarray(componentIndices', AllPowers, [], @max);

[~, z2]=unique(componentIndices);
merged_Class = AllClass(z2);


call_duration = end_time__ - begin_time;
call_bandwidth = high_freq_ - lower_freq;

%% Make the boxes all a little bigger
timeExpansion = .1;
freqExpansion = .05;

begin_time = begin_time - call_duration.*timeExpansion;
end_time__ = end_time__ + call_duration.*timeExpansion;
lower_freq = lower_freq - call_bandwidth.*freqExpansion;
high_freq_ = high_freq_ + call_bandwidth.*freqExpansion;

% Don't let the calls leave the range of the audio
begin_time = max(begin_time,0.01);
end_time__ = min(end_time__,info.Duration);
lower_freq = max(lower_freq,1);
high_freq_ = min(high_freq_,info.SampleRate./2000 - 1);

call_duration = end_time__ - begin_time;
call_bandwidth = high_freq_ - lower_freq;
catch
errordlg('Why No Calls?');    
end

%% Create Output Structure
hc = waitbar(0,'Writing Output Structure');
if ~isempty(merged_scores)
    for i=1:length(begin_time)
        waitbar(i/length(begin_time),hc);
        
        %% Audio beginning and end time
        WindL=round((begin_time(i)-call_duration(i)) .* info.SampleRate);
        if WindL<=1
            pad=abs(WindL);
            WindL = 1;
        end
        
        WindR=round((end_time__(i)+call_duration(i)) .* info.SampleRate);
        WindR = min(WindR,info.TotalSamples); % Prevent WindR from being greater than total samples
        
        
        audio = audioread(inputfile,([WindL WindR]),'native');
        
        % Pad the audio if the call would be cut off
        if WindL==1
            pad=zeros(pad,1);
            audio=[pad; audio];
        end
        
        
        % box = [start time (s), low freq (Hz), duration (s), bandwidth (Hz)]
        % Final Structure
        Calls(i).Rate=info.SampleRate;
        Calls(i).Box=[begin_time(i), lower_freq(i), call_duration(i), call_bandwidth(i)];
        Calls(i).RelBox=[call_duration(i), lower_freq(i), call_duration(i), call_bandwidth(i)];
        Calls(i).Score=merged_scores(i,:);
        Calls(i).Audio=audio;
        Calls(i).Type=merged_Class(i);
        Calls(i).Power = merged_powers(i);
        
        % Acceptance
        if merged_scores(i,:)>score_cuttoff
            Calls(i).Accept=1;
        else
            Calls(i).Accept=0;
        end
        
    end
    
    try % Reject calls below the power threshold and combine 22s
        Calls = Calls([Calls.Accept] == 1);
        if contains(networkname,'long','IgnoreCase',true)
            Calls = SeperateLong22s_Callback([],[],[],inputfile,Calls);
        end
    catch ME
        disp(ME)
    end
    
    close(hc);
else
    Calls=[];
    close(hc);
end

