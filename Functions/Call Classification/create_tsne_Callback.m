function create_tsne_Callback(hObject, eventdata, handles)
% Creates a 2-dimensional t-sne image of calls.


padding = 1000; % Pad the temp image by this amount, so that calls near the border still fit.
blackLevel = 10; % Subtract this value from each call image to make a nicer picture.

% Get the clustering parameters, prepare data as if performing k-means
clusterParameters= inputdlg({'Shape weight','Frequency weight','Duration weight','Images height (pixels)','Image width (pixels)','Perplexity','Max number of calls to plot (set to 0 to plot everything)'},'Choose cluster parameters:',1,{'1','1','1','9000','6000','30','2000'});
if isempty(clusterParameters); return; end

% Choose to assign colors by the call classification or by pitch.
colorType = questdlg({'Color the calls by frequecy (pitch), or by cluster identity?','If coloring by cluster, you may not use pre-extracted contours'}, 'Choose Color', 'Frequency' , 'Cluster', 'Frequency');
if isempty(colorType); return; end

slope_weight = str2double(clusterParameters{1});
freq_weight = str2double(clusterParameters{2});
duration_weight = str2double(clusterParameters{3});
imsize = str2double(clusterParameters(4:5))';
perplexity = str2double(clusterParameters{6});
NumberOfCalls = str2double(clusterParameters{7});

% Get the data
[a, clustAssign] = CreateClusteringData(handles.data, 1);

if NumberOfCalls == 0
    NumberOfCalls = size(a,1);
end

%% Extract features
nrm = @(x) ((x - mean(x,1)) ./ std(x,1));
ReshapedX=cell2mat(cellfun(@(x) imresize(x',[1 9]) ,a(:,4),'UniformOutput',0));
slope = diff(ReshapedX,1,2);
slope = nrm(slope);
freq=cell2mat(cellfun(@(x) imresize(x',[1 8]) ,a(:,4),'UniformOutput',0));
freq = nrm(freq);
duration = repmat(cell2mat(a(:,3)),[1 8]);
duration = nrm(duration);

data = [
    freq     .*  freq_weight,...
    slope    .*  slope_weight,...
    duration .*  duration_weight,...
    ];

%% Get parameters


% Calculate embeddings
rng default;
embed = tsne(data,'Verbose',1,'Perplexity',perplexity);
embed = (embed - min(embed)) ./ (max(embed)-min(embed));

a(:,10) = num2cell(embed(:,1));
a(:,11) = num2cell(embed(:,2));


switch colorType
    case 'Frequency'
        minfreq = floor(min([a{:,2}]))-1; % Find the min frequency
        maxfreq = ceil(max([a{:,2}] + [a{:,9}])); % Find the max frequency
        ColorData = jet(maxfreq - minfreq);
        ColorData = reshape(ColorData,size(ColorData,1),1,size(ColorData,2));
    case 'Cluster'
        [clustAssignID, cName] = findgroups(clustAssign); % Convert categories into numbers
        a(:,13) = num2cell(clustAssignID); % Append the category number to clustering data
        hueRange = [0 360];
        cMap = HSLuv_to_RGB(length(cName)+1, 'H', hueRange, 'S', 100, 'L', 75); % Make a color map for each category 
        colorOrder = randperm(length(cName)+1); % Randomize the order of the colors
        cMap = cMap(colorOrder,:); 
        figure('Color','w') % Display the colors
        h = image(reshape(cMap,[],1,3));
        yticks(h.Parent,1:length(cName))
        yticklabels(h.Parent, cellstr(cName))
end





%% Create the image
im = zeros([imsize+padding*2,3],'uint8');

% Only plot the X number of calls
calls2plot = datasample(a,min(size(a,1),NumberOfCalls),1,'Replace',false);

for i = calls2plot'
    
    % Get x and y coordinates to place with image
    iy = imsize(1) * i{10};
    iy = iy:iy+size(i{1},1)-1;
    iy = round(iy - mean(size(i{1},1))) + padding;
    ix = imsize(2) * i{11};
    ix = ix:ix+size(i{1},2)-1;
    ix = round(ix - mean(size(i{1},2))) + padding;
    
    % Either use the call pitch or the cluster id to apply a color mask
    switch colorType
        case 'Frequency'
            % High freq to low freq
            freqdata = round(linspace(i{2} + i{9},i{2},size(i{1},1)));            
            colorMask = ColorData(freqdata-minfreq,:,:);
        case 'Cluster'
            colorMask = reshape(cMap(i{13},:),1,1,3);
    end
    
    im(iy,ix,:) = max(im(iy,ix,:),uint8(single(i{1}) .* colorMask - blackLevel));
    
end



% Crop the image at the first and last non-empty pixel
[y1,~] = find(max(max(im,[],3),[],2),1,'first');
[y2,~] = find(max(max(im,[],3),[],2),1,'last');

[~,x1] = find(max(max(im,[],3),[],1),1,'first');
[~,x2] = find(max(max(im,[],3),[],1),1,'last');

[fname,fpath] = uiputfile('TNSE.jpg','Save image');
imwrite(im2uint8(im(y1:y2,x1:x2,:)),fullfile(fpath,fname))