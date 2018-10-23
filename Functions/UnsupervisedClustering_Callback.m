function UnsupervisedClustering_Callback(hObject, eventdata, handles)
% Cluster with k-means or adaptive

% Get the data
[ClusteringData] = CreateClusteringData(hObject, eventdata, handles);

[FileName,PathName] = uiputfile('Extracted Contours.mat','Save contours for faster loading');
if FileName ~= 0
    save(fullfile(PathName,FileName),'ClusteringData','-v7.3');
end

clustAssign = zeros(size(ClusteringData,1),1);

finished = 0; % Repeated until
while ~finished
    choice = questdlg('Choose clustering method:','Cluster','ARTwarp','K-means (recommended)','Cancel','K-means (recommended)');
    
    switch choice
        case 'Cancel'
            return
            
        case 'K-means (recommended)'
            hb = waitbar(.5,'Preparing Data');
            % FREQ 15 Chunks
            %             data = cellfun(@(x) imresize(x-mean(x),[20 1]),ClusteringData(:,4),'UniformOutput',0);
            %             data = [data{:}]';
            
            % Parameterized data
            nrm = @(x) ((x - mean(x,1)) ./ std(x,1));
            ReshapedX=cell2mat(cellfun(@(x) imresize(x',[1 9]) ,ClusteringData(:,4),'UniformOutput',0));
            slope = diff(ReshapedX,1,2);
            slope = nrm(slope);
            freq=cell2mat(cellfun(@(x) imresize(x',[1 8]) ,ClusteringData(:,4),'UniformOutput',0));
            freq = nrm(freq);
            duration = repmat(cell2mat(ClusteringData(:,3)),[1 8]);
            duration = nrm(duration);
 
            close(hb)
            FromExisting = questdlg('From existing model?','Cluster','Yes','No','No');
            switch FromExisting % Load Model
                case 'No'
                    % Get parameter weights
                    clusterParameters= inputdlg({'Shape weight','Frequency weight','Duration weight'},'Choose cluster parameters:',1,{'1','1','1'});
                    if isempty(clusterParameters); return; end
                    slope_weight = num2str(clusterParameters{1});
                    freq_weight = num2str(clusterParameters{2});
                    duration_weight = num2str(clusterParameters{3});

                    data = [
                        freq     .*  freq_weight,...
                        slope    .*  slope_weight,...
                        duration .*  duration_weight,...
                        ];
                    
                    optimize = questdlg('Optimize Cluster Number?','Cluster Optimization','Elbow Optimized','User Defined','Elbow Optimized');
                    
                    switch optimize
                        case 'Elbow Optimized'
                            opt_options = inputdlg({'Max Clusters','Replicates'},'Cluster Optimization',[1 50; 1 50],{'100','3'});
                            if isempty(opt_options)
                                return
                            end
                            [clustAssign,C]=kmeans_opt(data,str2num(opt_options{1}),0,str2num(opt_options{2}));
                        case 'User Defined'
                            k = inputdlg({'Choose number of k-means:'},'Cluster with k-means',1,{'15'});
                            if isempty(k)
                                return
                            end
                            k = str2num(k{1});
                            [clustAssign, C]= kmeans(data,k,'Distance','sqeuclidean','Replicates',10);
                    end
                    
                case 'Yes'
                    [FileName,PathName] = uigetfile(fullfile(handles.squeakfolder,'Clustering Models','*.mat'));
                    load(fullfile(PathName,FileName),'C','freq_weight','slope_weight','duration_weight');
                    data = [
                        freq     .*  freq_weight,...
                        slope    .*  slope_weight,...
                        duration .*  duration_weight,...
                        ];
                    
                    
                    if exist('C') ~= 1
                        warndlg('K-means model could not be found. Is this file a trained k-means model?')
                        continue
                    end
            end
            clustAssign = knnsearch(C,data);
            
        case 'ARTwarp'
            FromExisting = questdlg('From existing model?','Cluster','Yes','No','No');
            switch FromExisting% Load Art Model
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
                    try
                        [ARTnet, clustAssign] = ARTwarp2(ClusteringData(:,4),settings);
                    catch ME
                        disp(ME)
                    end
                    
                case 'Yes'
                    [FileName,PathName] = uigetfile(fullfile(handles.squeakfolder,'Clustering Models','*.mat'));
                    load(fullfile(PathName,FileName),'ARTnet','settings');
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
% Save the clustering model
if FromExisting(1) == 'N';
    switch choice
        case 'K-means (recommended)'
            [FileName,PathName] = uiputfile(fullfile(handles.squeakfolder,'Clustering Models','K-Means Model.mat'),'Save clustering model');
            if ~isnumeric(FileName)
                save(fullfile(PathName,FileName),'C','freq_weight','slope_weight','duration_weight');
            end
        case 'ARTwarp'
            [FileName,PathName] = uiputfile(fullfile(handles.squeakfolder,'Clustering Models','ARTwarp Model.mat'),'Save clustering model');
            if ~isnumeric(FileName)
                save(fullfile(PathName,FileName),'ARTnet','settings');
            end
    end
end


% Save the clusters
saveChoice =  questdlg('Update files with new clusters?','Save clusters','Yes','No','No');
switch saveChoice
    case 'Yes'
        UpdateCluster(ClusteringData, clustAssign, clusterName, rejected)
    case 'No'
        return
end
end


%% Get Data
function [ClusteringData, trainingdata, trainingpath]= CreateClusteringData(hObject, eventdata, handles)
% For each file selected, create a cell array with the image, and contour
% of calls where Calls.Accept == 1
cd(handles.squeakfolder);
[trainingdata trainingpath] = uigetfile(fullfile(handles.settings.detectionfolder,'*.mat'),'Select Detection File(s) for Clustering or extracted contours','MultiSelect', 'on');
if isnumeric(trainingdata)
    return
end

% If one file is selected, turn it into a cell
if ischar(trainingdata)==1
    tmp{1}=trainingdata;
    clear trainingdata
    trainingdata=tmp;
end
h = waitbar(.5,'Gathering File Info');
c=0;

ClusteringData = {};

%% For Each File
for j = 1:length(trainingdata)
    FileInfo = who('-file',[trainingpath trainingdata{j}]);
    if ismember('ClusteringData',FileInfo)
        close(h)
        h = waitbar(.5,'Loading Contours From File');
        load([trainingpath trainingdata{j}],'ClusteringData');
        close(h)
        return
    end
    load([trainingpath trainingdata{j}],'Calls');
    
    %% for each call in the file
    for i = 1:length(Calls)     % For Each Call
        waitbar(i/length(Calls),h,['Loading File ' num2str(j) ' of '  num2str(length(trainingdata))]);
        if Calls(i).Accept == 1;
            call = Calls(i);
            wind = round(.0032 * call.Rate);
            noverlap = round(.0028 * call.Rate);
            nfft = round(.0032 * call.Rate);
            
            c=c+1;
            
            [I,~,noverlap,nfft,rate,box] = CreateSpectrogram(call);
            im = mat2gray(flipud(I),[0 max(max(I))/4]); % Set max brightness to 1/4 of max
            
            stats = CalculateStats(I,wind,noverlap,nfft,rate,box,handles.settings.EntropyThreshold,handles.settings.AmplitudeThreshold);
            
            
            spectrange = call.Rate / 2000; % get frequency range of spectrogram in KHz
            FreqScale = spectrange / (1 + floor(nfft / 2)); % size of frequency pixels
            TimeScale = (wind - noverlap) / call.Rate; % size of time pixels
            
            xFreq = FreqScale * (stats.ridgeFreq_smooth) + call.Box(2);
            xTime = stats.ridgeTime * TimeScale;
            
            ClusteringData(c,:) = [
                {uint8(im .* 256)} % Image
                {call.RelBox(2)} % Lower freq
                {stats.DeltaTime} % Delta time
                {xFreq} % Time points
                {xTime} % Freq points
                {[trainingpath trainingdata{j}]} % File path
                {i} % Call ID in file
                {stats.Power}
                {call.RelBox(4)}
                ]';
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
    [path, name] = fileparts(files{j});
    save(fullfile(path,name),'Calls','-v7.3');
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
