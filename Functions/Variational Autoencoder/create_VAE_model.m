function [encoderNet, decoderNet, options, ClusteringData] = create_VAE_model(handles)

options.imageSize = [128, 128, 1];

% Creates fixed frequency spectrograms
[ClusteringData, ~, options.freqRange, options.maxDuration, options.spectrogram] = CreateClusteringData(handles, 'scale_duration', true, 'fixed_frequency', true,'forClustering', true, 'save_data', true);

% Creates spectrograms only within the box
%[ClusteringData, ~, options.freqRange, options.maxDuration, options.spectrogram] = CreateClusteringData(handles, 'forClustering', true, 'save_data', true);

% Resize the images to match the input image size
images = zeros([options.imageSize, size(ClusteringData, 1)]);
for i = 1:size(ClusteringData, 1)
    images(:,:,:,i) = imresize(ClusteringData.Spectrogram{i}, options.imageSize(1:2));
end
try
figure; montage(images(:,:,:,1:32) ./ 256);
catch
    Disp('Not Enough Images Silly Billy'); 
end
images = dlarray(single(images) ./ 256, 'SSCB');

% Divide the images into training and validation
[trainInd,valInd] = dividerand(size(ClusteringData, 1), .9, .1);
XTrain  = images(:,:,:,trainInd);
XTest   = images(:,:,:,valInd);

% Load the network model
[encoderNet, decoderNet] = VAE_model();

% Train the network
[encoderNet, decoderNet] = train_vae(encoderNet, decoderNet, XTrain, XTest);

