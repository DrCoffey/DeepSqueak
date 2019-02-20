function Calls = merge_boxes(AllBoxes, AllScores, AllClass, AllPowers, audio_info, merge_in_frequency, score_cuttoff, pad_calls)
Calls = [];
%% Merge overlapping boxes
% Sort the boxes by start time
[AllBoxes,index] = sortrows(AllBoxes);
AllScores=AllScores(index);
AllClass=AllClass(index);
AllPowers=AllPowers(index);

% Find all the boxes that overlap in time
OverBoxes=AllBoxes;

% Set frequency on all boxes to be equal, so that only time is considered
if merge_in_frequency
    OverBoxes(:,2)=1;
    OverBoxes(:,4)=1;
end

% Calculate overlap ratio
overlapRatio = bboxOverlapRatio(OverBoxes, OverBoxes);

% Merge all boxes with overlap ratio greater than 0.2 (Currently off)
OverlapMergeThreshold = 0;
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
if pad_calls
    timeExpansion = .1;
    freqExpansion = .05;

    begin_time = begin_time - duration__.*timeExpansion;
    end_time__ = end_time__ + duration__.*timeExpansion;
    lower_freq = lower_freq - bandwidth_.*freqExpansion;
    high_freq_ = high_freq_ + bandwidth_.*freqExpansion;
end

% Don't let the calls leave the range of the audio
begin_time = max(begin_time,0.01);
end_time__ = min(end_time__,audio_info.Duration);
lower_freq = max(lower_freq,1);
high_freq_ = min(high_freq_,audio_info.SampleRate./2000 - 1);

duration__ = end_time__ - begin_time;
bandwidth_ = high_freq_ - lower_freq;

%% Create Output Structure

for i = 1:length(begin_time)
    % Audio beginning and end time
    WindL=round((begin_time(i)-duration__(i)) .* audio_info.SampleRate);
    
    % If the call starts at the very beginning of the file, pad the audio with zeros
    pad = [];
    if WindL<=1
        pad=zeros(abs(WindL),1);
        WindL = 1;
    end
    
    WindR=round((end_time__(i)+duration__(i)) .* audio_info.SampleRate);
    WindR = min(WindR,audio_info.TotalSamples); % Prevent WindR from being greater than total samples
    
    audio = audioread(audio_info.Filename,([WindL WindR]),'native');
    audio=[pad; audio(:,1)]; % Just use the first audio channel
    
    Calls(i).Rate=audio_info.SampleRate;
    Calls(i).Box=[begin_time(i), lower_freq(i), duration__(i), bandwidth_(i)];
    Calls(i).RelBox=[duration__(i), lower_freq(i), duration__(i), bandwidth_(i)];
    Calls(i).Score=call_score(i,:);
    Calls(i).Audio=audio;
    Calls(i).Type=call_Class(i);
    Calls(i).Power = call_power(i);
    Calls(i).Accept=1;
end
