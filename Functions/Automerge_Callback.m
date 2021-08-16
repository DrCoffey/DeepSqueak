function Calls = Automerge_Callback(Calls1,Calls2,AudioFile)
%% Merges two detection files into one

Calls=[Calls1; Calls2];

% Audio info
audio_info = audioinfo(AudioFile);

%% Merge overlapping boxes
Calls = merge_boxes(Calls.Box, Calls.Score, Calls.Type, audio_info, 1, 0, 0);
