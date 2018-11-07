function TrainSupervisedClassifier_Callback(hObject, eventdata, handles)

% This function trains a convolutional neural network to classify calls. To
% use this function, prepare call files by giving calls categories.
% Rejected Calls are ignored. This function produces training images from
% 15 to 75 KHz, and with width of the box.


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


settings = inputdlg({'Low Frequency (kHz)','High Frequency (kHz)'},'Frequency Range',[1 50],{'15','90'});
lowFreq = str2num(settings{1});
highFreq = str2num(settings{2});


imageSize = [200 100];


h = waitbar(0,'Initializing');
% X=zeros(200,100,1,30188,'single');
X = [];
TrainingImages = {};
Class = [];
for j = 1:length(trainingdata)  % For Each File
    load([trainingpath trainingdata{j}],'Calls');
    Xtemp = [];
    Classtemp = [];
    c = 0;

    for i = 1:length(Calls)     % For Each Call
        if (Calls(i).Accept == 1) && (Calls(i).Type ~= 'Noise');
            waitbar(i/length(Calls),h,['Loading File ' num2str(j) ' of '  num2str(length(trainingdata))]);
            c=c+1;
            audio =  Calls(i).Audio;
            if ~isa(audio,'double')
                audio = double(audio) / (double(intmax(class(audio)))+1);
            end
            
            [s, fr, ti] = spectrogram((audio),round(Calls(i).Rate * wind),round(Calls(i).Rate * noverlap),round(Calls(i).Rate * nfft),Calls(i).Rate,'yaxis');
            
            x1 = axes2pix(length(ti),ti,Calls(i).RelBox(1));
            x2 = axes2pix(length(ti),ti,Calls(i).RelBox(3)) + x1;
%             y1 = axes2pix(length(fr),fr./1000,Calls(i).RelBox(2)-10);
%             y2 = axes2pix(length(fr),fr./1000,Calls(i).RelBox(4)+20) + y1;
                    y1 = axes2pix(length(fr),fr./1000,lowFreq);
                    y2 = axes2pix(length(fr),fr./1000,highFreq);
            I=abs(s(round(y1:y2),round(x1:x2))); % Get the pixels in the box
            im = mat2gray(flipud(I),[prctile(abs(s(:)),7.5) prctile(abs(s(:)),99.8)]); % Set max brightness to 1/4 of max
            
            %             TrainingImages = [TrainingImages; {im}];
            Xtemp(:,:,:,c) = single(imresize(im,imageSize));
            Classtemp = [Classtemp; categorical(Calls(i).Type)];
        end
    end
    X = cat(4,X,Xtemp);
    Class = [Class; Classtemp];
end
Class = removecats(Class);

close(h)

%% Train


[trainInd,valInd,testInd] = dividerand(size(X,4),.9,.1,0);
TrainX = X(:,:,:,trainInd);
TrainY = Class(trainInd);
ValX = X(:,:,:,valInd);
ValY = Class(valInd);
TestX = X(:,:,:,testInd);
TestY = Class(testInd);

clear X

aug = imageDataAugmenter('RandXScale',[.75 1.25],'RandYScale',[.75 1.25],'RandXTranslation',[-20 20],'RandYTranslation',[-20 20]);
auimds = augmentedImageSource(imageSize,TrainX,TrainY,'DataAugmentation',aug);


layers = [
    imageInputLayer([imageSize 1],'Name','input','normalization','none')
    
    convolution2dLayer([5 3],8,'Padding','same','stride',[2 2])
    batchNormalizationLayer
    convolution2dLayer(5,8,'Padding','same','stride',[1 1])
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer([3 2],'Padding','same','Stride',[2 1])
    
    convolution2dLayer(5,16,'Padding','same','stride',[2 2])
    batchNormalizationLayer
    convolution2dLayer(5,16,'Padding','same','stride',2)
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer([2 2],'Padding','same','Stride',[2 2])
    
    convolution2dLayer(5,32,'Padding','same','stride',2)
    batchNormalizationLayer
    convolution2dLayer(5,32,'Padding','same','stride',2)
    batchNormalizationLayer
    reluLayer
    
    fullyConnectedLayer(64)
    batchNormalizationLayer
    reluLayer
    
    fullyConnectedLayer(length(unique(TrainY)))
    softmaxLayer
    classificationLayer];


options = trainingOptions('sgdm',...
    'MaxEpochs',10, ...
    'InitialLearnRate',.05,...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropFactor',0.8,...
    'LearnRateDropPeriod',1,...
    'ValidationData',{ValX, ValY},...
    'ValidationFrequency',50,...
    'ValidationPatience',inf,...
    'Verbose',false,...
    'Plots','training-progress');

ClassifyNet = trainNetwork(auimds,layers,options);

[FileName,PathName] = uiputfile('ClassifierNet.mat','Save Network');
save([PathName FileName],'ClassifyNet','wind','noverlap','nfft','lowFreq','highFreq','imageSize','layers','options');


end