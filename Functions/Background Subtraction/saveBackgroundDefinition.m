function saveBackgroundDefinition(Background, filename)
%% Save a background definition. Definitions are never overwritten.
% A definition is identified by its content, and results record which
% definition produced them, so an existing file must not change.

if isfile(filename)
    error('DeepSqueak:background:exists', ...
        'A file named %s already exists. Background definitions are not overwritten; choose a new name.', filename);
end
if ~strcmp(Background.id, backgroundHash(Background))
    error('DeepSqueak:background:corrupt', 'The background definition does not match its id and was not saved.');
end
if isfield(Background, 'sourceFile')
    Background = rmfield(Background, 'sourceFile');
end
% The id is also saved on its own, so a definition can be recognised without loading its audio
BackgroundId = Background.id;
save(filename, 'Background', 'BackgroundId', '-v7.3');
end
