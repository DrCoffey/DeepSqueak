function PostHocDenoising_Callback(hObject, eventdata, handles)

% This function uses a convolutional neural network, trained in
% "TrainPostHocDenoiser_Callback.m", to seperate noise from USVs.

% Load the network
try
    load(fullfile(handles.data.squeakfolder,'Denoising Networks','CleaningNet.mat'),'DenoiseNet','wind','noverlap','nfft','lowFreq','highFreq','imageSize');
catch
    errordlg(sprintf('Denoising network not found. \nNetwork must be named "CleaningNet.mat" \n In folder: "Denoising Networks"'))
    return
end

if exist(handles.data.settings.detectionfolder,'dir') == 0
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
    fname = fullfile(handles.detectionfiles(currentfile).folder, handles.detectionfiles(currentfile).name);
    
    audioReader = squeakData([]);
    [Calls, audioReader.audiodata] = loadCallfile(fname,handles);

    
    for i = 1:height(Calls)   % For Each Call
        waitbar(((i/height(Calls)) + j - 1) / length(selections), h, ['Denoising file ' num2str(j) ' of ' num2str(length(selections))]);
        
        options.frequency_padding = 0;
        options.windowsize = wind;
        options.overlap = noverlap;
        options.nfft = nfft;
        options.freq_range = [lowFreq, highFreq];
        [I,~,~,~,~,~,s] = CreateFocusSpectrogram(Calls(i,:),handles, true, options, audioReader);
        
        if isempty(I)
           continue; 
        end
        
        % Use median scaling
        med = median(abs(s(:)));
        im = mat2gray(flipud(I),[med*0.65, med*20]);

        X = imresize(im,imageSize);
        [Class, score] = classify(DenoiseNet,X);
        Calls.Score(i) = score(1);
        if Class == 'Noise'
            Calls.Type(i) = Class;
            Calls.Accept(i) = 0;
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