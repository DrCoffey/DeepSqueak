function UnsupervisedClustering_Callback(hObject, eventdata, handles)
% Cluster with k-means or adaptive

% Get the data
[ClusteringData] = CreateClusteringData(hObject, eventdata, handles);

[FileName,PathName] = uiputfile('Extracted Contours.mat','Save contours for faster loading');
if FileName ~= 0
    save([PathName FileName],'ClusteringData');
end

clustAssign = zeros(size(ClusteringData,1),1);

finished = 0; % Repeated until
while ~finished
    choice = questdlg('Choose clustering method:','Cluster','ARTwarp','K-means (recommended)','Cancel','Cancel');
    
    
    switch choice
        case 'Cancel'
            return
            
        case 'K-means (recommended)'
            
            prompt = {'Slope Weight','Sinuosity Weight','Frequency Weight','Duration Weight'};
            dlg_title = 'K-Means';
            num_lines = [1 50];
            defaultans = {'1','1','1','1'};
            settings = inputdlg(prompt,dlg_title,num_lines,defaultans);
            if isempty(settings)
                return
            end
            
            SlopeW = sscanf(settings{1},'%f',1);
            SinuosityW = sscanf(settings{2},'%f',1);
            FreqW = sscanf(settings{3},'%f',1);
            DurationW = sscanf(settings{4},'%f',1);
            
            hb = waitbar(0,'Preparing Data');
            %% Prepare Data by breaking each line into chunks, and calculating the slope, sinuosity, and frequency of each chunk.
            SlopeChunks = 6; % Number of chunks
            Slope = zeros(size(ClusteringData,1),SlopeChunks);
            
            SinuosityChunks = 2; % Number of chunks
            Sinuosity =  zeros(size(ClusteringData,1),SinuosityChunks);
            
            FrequencyChunks = 6; % Number of chunks
            Freq = zeros(size(ClusteringData,1),FrequencyChunks);
            
            for i = 1:size(ClusteringData,1)
                if mod(i,50) == 1;
                    waitbar(i/size(ClusteringData,1),hb)
                end
                
                if ClusteringData{i,3} < 0.4
                    
                    xFreq = ClusteringData{i,4}; % Frquency of current line
                    xTime = ClusteringData{i,5} * 1000; % Time of current line
                    
                    % Make sure each chunk has at least 2 points
                    if length(xFreq) < 2*SinuosityChunks
                        xFreq = imresize(xFreq,[2*SinuosityChunks 1]);
                        xTime = imresize(xTime,[1 2*SinuosityChunks]) ;
                    end
                    
                    
                    %% Slope
                    tmpSlope = [];
                    chunk = discretize(1:length(xTime),SlopeChunks);  % Break into chunks
                    for j = 1:SlopeChunks
                        X = [ones(length(xFreq(chunk==j)),1), xTime(chunk==j)'];
                        ls = X \ log2(xFreq(chunk==j));
                        tmpSlope = [tmpSlope, ls(2)];
                    end
                    Slope(i,:) =  tmpSlope;
                    
                    %% Sinuosity
                    tmpSinuosity = [];
                    chunk = discretize(1:length(xTime),SinuosityChunks);  % Break into chunks
                    for j = 1:SinuosityChunks
                        totleng = [];
                        D = pdist([xTime(chunk==j)' xFreq(chunk==j)],'Euclidean');
                        Z = squareform(D);
                        leng=Z(1,end);
                        c=0;
                        for ll=2:length(Z)
                            c=c+1;
                            totleng(c)=Z(ll-1,ll);
                        end
                        tmpSinuosity = [tmpSinuosity, sum(totleng)/leng];
                    end
                    Sinuosity(i,:) = tmpSinuosity;
                    
                    %% Frequency
                    tmpFreq = [];
                    chunk = discretize(1:length(xTime),FrequencyChunks);  % Break into chunks
                    for j = 1:FrequencyChunks
                        tmpFreq = [tmpFreq, mean(xFreq(chunk==j))];
                    end
                    Freq(i,:) = tmpFreq;
                    
                end
            end
            Duration = cell2mat(ClusteringData(:,3));
            
            Slope = SlopeW .* ((Slope - nanmean(Slope)) ./ nanstd(Slope));
            Sinuosity = SinuosityW .* ((Sinuosity - nanmean(Sinuosity)) ./ nanstd(Sinuosity));
            Freq = FreqW .* ((Freq - nanmean(Freq)) ./ nanstd(Freq));
            Duration = DurationW .* ((Duration - nanmean(Duration)) ./ nanstd(Duration));
            
            data = [Slope, Sinuosity, Freq, Duration]; % Concatenate data for clustering
            
            km = questdlg('From existing model?','Cluster','Yes','No','No');
            switch km% Load Model
                case 'No'
                    k = inputdlg({'Choose number of k-means:'},'Cluster with k-means',1,{'15'});
                    if isempty(k)
                        return
                    end
                    k = str2num(k{1});
                    [clustAssign, C]= kmeans(data,k,'Distance','sqeuclidean','Replicates',50);
                    [FileName,PathName] = uiputfile('K-Means Model.mat');
                    if ~isnumeric(FileName)
                        save([PathName FileName],'C');
                    end
                case 'Yes'
                    [FileName,PathName] = uigetfile('*.mat');
                    load([PathName FileName],'C');
                    if exist('C') ~= 1
                        warndlg('K-means model could not be found. Is this file a trained k-means model?')
                        continue
                    end
            end
            clustAssign = knnsearch(C,data);
            
            
        case 'ARTwarp'
            art = questdlg('From existing model?','Cluster','Yes','No','No');
            switch art% Load Art Model
                case 'No'
                    %% Get settings
                    prompt = {'Matching Threshold:','Duplicate Category Merge Threshold:','Outlier Threshold','Learning Rate:','Interations:','Shape Importance','Frequency Importance','Duration Importance'};
                    dlg_title = 'ARTwarp';
                    num_lines = [1 50];
                    defaultans = {'5','2.5','8','0.001','5','4','1','1'};
                    settings = inputdlg(prompt,dlg_title,num_lines,defaultans);
                    if isempty(settings)
                        return
                    end
                    %% Cluster
                    %                 [~, NET] = ARTwarpClustering(ClusteringData(:,4),settings);
                    try
                        [ARTnet, clustAssign] = ARTwarp2(ClusteringData(:,4),settings);
                    catch ME
                        disp(ME)
                    end
                    [FileName,PathName] = uiputfile('ARTwarp Model.mat');
                    try
                        save([PathName FileName],'ARTnet','settings');
                    catch ME
                        disp(ME)
                    end
                case 'Yes'
                    [FileName,PathName] = uigetfile('*.mat');
                    load([PathName FileName],'ARTnet','settings');
                    if exist('ARTnet') ~= 1
                        warndlg('ARTnet model could not be found. Is this file a trained ARTwarp2 model?')
                        continue
                    end
                    
            end
            [clustAssign] = GetARTwarpClusters(ClusteringData(:,4),ARTnet,settings);
    end
    
    %% Assign Names
    [clusterName, rejected, finished] = clusteringGUI(clustAssign, ClusteringData);
    
end
%% Update Files
UpdateCluster(ClusteringData, clustAssign, clusterName, rejected)

end


%% Get Data
function [ClusteringData, trainingdata, trainingpath]= CreateClusteringData(hObject, eventdata, handles)
% For each file selected, create a cell array with the image, and contour
% of calls where Calls.Accept == 1
cd(handles.squeakfolder);
[trainingdata trainingpath] = uigetfile([handles.settings.detectionfolder '\*.mat'],'Select Detection File(s) for Clustering ','MultiSelect', 'on');
if isnumeric(trainingdata)
    close(h)
    
    return
end

% prompt = {'winds Frames (default: 800)','Overlap Frames (700 for 55s, 7 for 22s)','NFFT (default: 800)'};
%             dlg_title = 'Spectrogram Settings';
%             num_lines=1; options.Resize='off'; options.windStyle='modal'; options.Interpreter='tex';
% spectSettings = str2double(inputdlg(prompt,dlg_title,num_lines,{'800','700','800'},options));




if ischar(trainingdata)==1
    tmp{1}=trainingdata;
    clear trainingdata
    trainingdata=tmp;
end
h = waitbar(0,'Initializing');
c=0;

ClusteringData = {};

for j = 1:length(trainingdata)  % For Each File
    FileInfo = who('-file',[trainingpath trainingdata{j}]);
    if ismember('ClusteringData',FileInfo)
        load([trainingpath trainingdata{j}],'ClusteringData');
        return
    end
    load([trainingpath trainingdata{j}],'Calls');
    
    for i = 1:length(Calls)     % For Each Call
        waitbar(i/length(Calls),h,['Loading File ' num2str(j) ' of '  num2str(length(trainingdata))]);
        if Calls(i).Accept == 1;
            wind = round(.0032 * Calls(i).Rate);
            noverlap = round(.0028 * Calls(i).Rate);
            nfft = round(.0032 * Calls(i).Rate);
            
            c=c+1;
            
            audio =  Calls(i).Audio;
            if ~isa(audio,'double')
                audio = double(audio) / (double(intmax(class(audio)))+1);
            end
            
            %             [s, fr, ti] = spectrogram(audio,wind,noverlap,nfft,Calls(i).Rate,'yaxis');
            %             x1 = axes2pix(length(ti),ti,Calls(i).RelBox(1));
            %             x2 = axes2pix(length(ti),ti,Calls(i).RelBox(3)) + x1;
            %             y1 = axes2pix(length(fr),fr./1000,Calls(i).RelBox(2));
            %             y2 = axes2pix(length(fr),fr./1000,Calls(i).RelBox(4)) + y1;
            %             I=abs(s(round(y1:y2),round(x1:x2))); % Get the pixels in the box
            % Get spectrogram data
            [I,~,noverlap,nfft,rate,box] = CreateSpectrogram(Calls(i));
            im = mat2gray(flipud(I),[0 max(max(I))/4]); % Set max brightness to 1/4 of max
            
            stats = CalculateStats(I,wind,noverlap,nfft,rate,box,handles.settings.EntropyThreshold,handles.settings.AmplitudeThreshold);
            
            
            spectrange = Calls(i).Rate / 2000; % get frequency range of spectrogram in KHz
            FreqScale = spectrange / (1 + floor(nfft / 2)); % size of frequency pixels
            TimeScale = (wind - noverlap) / Calls(i).Rate; % size of time pixels
            
            xFreq = FreqScale * (stats.ridgeFreq_smooth) + Calls(i).Box(2);
            xTime = stats.ridgeTime * TimeScale;
            
            ClusteringData(c,:) = [{uint8(im .* 256)}, {Calls(i).RelBox(2)}, {Calls(i).RelBox(3)}, {xFreq}, {xTime}, {[trainingpath trainingdata{j}]}, {i}, {stats.SignalToNoise},  {Calls(i).RelBox(4)}]; % image, frequency, length, yline, xline, path, i
        end
    end
end
close(h)
handles = guidata(hObject);  % Get newest version of handles
end

%% Save new data
function UpdateCluster(ClusteringData, clustAssign, clusterName, rejected)
[files, ia, ic] = unique(ClusteringData(:,6),'stable');
h = waitbar(0,'Initializing');
c=0;
for j = 1:length(files)  % For Each File
    load(files{j});
    for i = 1:sum(ic==j)   % For Each Call
        waitbar(j/length(files),h,['Processing File ' num2str(j) ' of '  num2str(length(files))]);
        c=c+1;
        if ~isnan(clustAssign(c))
            Calls(ClusteringData{c,7}).Type = clusterName(clustAssign(c));
            if rejected(ClusteringData{c,7})
                Calls(ClusteringData{c,7}).Accept = 0;
            end
        end
    end
    Calls = Calls(1:length([Calls.Rate]));
    [path name] = fileparts(files{j});
    save([path '\' name],'Calls','-v7.3');
end
close(h)
end



%% Dyanamic Time Warping
% for use as a custom distance function for pdist, kmedoids
function D = dtw2(ZI,ZJ)
D = zeros(size(ZJ,1),1);
for i = 1:size(ZJ,1)
    D(i) = dtw(ZI,ZJ(i,:),3);
end
end
