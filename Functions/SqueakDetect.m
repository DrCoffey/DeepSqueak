function  Calls=SqueakDetect(inputfile,networkfile,fname,Settings,currentFile,totalFiles,networkname)
% Find Squeaks
h = waitbar(0,'Initializing');

% Get the audio info
info = audioinfo(inputfile);
SampleRate = info.SampleRate;
TotalSamples = info.TotalSamples;

% Get network and spectrogram settings
network=networkfile.detector;
wind=networkfile.wind;
noverlap=networkfile.noverlap;
nfft=networkfile.nfft;


% Adjust settings, so spectrograms are the same for different sample rates
wind = round(wind * SampleRate);
noverlap = round(noverlap * SampleRate);
nfft = round(nfft * SampleRate);

%% Get settings
% (1) Detection length (s)
if Settings(1)>info.Duration
    DetectLength=info.Duration;
    disp([fname ' is shorter then the requested analysis duration. Only the first ' num2str(info.Duration) ' will be processed.'])
elseif Settings(1)==0
    DetectLength=info.Duration;
else
    DetectLength=Settings(1);
end

% (2) Detection chunk size (s)
chunksize=Settings(2);

% (3) Overlap between chucks (s)
overlap=Settings(3);

% (4) High frequency cutoff (kHz)
if SampleRate < (Settings(4)*1000)*2
    disp('Warning: Upper Range Above Samplng Frequency');
    HighCutoff=floor(SampleRate/2000);
else
    HighCutoff = Settings(4);
end

% (5) Low frequency cutoff (kHz)
LowCutoff = Settings(5);

% (6) Score cutoff (kHz)
score_cuttoff=Settings(6);

%% Detect Calls
% Initialize variables
AllBoxes=[];
AllScores=[];
AllClass=[];
AllPowers=[];
Calls = [];

% Break the audio file into chunks
chunks = linspace(1,(DetectLength - overlap) * SampleRate,round(DetectLength / chunksize));
for i = 1:length(chunks)-1
    try
        DetectStart = tic;
        
        % Get the audio windows
        windL = chunks(i);
        windR = chunks(i+1) + overlap*SampleRate;
        
        % Read the audio
        audio = audioread(inputfile,floor([windL, windR]));
        
        % Create the spectrogram
        [s,fr,ti] = spectrogram(audio,wind,noverlap,nfft,SampleRate,'yaxis');
        
        upper_freq = find(fr>=HighCutoff*1000,1);
        lower_freq = find(fr>=LowCutoff*1000,1);
        
        % Extract the region within the frequency range
        s = s(lower_freq:upper_freq,:);
        s = flip(abs(s),1);
        
        % Normalize gain setting
        med=median(s(:));
        im = mat2gray(s,[med*.1 med*30]);
        
        % Subtract the 5th percentile to remove horizontal noise bands
        %im = im - prctile(im,5,2);
        
        % Detect!
        % Convert spectrogram to uint8 for detection, because network is trained with uint8 images.
        [bboxes, scores, Class] = detect(network, im2uint8(im), 'ExecutionEnvironment','auto','NumStrongestRegions',Inf);
        
        % Calculate each call's power
        Power = [];
        for j = 1:size(bboxes,1)
            Power = [Power
                max(max(...
                s(bboxes(j,2):bboxes(j,2)+bboxes(j,4)-1,bboxes(j,1):bboxes(j,3)+bboxes(j,1)-1)))];
        end
        
        % Convert boxes from pixels to time and kHz
        bboxes(:,1) = ti(bboxes(:,1)) + (windL ./ SampleRate);
        bboxes(:,2) = fr(upper_freq - (bboxes(:,2) + bboxes(:,4))) ./ 1000;
        bboxes(:,3) = ti(bboxes(:,3));
        bboxes(:,4) = fr(bboxes(:,4)) ./ 1000;
        
        
        % Concatinate the results
        AllBoxes=[AllBoxes
            bboxes(Class == 'USV',:)];
        AllScores=[AllScores
            scores(Class == 'USV',:)];
        AllClass=[AllClass
            Class(Class == 'USV',:)];
        AllPowers=[AllPowers
            Power(Class == 'USV',:)];
        
            t = toc(DetectStart);
            waitbar(...
                i/(length(chunks)-1),...
                h,...
                sprintf(['Detection Speed: ' num2str((chunksize - overlap) / t,'%.1f') 'x  Call Fragments Found:' num2str(length(AllBoxes)) '\n File ' num2str(currentFile) ' of ' num2str(totalFiles)]));
          
    catch ME
        waitbar(...
            i/(length(chunks)-1),...
            h,...
            sprintf(['Error in Network, Skiping Audio Chunk']));
        disp('Error in Network, Skiping Audio Chunk');
        warning( getReport( ME, 'extended', 'hyperlinks', 'on' ) );
    end
end
% Return is nothing was found
if isempty(AllScores); close(h); return; end

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

call_score = accumarray(componentIndices', AllScores, [], @mean);
call_power = accumarray(componentIndices', AllPowers, [], @max);

[~, z2]=unique(componentIndices);
call_Class = AllClass(z2);

duration__ = end_time__ - begin_time;
bandwidth_ = high_freq_ - lower_freq;

%% Do score cutoff
Accepted = call_score>score_cuttoff;
if ~any(Accepted); close(h); return; end
begin_time = begin_time(Accepted);
end_time__ = end_time__(Accepted);
lower_freq = lower_freq(Accepted);
high_freq_ = high_freq_(Accepted);
duration__ = duration__(Accepted);
bandwidth_ = bandwidth_(Accepted);
call_score = call_score(Accepted);
call_power = call_power(Accepted);
call_Class = call_Class(Accepted);


%% Make the boxes all a little bigger
timeExpansion = .1;
freqExpansion = .05;

begin_time = begin_time - duration__.*timeExpansion;
end_time__ = end_time__ + duration__.*timeExpansion;
lower_freq = lower_freq - bandwidth_.*freqExpansion;
high_freq_ = high_freq_ + bandwidth_.*freqExpansion;

% Don't let the calls leave the range of the audio
begin_time = max(begin_time,0.01);
end_time__ = min(end_time__,info.Duration);
lower_freq = max(lower_freq,1);
high_freq_ = min(high_freq_,SampleRate./2000 - 1);

duration__ = end_time__ - begin_time;
bandwidth_ = high_freq_ - lower_freq;

%% Create Output Structure
waitbar(.5,h,'Writing Output Structure');

for i = 1:length(begin_time)
    % Audio beginning and end time
    WindL=round((begin_time(i)-duration__(i)) .* SampleRate);
    
    % If the call starts at the very beginning of the file, pad the audio with zeros
    pad = [];
    if WindL<=1
        pad=zeros(abs(WindL),1);
        WindL = 1;
    end
    
    WindR=round((end_time__(i)+duration__(i)) .* SampleRate);
    WindR = min(WindR,TotalSamples); % Prevent WindR from being greater than total samples
    
    audio = audioread(inputfile,([WindL WindR]),'native');
    audio=[pad; audio];
    
    Calls(i).Rate=SampleRate;
    Calls(i).Box=[begin_time(i), lower_freq(i), duration__(i), bandwidth_(i)];
    Calls(i).RelBox=[duration__(i), lower_freq(i), duration__(i), bandwidth_(i)];
    Calls(i).Score=call_score(i,:);
    Calls(i).Audio=audio;
    Calls(i).Type=call_Class(i);
    Calls(i).Power = call_power(i);
    Calls(i).Accept=1;
end

% Merge long 22s if detected with a long 22 network
if contains(networkname,'long','IgnoreCase',true)
    try
        Calls = SeperateLong22s_Callback([],[],[],inputfile,Calls);
    catch ME
        disp(ME)
    end
end
close(h);
end
