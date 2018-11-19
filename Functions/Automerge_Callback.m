function Calls = Automerge_Callback(Calls1,Calls2,AudioFile)
%% Merges two detection files into one

A = Calls1';
B=Calls2';
A=[A;B];

% Audio info
info = audioinfo(AudioFile);

%% Merge overlapping boxes
for i=1:length(A)
    AllBoxes(i,1:4)=A(i).Box;
    AllScores(i,1)=A(i).Score;
    AllRelBoxes(i,1:4)=A(i).RelBox;
    AllPower(i,1)=A(i).Power;
    AllAccept(i,1)=A(i).Accept;
end
xmin = AllBoxes(:,1);
ymin = AllBoxes(:,2);
xmax = xmin + AllBoxes(:,3) - 1;
ymax = ymin + AllBoxes(:,4) - 1;

overlapRatio = bboxOverlapRatio(AllBoxes, AllBoxes);
n = size(overlapRatio,1);
overlapRatio(1:n+1:n^2) = 0;
g = graph(overlapRatio);
componentIndices = conncomp(g);

xmin = accumarray(componentIndices', xmin, [], @min);
ymin = accumarray(componentIndices', ymin, [], @min);
xmax = accumarray(componentIndices', xmax, [], @max);
ymax = accumarray(componentIndices', ymax, [], @max);

[z1 z2 z3]=unique(componentIndices);
merged_boxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
merged_scores = accumarray(componentIndices', AllScores, [], @max);
merged_power = accumarray(componentIndices', AllPower, [], @max);
merged_accept = accumarray(componentIndices', AllAccept, [], @max);

% Re Make Call Structure
hc = waitbar(0,'Merging Output Structures');
for i=1:size(merged_boxes,1)
    waitbar(i/length(merged_boxes),hc);
    
    WindL=round((merged_boxes(i,1)-(merged_boxes(i,3)))*(info.SampleRate));
    if WindL<=1
        pad=abs(WindL);
        WindL = 1;
    end
    WindR=round((merged_boxes(i,1)+merged_boxes(i,3)+(merged_boxes(i,3)))*(info.SampleRate));
    WindR = min(WindR,info.TotalSamples); % Prevent WindR from being greater than total samples
    
    a = audioread(AudioFile,[WindL WindR],'native');

    
    if WindL==1;
        pad=zeros(pad,1);
        a=[pad
            a];
    end
    
    % Final Structure
    Calls(i).Rate=info.SampleRate;
    Calls(i).Box=merged_boxes(i,:);
    Calls(i).RelBox=[merged_boxes(i,3) merged_boxes(i,2) merged_boxes(i,3) merged_boxes(i,4)];
    Calls(i).Score=merged_scores(i);
    Calls(i).Audio=a;
    Calls(i).Type=1;
    Calls(i).Power=merged_power(i);
    Calls(i).Accept=merged_accept(i);
end

close(hc);
end
