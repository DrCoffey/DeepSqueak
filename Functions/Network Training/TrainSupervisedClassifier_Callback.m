function TrainSupervisedClassifier_Callback(hObject, eventdata, handles)

% This function trains a convolutional neural network to classify calls. To
% use this function, prepare call files by giving calls categories.
% Rejected Calls are ignored. This function produces training images from
% 15 to 75 KHz, and with width of the box.


%% Prepare the data
% Select files
cd(handles.data.squeakfolder);
[trainingdata, trainingpath] = uigetfile([handles.data.settings.detectionfolder '/*.mat'],'Select Detection File(s) for Training ','MultiSelect', 'on');
if isnumeric(trainingdata)  % If user cancels
    return
end
trainingdata = cellstr(trainingdata);


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
    load(fullfile(trainingpath, trainingdata{j}),'Calls');
    % Backwards compatibility with struct format for detection files
    if isstruct(Calls); Calls = struct2table(Calls); end
    
    Xtemp = [];
    Classtemp = [];
    c = 0;
    
    for i = 1:height(Calls)     % For Each Call
        if Calls.Accept(i) && Calls.Type(i) ~= 'Noise'
            waitbar(i/height(Calls),h,['Loading File ' num2str(j) ' of '  num2str(length(trainingdata))]);
            c = c + 1;
            audio = Calls.Audio{i};
            if ~isfloat(audio)
                audio = double(audio) / (double(intmax(class(audio)))+1);
            elseif ~isa(audio,'double')
                audio = double(audio);
            end
            
            [s, fr, ti] = spectrogram((audio),round(Calls.Rate(i) * wind),round(Calls.Rate(i) * noverlap),round(Calls.Rate(i) * nfft),Calls.Rate(i),'yaxis');
            
            x1 = axes2pix(length(ti),ti,Calls.RelBox(i, 1));
            x2 = axes2pix(length(ti),ti,Calls.RelBox(i, 3)) + x1;
            %             y1 = axes2pix(length(fr),fr./1000,Calls.RelBox(i, 2)-10);
            %             y2 = axes2pix(length(fr),fr./1000,Calls.RelBox(i, 4)+20) + y1;
            y1 = axes2pix(length(fr),fr./1000,lowFreq);
            y2 = axes2pix(length(fr),fr./1000,highFreq);
            I=abs(s(round(y1:min(y2,size(s,1))),round(x1:x2))); % Get the pixels in the box
            % Use median scaling
            med = median(abs(s(:)));
            im = mat2gray(flipud(I),[med*0.1, med*35]);
            
            Xtemp(:,:,:,c) = single(imresize(im,imageSize));
            Classtemp = [Classtemp; categorical(Calls.Type(i))];
        end
    end
    X = cat(4,X,Xtemp);
    Class = [Class; Classtemp];
end
Class = removecats(Class);

close(h)

%% Select the categories to train the neural network with
call_categories = categories(Class);
idx = listdlg('ListString',call_categories,'Name','Select categories for training','ListSize',[300,300]);
calls_to_train_with = ismember(Class,call_categories(idx));
X = X(:,:,:,calls_to_train_with);
Class = Class(calls_to_train_with);
Class = removecats(Class);


%% Train

% Divide the data into training and validation data.
% 90% goes to training, 10% to validation.
[trainInd,valInd,testInd] = dividerand(size(X,4),.9,.1,0);
TrainX = X(:,:,:,trainInd);
TrainY = Class(trainInd);
ValX = X(:,:,:,valInd);
ValY = Class(valInd);
TestX = X(:,:,:,testInd);
TestY = Class(testInd);

%clear X

% Augment the data by scaling and translating
aug = imageDataAugmenter('RandXScale',[.9 1.1],'RandYScale',[.9 1.1],'RandXTranslation',[-10 10],'RandYTranslation',[-10 10]);
auimds = augmentedImageDatastore(imageSize,TrainX,TrainY,'DataAugmentation',aug);


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

ClassifyNet = trainNetwork(auimds,layers,options);

% Plot the confusion matrix
figure('color','w')
[C,order] = confusionmat(classify(ClassifyNet,ValX),ValY)
h = heatmap(order,order,C)
h.Title = 'Confusion Matrix';
h.XLabel = 'Predicted class';
h.YLabel = 'True Class';
h.ColorbarVisible = 'off';

[FileName,PathName] = uiputfile('ClassifierNet.mat','Save Network');
save([PathName FileName],'ClassifyNet','wind','noverlap','nfft','lowFreq','highFreq','imageSize','layers');


end
