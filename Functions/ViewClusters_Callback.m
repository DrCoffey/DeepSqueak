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
        
        
        spectrange = call.Rate / 2000; % get frequency range of spectrogram in KHz
        FreqScale = spectrange / (1 + floor(nfft / 2)); % size of frequency pixels
        TimeScale = (wind - noverlap) / call.Rate; % size of time pixels
        

        
        ClusteringData = [ClusteringData
            [{uint8(im .* 256)} % Image
            {call.RelBox(2)} % Lower freq
            {[]} % Delta time
            {[]} % Time points
            {[]} % Freq points
            {[trainingpath trainingdata{j}]} % File path
            {i} % Call ID in file
            {[]}
            {call.RelBox(4)}
            ]'];
        clustAssign = [clustAssign; Calls.Type(i)];
    end
    
end
close(h)
end
