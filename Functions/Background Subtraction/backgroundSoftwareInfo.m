function info = backgroundSoftwareInfo()
%% What software produced a background definition
info = struct('matlab', version, 'deepsqueak', '', 'gitCommit', '');
squeakfolder = fileparts(fileparts(fileparts(mfilename('fullpath'))));
try
    tokens = regexp(fileread(fullfile(squeakfolder, 'CHANGELOG.md')), '## ([.\d])+', 'tokens', 'once');
    info.deepsqueak = tokens{1};
catch
end
try
    [status, commit] = system(sprintf('git -C "%s" rev-parse HEAD', squeakfolder));
    if status == 0
        info.gitCommit = strtrim(commit);
    end
catch
end
end
