function ViewClusters_Callback(hObject, eventdata, handles)
[ClusteringData,clustAssign] = CreateClusteringData(hObject, eventdata, handles);

[clusterName, rejected, finished] = clusteringGUI(clustAssign, ClusteringData,1);

% Save the clusters
if finished == 1
    saveChoice =  questdlg('Update files with new clusters?','Save clusters','Yes','No','No');
    switch saveChoice
        case 'Yes'
            % Apply new category names
            clustAssign =  renamecats(clustAssign,cellstr(unique(clustAssign)),cellstr(clusterName));
            UpdateCluster(ClusteringData, clustAssign, clusterName, rejected)
        case 'No'
            return
    end
end

end


%% Get Data
function [ClusteringData, clustAssign]= CreateClusteringData(hObject, eventdata, handles)
% For each file selected, create a cell array with the image, and contour
% of calls where Calls.Accept == 1
cd(handles.data.squeakfolder);
[trainingdata, trainingpath] = uigetfile([handles.data.settings.detectionfolder '/*.mat'],'Select Detection File(s) for Clustering ','MultiSelect', 'on');
if isnumeric(trainingdata)
    return
end
trainingdata = cellstr(trainingdata);

h = waitbar(0,'Initializing');

ClusteringData = {};
clustAssign = categorical();
for j = 1:length(trainingdata)  % For Each File
    load([trainingpath trainingdata{j}],'Calls');
    % Backwards compatibility with struct format for detection files
    if isstruct(Calls); Calls = struct2table(Calls); end
    
    for i = 1:height(Calls)
        waitbar(i/height(Calls),h,['Loading File ' num2str(j) ' of '  num2str(length(trainingdata))]);
        call = Calls(i,:);
        
        % Skip if not accepted
        if (call.Accept ~= 1) || ismember(call.Type,'Noise')
            continue
        end
        
        [I,wind,noverlap,nfft,rate,box] = CreateSpectrogram(call);
        im = mat2gray(flipud(I),[0 max(max(I))/4]); % Set max brightness to 1/4 of max
        
        stats = CalculateStats(I,wind,noverlap,nfft,rate,box,handles.data.settings.EntropyThreshold,handles.data.settings.AmplitudeThreshold);
        
        spectrange = call.Rate / 2000; % get frequency range of spectrogram in KHz
        FreqScale = spectrange / (1 + floor(nfft / 2)); % size of frequency pixels
        TimeScale = (wind - noverlap) / call.Rate; % size of time pixels
        
        xFreq = FreqScale * (stats.ridgeFreq_smooth) + call.Box(2);
        xTime = stats.ridgeTime * TimeScale;
        
        ClusteringData = [ClusteringData
            [{uint8(im .* 256)} % Image
            {call.RelBox(2)} % Lower freq
            {stats.DeltaTime} % Delta time
            {xFreq} % Time points
            {xTime} % Freq points
            {[trainingpath trainingdata{j}]} % File path
            {i} % Call ID in file
            {stats.Power}
            {call.RelBox(4)}
            ]'];
        clustAssign = [clustAssign; Calls.Type(i)];
    end
    
end
close(h)
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
        
        % Update the cluster assignment and rejected status
        Calls.Type(ClusteringData{i,7}) = clustAssign(i);
        if rejected(i)
            Calls.Accept(ClusteringData{i,7}) = 0;
        end
    end
    % If forgot why I added this line, but I feel like I had a reason...
    Calls = Calls(1:length(Calls.Rate), :);
    waitbar(j/length(files),h,['Saving File ' num2str(j) ' of '  num2str(length(files))]);
    save(files{j}, 'Calls', '-v7.3');
end
close(h)
end

