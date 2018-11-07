function SupervisedClassification_Callback(hObject, eventdata, handles)

% This function uses a convolutional neural network, trained in
% "TrainSupervisedClassifier_Callback.m", to classify USVs.

[FileName,PathName] = uigetfile(fullfile(handles.squeakfolder,'Clustering Models','*.mat'),'Select Network');
load([PathName FileName],'ClassifyNet','wind','noverlap','nfft','lowFreq','highFreq','imageSize');

if exist('ClassifyNet') ~= 1
    errordlg('Network not be found. Is this file a trained CNN?')
    return
end



if exist(handles.settings.detectionfolder,'dir')==0
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
    lastwarn(''); % Skip files if variable: 'Calls' doesn't exist
    fname = fullfile(handles.detectionfiles(currentfile).folder,handles.detectionfiles(currentfile).name);
    tmp=load(fname,'Calls');
    if ~isempty(lastwarn)
        disp([handles.detectionfiles(currentfile).name ' is not a Call file, skipping...'])
        continue
    end
    Calls = tmp.Calls;
    for i = 1:length(Calls)   % For Each Call
        waitbar(((i/length(Calls)) + j - 1) / length(selections), h, ['Classifying file ' num2str(j) ' of ' num2str(length(selections))]);
        
        if Calls(i).Accept == 1;
            
            audio =  Calls(i).Audio;
            if ~isa(audio,'double')
                audio = double(audio) / (double(intmax(class(audio)))+1);
            end
            
            [s, fr, ti] = spectrogram(audio,round(Calls(i).Rate * wind),round(Calls(i).Rate * noverlap),round(Calls(i).Rate * nfft),Calls(i).Rate,'yaxis');
            x1 = axes2pix(length(ti),ti,Calls(i).RelBox(1));
            x2 = axes2pix(length(ti),ti,Calls(i).RelBox(3)) + x1;
%                 y1 = axes2pix(length(fr),fr./1000,Calls(i).RelBox(2));
%                 y2 = axes2pix(length(fr),fr./1000,Calls(i).RelBox(4)) + y1;
            y1 = axes2pix(length(fr),fr./1000,lowFreq);
            y2 = axes2pix(length(fr),fr./1000,highFreq);
            I=abs(s(round(y1:y2),round(x1:x2))); % Get the pixels in the box
            im = mat2gray(flipud(I),[prctile(abs(s(:)),7.5) prctile(abs(s(:)),99.8)]); % Set max brightness to 1/4 of max
            
            X = imresize(im,imageSize);
            [Class,score] = classify(ClassifyNet,X);
            Calls(i).Score = score(1);
            Calls(i).Type = Class;
        end
    end
    save(fname,'Calls','-append');
end
close(h)

%% Update display
if isfield(handles,'current_detection_file')
    loadcalls_Callback(hObject, eventdata, handles,handles.current_file_id)
end

end