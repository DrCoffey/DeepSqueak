function UpdateCluster(ClusteringData, clustAssign, clusterName, rejected)
%% This function saves the files with new cluster names

h = waitbar(0,'Initializing');

[files, ~, file_idx] = unique(ClusteringData.Filename,'stable');

% Merge "Noise" and "noise"
clusterName = mergecats(clusterName, {'Noise', 'noise'});

% Apply cluster names to clustAssign
if ~iscategorical(clustAssign) 
    clustAssign = clusterName(clustAssign);
end

% Convert rejected into a logical for indexing
rejected = logical(rejected);

% Classify all rejected calls as 'Noise'
clustAssign(rejected) = 'Noise';

% Reject all calls classified as 'Noise'
rejected(clustAssign == 'Noise') = 1;

for i = 1:length(files)

    Calls = loadCallfile(files{i},[]);

    % Find the index of the clustering data that belongs to the file
    cluster_idx = find(file_idx == i);

    % Find the index of the calls in the file that correspond the the clustering data
    %call_idx = [ClusteringData{cluster_idx, 7}];
    call_idx = [ClusteringData.callID(cluster_idx)];

    % Update call type with cluster names
    Calls.Type(call_idx) = clustAssign(cluster_idx);

    % Reject calls classified as 'Noise'
    Calls.Accept(call_idx(rejected(cluster_idx))) = 0;

    waitbar(i/length(files),h,['Saving File ' num2str(i) ' of '  num2str(length(files))]);
    save(files{i},'Calls', '-append');

end
close(h)
end
