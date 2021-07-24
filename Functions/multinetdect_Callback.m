% --- Executes on button press in multinetdect.
function multinetdect_Callback(hObject, eventdata, handles, SingleDetect)


if isempty(handles.audiofiles)
    errordlg('No Audio Selected')
    return
end
if isempty(handles.networkfiles)
    errordlg('No Network Selected')
    return
end
if exist(handles.data.settings.detectionfolder,'dir')==0
    errordlg('Please Select Output Folder')
    uiwait
    load_detectionFolder_Callback(hObject, eventdata, handles)
    handles = guidata(hObject);  % Get newest version of handles
end

%% Do this if button Multi-Detect is clicked
if ~SingleDetect
    audioselections = listdlg('PromptString','Select Audio Files:','ListSize',[500 300],'ListString',handles.audiofilesnames);
    if isempty(audioselections)
        return
    end
    networkselections = listdlg('PromptString','Select Networks:','ListSize',[500 300],'ListString',handles.networkfilesnames);
    if isempty(audioselections)
        return
    end
    
  
    %% Do this if button Single-Detect is clicked
elseif SingleDetect
    audioselections = get(handles.AudioFilespopup,'Value');
    networkselections = get(handles.neuralnetworkspopup,'Value');
end

Settings = [];
for k=1:length(networkselections)
    prompt = {'Total Analysis Length (Seconds; 0 = Full Duration)','Frequency Cut Off High (kHZ)','Frequency Cut Off Low (kHZ)','Score Threshold (0-1)','Append Date to FileName (1 = yes)'};
    dlg_title = ['Settings for ' handles.networkfiles(networkselections(k)).name];
    num_lines=[1 100]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
    def = handles.data.settings.detectionSettings;
    current_settings = str2double(inputdlg(prompt,dlg_title,num_lines,def,options));
    
    if isempty(current_settings) % Stop if user presses cancel
        return
    end
    
    Settings = [Settings, current_settings];
    handles.data.settings.detectionSettings = sprintfc('%g',Settings(:,1))';
end

if isempty(Settings)
    return
end

% Save the new settings
handles.data.saveSettings();

update_folders(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles


%% For Each File
for j = 1:length(audioselections)
    CurrentAudioFile = audioselections(j);
    % For Each Network
    Calls = [];
    for k=1:length(networkselections)
        h = waitbar(0,'Loading neural network...');
        
        AudioFile = fullfile(handles.audiofiles(CurrentAudioFile).folder,handles.audiofiles(CurrentAudioFile).name);
        
        networkname = handles.networkfiles(networkselections(k)).name;
        networkpath = fullfile(handles.networkfiles(networkselections(k)).folder,networkname);
        NeuralNetwork=load(networkpath);%get currently selected option from menu
        close(h);
        
        Calls = [Calls; SqueakDetect(AudioFile,NeuralNetwork,handles.audiofiles(CurrentAudioFile).name,Settings(:,k),j,length(audioselections),networkname)];

    end
    
    [~,audioname] = fileparts(AudioFile);
    detectiontime=datestr(datetime('now'),'yyyy-mm-dd HH_MM PM');
    
    if isempty(Calls)
        fprintf(1,'No Calls found in: %s \n',audioname)
        continue
    end
    
    h = waitbar(1,'Saving...');
    Calls = Automerge_Callback(Calls, [], AudioFile);
    
    %% Save the file
    % Save the Call table, detection metadata, and results of audioinfo
    
    % Append date to filename
    if Settings(5)
        fname = fullfile(handles.data.settings.detectionfolder,[audioname ' ' detectiontime '.mat']);
    else
        fname = fullfile(handles.data.settings.detectionfolder,[audioname '.mat']);
    end
    
    % Display the number of calls
    fprintf(1,'%d Calls found in: %s \n',height(Calls),audioname)
    
    if ~isempty(Calls)
        detection_metadata = struct(...
            'Settings', Settings,...
            'detectiontime', detectiontime,...
            'networkselections', {handles.networkfiles(networkselections).name});
        audiodata = audioinfo(AudioFile);
        save(fname,'Calls', 'detection_metadata', 'audiodata' ,'-v7.3', '-mat');
    end
    
    delete(h)
end
update_folders(hObject, eventdata, handles);
guidata(hObject, handles);
