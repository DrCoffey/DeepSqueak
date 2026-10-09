function removed = removeBackgroundAssignment(audiofile, backgroundfolder)
%% Stop a recording from using a background
% Deletes the recording's assignment file. The definition is kept.
filename = backgroundAssignmentFile(audiofile, backgroundfolder);
removed = isfile(filename);
if removed
    delete(filename);
end
end
