function UpdateCluster(ClusteringData, clustAssign, clusterName, rejected)
%% This function saves the files with new cluster names

h = waitbar(0,'Initializing');

[files, ~, file_idx] = unique(ClusteringData(:,6),'stable');

% Merge "Noise" and "noise"
clusterName = mergecats(clusterName, {'Noise', 'noise'});

% Apply cluster names to clustAssign
clustAssign = clusterName(clustAssign);

% Convert rejected into a logical for indexing
rejected = logical(rejected);

% Classify all rejected calls as 'Noise'
clustAssign(rejected) = 'Noise';

% Reject all calls classified as 'Noise'
rejected(clustAssign == 'Noise') = 1;

for i = 1:length(files)
    
    % Load the file
    load(files{i}, 'Calls');
    % Backwards compatibility with struct format for detection files
    if isstruct(Calls); Calls = struct2table(Calls); end
    
    % Find the index of the clustering data that belongs to the file
    cluster_idx = find(file_idx == i);
    
    % Find the index of the calls in the file that correspond the the clustering data
    call_idx = [ClusteringData{cluster_idx, 7}];

    % Update call type with cluster names
    Calls.Type(call_idx) = clustAssign(cluster_idx);
    
    % Reject calls classified as 'Noise'
    Calls.Accept(call_idx(rejected(cluster_idx))) = 0;
    
    waitbar(i/length(files),h,['Saving File ' num2str(i) ' of '  num2str(length(files))]);
    save(files{i},'Calls','-v7.3');
    
end
close(h)
end