function ViewClusters_Callback(hObject, eventdata, handles)
[ClusteringData,clustAssign] = CreateClusteringData(hObject, eventdata, handles);

[clusterName, rejected, finished] = clusteringGUI(clustAssign, ClusteringData,1);
if finished == 1
    UpdateCluster(ClusteringData, clustAssign, clusterName, rejected)
end

end


%% Get Data
function [ClusteringData, clustAssign]= CreateClusteringData(hObject, eventdata, handles)
% For each file selected, create a cell array with the image, and contour
% of calls where Calls.Accept == 1
cd(handles.squeakfolder);
[trainingdata trainingpath] = uigetfile([handles.settings.detectionfolder '\*.mat'],'Select Detection File(s) for Clustering ','MultiSelect', 'on');
if isnumeric(trainingdata)    
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
clustAssign = categorical();
for j = 1:length(trainingdata)  % For Each File
    FileInfo = who('-file',[trainingpath trainingdata{j}]);
    if ismember('ClusteringData',FileInfo)
        load([trainingpath trainingdata{j}],'ClusteringData');
        return
    end
    load([trainingpath trainingdata{j}],'Calls');
    
    for i = 1:length(Calls)     % For Each Call
        waitbar(i/length(Calls),h,['Loading File ' num2str(j) ' of '  num2str(length(trainingdata))]);
        if Calls(i).Accept == 1 && Calls(i).Type ~= 'Noise';
            wind = round(.0032 * Calls(i).Rate);
            noverlap = round(.0028 * Calls(i).Rate);
            nfft = round(.0032 * Calls(i).Rate);
            
            c=c+1;
            
            audio =  Calls(i).Audio;
            if ~isa(audio,'double')
                audio = double(audio) / (double(intmax(class(audio)))+1);
            end
            
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
            clustAssign(c) = Calls(i).Type;
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
    save(files{j},'Calls','-append');
end
close(h)
end