function [ClusteringData, clustAssign, freqRange, maxDuration, spectrogramOptions] = CreateClusteringData(handles, varargin)
%% This function prepares data for clustering
% For each file selected, create a cell array with the image, and contour
% of calls where Calls.Accept == 1

p = inputParser;
addParameter(p,'forClustering', false);
addParameter(p,'spectrogramOptions', []);
% scale_duration can eithor be logical or scaler. If scalar, scale_duration
% is the duration used at t_max to scale duration by sqrt(t_max ./ t)
% If true, than t_max is the 95th percentile of call durations
addParameter(p,'scale_duration', false);
% If scale_duration is true, use a fixed frequency range for spectrograms
addParameter(p,'fixed_frequency', false);
% fixed_frequency = [lowFreq, highFreq] for fixed frequency range
addParameter(p,'freqRange', []);
% Ask to save the data for future use
addParameter(p,'save_data', false);
addParameter(p,'for_denoise', false);
parse(p,varargin{:});
spectrogramOptions = p.Results.spectrogramOptions;

ClusteringData = {};
clustAssign = [];
maxDuration = [];
freqRange = [];
xFreq = [];
xTime = [];
stats.Power = [];

% Select the files
if p.Results.forClustering
    prompt = 'Select detection file(s) for clustering AND/OR extracted contours';
else
    prompt = 'Select detection file(s) for viewing';
end
[fileName, filePath] = uigetfile(fullfile(handles.data.settings.detectionfolder,'*.mat'),prompt,'MultiSelect', 'on');
if isnumeric(fileName); ClusteringData = {}; return;end

% If one file is selected, turn it into a cell
fileName = cellstr(fileName);

h = waitbar(0,'Initializing');
audioReader = squeakData([]);
%% Load the data
audiodata = {};
Calls = [];
for j = 1:length(fileName)
    [Calls_tmp,  audiodata{j}, loaded_ClusteringData] = loadCallfile(fullfile(filePath,fileName{j}),handles);
    % If the files is extracted contours, rather than a detection file
    if ~isempty(loaded_ClusteringData)
        ClusteringData = [ClusteringData; table2cell(loaded_ClusteringData)];
        continue
    else
        % Remove calls that aren't accepted
        if ~p.Results.for_denoise
        % Calls_tmp = Calls_tmp(Calls_tmp.Accept == 1 & ~ismember(Calls_tmp.Type,'Noise'), :);
        end
        % Create a variable that contains the index of audiodata to use
        Calls_tmp.audiodata_index = repmat(j, height(Calls_tmp), 1);
        Calls = [Calls; Calls_tmp];
    end
end

%% Stretch the duration of calls by a factor of sqrt(t_max / t)
% This is used for VAE
if ~isempty(Calls)
    if p.Results.scale_duration
        if islogical(p.Results.scale_duration)
            maxDuration = prctile(Calls.Box(:,3),95);
        else
            maxDuration = p.Results.scale_duration;
        end
        %time_padding = maxDuration  - sqrt(maxDuration ./ Calls.Box(:,3)) .* Calls.Box(:,3);
        % time_padding = maxDuration  - Calls.Box(:,3);
        time_padding = Calls.Box(:,3)*.25;
        %Calls.Box(:,3) = Calls.Box(:,3) + time_padding;
%         Calls.Box(:,3) = maxDuration;
%         Calls.Box(:,1) = Calls.Box(:,1) - time_padding/2;
        Calls.Box(:,3) =  Calls.Box(:,3) + time_padding*2;
        Calls.Box(:,1) = Calls.Box(:,1) - time_padding;
    end
    % Use the box, or a fixed frequency range?
    if p.Results.fixed_frequency || ~isempty(p.Results.freqRange)
        if ~isempty(p.Results.freqRange)
            freqRange = p.Results.freqRange;
        else
            freqRange(1) = prctile(Calls.Box(:,2), 5);
            freqRange(2) = prctile(Calls.Box(:,4) + Calls.Box(:,2), 95);
        end
%         Calls.Box(:,2) = freqRange(1);
%         Calls.Box(:,4) = freqRange(2) - freqRange(1);
          freq_padding = Calls.Box(:,4)*.25;
          Calls.Box(:,2) = Calls.Box(:,2) - freq_padding;
          Calls.Box(:,4) = Calls.Box(:,4) + freq_padding*2;
    end
end
%% for each call in the file, calculate stats for clustering
currentAudioFile = 0;
perFileCallID = 0;
for i = 1:height(Calls)
    waitbar(i/height(Calls),h, sprintf('Loading File %u of %u', Calls.audiodata_index(i), length(fileName)));
    
    % Change the audio file if needed
    if Calls.audiodata_index(i) ~= currentAudioFile;
        audioReader.audiodata = audiodata{Calls.audiodata_index(i)};
        currentAudioFile = Calls.audiodata_index(i);
        perFileCallID = 0;
    end
    perFileCallID = perFileCallID + 1;
        
    [I,wind,noverlap,nfft,rate,box,s,fr,ti,~,pow] = CreateFocusSpectrogram(Calls(i,:), handles, true, [], audioReader);
    % im = mat2gray(flipud(I),[0 max(max(I))/4]); % Set max brightness to 1/4 of max
    % im = mat2gray(flipud(I), prctile(I, [1 99], 'all')); % normalize brightness
    pow(pow==0)=.01;
    pow = log10(pow);
    pow = rescale(imcomplement(abs(pow)));
    % Create Adjusted Image for Identification
    xTile=ceil(size(pow,1)/10);
    yTile=ceil(size(pow,2)/10);
    if xTile>1 && yTile>1
    im = adapthisteq(flipud(pow),'NumTiles',[xTile yTile],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);
    else
    im = adapthisteq(flipud(pow),'NumTiles',[2 2],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);    
    end

    if p.Results.forClustering
        stats = CalculateStats(I,wind,noverlap,nfft,rate,box,handles.data.settings.EntropyThreshold,handles.data.settings.AmplitudeThreshold);
        spectrange = audioReader.audiodata.SampleRate / 2000; % get frequency range of spectrogram in KHz
        FreqScale = spectrange / (1 + floor(nfft / 2)); % size of frequency pixels
        TimeScale = (wind - noverlap) / audioReader.audiodata.SampleRate; % size of time pixels
        xFreq = FreqScale * (stats.ridgeFreq_smooth) + Calls.Box(i,2);
        xTime = stats.ridgeTime * TimeScale;
    else
        stats.DeltaTime = box(3);
    end
    
    ClusteringData = [ClusteringData
        [{uint8(im .* 256)} % Image
        {box}
        {box(2)} % Lower freq
        {stats.DeltaTime} % Delta time
        {xFreq} % Time points
        {xTime} % Freq points
        {[filePath fileName{Calls.audiodata_index(i)}]} % File path
        {perFileCallID} % Call ID in file
        {stats.Power}
        {box(4)}
        ]'];
    
    clustAssign = [clustAssign; Calls.Type(i)];
end


ClusteringData = cell2table(ClusteringData, 'VariableNames', {'Spectrogram', 'Box','MinFreq', 'Duration', 'xFreq', 'xTime', 'Filename', 'callID', 'Power', 'Bandwidth'});

close(h)

if p.Results.save_data && ~all(cellfun(@(x) isempty(fields(x)), audiodata)) % If audiodata has no fields, then only extracted contours were used, so don't ask to save them again
    [FileName,PathName] = uiputfile('Extracted Contours.mat','Save extracted data for faster loading (optional)');
    if FileName ~= 0
        save(fullfile(PathName,FileName),'ClusteringData','-v7.3');
    end
end
