
% --------------------------------------------------------------------
function create_tsne_Callback(hObject, eventdata, handles)
% hObject    handle to create_tsne (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Creates a 2-dimensional t-sne image of calls.


% Get the clustering parameters, prepare data as if performing k-means
clusterParameters= inputdlg({'Shape weight','Frequency weight','Duration weight','Images height (pixels)','Image width (pixels)','Perplexity'},'Choose cluster parameters:',1,{'1','1','1','9000','6000','30'});
if isempty(clusterParameters); return; end

slope_weight = str2double(clusterParameters{1});
freq_weight = str2double(clusterParameters{2});
duration_weight = str2double(clusterParameters{3});
imsize = str2double(clusterParameters(4:5))';
perplexity = str2double(clusterParameters{6});

padding = 1000;

% Get the data
% a = ClusteringData
[a] = CreateClusteringData(hObject, eventdata, handles);



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
minfreq = floor(min([a{:,2}]))-1;
maxfreq = ceil(max([a{:,2}] + [a{:,9}]));
ColorData = jet(maxfreq - minfreq);
ColorData = reshape(ColorData,size(ColorData,1),1,size(ColorData,2));

% Calculate embeddings
embed = tsne(data,'Verbose',1,'Perplexity',perplexity);
embed = (embed - min(embed)) ./ (max(embed)-min(embed));

a(:,10) = num2cell(embed(:,1));
a(:,11) = num2cell(embed(:,2));


%% Create the image
im = zeros([imsize+padding*2,3],'uint8');

NumberOfCalls = 2000;
% Only plot the X number of calls
calls2plot = datasample(a,min(size(a,1),NumberOfCalls),1,'Replace',false);

for i = calls2plot'
    
    % High freq to low freq
    freqdata = round(linspace(i{2} + i{9},i{2},size(i{1},1)));
    
    %     freqdata = round(linspace(i{2} + i{9}+10,i{2}-30,size(i{1},1)));
    %     freqdata(freqdata <= 0) = 1;
    %     freqdata(freqdata >= maxfreq - minfreq) = maxfreq - minfreq;
    
    
    iy = imsize(1) * i{10};
    iy = iy:iy+size(i{1},1)-1;
    iy = round(iy - mean(size(i{1},1))) + padding;
    ix = imsize(2) * i{11};
    ix = ix:ix+size(i{1},2)-1;
    ix = round(ix - mean(size(i{1},2))) + padding;
    
    im(iy,ix,:) = max(im(iy,ix,:),uint8(single(i{1}).*ColorData(freqdata-minfreq,:,:))-10);
    %     im(iy,ix,:) = max(im(iy,ix,:),uint8(single(i{1}).*ColorData(freqdata,:,:))-10);
    
end



% Crop the image at the first and last non-empty pixel
[y1,~] = find(max(max(im,[],3),[],2),1,'first');
[y2,~] = find(max(max(im,[],3),[],2),1,'last');

[~,x1] = find(max(max(im,[],3),[],1),1,'first');
[~,x2] = find(max(max(im,[],3),[],1),1,'last');

[fname,fpath] = uiputfile('TNSE.jpg','Save image');
imwrite(im2uint8(im(y1:y2,x1:x2,:)),fullfile(fpath,fname))