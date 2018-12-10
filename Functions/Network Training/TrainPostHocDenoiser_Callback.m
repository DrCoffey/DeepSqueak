function TrainPostHocDenoiser_Callback(hObject, eventdata, handles)

% This function trains a convolutional neural network to detected if
% identified sounds are USVs or Noise. To use this function, prepare call
% files by labelling negative samples as "Noise", and by accepting positive
% samples. This function produces training images from 15 to 75 KHz, and
% with width of the box.



%% Prepare the data
% Select files
cd(handles.squeakfolder);
[trainingdata, trainingpath] = uigetfile([handles.settings.detectionfolder '/*.mat'],'Select Detection File(s) for Training ','MultiSelect', 'on');
if isnumeric(trainingdata)  % If user cancels
    return
end
if ischar(trainingdata)==1
    tmp{1}=trainingdata;
    clear trainingdata
    trainingdata=tmp;
end

% Spectrogram Settings
wind = .0032;
noverlap = .0028;
nfft = .0032;

% Frequency cutoff
lowFreq = 15;
highFreq = 110;
imageSize = [193 100];



h = waitbar(0,'Initializing');
c=0;
TrainingImages = {};
Class = [];
for j = 1:length(trainingdata)  % For Each File
    load([trainingpath trainingdata{j}],'Calls');
    for i = 1:length(Calls)     % For Each Call
        waitbar(i/length(Calls),h,['Loading File ' num2str(j) ' of '  num2str(length(trainingdata))]);
        c=c+1;
        
        audio =  Calls(i).Audio;
        if ~isa(audio,'double')
            audio = double(audio) / (double(intmax(class(audio)))+1);
        end

        [s, fr, ti] = spectrogram(audio,round(Calls(i).Rate * wind),round(Calls(i).Rate * noverlap),round(Calls(i).Rate * nfft),Calls(i).Rate,'yaxis');
            x1 = axes2pix(length(ti),ti,Calls(i).RelBox(1));
            x2 = axes2pix(length(ti),ti,Calls(i).RelBox(3)) + x1;
%             y1 = axes2pix(length(fr),fr./1000,Calls(i).RelBox(2));
%             y2 = axes2pix(length(fr),fr./1000,Calls(i).RelBox(4)) + y1;
            y1 = axes2pix(length(fr),fr./1000,lowFreq);
            y2 = axes2pix(length(fr),fr./1000,highFreq);
            I=abs(s(round(y1:y2),round(x1:x2))); % Get the pixels in the box
            im = mat2gray(flipud(I),[prctile(abs(s(:)),7.5) prctile(abs(s(:)),99)]); % Set max brightness to 1/4 of max
            im2 = imnoise(im,'gaussian',.4*rand()+.1,.1*rand());
        if categorical(Calls(i).Type) == 'Noise';
            TrainingImages = [TrainingImages; {im}; {im2}];
            Class = [Class; categorical({'Noise'}); categorical({'Noise'})];
        elseif Calls(i).Accept == 1;
            TrainingImages = [TrainingImages; {im}; {im2}];
            Class = [Class; categorical({'USV'}); categorical({'USV'})];
        end
    end
end
delete(h)


%% Train 

X = [];
for i = 1:length(TrainingImages)
X(:,:,:,i) = imresize(TrainingImages{i,1},imageSize);
end

[trainInd,valInd,testInd] = dividerand(length(TrainingImages)/2,.9,.1,0);
% TrainX = X(:,:,:,trainInd);
% TrainY = Class(trainInd);
ValX = X(:,:,:,(valInd * 2) - 1);
ValY = Class((valInd * 2) - 1);
TrainX = X(:,:,:,~ismembc(1:length(TrainingImages),(valInd * 2) - 1));
TrainY = Class(~ismembc(1:length(TrainingImages),(valInd * 2) - 1));

aug = imageDataAugmenter('RandXScale',[.75 1.5],'RandYScale',[.75 1.5],'RandXTranslation',[-10 10],'RandYTranslation',[-10 10]);
auimds = augmentedImageSource(imageSize,TrainX,TrainY,'DataAugmentation',aug);

layers = [
    imageInputLayer([imageSize 1])

    convolution2dLayer(3,16,'Padding',1,'stride',1)
    reluLayer
    convolution2dLayer(3,16,'Padding',1,'stride',1)
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer([2 2],'Padding',1,'Stride',[2 2])
    
    convolution2dLayer(3,16,'Padding',1,'stride',1)
    convolution2dLayer(3,16,'Padding',1,'stride',1)
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer([2 2],'Stride',[2 2])

    convolution2dLayer(5,8,'Padding',1,'stride',2)
    batchNormalizationLayer
    reluLayer

    fullyConnectedLayer(2)
    softmaxLayer
    classificationLayer];


options = trainingOptions('sgdm',...
    'MaxEpochs',10, ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropFactor',0.8,...
    'LearnRateDropPeriod',1,...    
    'ValidationData',{ValX, ValY},...
    'ValidationFrequency',4,...
    'ValidationPatience',inf,...
    'Verbose',false,...
    'Plots','training-progress');

DenoiseNet = trainNetwork(auimds,layers,options);

% [FileName,PathName] = uiputfile('CleaningNet.mat','Save Network');
save(fullfile(handles.squeakfolder,'Denoising Networks','CleaningNet.mat'),'DenoiseNet','wind','noverlap','nfft','lowFreq','highFreq','imageSize','layers','options');


end
