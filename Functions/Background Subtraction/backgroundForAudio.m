function [Background, assignment] = backgroundForAudio(audio, backgroundfolder)
%% The background definition assigned to a recording, or [] if it has none
% audio             audio file name, or the struct returned by audioinfo
% backgroundfolder  folder holding assignment files and definitions
%
% Background   the verified definition, or [] when the recording has no
%              assignment file in the folder
% assignment   contents of the assignment file, or []
%
% A recording that HAS an assignment which cannot be honoured (definition
% missing or altered, different recording with the same name, sample rate
% mismatch) is an error. It is never treated as having no background.

Background = [];
assignment = [];
if ischar(audio) || isstring(audio)
    audio = audioinfo(audio);
end
if isempty(backgroundfolder) || ~isfolder(backgroundfolder)
    return
end
filename = backgroundAssignmentFile(audio.Filename, backgroundfolder);
if ~isfile(filename)
    return
end

data = load(filename);
if ~isfield(data, 'BackgroundAssignment')
    error('DeepSqueak:background:badAssignment', '%s is not a background assignment file.', filename);
end
assignment = data.BackgroundAssignment;

[~, name, ext] = fileparts(audio.Filename);
if ~strcmp(assignment.audioName, [name ext]) || assignment.audioTotalSamples ~= audio.TotalSamples || assignment.audioSampleRate ~= audio.SampleRate
    error('DeepSqueak:background:wrongRecording', ...
        ['The background assignment %s was made for %s (%d samples at %g Hz), which is not this recording ' ...
        '(%s, %d samples at %g Hz). Remove or redo the assignment.'], ...
        filename, assignment.audioName, assignment.audioTotalSamples, assignment.audioSampleRate, ...
        [name ext], audio.TotalSamples, audio.SampleRate);
end

Background = findBackgroundDefinition(backgroundfolder, assignment.backgroundId, assignment.definitionFile);
if Background.SampleRate ~= audio.SampleRate
    error('DeepSqueak:background:sampleRate', ...
        'Background "%s" was defined from %g Hz audio and cannot be applied to %s (%g Hz).', ...
        Background.name, Background.SampleRate, [name ext], audio.SampleRate);
end
end
