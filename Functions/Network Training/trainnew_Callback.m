function trainnew_Callback(hObject, eventdata, handles)
%% Train a new neural network
cd(handles.data.squeakfolder);

% Apparently, "wind" is a function name, so initialize it as empty
wind = [];

%% Select the tables that contains the training data
waitfor(msgbox('Select Image Tables'))
[trainingdata, trainingpath] = uigetfile(['Training/*.mat'],'Select Training File(s) for Training ','MultiSelect', 'on');
TrainingTables = [];
trainingdata = cellstr(trainingdata);


%% Load the data into a single table
AllSettings = [];
AllBackgrounds = [];
for i = 1:length(trainingdata)
    load([trainingpath trainingdata{i}],'TTable','wind','noverlap','nfft','imLength','imScale');
    TrainingTables = [TrainingTables; TTable];
    AllSettings = [AllSettings; wind noverlap nfft];
    % Were these images made from background subtracted spectrograms?
    if ismember('background', who('-file', [trainingpath trainingdata{i}]))
        tmp = load([trainingpath trainingdata{i}], 'background');
        AllBackgrounds = [AllBackgrounds; tmp.background];
    else
        AllBackgrounds = [AllBackgrounds; backgroundInfo([])];
    end
end

%% Create a warning if only some images were background subtracted
if length(unique([AllBackgrounds.used])) > 1
    mixed = questdlg({'Some images were made with background subtraction and some without','Network may not work as expected'}, ...
        'Warning','Train anyway','Cancel','Cancel');
    if ~strcmp(mixed,'Train anyway'); return; end
end
background = backgroundInfo([]);
background.used = any([AllBackgrounds.used]);
background.id = strjoin(unique({AllBackgrounds.id}), ', ');
background.name = strjoin(unique({AllBackgrounds.name}), ', ');
background.file = strjoin(unique({AllBackgrounds.file}), ', ');

%% Create a warning if training files were created with different parameters
warningmsg = 'Train anyway';
if size(unique(AllSettings,'rows'),1) ~= 1
    warningmsg = questdlg({'Not all images were created with the same spectrogram settings','Network may not work as expected'}, ...
        'Warning','Train anyway','Cancel','Cancel');
    waitfor(warningmsg)
end
if ~strcmp(warningmsg,'Train anyway'); return; end

%% Train the network
choice = questdlg('Train from existing network?', 'Yes', 'No');
switch choice
    case 'Yes'
        [NetName, NetPath] = uigetfile(handles.data.settings.networkfolder,'Select Existing Network');
        load([NetPath NetName],'detector');
        [detector, layers, options] = TrainSqueakDetector(TrainingTables,detector);
    case 'No'
        [detector, layers, options] = TrainSqueakDetector(TrainingTables);
end

%% Save the new network
[FileName,PathName] = uiputfile(fullfile(handles.data.settings.networkfolder,'*.mat'),'Save New Network');
wind = max(AllSettings(:,1));
noverlap = max(AllSettings(:,2));
nfft = max(AllSettings(:,3));

version = handles.DSVersion;
save(fullfile(PathName,FileName),'detector','layers','options','wind','noverlap','nfft','version','imLength','imScale','background');

%% Update the menu
update_folders(hObject, eventdata, handles);
guidata(hObject, handles);

