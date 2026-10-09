function info = backgroundInfo(Background)
%% Short provenance record to store with anything computed from a spectrogram
% Says whether background subtraction was applied and, if so, with which
% definition. Background may be [] (no subtraction).

info = struct('used', false, 'id', '', 'name', '', 'file', '', 'percentile', [], 'flickerScaling', false);
if isempty(Background)
    return
end
if ischar(Background)
    error('DeepSqueak:background:unresolved', 'The background for this recording has not been looked up.');
end
info.used = true;
info.id = Background.id;
info.name = Background.name;
info.percentile = Background.percentile;
info.flickerScaling = isfield(Background, 'flickerScaling') && Background.flickerScaling;
if isfield(Background, 'sourceFile')
    info.file = Background.sourceFile;
end
end
