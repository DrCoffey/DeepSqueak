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

settings = inputdlg({'Frequency to pad boxes aboxe and below each box (kHz):'},'Frequency to pad boxes by',[1 60],{'10'});
padFreq = str2double(settings{1});
imageSize = [200 200];

h = waitbar(0,'Initializing');
X = [];
Class = [];
for j = 1:length(trainingdata)  % For Each File
    audioReader = squeakData([]);
    [Calls, audioReader.audiodata] = loadCallfile(fullfile(trainingpath, trainingdata{j}),handles);
    
    Xtemp = [];
    Classtemp = [];
    Calls=Calls(Calls.Accept==1 & Calls.Type ~= 'Noise', :);
    
    for i = 1:height(Calls)     % For Each Call
        waitbar(i/height(Calls),h,['Loading File ' num2str(j) ' of '  num2str(length(trainingdata))]);
        
        options.frequency_padding = padFreq;
        options.windowsize = wind;
        options.overlap = noverlap;
        options.nfft = nfft;
        [I,~,~,~,~,~,s] = CreateFocusSpectrogram(Calls(i,:),handles, true, options, audioReader);
        
        % Use median scaling
        med = median(abs(s(:)));
        im = mat2gray(flipud(I),[med*0.65, med*20]);
        Xtemp(:,:,:,i) = single(imresize(im,imageSize));
        Classtemp = [Classtemp; categorical(Calls.Type(i))];
    end
    X = cat(4,X,Xtemp);
    Class = [Class; Classtemp];
end
close(h)

%% Make all categories 'Title Case'
cats = categories(Class);
for i = 1:length(cats)
    newstr = lower(cats{i}); % Make everything lowercase
    idx = regexp([' ' newstr],'[\ \-\_]'); % Find the start of each word
    newstr(idx) = upper(newstr(idx)); % Make the start of each word uppercase
    Class = mergecats(Class, cats{i}, newstr);
end
Class = removecats(Class);

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
[trainInd,valInd] = dividerand(size(X,4),.90,.10);
TrainX = X(:,:,:,trainInd);
TrainY = Class(trainInd);
ValX = X(:,:,:,valInd);
ValY = Class(valInd);

% Augment the data by scaling and translating
aug = imageDataAugmenter('RandXScale',[.90 1.10],'RandYScale',[.90 1.10],'RandXTranslation',[-20 20],'RandYTranslation',[-20 20],'RandXShear',[-9 9]);
auimds = augmentedImageDatastore(imageSize,TrainX,TrainY,'DataAugmentation',aug);

%P2=preview(auimds);
%imshow(imtile(P2.input));

layers = [
    imageInputLayer([imageSize],'Name','input','normalization','none')
    
    convolution2dLayer(3,16,'Padding','same','stride',[2 2])
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(5,16,'Padding','same','stride',1)
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(5,32,'Padding','same','stride',1)
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(5,32,'Padding','same','stride',1)
    batchNormalizationLayer
    reluLayer
    
    fullyConnectedLayer(32)
    batchNormalizationLayer
    reluLayer
    
    fullyConnectedLayer(length(categories(TrainY)))
    softmaxLayer
    classificationLayer];

options = trainingOptions('sgdm',...
    'MiniBatchSize',20, ...
    'MaxEpochs',25, ...
    'InitialLearnRate',.075, ...
    'Shuffle','every-epoch', ...
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
[C,order] = confusionmat(classify(ClassifyNet,ValX),ValY);
h = heatmap(order,order,C);
h.Title = 'Confusion Matrix';
h.XLabel = 'Predicted class';
h.YLabel = 'True Class';
h.ColorbarVisible = 'off';
colormap(inferno);

[FileName,PathName] = uiputfile('ClassifierNet.mat','Save Network');
save([PathName FileName],'ClassifyNet','wind','noverlap','nfft','padFreq','imageSize','layers');
end
