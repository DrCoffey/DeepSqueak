function [encoderNet, decoderNet] = train_vae(encoderNet, decoderNet, XTrain, XTest)

numTrainImages = size(XTrain, 4);

executionEnvironment = "auto";


numEpochs = 250;
miniBatchSize = 128;
lr = .25e-3;
numIterations = floor(numTrainImages/miniBatchSize);
iteration = 0;

avgGradientsEncoder = [];
avgGradientsSquaredEncoder = [];
avgGradientsDecoder = [];
avgGradientsSquaredDecoder = [];


figure1 = figure('Color',[1 1 1],'Position',[200 200 600 500]);
axes1 = axes('Parent',figure1,'LineWidth',1,'TickDir','out',...
    'FontSmoothing','on',...
    'FontSize',12);
ylabel(axes1,'ELBO loss');
xlabel(axes1,'Epoch');
plotTitle = title(axes1, 'Training progress', 'Close this window to end training');
h = animatedline(axes1, 'Color', [.1, .9, .7], 'LineWidth', 1.5, 'Marker', '.', 'MarkerSize', 20);
% xlim(axes1, [0, numEpochs])

set(axes1, 'yscale', 'log')
for epoch = 1:numEpochs
    tic;
    for i = 1:numIterations
        iteration = iteration + 1;
        idx = (i-1)*miniBatchSize+1:i*miniBatchSize;
        XBatch = XTrain(:,:,:,idx);
        XBatch = dlarray(single(XBatch), 'SSCB');
        
        if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
            XBatch = gpuArray(XBatch);           
        end 
            
        [infGrad, genGrad] = dlfeval(...
            @modelGradients, encoderNet, decoderNet, XBatch);
        
        [decoderNet.Learnables, avgGradientsDecoder, avgGradientsSquaredDecoder] = ...
            adamupdate(decoderNet.Learnables, ...
                genGrad, avgGradientsDecoder, avgGradientsSquaredDecoder, iteration, lr);
        [encoderNet.Learnables, avgGradientsEncoder, avgGradientsSquaredEncoder] = ...
            adamupdate(encoderNet.Learnables, ...
                infGrad, avgGradientsEncoder, avgGradientsSquaredEncoder, iteration, lr);
    end
    elapsedTime = toc;
    
    if ~isvalid(h)
        return
    end
    
    [z, zMean, zLogvar] = sampling(encoderNet, XTest);
    forward(encoderNet, XTest);
    xPred = sigmoid(forward(decoderNet, z));
    elbo = ELBOloss(XTest, xPred, zMean, zLogvar);
    
    % Update figure and print results
    fprintf('Epoch : %-3g Test ELBO loss = %#.5g. Time taken for epoch = %#.3gs\n', epoch, gather(extractdata(elbo))/2, elapsedTime)
    addpoints(h,epoch,double(gather(extractdata(elbo))));
    plotTitle.String = sprintf('Training progress - epoch %u/%u', epoch, numEpochs);
    drawnow 
end