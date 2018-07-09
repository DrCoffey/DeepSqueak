function  Calls=SqueakDetect(inputfile,networkfile,fname,Settings,include_date,savefile,currentFile,totalFiles,networkname)
% Find Squeaks
if ~exist('include_date');
    include_date = 1;
end

if ~exist('savefile');
    savefile = 1;
end

info = audioinfo(inputfile);
if info.SampleRate ~= 250000
    disp('Warning: DeepSqueak was designed for sample rates of 250KHz')
end


% Get network and spectrogram settings
network=networkfile.detector;
wind=networkfile.wind;
noverlap=networkfile.noverlap;
nfft=networkfile.nfft;
cont=networkfile.cont;

% Adjust settings, so spectrograms are the same for different sample rates
wind = round(wind * info.SampleRate);
noverlap = round(noverlap * info.SampleRate);
nfft = round(nfft * info.SampleRate);

AllBoxes=[];
AllScores=[];
AllClass=[];
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
sensitivity=Settings(6);
powerthresh=Settings(7);

spectrange = info.SampleRate / 2000; % get range of spectrogram in KHz
upper = round((spectrange - Settings(4)) * (1 + floor(nfft / 2)) / spectrange); % get upper limit
lower = round((spectrange - Settings(5)) * (1 + floor(nfft / 2)) / spectrange); % get upper limit


% Detect Calls
h = waitbar(0,'Initializing');
for i = 1:((time - overlap) / (chunksize - overlap))
    tic
    if i==1
        windL=1;
        windR=chunksize*info.SampleRate;
    else
        windL=windR  - (overlap*info.SampleRate);
        windR=windL + (chunksize*info.SampleRate);
    end
    % a = gpuArray(audioread(inputfile,[windL windR]));
    a = (audioread(inputfile,[windL windR]));
    if wind > length(a)
        errordlg(['For this network, audio chucks must be at least ' num2str(networkfile.wind) ' seconds long.']);
        return
    end
    s = spectrogram((a),wind,noverlap,nfft,info.SampleRate,'yaxis');
    pixels = length(s);
    % G = gpuArray(s);
    % s = mat2gray(flipud(abs(s)),[0 cont]);
    
    s=flipud(abs(s));
    if i==1
        low=prctile(s(:),7.5);
    end
    % s = mat2gray(s,[0 cont]);
    s = mat2gray(s,[low cont]);
    s = s(upper:lower,:);
    try
        if contains(version,'2018')
            [bboxes, scores, Class] = detect(network, s*255, 'ExecutionEnvironment','auto'); % Don't know why it needs this
        else
            [bboxes, scores, Class] = detect(network, s, 'ExecutionEnvironment','auto'); % Detect!
        end
        
        bboxes(:,2)=bboxes(:,2)+upper;
        bboxes(:,1)=bboxes(:,1)+round(c*(pixels*(1-(overlap/chunksize))));
        [bboxes(:,1),idex] = sort(bboxes(:,1),'ascend');
        bboxes(:,2)=bboxes(idex,2);
        bboxes(:,3)=bboxes(idex,3);
        bboxes(:,4)=bboxes(idex,4);
        scores=scores(idex);
        Class=Class(idex);
        AllBoxes=[AllBoxes
            bboxes(Class == 'USV',:)];
        AllScores=[AllScores
            scores(Class == 'USV',:)];
        AllClass=[AllClass
            Class(Class == 'USV',:)];
    catch
        warning('Error in Network, Skiping Audio Chunk');
    end
    c=c+1;
    t=toc;
    waitbar(i/((time - overlap) / (chunksize - overlap)),h,sprintf(['Detection Speed: ' num2str((chunksize - overlap)/(t)) 'x  Call Fragments Found:' num2str(length(AllBoxes)) '\n File ' num2str(currentFile) ' of ' num2str(totalFiles)]));
end
close(h);

%% Merge overlapping boxes
OverBoxes=AllBoxes;
OverBoxes(:,2)=1;
OverBoxes(:,4)=100;
xmin = AllBoxes(:,1);
ymin = AllBoxes(:,2);
xmax = xmin + AllBoxes(:,3) - 1;
ymax = ymin + AllBoxes(:,4) - 1;
overlapRatio = bboxOverlapRatio(OverBoxes, OverBoxes);
n = size(overlapRatio,1);
overlapRatio(1:n+1:n^2) = 0;
% overlapRatio(overlapRatio<.2)=0; Change Overlap Ratio Acceptance
g = graph(overlapRatio);
componentIndices = conncomp(g);
xmin = accumarray(componentIndices', xmin, [], @min);
ymin = accumarray(componentIndices', ymin, [], @min);
xmax = accumarray(componentIndices', xmax, [], @max);
ymax = accumarray(componentIndices', ymax, [], @max);
merged_scores = accumarray(componentIndices', AllScores, [], @max);
merged_boxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
[z1 z2 z3]=unique(componentIndices);
merged_Class = AllClass(z2);

%% Create Output Structure
thresholdBoxes = merged_boxes;
thresholdScores = merged_scores;
hc = waitbar(0,'Writing Output Structure');
if ~isempty(thresholdScores)
    for i=1:size(thresholdBoxes,1)
        waitbar(i/length(thresholdBoxes),hc);
        frames = ((chunksize)*info.SampleRate)/pixels;
        WindL=round((thresholdBoxes(i,1)-(thresholdBoxes(i,3)))*frames);
        if WindL<=0
            pad=abs(WindL);
            WindL = 1;
        end
        WindR=round((thresholdBoxes(i,1)+thresholdBoxes(i,3)+(thresholdBoxes(i,3)))*frames);
        WindR = min(WindR,info.TotalSamples); % Prevent WindR from being greater than total samples
        a = audioread(inputfile,[WindL WindR],'native');
        if WindL==1;
            pad=zeros(pad,1);
            a=[pad
                a];
        end
        CallAudio = a;
        
        if ~isa(a,'double')
            tmp_a = a;
            a = double(tmp_a) / (double(intmax(class(tmp_a)))+1);
        end
        
        
        
        [sn,fr,ti] = spectrogram(a,wind,noverlap,nfft,info.SampleRate,'yaxis');
        ffr=flipud(fr);
        
        
        % Final Structure
        Calls(i).Rate=info.SampleRate;
        Calls(i).Box=[ti(thresholdBoxes(i,3)) + WindL/250000,...
            ((ffr(thresholdBoxes(i,2)+thresholdBoxes(i,4))))/1000,...
            ti(thresholdBoxes(i,3)),...
            fr(thresholdBoxes(i,4))/1000];
        Calls(i).RelBox=[ti(thresholdBoxes(i,3)) ((ffr(thresholdBoxes(i,2)+thresholdBoxes(i,4))))/1000 ti(thresholdBoxes(i,3)) fr(thresholdBoxes(i,4))/1000];
        Calls(i).Score=thresholdScores(i,:);
        Calls(i).Audio=a;
        Calls(i).Type=merged_Class(i);
        
        % Power
        x1=find(ti>=Calls(i).RelBox(1),1);
        x2=find(ti>=Calls(i).RelBox(1)+Calls(i).RelBox(3),1);
        y1=find(fr./1000>=round(Calls(i).RelBox(2)),1);
        y2=find(fr./1000>=round(Calls(i).RelBox(2)+Calls(i).RelBox(4)),1);
        I=abs(sn(y1:y2,x1:x2));
        [max_amp ind] = max(max(I,[],2));
        Calls(i).Power=max_amp;
        
        % Acceptance
        if thresholdScores(i,:)>sensitivity
            Calls(i).Accept=1;
        else
            Calls(i).Accept=0;
        end
        
        
        % For the long call network, remove calls with tonality < 0.5
        if contains(networkname,'long','IgnoreCase',true)
            EntropyThreshold = 0.3;
            AmplitudeThreshold = 0.15;
            stats = CalculateStats(I,wind,noverlap,nfft,Calls(i).Rate,Calls(i).Box,EntropyThreshold,AmplitudeThreshold,0);
            if (stats.SignalToNoise > .4) & stats.DeltaTime > .2;
                Calls(i).Accept=1;
            else
                Calls(i).Accept=0;
            end
        end
            
            
            
    end
    
    try 
    Calls = Calls([Calls.Power] > powerthresh);
    Calls = Calls([Calls.Accept] == 1);
    
    if contains(networkname,'long','IgnoreCase',true)
        Calls = SeperateLong22s_Callback([],[],[],inputfile,Calls);
    end
    
    catch ME
        disp(ME)
    end
    
    if savefile == 1;
        if include_date == 1;
            t=datestr(datetime('now'),'mmm-DD-YYYY HH_MM PM');
            waitbar(.5,hc,'Saving Output Structure');
            save([strtok(fname,'.') ' ' t],'Calls','-v7.3');
        else
            waitbar(.5,hc,'Saving Output Structure');
            save([strtok(fname,'.')],'Calls','-v7.3');
        end
    end
    close(hc);
else
    Calls=[];
    close(hc);
end

