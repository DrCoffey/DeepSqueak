function [detector layers options] = TrainSqueakDetector(TrainingTables,layers)
switch nargin
    case 1 % Specify layers if not transfering from previous network
        layers = [
            imageInputLayer([30 50 1])
            
            convolution2dLayer([5 5], 20, 'Padding', 1, 'Stride', [2 2])
            batchNormalizationLayer
            leakyReluLayer(0.1)
            
            convolution2dLayer([5 5], 20, 'Padding', 1, 'Stride', [2 2])
            batchNormalizationLayer
            leakyReluLayer(0.1)
            
            maxPooling2dLayer(3, 'Stride',2)
            
            fullyConnectedLayer(64)
            reluLayer()
            fullyConnectedLayer(width(TrainingTables))
            softmaxLayer()
            classificationLayer()
            ];
end

        optionsStage1 = trainingOptions('sgdm', ...
            'MaxEpochs', 8, ...
            'InitialLearnRate', 1e-5);

        optionsStage2 = trainingOptions('sgdm', ...
            'MaxEpochs', 8, ...
            'InitialLearnRate', 1e-5);

        optionsStage3 = trainingOptions('sgdm', ...
            'MaxEpochs', 8, ...
            'InitialLearnRate', 1e-6);

        optionsStage4 = trainingOptions('sgdm', ...
            'MaxEpochs', 8, ...
            'InitialLearnRate', 1e-6);

        options = [
            optionsStage1
            optionsStage2
            optionsStage3
            optionsStage4
            ];
        
    detector = trainFasterRCNNObjectDetector(TrainingTables, layers, options, ...
        'NegativeOverlapRange', [0 0.3], ...
        'PositiveOverlapRange', [0.6 1], ...
        'BoxPyramidScale', 1.2,'NumStrongestRegions',Inf);
end
    