function Background = findBackgroundDefinition(backgroundfolder, id, definitionFile)
%% Find a background definition in a folder by its id
% definitionFile is the file name it had when assigned, tried first. The
% definition is found by id even if the file has since been renamed.

% Definitions never change, so a loaded one can be reused
persistent cache
if isempty(cache) || cache.Count > 8
    cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
end
key = [id '|' backgroundfolder];
if isKey(cache, key)
    Background = cache(key);
    if isfile(Background.sourceFile)
        return
    end
end

found = '';
if nargin > 2 && ~isempty(definitionFile) && isfile(fullfile(backgroundfolder, definitionFile)) ...
        && strcmp(definitionId(fullfile(backgroundfolder, definitionFile)), id)
    found = fullfile(backgroundfolder, definitionFile);
else
    files = dir(fullfile(backgroundfolder, '*.mat'));
    for i = 1:length(files)
        if endsWith(files(i).name, '_background.mat'); continue; end
        if strcmp(definitionId(fullfile(files(i).folder, files(i).name)), id)
            found = fullfile(files(i).folder, files(i).name);
            break
        end
    end
end
if isempty(found)
    if nargin < 3; definitionFile = ''; end
    error('DeepSqueak:background:definitionMissing', ...
        'Background definition %s (last known as "%s") was not found in %s.', id(1:12), definitionFile, backgroundfolder);
end

Background = loadBackgroundDefinition(found);
cache(key) = Background;
end

function id = definitionId(filename)
% The id of the definition in a file, or '' if it is not a definition
id = '';
variables = who('-file', filename);
if ismember('BackgroundId', variables)
    data = load(filename, 'BackgroundId');
    id = data.BackgroundId;
elseif ismember('Background', variables)
    data = load(filename, 'Background');
    if isfield(data.Background, 'id'); id = data.Background.id; end
end
end
