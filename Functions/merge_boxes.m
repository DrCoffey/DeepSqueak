function Calls = merge_boxes(AllBoxes, AllScores, AllClass, AllPowers, audio_info, merge_in_frequency, score_cuttoff, pad_calls)
%% Merge overlapping boxes
% Sort the boxes by start time
[AllBoxes,index] = sortrows(AllBoxes);
AllScores=AllScores(index);
AllClass=AllClass(index);
AllPowers=AllPowers(index);

% Find all the boxes that overlap in time
OverBoxes=single(AllBoxes);

% Set frequency on all boxes to be equal, so that only time is considered
if merge_in_frequency
    OverBoxes(:,2)=1;
    OverBoxes(:,4)=1;
end

% Calculate overlap ratio
overlapRatio = bboxOverlapRatio(OverBoxes, OverBoxes);

% Merge all boxes with overlap ratio greater than 0.2 (Currently off)
OverlapMergeThreshold = .15;
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

Calls = table('Size',[length(begin_time), 14], 'VariableTypes',...
    {'double',...
    'double', 'double', 'double', 'double',...
    'double', 'double', 'double', 'double',...
    'double',...
    'cell',...
    'categorical',...
    'double',...
    'logical'},...
    'VariableNames',...
    {'Rate',...
    'Box1', 'Box2', 'Box3', 'Box4',...
    'RelBox1', 'RelBox2', 'RelBox3', 'RelBox4',...
    'Score',...
    'Audio',...
    'Type',...
    'Power',...
    'Accept'});
Calls = mergevars(Calls,{'Box1', 'Box2', 'Box3', 'Box4'},'NewVariableName','Box');
Calls = mergevars(Calls,{'RelBox1', 'RelBox2', 'RelBox3', 'RelBox4'},'NewVariableName','RelBox');

%% Create Output Table

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
    
    audio = audioread(audio_info.Filename,([WindL WindR]));
    audio = [pad; mean(audio - mean(audio,1) ,2)]; % Take the mean of the audio channels
    audio = int16(audio * 32767); % Convert to int16
    
    Calls(i,:) = {
        audio_info.SampleRate,...
        [begin_time(i), lower_freq(i), duration__(i), bandwidth_(i)],...
        [duration__(i), lower_freq(i), duration__(i), bandwidth_(i)],...
        call_score(i,:),...
        {audio},...
        call_Class(i),...
        call_power(i),...
        1,...
        };
end
