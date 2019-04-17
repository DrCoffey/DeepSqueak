function [IDX,C,SUMD,K]=kmeans_opt(X,varargin)
%%% [IDX,C,SUMD,K]=kmeans_opt(X,varargin) returns the output of the k-means
%%% algorithm with the optimal number of clusters, as determined by the ELBOW
%%% method. this function treats NaNs as missing data, and ignores any rows of X that
%%% contain NaNs.
%%%
%%% [IDX]=kmeans_opt(X) returns the cluster membership for each datapoint in
%%% vector X.
%%%
%%% [IDX]=kmeans_opt(X,MAX) returns the cluster membership for each datapoint in
%%% vector X. The Elbow method will be tried from 1 to MAX number of
%%% clusters (default: square root of the number of samples)
%%% [IDX]=kmeans_opt(X,MAX,CUTOFF) returns the cluster membership for each datapoint in
%%% vector X. The Elbow method will be tried from 1 to MAX number of
%%% clusters and will choose the number which explains a fraction CUTOFF of
%%% the variance (default: 0.95)
%%% [IDX]=kmeans_opt(X,MAX,CUTOFF,REPEATS) returns the cluster membership for each datapoint in
%%% vector X. The Elbow method will be tried from 1 to MAX number of
%%% clusters and will choose the number which explains a fraction CUTOFF of
%%% the variance, taking the best of REPEATS runs of k-means (default: 3).
%%% [IDX,C]=kmeans_opt(X,varargin) returns in addition, the location of the
%%% centroids of each cluster.
%%% [IDX,C,SUMD]=kmeans_opt(X,varargin) returns in addition, the sum of
%%% point-to-cluster-centroid distances.
%%% [IDX,C,SUMD,K]=kmeans_opt(X,varargin) returns in addition, the number of
%%% clusters.

%%% sebastien.delandtsheer@uni.lu
%%% sebdelandtsheer@gmail.com
%%% Thomas.sauter@uni.lu


[m,~]=size(X); %getting the number of samples

if nargin>1, ToTest=cell2mat(varargin(1)); else, ToTest=ceil(sqrt(m)); end
if nargin>2, Cutoff=cell2mat(varargin(2)); else, Cutoff=0.95; end
if nargin>3, Repeats=cell2mat(varargin(3)); else, Repeats=3; end

D=zeros(ToTest,1); %initialize the results matrix
XData= 1:1:ToTest;
% Create figure
figure1 = figure('Color',[1 1 1],'Position',[200 200 600 500]);
axes1 = axes('Parent',figure1,'LineWidth',1.5,'TickDir','out',...
    'FontSmoothing','on',...
    'FontSize',12);
ylabel(axes1,'Normalized Error');
xlabel(axes1,'Number of Clusters');
hold on
h=plot(XData,D,'LineWidth',0.5,'Marker','o','MarkerSize',3);
h.XDataSource='XData';
h.YDataSource='D';
for c=1:1:ToTest %for each sample
    [~,~,dist]=kmeans(X,c,'emptyaction','drop'); %compute the sum of intra-cluster distances
    tmp=sum(dist); %best so far
    if c==1;
       tmp2=sum(dist);
    end
    for cc=2:Repeats %repeat the algo
        [~,~,dist]=kmeans(X,c,'emptyaction','drop');
        tmp=min(sum(dist),tmp);    
    end
    D(c,1)=tmp/tmp2; %collect the best so far in the results vecor
    refreshdata(h,'caller');
    drawnow
end

[res_x, idx_of_result] = knee_pt(D, 1:1:ToTest, 1);
scatter(res_x,D(idx_of_result),50,'MarkerEdgeColor',[1 0 0],...
              'MarkerFaceColor',[1 0 0]);
title(axes1,['Elbow Location: ' num2str(idx_of_result)]);
          
K=idx_of_result;
% [r,~]=find(PC>Cutoff); %find the best index
% K=r(1,1); %get the optimal number of clusters
[IDX,C,SUMD]=kmeans(X,K); %now rerun one last time with the optimal number of clusters

end