function Background = loadBackgroundDefinition(filename)
%% Load and verify a background definition
% Fails loudly if the file is missing, is not a background definition, or
% no longer matches the id it was created with.

if ~isfile(filename)
    error('DeepSqueak:background:missing', 'Background definition not found: %s', filename);
end
if ~ismember('Background', who('-file', filename))
    error('DeepSqueak:background:notDefinition', '%s is not a background definition.', filename);
end
data = load(filename, 'Background');
Background = data.Background;

if ~isfield(Background, 'formatVersion') || ~ismember(Background.formatVersion, [1 2 3])
    error('DeepSqueak:background:version', '%s uses a background format this version of the code does not understand.', filename);
end
if ~strcmp(Background.id, backgroundHash(Background))
    error('DeepSqueak:background:corrupt', ...
        '%s has been altered since it was created (its content does not match its id). It will not be used.', filename);
end

% Where it was loaded from. Not part of the saved definition.
Background.sourceFile = filename;
end
