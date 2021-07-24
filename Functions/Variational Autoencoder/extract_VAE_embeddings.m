function data = extract_VAE_embeddings(encoderNet, options, ClusteringData)

% Resize the images to match the input image size
images = zeros([options.imageSize, size(ClusteringData, 1)]);
for i = 1:size(ClusteringData, 1)
    images(:,:,:,i) = imresize(ClusteringData.Spectrogram{i}, options.imageSize(1:2));
end
images = dlarray(single(images) ./ 256, 'SSCB');

[~, zMean] = sampling(encoderNet, single(images));
zMean = stripdims(zMean)';
zMean = gather(extractdata(zMean));
data = double(zMean);
