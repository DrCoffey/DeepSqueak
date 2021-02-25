function SupervisedClassification_Callback(hObject, eventdata, handles)

% This function uses a convolutional neural network, trained in
% "TrainSupervisedClassifier_Callback.m", to classify USVs.

[FileName,PathName] = uigetfile(fullfile(handles.data.squeakfolder,'Clustering Models','*.mat'),'Select Network');
net = load([PathName FileName],'ClassifyNet','wind','noverlap','nfft','imageSize','padFreq');

if exist('ClassifyNet', 'var') ~= 1
    errordlg('Network not be found. Is this file a trained CNN?')
    return
end



if exist(handles.data.settings.detectionfolder,'dir')==0
    errordlg('Please Select Detection Folder')
    uiwait
    load_detectionFolder_Callback(hObject, eventdata, handles)
    handles = guidata(hObject);  % Get newest version of handles
end

selections = listdlg('PromptString','Select Files for Classification:','ListSize',[500 300],'ListString',handles.detectionfilesnames);
if isempty(selections)
    return
end



h = waitbar(0,'Initializing');

for j = 1:length(selections) % Do this for each file
    currentfile = selections(j);
    fname = fullfile(handles.detectionfiles(currentfile).folder,handles.detectionfiles(currentfile).name);
    audioReader = squeakData([]);
    [Calls, audioReader.audiodata] = loadCallfile(fname,handles);

    for i = 1:height(Calls)   % For Each Call
        waitbar(((i/height(Calls)) + j - 1) / length(selections), h, ['Classifying file ' num2str(j) ' of ' num2str(length(selections))]);

        if Calls.Accept(i)

            options.frequency_padding = net.padFreq;
            options.windowsize = net.wind;
            options.overlap = net.noverlap;
            options.nfft = net.nfft;
            [I,~,~,~,~,~,s] = CreateFocusSpectrogram(Calls(i,:),handles, true,options, audioReader);
            
            % Use median scaling
            med = median(abs(s(:)));
            im = mat2gray(flipud(I),[med*0.65, med*20]);

            X = imresize(im,imageSize);
            [Class, score] = classify(net.ClassifyNet, X);
            Calls.Score(i) = max(score);
            Calls.Type(i) = Class;
        end
    end
    save(fname, 'Calls', '-append');
end
close(h)

%% Update display
if isfield(handles,'current_detection_file')
    loadcalls_Callback(hObject, eventdata, handles,handles.current_file_id)
end

end
