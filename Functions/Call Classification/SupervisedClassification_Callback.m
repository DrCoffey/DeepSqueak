function SupervisedClassification_Callback(hObject, eventdata, handles)

% This function uses a convolutional neural network, trained in
% "TrainSupervisedClassifier_Callback.m", to classify USVs.

[FileName,PathName] = uigetfile(fullfile(handles.data.squeakfolder,'Clustering Models','*.mat'),'Select Network');
net = load([PathName FileName],'ClassifyNet','wind','noverlap','nfft','imageSize');

if exist('net','var') ~= 1
    errordlg('Network not be found. Is this file a trained CNN?')
    return
end

if exist(handles.data.settings.detectionfolder,'dir')==0
    errordlg('Please Select Detection Folder')
    uiwait
    load_detectionFolder_Callback(hObject, eventdata, handles)
    handles = guidata(hObject);  % Get newest version of handles
end

options.imageSize = [128, 128, 1];
[ClusteringData, Class, options.freqRange, options.maxDuration, options.spectrogram] = CreateClusteringData(handles, 'scale_duration', true, 'fixed_frequency', true);

% Resize the images to match the input image size
images = zeros([options.imageSize, size(ClusteringData, 1)]);
for i = 1:size(ClusteringData, 1)
    images(:,:,:,i) = imresize(ClusteringData.Spectrogram{i}, options.imageSize(1:2));
end
% wind=options.spectrogram.windowsize;
% noverlap=options.spectrogram.overlap;
% nfft=options.spectrogram.nfft;
imageSize=options.imageSize;

h = waitbar(0,'Initializing');
for j=1:height(ClusteringData);
    waitbar(j/height(ClusteringData), h, ['Classifying Image ' num2str(j) ' of ' num2str(height(ClusteringData))]);
    X = images(:,:,:,j) ./ 256;
    [Cl, sc] = classify(net.ClassifyNet, X);
    clustAssign(j,1)=Cl;
end
close(h);
clusterName=unique(clustAssign);
saveChoice =  questdlg('Update files with new classifications?','Save Classification','Yes','No','Yes');
switch saveChoice
    case 'Yes'
        UpdateCluster(ClusteringData, clustAssign, clusterName, zeros(1,height(ClusteringData)));
        update_folders(hObject, eventdata, handles);
        if isfield(handles,'current_detection_file')
            loadcalls_Callback(hObject, eventdata, handles, true)
        end
    case 'No'
        return
end
end
