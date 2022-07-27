function TrainSupervisedClassifier_Callback(hObject, eventdata, handles)

% This function trains a convolutional neural network to classify calls. To
% use this function, prepare call files by giving calls categories.
% Rejected Calls are ignored. This function produces training images from
% 15 to 75 KHz, and with width of the box.

options.imageSize = [128, 128, 1];
[ClusteringData, Class, options.freqRange, options.maxDuration, options.spectrogram] = CreateClusteringData(handles, 'scale_duration', true, 'fixed_frequency', true);

% Resize the images to match the input image size
images = zeros([options.imageSize, size(ClusteringData, 1)]);
for i = 1:size(ClusteringData, 1)
    images(:,:,:,i) = imresize(ClusteringData.Spectrogram{i}, options.imageSize(1:2));
end
% wind=options.spectrogram.windowsize;
% noverlap=options.spectrogram.overlap;
% nfft=options.spectrogram.nfft;
imageSize=options.imageSize;

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
X = images(:,:,:,calls_to_train_with) ./ 256;
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
auimds = augmentedImageDatastore(options.imageSize,TrainX,TrainY,'DataAugmentation',aug);

P2=preview(auimds);
figure;
imshow(imtile(P2.input));

layers = [
    imageInputLayer([options.imageSize],'Name','input','normalization','none')
    
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
    'MiniBatchSize',100, ...
    'MaxEpochs',1000, ...
    'InitialLearnRate',.05, ...
    'Shuffle','every-epoch', ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropFactor',0.95,...
    'LearnRateDropPeriod',10,...
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
save([PathName FileName],'ClassifyNet','imageSize','layers');
end
