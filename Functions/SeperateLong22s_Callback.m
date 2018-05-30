function SeperateLong22s_Callback(hObject, eventdata, handles)

[trainingdata, trainingpath] = uigetfile([handles.settings.detectionfolder '\*.mat'],'Select Detection File','MultiSelect', 'off');
[audiodata, audiopath] = uigetfile({'*.wav;*.flac;*.UVD' 'Audio File';'*.wav' 'WAV(*.wav)'; '*.flac' 'FLAC (*.flac)'; '*.UVD' 'Ultravox File (*.UVD)'},['Select Corresponding Audio File for ' trainingdata],handles.settings.audiofolder);
info = audioinfo([audiopath audiodata]);

hc = waitbar(0,'Loading File');

load([trainingpath trainingdata],'Calls');

newBoxes = [];
newScores = [];
newPower = [];
newAccept = [];

for i=1:length(Calls)
    
    
    waitbar(i/length(Calls),hc,'Splitting Calls'); 

    
    
    WindL=round((Calls(i).Box(1)-(Calls(i).Box(3)))*(info.SampleRate));
    if WindL<=0
        pad=abs(WindL);
        WindL = 1;
    end
    WindR=round((Calls(i).Box(1)+Calls(i).Box(3)+(Calls(i).Box(3)))*(info.SampleRate));
    audio = audioread([audiopath audiodata],[WindL WindR]);
    if WindL==1;
        pad=zeros(pad,1);
        audio=[pad
            audio];
    end
    
    
    
    windowsize = round(info.SampleRate * 0.01);
    noverlap = round(info.SampleRate * 0.005);
    nfft = round(info.SampleRate * 0.01);
    
    [s, fr, ti] = spectrogram(audio,windowsize,noverlap,nfft,info.SampleRate,'yaxis');
    
    x1 = axes2pix(length(ti),ti,Calls(i).Box(3));
    x2 = axes2pix(length(ti),ti,Calls(i).Box(3));
    y1 = axes2pix(length(fr),fr./1000,Calls(i).Box(2)-5);
    y2 = axes2pix(length(fr),fr./1000,Calls(i).Box(4)+5);
    
    
    I = (abs(s(round(y1:y1+y2),:)));
    
    signal2noise = geomean(I,1) ./ mean(I,1);
    
    [kmean, C] = kmeans(signal2noise',2);
    [~,ind] = min(C);
    CallRegions = (kmean==ind);
    
    
    radius = find(ti>0.025,1);
    dist = zeros(length(kmean));
    for k = 1:length(kmean)
        r = max(1,k-radius):min(length(kmean),k+radius);
        if  mean(CallRegions(r)) > .75;
            dist(r,r) = 1;
        end
    end
    
    G = graph(dist);
    callBins = conncomp(G,'OutputForm','cell');
    newBox = [];
    for bins = 1:length(callBins)
        if length(callBins{bins}) < 3
            continue
        end
        Call = callBins{bins};
        if ((Call(end) > x1) && (Call(end) < x1+x2)) || (Call(1) > x1) && (Call(1) < x1+x2); % if contained in original box
            newBox(1) = (WindL / info.SampleRate) + ti(Call(1));
            newBox(2) = Calls(i).Box(2);
            newBox(3) = ti(Call(end)) -  ti(Call(1));
            newBox(4) = Calls(i).Box(4);
            
            newBoxes(end+1,:) = newBox;
            newScores(end+1,:) = Calls(i).Score;
            newPower(end+1,:) = Calls(i).Power;
            newAccept(end+1,:) = Calls(i).Accept;
        end
    end
    if isempty(newBox)
        newBoxes(end+1,:) = Calls(i).Box;
        newScores(end+1,:) = Calls(i).Score;
        newPower(end+1,:) = Calls(i).Power;
        newAccept(end+1,:) = Calls(i).Accept;
    end
    
end

xmin = newBoxes(:,1);
ymin = newBoxes(:,2);
xmax = xmin + newBoxes(:,3) - 1;
ymax = ymin + newBoxes(:,4) - 1;

overlapRatio = bboxOverlapRatio(newBoxes, newBoxes);
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
merged_scores = accumarray(componentIndices', newScores, [], @max);
merged_power = accumarray(componentIndices', newPower, [], @max);
merged_accept = accumarray(componentIndices', newAccept, [], @max);


% Re Make Call Structure
for i=1:length(merged_boxes)
waitbar(i/length(merged_boxes),hc,'Remaking Structure'); 

WindL=round((merged_boxes(i,1)-(merged_boxes(i,3)))*(info.SampleRate));
if WindL<=1
    pad=abs(WindL);
    WindL = 1;
end
WindR=round((merged_boxes(i,1)+merged_boxes(i,3)+(merged_boxes(i,3)))*(info.SampleRate));
a = audioread([audiopath audiodata],[WindL WindR],'native');
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
Calls(i).Type=categorical({'USV'});
Calls(i).Power=merged_power(i);
Calls(i).Accept=merged_accept(i);
end

[FileName,PathName,FilterIndex] = uiputfile([handles.settings.detectionfolder '/*.mat'],'Save Merged Detections');
waitbar(i/length(merged_boxes),hc,'Saving...'); 
save([PathName,FileName],'Calls','-v7.3');
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles
close(hc);