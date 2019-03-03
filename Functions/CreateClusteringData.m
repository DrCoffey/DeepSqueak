%% This function prepares data for clustering

function [ClusteringData, trainingdata, trainingpath]= CreateClusteringData(hObject, eventdata, handles)
% For each file selected, create a cell array with the image, and contour
% of calls where Calls.Accept == 1

ClusteringData = [];

cd(handles.squeakfolder);
[trainingdata, trainingpath] = uigetfile(fullfile(handles.settings.detectionfolder,'*.mat'),'Select detection file(s) for clustering OR extracted contours','MultiSelect', 'on');
if isnumeric(trainingdata);return;end

% If one file is selected, turn it into a cell
trainingdata = cellstr(trainingdata);

h = waitbar(.5,'Gathering File Info');

ClusteringData = {};
%% For Each File
for j = 1:length(trainingdata)
    file = load(fullfile(trainingpath,trainingdata{j}));
    
    % If the files is extracted contours, rather than a detection file
    if isfield(file,'ClusteringData')
        ClusteringData = [ClusteringData; file.ClusteringData];
    else
        
        % Backwards compatibility with struct format for detection files
        if isstruct(file.Calls); file.Calls = struct2table(file.Calls); end
    
        % for each call in the file, calculate stats for clustering
        for i = 1:height(file.Calls)
            waitbar(i/height(file.Calls),h,['Loading File ' num2str(j) ' of '  num2str(length(trainingdata))]);
            
            % Skip if not accepted
            if ~file.Calls.Accept
                continue
            end
            
            call = file.Calls(i,:);
            
            [I,wind,noverlap,nfft,rate,box] = CreateSpectrogram(call);
            im = mat2gray(flipud(I),[0 max(max(I))/4]); % Set max brightness to 1/4 of max
            
            stats = CalculateStats(I,wind,noverlap,nfft,rate,box,handles.settings.EntropyThreshold,handles.settings.AmplitudeThreshold);
            
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
        end
    end
end
close(h)
end