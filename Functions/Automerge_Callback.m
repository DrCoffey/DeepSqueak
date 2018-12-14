function Calls = Automerge_Callback(Calls1,Calls2,AudioFile)
%% Merges two detection files into one

Calls1=[Calls1';Calls2'];

% Audio info
info = audioinfo(AudioFile);

%% Merge overlapping boxes
AllBoxes = vertcat(Calls1.Box);
AllScores = vertcat(Calls1.Score);
AllPower = vertcat(Calls1.Power);
AllAccept = vertcat(Calls1.Accept);

% Sort the boxes by start time
[AllBoxes,index] = sortrows(AllBoxes);
AllScores=AllScores(index);
AllPower=AllPower(index);

% Create a graph with the connected boxes
overlapRatio = bboxOverlapRatio(AllBoxes, AllBoxes);
g = graph(overlapRatio);

% Make new boxes from the minimum and maximum start and end time of each
% overlapping box.
componentIndices = conncomp(g);
begin_time = accumarray(componentIndices', AllBoxes(:,1), [], @min);
lower_freq = accumarray(componentIndices', AllBoxes(:,2), [], @min);
end_time__ = accumarray(componentIndices', AllBoxes(:,1)+AllBoxes(:,3), [], @max);
high_freq_ = accumarray(componentIndices', AllBoxes(:,2)+AllBoxes(:,4), [], @max);

call_duration = end_time__ - begin_time;
call_bandwidth = high_freq_ - lower_freq;


merged_scores = accumarray(componentIndices', AllScores, [], @max);
merged_power = accumarray(componentIndices', AllPower, [], @max);
merged_accept = accumarray(componentIndices', AllAccept, [], @max);



% Re Make Call Structure
hc = waitbar(0,'Merging Output Structures');
for i=1:size(begin_time,1)
    waitbar(i/length(begin_time),hc);
    
    WindL=round((begin_time(i)-call_duration(i)) .* info.SampleRate);
    if WindL<=1
        pad=abs(WindL);
        WindL = 1;
    end
    
    WindR=round((end_time__(i)+call_duration(i)) .* info.SampleRate);
    WindR = min(WindR,info.TotalSamples); % Prevent WindR from being greater than total samples
    
    a = audioread(AudioFile,[WindL WindR],'native');
    
    
    % Pad the audio if the call would be cut off
    if WindL==1
        pad=zeros(pad,1);
        audio=[pad; audio];
    end
    
    % Final Structure
    Calls(i).Rate=info.SampleRate;
    Calls(i).Box=[begin_time(i), lower_freq(i), call_duration(i), call_bandwidth(i)];
    Calls(i).RelBox=[call_duration(i), lower_freq(i), call_duration(i), call_bandwidth(i)];
    Calls(i).Score=merged_scores(i);
    Calls(i).Audio=a;
    Calls(i).Type=categorical({'USV'});
    Calls(i).Power=merged_power(i);
    Calls(i).Accept=merged_accept(i);
end

close(hc);
end
