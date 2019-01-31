function PostHocDenoising_Callback(hObject, eventdata, handles)

% This function uses a convolutional neural network, trained in
% "TrainPostHocDenoiser_Callback.m", to seperate noise from USVs.
if isfield(handles,'calls')
handles = rmfield(handles,'calls');
end

% Load the network
try
    load(fullfile(handles.squeakfolder,'Denoising Networks','CleaningNet.mat'),'DenoiseNet','wind','noverlap','nfft','lowFreq','highFreq','imageSize');
catch
    errordlg(sprintf('Denoising network not found. \nNetwork must be named "CleaningNet.mat" \n In folder: "Denoising Networks"'))
    return
end

if exist(handles.settings.detectionfolder,'dir')==0
    errordlg('Please Select Detection Folder')
    uiwait
    load_detectionFolder_Callback(hObject, eventdata, handles)
    handles = guidata(hObject);  % Get newest version of handles
end

selections = listdlg('PromptString','Select Files for Denoising:','ListSize',[500 300],'ListString',handles.detectionfilesnames);
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
        waitbar(((i/length(Calls)) + j - 1) / length(selections), h, ['Denoising file ' num2str(j) ' of ' num2str(length(selections))]);
        audio =  Calls(i).Audio;
        if ~isfloat(audio)
            audio = double(audio) / (double(intmax(class(audio)))+1);
        end
        
        [s, fr, ti] = spectrogram(audio,round(Calls(i).Rate * wind),round(Calls(i).Rate * noverlap),round(Calls(i).Rate * nfft),Calls(i).Rate,'yaxis');
        x1 = axes2pix(length(ti),ti,Calls(i).RelBox(1));
        x2 = axes2pix(length(ti),ti,Calls(i).RelBox(3)) + x1;
        %     y1 = axes2pix(length(fr),fr./1000,Calls(i).RelBox(2));
        %     y2 = axes2pix(length(fr),fr./1000,Calls(i).RelBox(4)) + y1;
        y1 = axes2pix(length(fr),fr./1000,lowFreq);
        y2 = axes2pix(length(fr),fr./1000,highFreq);
        I=abs(s(round(y1:min(y2,size(s,1))),round(x1:x2))); % Get the pixels in the box
        
        % Use median scaling
        med = median(abs(s(:)));
        im = mat2gray(flipud(I),[med*0.1, med*35]);
        
        X = imresize(im,imageSize);
        [Class,score] = classify(DenoiseNet,X);
        Calls(i).Score = score(1);
        if Class == 'Noise'
            Calls(i).Type = Class;
            Calls(i).Accept = 0;
        end
    end
    save(fname,'Calls','-v7.3');
end
close(h)

%% Update display
if isfield(handles,'current_detection_file')
    loadcalls_Callback(hObject, eventdata, handles,handles.current_file_id)
end

end