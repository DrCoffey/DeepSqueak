function filename = backgroundAssignmentFile(audiofile, backgroundfolder)
%% Name of the file that says which background a recording uses
% One small file per recording, in the background folder, named after the
% recording. It exists only for recordings that have been given a background.
[~, name] = fileparts(audiofile);
filename = fullfile(backgroundfolder, [name '_background.mat']);
end
