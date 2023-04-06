function create_tsne_Callback(hObject, eventdata, handles)
% Creates a 2-dimensional t-sne image of calls.


padding = 1000; % Pad the temp image by this amount, so that calls near the border still fit.
blackLevel = 80; % Subtract this value from each call image to make a nicer picture.

% Select embedding type
embeddingType = questdlg('Embed with UMAP or t-SNE?', 'Embedding Method', 't-SNE' , 'UMAP', 't-SNE');
if isempty(embeddingType); return; end
if strcmp(embeddingType, 'UMAP')
    if ~exist('run_umap.m', 'file')
        msgbox('Please download UMAP and add it to MATLAB''s path and try again')
        web('   https://www.mathworks.com/matlabcentral/fileexchange/71902-uniform-manifold-approximation-and-projection-umap');
        return
    end
end

%% Choose clustering dimensions
inputParameters= questdlg('Select the input dimensions', 'Input Dimensions', 'Variational autoencoder embeddings', 'Contour shape, frequency, and duration', 'Contour shape, frequency, and duration');
if isempty(inputParameters); return; end

% Choose to assign colors by the call classification or by pitch.
colorType = questdlg({'Color the calls by frequecy (pitch), or by cluster identity?','If coloring by cluster, you may not use pre-extracted contours'}, 'Choose Color', 'Frequency' , 'Cluster', 'Frequency');
if isempty(colorType); return; end

switch inputParameters
    case 'Contour shape, frequency, and duration'
        % Get the clustering parameters, prepare data as if performing k-means
        clusterParameters = inputdlg({'Images height (pixels)','Image width (pixels)','Perplexity (if using t-SNE, ignore for UMAP)','Max number of calls to plot (set to 0 to plot everything)', 'Shape weight','Frequency weight','Duration weight'},...
            'Choose cluster parameters:',1,...
            {'6000','6000','30','2000','1','1','1'});
        if isempty(clusterParameters); return; end
        
        slope_weight = str2double(clusterParameters{5});
        freq_weight = str2double(clusterParameters{6});
        duration_weight = str2double(clusterParameters{7});
        
        % Get the data
        [ClusteringData, clustAssign] = CreateClusteringData(handles, 'forClustering', true);
        
        
        %% Extract features
        ReshapedX   = cell2mat(cellfun(@(x) imresize(x',[1 9]) ,ClusteringData.xFreq,'UniformOutput',0));
        slope       = diff(ReshapedX,1,2);
        slope       = zscore(slope);
        freq        = cell2mat(cellfun(@(x) imresize(x',[1 8]) ,ClusteringData.xFreq,'UniformOutput',0));
        freq        = zscore(freq);
        duration    = repmat(ClusteringData.Duration,[1 8]);
        duration    = zscore(duration);
        
        data = [
            freq     .*  freq_weight,...
            slope    .*  slope_weight,...
            duration .*  duration_weight,...
            ];
        
    case 'Variational autoencoder embeddings'
        clusterParameters = inputdlg({'Images height (pixels)','Image width (pixels)','Perplexity (if using t-SNE, ignore for UMAP)','Max number of calls to plot (set to 0 to plot everything)'},...
            'Choose cluster parameters:',1,...
            {'6000','6000','30','2000'});
        if isempty(clusterParameters); return; end
        
        FromExisting = questdlg('From existing model?','Cluster','Yes','No','No');
        if isempty(FromExisting); return; end
        switch FromExisting % Load Model
            case 'No'
                [encoderNet, decoderNet, options, ClusteringData] = create_VAE_model(handles);
                [FileName, PathName] = uiputfile(fullfile(handles.data.squeakfolder, 'Clustering Models', 'Variational Autoencoder Model.mat'), 'Save clustering model (optional)');
                if ~isnumeric(FileName) % Save the new model
                    save(fullfile(PathName, FileName), 'encoderNet', 'decoderNet', 'options');
                end
            case 'Yes' % Load the VAE model
                [FileName, PathName] = uigetfile(fullfile(handles.data.squeakfolder, 'Clustering Models', '*.mat'), 'Select VAE model');
                if isnumeric(FileName);return;end
                load(fullfile(PathName,FileName),'encoderNet','options');
                [ClusteringData, clustAssign] = CreateClusteringData(handles, 'spectrogramOptions', options.spectrogram, 'scale_duration', options.maxDuration, 'freqRange', options.freqRange, 'forClustering', true);
                if isempty(ClusteringData); return; end
        end
        data = extract_VAE_embeddings(encoderNet, options, ClusteringData);
        freq  = cell2mat(cellfun(@(x) imresize(x',[1 16]) ,ClusteringData.xFreq,'UniformOutput',0));
        freq=zscore(freq,0,'all');
        data=zscore(data,0,'all');
        data=[data freq];
end

imsize = str2double(clusterParameters(1:2))';
perplexity = str2double(clusterParameters{3});
NumberOfCalls = str2double(clusterParameters{4});

% Plot all calls if number of calls is set to 0
if NumberOfCalls == 0 
    NumberOfCalls = size(ClusteringData,1);
end
NumberOfCalls = min(size(ClusteringData,1), NumberOfCalls);

%% Get parameters


% Calculate embeddings
rng default;

% Run embedding
switch embeddingType
    case 't-SNE'
        embed = tsne(data,'Verbose',1,'Perplexity',perplexity);
    case 'UMAP'
        embed = run_umap(data);
end
% Rescale values between 0 and 1
embed = (embed - min(embed)) ./ (max(embed)-min(embed));

ClusteringData.embedY = 1-embed(:,2); % flip Y coordinates so the images looks like the UMAP figure
ClusteringData.embedX = embed(:,1);

switch colorType
    case 'Frequency'
        minfreq = prctile(ClusteringData.MinFreq, 1);
        maxfreq = prctile(ClusteringData.MinFreq + ClusteringData.Bandwidth, 99);
        ColorData = HSLuv_to_RGB(256, 'H',  [0 270], 'S', 100, 'L', 75); % Make a color map for each category
        ColorData = reshape(ColorData,size(ColorData,1),1,size(ColorData,2));
    case 'Cluster'
        [clustAssignID, cName] = findgroups(clustAssign); % Convert categories into numbers
        ClusteringData.Cluster = clustAssignID; % Append the category number to clustering data
        
        % make it so that adjacent clusters are generally different colors.
        % it turns out that this isn't trivial, so try 200 different color
        % orders and use the best one.
        embedings=[ClusteringData.embedY,  ClusteringData.embedX];
        z=unique(clustAssignID);
        for c=1:height(z)
            idx=clustAssignID==z(c);
            clusterCentroids(c,:)=mean(embedings(idx,:));
        end
        % = splitapply(@mean,[ClusteringData.embedY,  ClusteringData.embedX], clustAssignID);
        clusterCentroids = pdist2(clusterCentroids, clusterCentroids);
        hueAngle = [
            sin(linspace(0,2*pi, length(cName)))
            cos(linspace(0,2*pi, length(cName)))]';
        hueDistance = pdist2(hueAngle, hueAngle, 'cosine');
        colorSeperation = zeros(200,1);
        colorOrders = zeros(200,length(cName));
        for i = 1:200
            colorOrders(i,:) = randperm(length(cName)); % Randomize the order of the colors
            colorSeperation(i) = sum((1-clusterCentroids).* hueDistance(colorOrders(i,:),colorOrders(i,:)), 'all');
        end
        [~, idx] = max(colorSeperation)
        colorOrder = colorOrders(idx,:)
        
        hueRange = [0 360-360/length(cName)];
        cMap = HSLuv_to_RGB(length(cName), 'H', hueRange, 'S', 100, 'L', 75); % Make a color map for each category
        cMap = cMap(colorOrder,:);
        figure('Color','w') % Display the colors
        h = image(reshape(cMap,[],1,3));
        yticklabels(h.Parent, cellstr(cName));
        yticks(h.Parent,1:length(cName));
end


%% Create the image
im = zeros([imsize+padding*2,3],'uint8');

% Only plot the X number of calls
calls2plot = randsample(size(ClusteringData, 1), NumberOfCalls, false);

for i = calls2plot'
    call = ClusteringData(i, :);
    % Get x and y coordinates to place with image
    iy = imsize(1) * call.embedY;
    iy = iy:iy + size(call.Spectrogram{:},1) - 1;
    iy = round(iy - mean(size(call.Spectrogram{:},1))) + padding;
    ix = imsize(2) * call.embedX;
    ix = ix:ix + size(call.Spectrogram{:},2) - 1;
    ix = round(ix - mean(size(call.Spectrogram{:},2))) + padding;
    
    % Either use the call pitch or the cluster id to apply a color mask
    switch colorType
        case 'Frequency'
            % Interpolate the color data
            freqdata = linspace(call.MinFreq, call.MinFreq + call.Bandwidth, size(call.Spectrogram{:},1));
            colorMask = interp1(linspace(minfreq, maxfreq, size(ColorData,1)), ColorData, freqdata, 'nearest', 'extrap');
        case 'Cluster'
            colorMask = reshape(cMap(call.Cluster,:),1,1,3);
    end
    im(iy,ix,:) = max(im(iy,ix,:),uint8(single(call.Spectrogram{:}) .* colorMask - blackLevel));
end



% Crop the image at the first and last non-empty pixel
[y1,~] = find(max(max(im,[],3),[],2),1,'first');
[y2,~] = find(max(max(im,[],3),[],2),1,'last');

[~,x1] = find(max(max(im,[],3),[],1),1,'first');
[~,x2] = find(max(max(im,[],3),[],1),1,'last');

[fname,fpath] = uiputfile({'*.jpg'; '*.png'},'Save image', 'embeddings');
imwrite(im2uint8(im(y1:y2,x1:x2,:)),fullfile(fpath,fname))

% Open the image in a file manager
if ispc % Open the file in windows explorer
    system(['explorer.exe /select,"' fullfile(fpath,fname) '"']);
    % winopen(fullfile(fpath,fname));
elseif ismac % Open the file in finder - UNTESTED (I don't have a mac)
    system(['open -a Finder "' fullfile(fpath,fname) '"']);
elseif isunix % Open the file in linux file manager - UNTESTED
    system(['xdg-open "' fullfile(fpath) '"']); % open folder in file manager
    % system(['xdg-open "' fullfile(fpath, fname) '"']); % open image in default viewer
end