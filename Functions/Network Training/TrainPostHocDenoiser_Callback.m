function TrainPostHocDenoiser_Callback(hObject, eventdata, handles)

% This function trains a convolutional neural network to detected if
% identified sounds are USVs or Noise. To use this function, prepare call
% files by labelling negative samples as "Noise", and by accepting positive
% samples. This function produces training images from 15 to 75 KHz, and
% with width of the box.
msgbox('This function will overwrite "DeepSqueak/Denoising Networks/CleaningNet.mat". You might want to back it up first.','Back up your network','help','modal')



%% Prepare the data
% Select files
cd(handles.squeakfolder);
[trainingdata, trainingpath] = uigetfile([handles.settings.detectionfolder '/*.mat'],'Select Detection File(s) for Training ','MultiSelect', 'on');
if isnumeric(trainingdata)  % If user cancels
    return
end
trainingdata = cellstr(trainingdata);

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
            I=abs(s(round(y1:min(y2,size(s,1))),round(x1:x2))); % Get the pixels in the box
            
            % Use median scaling
            med = median(abs(s(:)));
            im = mat2gray(flipud(I),[med*0.1, med*35]);
            
            % Duplicate the image with random gaussian noise.
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

% Reshape ans resize the training data
X = [];
for i = 1:length(TrainingImages)
X(:,:,:,i) = imresize(TrainingImages{i,1},imageSize);
end

% Divide the data into training and validation data.
% 90% goes to training, 10% to validation.
[trainInd,valInd,testInd] = dividerand(length(TrainingImages)/2,.9,.1,0);
% TrainX = X(:,:,:,trainInd);
% TrainY = Class(trainInd);

% Make sure that the validation data don't come from the images with added
% noise. This works because every other image in the training data is unmodified.
ValX = X(:,:,:,(valInd * 2) - 1);
ValY = Class((valInd * 2) - 1);
TrainX = X(:,:,:,~ismember(1:length(TrainingImages),(valInd * 2) - 1));
TrainY = Class(~ismember(1:length(TrainingImages),(valInd * 2) - 1));

aug = imageDataAugmenter('RandXScale',[.8 1.2],'RandYScale',[.8 1.2],'RandXTranslation',[-10 10],'RandYTranslation',[-10 10]);
auimds = augmentedImageSource(imageSize,TrainX,TrainY,'DataAugmentation',aug);

layers = [
    imageInputLayer([imageSize 1],'Name','input','normalization','none')
    
    convolution2dLayer(3,16,'Padding','same','stride',[2 2])
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2,'Stride',2)
    
    
    convolution2dLayer(5,16,'Padding','same','stride',2)
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2,'Stride',2)
    convolution2dLayer(3,31,'Padding','same','stride',1)
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2,'Stride',2)
    convolution2dLayer(3,31,'Padding','same','stride',1)
    batchNormalizationLayer
    reluLayer
    
    fullyConnectedLayer(64)
    batchNormalizationLayer
    reluLayer
    
    fullyConnectedLayer(length(categories(TrainY)))
    softmaxLayer
    classificationLayer];


options = trainingOptions('sgdm',...
    'MaxEpochs',10, ...
    'InitialLearnRate',.02,...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropFactor',0.95,...
    'LearnRateDropPeriod',1,...
    'ValidationData',{ValX, ValY},...
    'ValidationFrequency',10,...
    'ValidationPatience',inf,...
    'Verbose',false,...
    'Plots','training-progress');

DenoiseNet = trainNetwork(auimds,layers,options);

% Plot the confusion matrix
figure('color','w')
[C,order] = confusionmat(classify(DenoiseNet,ValX),ValY)
h = heatmap(order,order,C)
h.Title = 'Confusion Matrix';
h.XLabel = 'Predicted class';
h.YLabel = 'True Class';
h.ColorbarVisible = 'off';

% [FileName,PathName] = uiputfile('CleaningNet.mat','Save Network');
save(fullfile(handles.squeakfolder,'Denoising Networks','CleaningNet.mat'),'DenoiseNet','wind','noverlap','nfft','lowFreq','highFreq','imageSize','layers');
msgbox('The new network is now saved.','Saved','help')


end
