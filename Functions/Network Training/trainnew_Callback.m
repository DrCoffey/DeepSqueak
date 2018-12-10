function trainnew_Callback(hObject, eventdata, handles)
%% Train a new neural network
cd(handles.squeakfolder);

% Apparently, "wind" is a function name, so initialize it as empty
wind = [];

waitfor(msgbox('Select Image Tables'))
[trainingdata trainingpath] = uigetfile(['Training/*.mat'],'Select Training File(s) for Training ','MultiSelect', 'on');
TrainingTables = [];
if ischar(trainingdata)==1
   tmp{1}=trainingdata;
   clear trainingdata
   trainingdata=tmp;
end
AllSettings = [];
for i = 1:length(trainingdata)
load([trainingpath trainingdata{i}]);
TrainingTables = [TrainingTables; TTable];
AllSettings = [AllSettings; wind noverlap nfft cont];
end
warn = 'Train anyway';
if size(unique(AllSettings,'rows'),1) ~= 1
    warn = questdlg({'Not all images were created with the same spectrogram settings','Network may not work as expected'}, ...
	'Warning','Train anyway','Cancel','Cancel');
waitfor(warn)
end
if strcmp(warn,'Train anyway')
choice = questdlg(['Train from existing network?'], ...
	'Yes', 'No');
switch choice
    case 'Yes'
        [NetName NetPath] = uigetfile(handles.settings.networkfolder,'Select Existing Network');
        load([NetPath NetName]);
        layers = detector.Network.Layers;
        [detector layers, options] = TrainSqueakDetector(TrainingTables,layers);
    case 'No'
        [detector layers, options] = TrainSqueakDetector(TrainingTables);
end
[FileName,PathName,FilterIndex] = uiputfile([handles.settings.networkfolder '/*.mat'],'Save New Network');
wind = max(AllSettings(:,1));
noverlap = max(AllSettings(:,2));
nfft = max(AllSettings(:,3));
cont = max(AllSettings(:,4));

save([PathName,FileName],'detector','layers','options','wind','noverlap','nfft','cont');

% Update the menu
update_folders(hObject, eventdata, handles);
guidata(hObject, handles);
end
