function TrainPostHocDenoiser_Callback(hObject, eventdata, handles)

% This function trains a convolutional neural network to detected if
% identified sounds are USVs or Noise. To use this function, prepare call
% files by labelling negative samples as "Noise", and by accepting positive
% samples. This function produces training images from 15 to 75 KHz, and
% with width of the box.
msgbox('This function will overwrite "DeepSqueak/Denoising Networks/CleaningNet.mat". You might want to back it up first.','Back up your network','help','modal')



%% Prepare the data
% Select files
cd(handles.data.squeakfolder);
[trainingdata, trainingpath] = uigetfile(fullfile(handles.data.settings.detectionfolder,'*.mat'),'Select Detection File(s) for Training ','MultiSelect', 'on');
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
TrainingImages = {};
Class = [];
for j = 1:length(trainingdata)  % For Each File
    Calls = loadCallfile([trainingpath trainingdata{j}]);
    
    for i = 1:height(Calls)     % For Each Call
        waitbar(i/height(Calls),h,['Loading File ' num2str(j) ' of '  num2str(length(trainingdata))]);
        
        audio =  Calls.Audio{i};
        if ~isfloat(audio)
            audio = double(audio) / (double(intmax(class(audio)))+1);
        elseif ~isa(audio,'double')
            audio = double(audio);
        end

        [s, fr, ti] = spectrogram(audio,round(Calls.Rate(i) * wind),round(Calls.Rate(i) * noverlap),round(Calls.Rate(i) * nfft),Calls.Rate(i),'yaxis');
            x1 = axes2pix(length(ti),ti,Calls.RelBox(i,1));
            x2 = axes2pix(length(ti),ti,Calls.RelBox(i,3)) + x1;
%           y1 = axes2pix(length(fr),fr./1000,Calls.RelBox(i,2));
%           y2 = axes2pix(length(fr),fr./1000,Calls.RelBox(i,4)) + y1;
            y1 = axes2pix(length(fr),fr./1000,lowFreq);
            y2 = axes2pix(length(fr),fr./1000,highFreq);
            I=abs(s(round(y1:min(y2,size(s,1))),round(x1:x2))); % Get the pixels in the box
            
            % Use median scaling
            med = median(abs(s(:)));
            im = mat2gray(flipud(I),[med*0.65, med*20]);
            im = single(imresize(im,imageSize));
            % Duplicate the image with random gaussian noise.
            %im2 = imnoise(im,'gaussian',.4*rand()+.1,.1*rand());
            
        if categorical(Calls.Type(i)) == 'Noise'
            TrainingImages = [TrainingImages; {im}];% ; {im2}];
            Class = [Class; categorical({'Noise'})];% categorical({'Noise'})];
        elseif Calls.Accept(i)
            TrainingImages = [TrainingImages; {im}];% ; {im2}];
            Class = [Class; categorical({'USV'})];% ; categorical({'USV'})];
        end
    end
end
delete(h)

%% Train 

% Reshape ans resize the training data
X = single([]);
for i = 1:length(TrainingImages)
X(:,:,:,i) = TrainingImages{i,1};
end
clear TrainingImages

% Divide the data into training and validation data.
% 90% goes to training, 10% to validation.
[trainInd,valInd,testInd] = dividerand(size(X,4),.9,.1,0);
TrainX = X(:,:,:,trainInd);
TrainY = Class(trainInd);
ValX = X(:,:,:,valInd);
ValY = Class(valInd);


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
    
    convolution2dLayer(3,32,'Padding','same','stride',1)
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,32,'Padding','same','stride',1)
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
[C,order] = confusionmat(classify(DenoiseNet,ValX),ValY);
h = heatmap(order,order,C);
h.Title = 'Confusion Matrix';
h.XLabel = 'Predicted class';
h.YLabel = 'True Class';
h.ColorbarVisible = 'off';

% [FileName,PathName] = uiputfile('CleaningNet.mat','Save Network');
save(fullfile(handles.data.squeakfolder,'Denoising Networks','CleaningNet.mat'),'DenoiseNet','wind','noverlap','nfft','lowFreq','highFreq','imageSize','layers');
msgbox('The new network is now saved.','Saved','help')


end
