function [detector lgraph options] = TrainSqueakDetector(TrainingTables,layers)

% Estimate Anchor Boxes
blds = boxLabelDatastore(TrainingTables(:,2:end));
imds = imageDatastore(TrainingTables.imageFilename);
anchorBoxes = estimateAnchorBoxes(blds,8);

% Load unweighted mobilnetV2 to modify for a YOLO net
load('BlankNet.mat');

% YOLO Network Options
featureExtractionLayer = "block_12_add";
filterSize = [3 3];
numFilters = 96;
numClasses = (width(TrainingTables)-1);
numAnchors = size(anchorBoxes,1);
numPredictionsPerAnchor = 5;
numFiltersInLastConvLayer = numAnchors*(numClasses+numPredictionsPerAnchor);

% YOLO Network Layers
detectionLayers = [
    convolution2dLayer(filterSize,numFilters,"Name","yolov2Conv1","Padding", "same", "WeightsInitializer",@(sz)randn(sz)*0.01)
    batchNormalizationLayer("Name","yolov2Batch1")
    reluLayer("Name","yolov2Relu1")
    convolution2dLayer(filterSize,numFilters,"Name","yolov2Conv2","Padding", "same", "WeightsInitializer",@(sz)randn(sz)*0.01)
    batchNormalizationLayer("Name","yolov2Batch2")
    reluLayer("Name","yolov2Relu2")
    convolution2dLayer(1,numFiltersInLastConvLayer,"Name","yolov2ClassConv",...
    "WeightsInitializer", @(sz)randn(sz)*0.01)
    yolov2TransformLayer(numAnchors,"Name","yolov2Transform")
    yolov2OutputLayer(anchorBoxes,"Name","yolov2OutputLayer")
    ];

lgraph = addLayers(blankNet,detectionLayers);
lgraph = connectLayers(lgraph,featureExtractionLayer,"yolov2Conv1");

options = trainingOptions('sgdm',...
          'InitialLearnRate',0.001,...
          'Verbose',true,...
          'MiniBatchSize',16,...
          'MaxEpochs',100,...
          'Shuffle','never',...
          'VerboseFrequency',30,...
          'CheckpointPath',tempdir,...
          'Plots','training-progress');

% Train the YOLO v2 network.
if nargin == 1
    [detector,info] = trainYOLOv2ObjectDetector(TrainingTables,lgraph,options);
elseif nargin == 2
    [detector,info] = trainYOLOv2ObjectDetector(TrainingTables,layers,options);
else
    error('This should not happen');   
end
end

