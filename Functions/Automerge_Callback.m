function Calls = Automerge_Callback(Calls1,Calls2,AudioFile)
%% Merges two detection files into one

Calls=[Calls1, Calls2];

% Audio info
audio_info = audioinfo(AudioFile);

%% Merge overlapping boxes
AllBoxes = vertcat(Calls.Box);
AllScores = vertcat(Calls.Score);
AllClass = vertcat(Calls.Type);
AllPowers = vertcat(Calls.Power);

Calls = merge_boxes(AllBoxes, AllScores, AllClass, AllPowers, audio_info, 1, 0, 0);
