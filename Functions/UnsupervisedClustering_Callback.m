function UnsupervisedClustering_Callback(hObject, eventdata, handles)
% Cluster with k-means or adaptive

% Get the data
[ClusteringData] = CreateClusteringData(hObject, eventdata, handles);
if isempty(ClusteringData); return; end

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
                    slope_weight = str2double(clusterParameters{1});
                    freq_weight = str2double(clusterParameters{2});
                    duration_weight = str2double(clusterParameters{3});
                    
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
                    [FileName,PathName] = uigetfile(fullfile(handles.data.squeakfolder,'Clustering Models','*.mat'));
                    load(fullfile(PathName,FileName),'C','freq_weight','slope_weight','duration_weight','clusterName');
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
            [clustAssign,D] = knnsearch(C,data,'Distance','seuclidean');
            
            %% Sort the calls by how close they are to the cluster center
            [~,idx] = sort(D);
            clustAssign = clustAssign(idx);
            ClusteringData = ClusteringData(idx,:);
            %% Make a montage with the top calls in each class
            try
                % Find the median call length
                maxlength = [];
                for i = unique(clustAssign,'sorted')'
                    index = find(clustAssign==i,1);
                    im = ClusteringData{index,1};
                    maxlength = [maxlength,size(im,2)];
                end
                maxlength = round(prctile(maxlength,75));
                % Make the image stack
                montageI = [];
                for i = unique(clustAssign)'
                    index = find(clustAssign==i,1);
                    tmp = ClusteringData{index,1};
                    tmp = padarray(tmp,[0,max(maxlength-size(tmp,2),0)],'both');
                    tmp = rescale(tmp,1,100);
                    montageI(:,:,i) = floor(imresize(tmp,[120,240]));
                end
                % Make the figure
                figure('Color','w','Position',[50,50,800,800])
                montage(montageI,inferno,'BorderSize',1,'BackgroundColor','w');
                title('Top call in each cluster')
            catch
                disp('For some reason, I couldn''t make a montage of the call exemplars')
            end
            
            
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
                    [FileName,PathName] = uigetfile(fullfile(handles.data.squeakfolder,'Clustering Models','*.mat'));
                    load(fullfile(PathName,FileName),'ARTnet','settings');
                    if exist('ARTnet') ~= 1
                        warndlg('ARTnet model could not be found. Is this file a trained ARTwarp2 model?')
                        continue
                    end
                    
            end
            [clustAssign] = GetARTwarpClusters(ClusteringData(:,4),ARTnet,settings);
    end
    
    %     data = freq;
    %         epsilon = 0.0001;
    % mu = mean(data);
    % data = data - mean(data)
    % A = data'*data;
    % [V,D,~] = svd(A);
    % whMat = sqrt(size(data,1)-1)*V*sqrtm(inv(D + eye(size(D))*epsilon))*V';
    % Xwh = data*whMat;
    % invMat = pinv(whMat);
    %
    % data = Xwh
    %
    % data  = (freq-mean(freq)) ./ std(freq)
    % [clustAssign, C]= kmeans(data,10,'Distance','sqeuclidean','Replicates',10);
    
    
    %% Assign Names
    % If the 
    if strcmp(choice, 'K-means (recommended)') && strcmp(FromExisting, 'Yes')
        clustAssign = categorical(clustAssign, 1:size(C,1), cellstr(clusterName));
    end
    
    [clusterName, rejected, finished] = clusteringGUI(clustAssign, ClusteringData);
    
    
end
%% Update Files
% Save the clustering model
if FromExisting(1) == 'N'
    switch choice
        case 'K-means (recommended)'
            [FileName, PathName] = uiputfile(fullfile(handles.data.squeakfolder, 'Clustering Models', 'K-Means Model.mat'), 'Save clustering model');
            if ~isnumeric(FileName)
                save(fullfile(PathName, FileName), 'C', 'freq_weight', 'slope_weight', 'duration_weight', 'clusterName');
            end
        case 'ARTwarp'
            [FileName, PathName] = uiputfile(fullfile(handles.data.squeakfolder, 'Clustering Models', 'ARTwarp Model.mat'), 'Save clustering model');
            if ~isnumeric(FileName)
                save(fullfile(PathName, FileName), 'ARTnet', 'settings');
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



%% Save new data
function UpdateCluster(ClusteringData, clustAssign, clusterName, rejected)
[files, ia, ic] = unique(ClusteringData(:,6),'stable');
h = waitbar(0,'Initializing');
for j = 1:length(files)  % For Each File
    load(files{j}, 'Calls');
    % Backwards compatibility with struct format for detection files
    if isstruct(Calls); Calls = struct2table(Calls); end
    
    for i = (1:sum(ic==j)) + ia(j) - 1   % For Each Call
        waitbar(j/length(files),h,['Processing File ' num2str(j) ' of '  num2str(length(files))]);
        
        if isnan(clustAssign(i))
            continue
        end
        
        % Update the cluster assignment and rejected status
        Calls.Type(ClusteringData{i,7}) = clusterName(clustAssign(i));
        if rejected(i) || clusterName(clustAssign(i)) == 'Noise' || clusterName(clustAssign(i)) == 'noise'
            Calls.Accept(ClusteringData{i,7}) = 0;
            Calls.Type(ClusteringData{i,7}) = categorical({'Noise'});
        end
    end
    % If forgot why I added this line, but I feel like I had a reason... -RM
    Calls = Calls(1:length(Calls.Rate), :);
    waitbar(j/length(files),h,['Saving File ' num2str(j) ' of '  num2str(length(files))]);
    save(files{j},'Calls','-v7.3');
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
