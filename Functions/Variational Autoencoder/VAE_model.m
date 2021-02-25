function [encoderNet, decoderNet] = VAE_model()


latentDim = 32;
imageSize = [128, 128, 1];

encoderLG = layerGraph([
    imageInputLayer(imageSize,'Name','input_encoder','Normalization','none')
    
    convolution2dLayer(3, 8, 'Padding','same', 'Stride', 2, 'Name', 'conv1')
    batchNormalizationLayer('Name', 'bnorm1')
    reluLayer('Name','relu1')
    
    convolution2dLayer(3, 16, 'Padding','same', 'Stride', 2, 'Name', 'conv2')
    batchNormalizationLayer('Name', 'bnorm2')
    reluLayer('Name','relu2')
    
    convolution2dLayer(3, 32, 'Padding','same', 'Stride', 2, 'Name', 'conv3')
    batchNormalizationLayer('Name', 'bnorm3')
    reluLayer('Name','relu3')
    
    convolution2dLayer(3, 64, 'Padding','same', 'Stride', 2, 'Name', 'conv4')
    batchNormalizationLayer('Name', 'bnorm4')
    reluLayer('Name','relu4')
    
        fullyConnectedLayer(1024, 'Name', 'fc_1')
    reluLayer('Name','relu5')

    fullyConnectedLayer(2 * latentDim, 'Name', 'fc_encoder')
    ]);

decoderLG = layerGraph([
    imageInputLayer([1 1 latentDim],'Name','i','Normalization','none')
    
    transposedConv2dLayer(16, 32, 'Cropping', 0, 'Stride', 1, 'Name', 'transpose1')
    batchNormalizationLayer('Name', 'bnorm1')
    reluLayer('Name','relu1')
    transposedConv2dLayer(3, 32, 'Cropping', 'same', 'Stride', 2, 'Name', 'transpose2')
    batchNormalizationLayer('Name', 'bnorm2')
    reluLayer('Name','relu2')
    transposedConv2dLayer(3, 24, 'Cropping', 'same', 'Stride', 2, 'Name', 'transpose3')
    batchNormalizationLayer('Name', 'bnorm3')
    reluLayer('Name','relu3')
    transposedConv2dLayer(3, 16, 'Cropping', 'same', 'Stride', 2, 'Name', 'transpose4')
    batchNormalizationLayer('Name', 'bnorm4')
    reluLayer('Name','relu4')
    transposedConv2dLayer(3, 8, 'Cropping', 'same', 'Stride', 1, 'Name', 'transpose5')
    batchNormalizationLayer('Name', 'bnorm5')
    reluLayer('Name','relu5')
    transposedConv2dLayer(3, 1, 'Cropping', 'same', 'Name', 'transpose6')
    ]);



% analyzeNetwork(encoderLG)
% analyzeNetwork(decoderLG)

encoderNet = dlnetwork(encoderLG);
decoderNet = dlnetwork(decoderLG);

end

