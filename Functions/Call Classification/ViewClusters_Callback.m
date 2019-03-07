function ViewClusters_Callback(hObject, eventdata, handles)
[ClusteringData,clustAssign] = CreateClusteringData(handles.data, 0);

[clusterName, rejected, finished] = clusteringGUI(clustAssign, ClusteringData,1);

% Save the clusters
if finished == 1
    saveChoice =  questdlg('Update files with new clusters?','Save clusters','Yes','No','No');
    switch saveChoice
        case 'Yes'
            [~, ~, clustAssign] = unique(clustAssign);
            UpdateCluster(ClusteringData, clustAssign, clusterName, rejected)
        case 'No'
            return
    end
end

end
